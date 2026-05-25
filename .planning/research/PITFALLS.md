# Pitfalls Research — Lista Smart

**Stack:** Flutter + flutter_riverpod ^2.5.1 + go_router ^14.0.0 + shared_preferences ^2.2.0
**Researched:** 2026-05-25
**Confidence:** HIGH (all claims verified against official docs, source code analysis, or high-reputation community sources)

---

## Critical Pitfalls (Will Break the Build/App)

### C-1: GoRouter Instance Created Inside Widget Tree

**Problem:** Declaring `GoRouter(...)` inside a `build()` method or as a local variable in a widget creates a new instance on every rebuild. This causes a "multiple widgets used the same GlobalKey" crash during hot reload and produces stale navigation state in production.

**Symptoms:**
- `Exception: Multiple widgets used the same GlobalKey` on hot reload
- Navigation history resets unexpectedly on state change
- `refreshListenable` fires but router silently ignores it

**Prevention:**
```dart
// WRONG — inside build() or as local in ConsumerWidget
class App extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(routes: [...]);  // recreated every build
    return MaterialApp.router(routerConfig: router);
  }
}

// CORRECT — declare as a Riverpod provider so it is created once
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) => ref.read(routerNotifierProvider).redirect(context, state),
    routes: [...],
  );
});
```

**Phase to address:** Phase 1 (Project Bootstrap / Navigation Setup)

---

### C-2: Notifier Instantiated by Hand / Stored in Variable

**Problem:** `Notifier` and `AsyncNotifier` subclasses must never be instantiated with `MyNotifier()` or assigned to a variable outside Riverpod. The `ref` and `family` args are injected by the framework after construction; accessing them in a constructor or storing the object externally throws `"Tried to use a notifier in an uninitialized state"`.

**Symptoms:**
- Runtime crash: `Bad state: Tried to use a notifier in an uninitialized state`
- Stale state references across async gaps after navigation
- State mutations not reflected in UI despite `state = ...` being called

**Prevention:**
```dart
// WRONG
final notifier = MyNotifier();       // ref is null here
notifier.doSomething();

// WRONG — storing the notifier across async gaps
final notifier = ref.read(myProvider.notifier);
await someAsyncOperation();
notifier.update();  // notifier may be unmounted now

// CORRECT — read fresh reference each time after await
await someAsyncOperation();
if (!mounted) return;  // for StatefulWidget context
ref.read(myProvider.notifier).update();  // fresh read after await
```

**Phase to address:** Phase 2 (State Management Layer)

---

### C-3: ref Used After Async Gap Without Mounted Check

**Problem:** Riverpod's `Ref` checks `mounted` before every operation. Accessing `ref.read()`, `ref.watch()`, or `state =` after an `await` in a Notifier's method will throw `UnmountedRefException` if the provider was disposed while the future was in flight (e.g., user navigated away).

**Symptoms:**
- `UnmountedRefException` or `StateError: A notifier was used after disposal` in release logs
- Intermittent crashes that are hard to reproduce (timing-dependent)
- Most common in `AsyncNotifier` methods that call APIs then write state

**Prevention:**
```dart
// Inside AsyncNotifier or Notifier methods
Future<void> loadData() async {
  final data = await repository.fetch();
  if (!ref.mounted) return;  // ALWAYS check after every await
  state = AsyncData(data);
}
```

**Phase to address:** Phase 2 (State Management Layer) and every phase with async operations

---

### C-4: SharedPreferences Not Awaited Before runApp

**Problem:** `SharedPreferences.getInstance()` is asynchronous. Calling it inside a widget `build()` or without `await` in `main()` causes reads to return null/default values on first frame, creating a race condition where the app renders with stale or empty persisted state.

**Symptoms:**
- Onboarding screen flashes even for returning users
- Saved preferences read as empty on cold start
- Intermittent Android data loss (multiple rapid commits run out of order on Android)

**Prevention:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize here, before runApp, and pass as provider override
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
```

**Phase to address:** Phase 1 (Project Bootstrap)

---

### C-5: GlobalKey Recreated on Every Build

**Problem:** Declaring `GlobalKey()` as a local variable inside `build()` creates a new key instance on every rebuild. Flutter interprets this as a completely new widget, tearing down and rebuilding the associated subtree, losing scroll position, animation state, and form data.

**Symptoms:**
- `AnimatedList` resets to initial state unexpectedly
- Form fields clear themselves on parent state change
- Performance degradation as large subtrees rebuild unnecessarily

**Prevention:**
```dart
// WRONG
Widget build(BuildContext context) {
  final key = GlobalKey<AnimatedListState>();  // new key every build
  return AnimatedList(key: key, ...);
}

// CORRECT — declare as instance variable in State class
class _MyWidgetState extends State<MyWidget> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  Widget build(BuildContext context) {
    return AnimatedList(key: _listKey, ...);
  }
}
```

**Phase to address:** Phase 3 (List/Grid UI) and any phase using AnimatedList

---

### C-6: ColorScheme.fromSeed with Explicit Brightness in Same ThemeData

**Problem:** Passing both `ColorScheme.fromSeed(seedColor: X)` (which defaults to `Brightness.light`) and `brightness: Brightness.dark` at the ThemeData level triggers the assertion `"colorScheme?.brightness == null || brightness == null || colorScheme!.brightness == brightness"`, crashing the app at startup in debug mode.

**Symptoms:**
- Assertion failure at app startup in debug builds
- Dark theme colors do not match expected dark palette
- Primary color in dark mode does not match `colorScheme.primary`

**Prevention:**
```dart
// WRONG
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  brightness: Brightness.dark,  // conflicts — fromSeed defaults to light
)

// CORRECT — specify brightness inside fromSeed
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
)
```

**Phase to address:** Phase 1 (Project Bootstrap / Theme Setup)

---

## Performance Pitfalls (Will Cause Jank)

### P-1: Multiple BackdropFilter Widgets Without RepaintBoundary

**Problem:** `BackdropFilter` with `ImageFilter.blur` is one of the most GPU-expensive Flutter operations. Multiple blur filters on screen simultaneously (glassmorphic cards in a list, overlapping panels) cause severe frame drops, especially on Impeller (iOS/Android default renderer in Flutter 3.x+). The issue is documented as a regression in flutter/flutter#126353.

**Symptoms:**
- Frame time exceeds 16ms whenever glassmorphic surfaces are on screen
- Worse on physical devices than on emulator (GPU-bound, not CPU-bound)
- Flutter DevTools shows the raster thread at 100% utilization

**Prevention:**
1. Wrap each `BackdropFilter` subtree in `RepaintBoundary` to create isolated compositor layers
2. Limit blur to small surfaces (dialogs, chips) — not full-screen backgrounds
3. For static blurred backgrounds, pre-render once with `RepaintBoundary` and avoid animating `sigma`
4. Use `ClipRRect` to bound the blur to exactly the required area
5. Consider `ImageFiltered` (applies filter to the widget itself, not what is behind it) when the effect is on the widget rather than its background — it renders faster than `BackdropFilter`

```dart
// Expensive: multiple uncontained BackdropFilters
ListView.builder(
  itemBuilder: (ctx, i) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: GlassCard(item: items[i]),
  ),
)

// Better: wrap each with RepaintBoundary
RepaintBoundary(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: GlassCard(item: items[i]),
  ),
)
```

**Phase to address:** Phase 2 (Core UI Components — glassmorphic card design)

---

### P-2: Animating Blur Sigma or Gradient Stops Every Frame

**Problem:** Changing `ImageFilter.blur(sigmaX: animatedValue)` on every animation tick forces the GPU to recompute the blur for every frame. Animating gradient stop positions inside `CustomPainter.paint()` without `shouldRepaint` returning `false` when nothing changed causes full repaints.

**Symptoms:**
- Smooth animations in profile mode degrade to <30fps on mid-range devices
- `flutter run --profile` shows raster thread consistently above 8ms
- Confetti + glassmorphic overlay simultaneously = guaranteed jank

**Prevention:**
- Do not animate blur sigma — use a fixed sigma and animate opacity instead
- In `CustomPainter`, implement `shouldRepaint` strictly:
```dart
@override
bool shouldRepaint(MyPainter oldDelegate) =>
    oldDelegate.progress != progress;  // only repaint on actual change
```
- Isolate the confetti `CustomPainter` in its own `RepaintBoundary` so it does not invalidate the rest of the screen on every tick

**Phase to address:** Phase 3 (Step 3 confetti animation, progress bar animations)

---

### P-3: Riverpod Provider Watch Causing Whole-Screen Rebuilds

**Problem:** Calling `ref.watch(someProvider)` at the root of a large widget tree (e.g., directly in a `ConsumerWidget` that renders a `Scaffold` with many children) causes the entire tree to rebuild on every state change, even if only a small piece of state changed.

**Symptoms:**
- Profile mode shows large build batches (>10 widgets rebuilt) on simple state changes
- List scrolling stutters after a filter or sort operation updates a provider
- `debugPrintRebuildDirtyWidgets = true` shows unrelated widgets rebuilding

**Prevention:**
- Push `ref.watch` as deep into the tree as possible — use `Consumer` widget inline rather than making the whole screen a `ConsumerWidget`
- Use `select` to subscribe to only the relevant slice:
```dart
// Rebuilds on any task list change
final tasks = ref.watch(taskListProvider);

// Rebuilds only when the count changes
final count = ref.watch(taskListProvider.select((list) => list.length));
```
- For list items, use `ConsumerWidget` at the item level, not the list level

**Phase to address:** Phase 2 (State Management) and Phase 3 (List rendering)

---

### P-4: google_fonts Network Fetch on Every Cold Start

**Problem:** By default, `google_fonts` fetches font files from Google's CDN on first use. If the font is not yet cached, this adds a visible FOIT (flash of invisible text) or FOUT (flash of unstyled text) on cold start. In offline environments, the app can stall for up to 10 seconds attempting to reach `fonts.gstatic.com`.

**Symptoms:**
- Text appears unstyled/system font for first 1-2 seconds on fresh install
- App appears frozen on cold start with no network
- Inconsistent appearance between first and subsequent launches

**Prevention:**
Bundle the font files as assets instead of relying on runtime download:
1. Download the required font files (.ttf) and place in `assets/fonts/`
2. Declare them in `pubspec.yaml` under `flutter.fonts`
3. `google_fonts` will automatically prefer asset files over network fetch when they match the expected filename pattern
```yaml
flutter:
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

**Phase to address:** Phase 1 (Project Bootstrap / Asset Setup)

---

### P-5: AnimatedContainer / TweenAnimationBuilder Rebuilding Large Subtrees

**Problem:** Implicit animation widgets (`AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`) extend `ImplicitlyAnimatedWidget`, which calls `setState` on every animation tick. If the animated widget is high in the widget tree or wraps a large subtree, this triggers full subtree rebuilds at 60fps.

**Symptoms:**
- Smooth animation on simulator, janky on device (CPU-bound rebuilds)
- Profile mode shows build thread at >4ms during animations
- Flutter DevTools' "Widget Rebuilds" count shows thousands of rebuilds/second

**Prevention:**
- Extract the animated portion into its own small widget so only it rebuilds
- Prefer `AnimatedBuilder` with a `controller` over `AnimatedContainer` for complex animations — `AnimatedBuilder` rebuilds only its `builder` subtree
- Use `AnimatedWidget` for single-property animations on leaf widgets
```dart
// Rebuilds the entire card subtree 60 times/second
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  child: ExpensiveTaskCard(task: task),  // full rebuild every frame
)

// Better: only the Container itself rebuilds
AnimatedBuilder(
  animation: _controller,
  builder: (ctx, child) => Container(
    height: _heightTween.evaluate(_controller),
    child: child,  // child is not rebuilt
  ),
  child: ExpensiveTaskCard(task: task),  // built once
)
```

**Phase to address:** Phase 3 (Animated progress bars, list item animations)

---

## State Management Pitfalls (Riverpod-specific)

### S-1: Using ref.read Inside build() / Widget Lifecycle

**Problem:** `ref.read()` accesses a provider's current value without subscribing. Using it inside `build()` means the widget will never rebuild when that provider's state changes — displaying permanently stale data.

**Symptoms:**
- UI shows correct initial value but never updates when state changes
- Filtering or sorting tasks has no visible effect until hot reload
- Counter-intuitive behavior: state updates in the provider but the widget ignores them

**Prevention:**
```dart
// Rule: ref.watch in build, ref.read in callbacks
Widget build(BuildContext context, WidgetRef ref) {
  final tasks = ref.watch(taskListProvider);  // subscribes, triggers rebuilds
  return ListView(...);
}

void _onFilterTap() {
  ref.read(filterProvider.notifier).setFilter(Filter.active);  // one-off action
}
```

**Phase to address:** Phase 2 (State Management Layer)

---

### S-2: Calling ref.watch Inside Callbacks, initState, or Notifier Methods

**Problem:** `ref.watch` must only be called synchronously inside a widget's `build` method or a provider's `build` method. Calling it inside `initState`, `onPressed`, `FutureBuilder` callbacks, or a Notifier's non-build methods creates subscriptions that are never cleaned up and can trigger cascading rebuilds.

**Symptoms:**
- Providers rebuild in unexpected cascades
- `StateError: ref.watch was called outside of a build phase` in debug mode
- Memory leak: subscriptions accumulate as the widget is navigated to repeatedly

**Prevention:**
```dart
// WRONG — watch inside initState
void initState() {
  super.initState();
  ref.watch(someProvider);  // crash or silent leak
}

// CORRECT — use listen for side effects in initState equivalent
@override
void initState() {
  super.initState();
  // For side effects on provider change, use addPostFrameCallback
  // or use ref.listen inside build
}

// CORRECT — ref.listen inside build for side effects
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(authProvider, (prev, next) {
    if (next == AuthState.loggedOut) context.go('/login');
  });
  return ...;
}
```

**Phase to address:** Phase 2 (State Management Layer)

---

### S-3: StateNotifier vs Notifier Confusion Leading to Listenable Issues

**Problem:** The project uses `flutter_riverpod: ^2.5.1` which supports both `StateNotifier` (legacy) and `Notifier` (current). `StateNotifier` cannot implement the `Listenable` interface required by `GoRouter`'s `refreshListenable` parameter. Mixing the two patterns creates integration dead ends.

**Symptoms:**
- Cannot pass auth state notifier to `GoRouter(refreshListenable: ...)` when using `StateNotifier`
- Type errors when trying to use `ChangeNotifier` features on a `StateNotifier`
- Confusing to reason about which notifier provides which capabilities

**Prevention:**
- Use `Notifier` / `AsyncNotifier` for all new code (the documented migration target)
- For `go_router` refresh integration, create a dedicated `ChangeNotifier`-based adapter or use `GoRouterRefreshStream` with a `StreamController`:
```dart
// Adapter pattern for go_router refresh
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);
```

**Phase to address:** Phase 1 (Project Bootstrap) — decide pattern upfront

---

### S-4: Provider Family with Non-Primitive Parameter Missing Equality

**Problem:** `provider.family` creates one provider instance per unique parameter. When the parameter type is a custom class without `==` and `hashCode` overrides, every call creates a new instance (because Dart's default `==` is identity), causing duplicate provider states and memory leaks.

**Symptoms:**
- Multiple provider instances for logically identical parameters
- State does not persist between navigations even though it should
- Memory grows unboundedly as the user navigates back and forth

**Prevention:**
```dart
// WRONG — custom class without equality
final taskProvider = Provider.family<Task, TaskFilter>((ref, filter) => ...);
// TaskFilter must override == and hashCode

// CORRECT — use primitive types or Equatable
@immutable
class TaskFilter {
  final String category;
  final bool completed;
  const TaskFilter(this.category, this.completed);

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
      other.category == category &&
      other.completed == completed;

  @override
  int get hashCode => Object.hash(category, completed);
}
```

**Phase to address:** Phase 2 (State Management Layer)

---

### S-5: autoDispose Provider Disposing State Mid-Navigation

**Problem:** `autoDispose` destroys provider state when no listeners remain. During a navigation transition (e.g., going from list → detail → back → list), there is a brief moment where the old list widget is unmounted before the new one mounts. If the provider is `autoDispose`, its state is destroyed and rebuilt, causing a loading flicker or lost scroll position.

**Symptoms:**
- List flashes to loading state briefly when navigating back
- Scroll position resets on every back navigation
- Filter/sort state resets unexpectedly

**Prevention:**
- For providers holding UI state that should survive navigation, use `keepAlive()`:
```dart
final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(() {
  return TaskListNotifier();
});
// In build:
ref.keepAlive();  // prevents disposal during navigation transitions
```
- Alternatively, do not use `autoDispose` for providers that represent persistent app state

**Phase to address:** Phase 2–3 (List state persistence)

---

## Navigation Pitfalls (go_router-specific)

### N-1: context.go vs context.push Behavior Difference

**Problem:** `context.go('/path')` replaces the entire navigation stack with the new route. `context.push('/path')` adds to the stack. Developers from Navigator 1.0 habitually use `go()` thinking it is equivalent to `Navigator.push()`. This silently destroys back-navigation history.

**Symptoms:**
- Back button does nothing (no stack to pop)
- Bottom navigation tab switches lose the tab's previous route
- Deep links work but the user cannot navigate back

**Prevention:**
```dart
// "Replace entire stack" — use for primary destinations
context.go('/tasks');

// "Push on current stack" — use for detail/modal destinations
context.push('/tasks/detail/123');

// Rule for Lista Smart:
// Tab switches → go()
// Task detail, create, edit → push()
// Auth redirects → go()
```

**Phase to address:** Phase 1 (Navigation Setup)

---

### N-2: Passing Complex Objects via route extra Across Deep Links

**Problem:** `context.push('/detail', extra: taskObject)` stores the extra value in memory. It is not serialized into the URL. When the app is cold-started from a deep link or the route is restored, `extra` is `null`, crashing any code that casts it without a null check. On web it is always lost.

**Symptoms:**
- Crash on deep link: `Null check operator used on a null value`
- Detail screen shows empty data after app restart and restoration
- Works in development, crashes in user testing with real links

**Prevention:**
- Pass only primitive IDs in route parameters; load full data from Riverpod providers inside the destination screen:
```dart
// WRONG
context.push('/tasks/detail', extra: fullTaskObject);
// destination screen: final task = GoRouterState.of(context).extra as Task;

// CORRECT
context.push('/tasks/detail/${task.id}');
// destination screen:
final taskId = GoRouterState.of(context).pathParameters['id']!;
final task = ref.watch(taskByIdProvider(taskId));
```

**Phase to address:** Phase 1 (Navigation Setup) and Phase 3 (Task detail routing)

---

### N-3: Redirect Loops from Async Auth State During Initialization

**Problem:** `GoRouter`'s `redirect` callback runs synchronously. When auth state comes from an `AsyncNotifier` (i.e., `AsyncValue<AuthState>`), the value is `AsyncLoading` during app startup. A naive redirect check that treats `loading` as "not authenticated" immediately redirects to the login screen, and then immediately redirects back as loading completes — causing a redirect loop or flash of login screen.

**Symptoms:**
- Login screen flashes briefly on every app startup even for authenticated users
- `GoException: Redirect limit exceeded` in debug logs
- Route redirect logs show the same route being redirected repeatedly

**Prevention:**
```dart
String? redirect(BuildContext context, GoRouterState state) {
  final authState = ref.read(authStateProvider);

  // Do not redirect while loading — let the splash/loading screen handle it
  if (authState.isLoading || authState.hasError) return null;

  final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
  final onAuthRoute = state.matchedLocation.startsWith('/login');

  if (!isLoggedIn && !onAuthRoute) return '/login';
  if (isLoggedIn && onAuthRoute) return '/tasks';
  return null;
}
```

**Phase to address:** Phase 1 (Auth/Navigation Bootstrap)

---

### N-4: WillPopScope / PopScope Incompatibility with go_router

**Problem:** `WillPopScope` (deprecated in Flutter 3.12) and its replacement `PopScope` do not intercept the back gesture when using `GoRouter` with page-backed routes. GoRouter manages its own navigator, and the `PopScope.canPop` / `onPopInvoked` callbacks are not invoked for programmatic navigation initiated by the router.

**Symptoms:**
- "Are you sure?" confirmation dialog never appears on back navigation in go_router screens
- `PopScope.canPop = false` still allows back navigation
- Works correctly with `Navigator.push` but not with `GoRouter`

**Prevention:**
- For forms that need a dirty-check on back, use `GoRouter`'s `onExit` parameter on `GoRoute` (available in go_router 13+):
```dart
GoRoute(
  path: '/tasks/edit/:id',
  onExit: (context) async {
    if (!ref.read(formDirtyProvider)) return true;
    return await showDiscardDialog(context) ?? false;
  },
  builder: (context, state) => EditTaskScreen(),
)
```

**Phase to address:** Phase 3 (Task creation/edit forms)

---

### N-5: ShellRoute vs StatefulShellRoute Wrong Choice for Tab Navigation

**Problem:** `ShellRoute` creates a single `Navigator`. Switching tabs rebuilds the tab content from scratch — the list scroll position, Riverpod state, and any in-progress user input is lost. Using `ShellRoute` when the app requires tab state preservation is a structural mistake requiring a full navigation rewrite.

**Symptoms:**
- Scroll position resets every time a tab is re-selected
- Filter/sort state on one tab resets when another tab is visited
- Performance profiling shows full list rebuilds on every tab switch

**Prevention:**
Use `StatefulShellRoute.indexedStack` for bottom navigation from day one:
```dart
StatefulShellRoute.indexedStack(
  builder: (ctx, state, navigationShell) =>
      ScaffoldWithBottomNav(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/tasks', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/profile', ...)]),
  ],
)
```

**Phase to address:** Phase 1 (Navigation Setup) — structural decision, very costly to change later

---

## UI/Animation Pitfalls

### U-1: Material 3 Surface Tint Overriding Custom Dark Theme Colors

**Problem:** With `useMaterial3: true` (Flutter default in 3.x+), Material widgets apply a `surfaceTintColor` overlay whose opacity scales with elevation. In dark themes with custom gradient or glassmorphic backgrounds, this tint layer renders on top of the custom colors, producing an unexpected blue/primary-colored wash over cards and containers.

**Symptoms:**
- Cards appear slightly purple/blue-tinted despite setting explicit background colors
- `Card(color: myDarkColor)` renders a different shade than specified
- `Container` inside `Material` looks different from `Container` outside it
- Issue worsens at higher elevations

**Prevention:**
```dart
// Option 1: Explicitly null out surfaceTintColor in component themes
ThemeData(
  useMaterial3: true,
  cardTheme: const CardTheme(surfaceTintColor: Colors.transparent),
  // Repeat for AppBarTheme, DrawerTheme, etc.
)

// Option 2: Use ColorScheme.fromSeed with a dark seed that produces
// tonally appropriate surface colors rather than fighting the tint
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1A1A2E),
    brightness: Brightness.dark,
  ),
)
```

**Phase to address:** Phase 1 (Theme Setup)

---

### U-2: ValueKey vs ObjectKey Wrong Choice in Animated Lists

**Problem:** Using `ValueKey(item.id)` is correct for stable, unique IDs. Using `UniqueKey()` in a list item creates a new key on every build, telling Flutter the widget is entirely new — destroying and recreating element state (expansion, focus, animation) on every rebuild. Using `ObjectKey(item)` is dangerous when the same object can appear at multiple positions.

**Symptoms:**
- List item animations always run "initial appearance" animation instead of "reorder" animation
- Checkbox/expansion state resets on list filter change
- `AnimatedList` removes and re-inserts items that did not change

**Prevention:**
```dart
// WRONG: new key every build → full widget recreation
ListView.builder(
  itemBuilder: (ctx, i) => ListTile(key: UniqueKey(), ...)
)

// WRONG: ObjectKey identity — fails with duplicate objects
ListView.builder(
  itemBuilder: (ctx, i) => ListTile(key: ObjectKey(tasks[i]), ...)
)

// CORRECT: stable, unique value from data model
ListView.builder(
  itemBuilder: (ctx, i) => ListTile(key: ValueKey(tasks[i].id), ...)
)
```

**Phase to address:** Phase 3 (List/Grid UI)

---

### U-3: MediaQuery vs LayoutBuilder for Adaptive Breakpoints

**Problem:** Using `MediaQuery.of(context).size.width` at the top of the widget tree responds to the full screen size, not the available space for the widget. In a split-view or tablet layout where a panel occupies half the screen, MediaQuery still returns the full screen width, causing the panel content to render in "tablet mode" when it should render in "phone mode".

**Symptoms:**
- Sidebar panel uses grid layout (designed for full screen) in a narrow column
- Grid/list toggle calculates wrong column count on tablets in landscape
- Rotating device causes wrong layout mode until the widget is rebuilt

**Prevention:**
```dart
// WRONG — uses screen width, ignores parent constraints
final isTablet = MediaQuery.of(context).size.width > 600;

// CORRECT — uses actual available space
LayoutBuilder(
  builder: (ctx, constraints) {
    final isTablet = constraints.maxWidth > 600;
    return isTablet ? GridView(...) : ListView(...);
  },
)
```

**Phase to address:** Phase 3 (Adaptive Layout)

---

### U-4: Confetti / Particle CustomPainter Not Isolated with RepaintBoundary

**Problem:** A confetti animation using `CustomPainter` runs `paint()` at 60fps. Without `RepaintBoundary`, every frame invalidates the entire widget layer containing the confetti, forcing all sibling widgets (step summary text, progress bars, buttons) to repaint even though they have not changed.

**Symptoms:**
- Entire step 3 screen shows 60fps repaint flashes in Flutter DevTools "Repaint Rainbow" mode
- Other animations on the same screen (progress bar) stutter while confetti runs
- Low-end Android devices drop to 30fps during the confetti sequence

**Prevention:**
```dart
Stack(
  children: [
    // Static content — not repainted during confetti
    StepSummaryContent(step: step),

    // Animated confetti — isolated in its own compositor layer
    RepaintBoundary(
      child: ConfettiWidget(controller: confettiController),
    ),
  ],
)
```

**Phase to address:** Phase 3 (Step 3 completion animation)

---

### U-5: google_fonts TextStyle Applied at Widget Level Instead of Theme Level

**Problem:** Calling `GoogleFonts.inter(fontSize: 14)` inside individual widget `TextStyle` parameters bypasses Flutter's `TextTheme` inheritance. Every widget that needs the custom font must manually apply it — and forgetting one widget produces visual inconsistency. In dark mode, hardcoded colors inside the `TextStyle` returned by `GoogleFonts.*()` will not adapt to theme changes.

**Symptoms:**
- Inconsistent font weights or letter spacing across the app
- Some text in dark mode remains dark-colored (invisible) because it has hardcoded `color: Colors.black`
- Future font changes require updating dozens of call sites

**Prevention:**
Define the font at the `ThemeData.textTheme` level once, then let widgets inherit:
```dart
ThemeData(
  textTheme: GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ),
)
// Widget-level: use Theme.of(context).textTheme.bodyMedium
// Never use GoogleFonts.inter() at individual widget call sites
```

**Phase to address:** Phase 1 (Theme Setup)

---

## Key Checklist Before Submission

Academic project quality gates — check each before final submission:

### Architecture & Setup
- [ ] `GoRouter` is declared as a Riverpod `Provider`, not instantiated inside a widget
- [ ] `SharedPreferences.getInstance()` is awaited in `main()` before `runApp()` and injected via `ProviderScope.overrides`
- [ ] `ThemeData` uses `ColorScheme.fromSeed(..., brightness: Brightness.dark)` — not conflicting `brightness` at two levels
- [ ] `GoogleFonts.*TextTheme()` applied at `ThemeData.textTheme` level, not at individual widget level
- [ ] `StatefulShellRoute.indexedStack` used for bottom navigation (not `ShellRoute`)

### State Management
- [ ] Every `async` method in a `Notifier` checks `if (!ref.mounted) return;` after each `await`
- [ ] `ref.watch` used inside `build()` only; `ref.read` used in callbacks
- [ ] No `Notifier` subclass is instantiated directly with `MyNotifier()`
- [ ] `family` provider parameters override `==` and `hashCode`
- [ ] Providers requiring auth-state-driven navigation use a `ChangeNotifier` adapter, not a raw `StateNotifier`

### Performance
- [ ] Every `BackdropFilter` is wrapped in `RepaintBoundary`
- [ ] Confetti `CustomPainter` is in its own `RepaintBoundary`
- [ ] Blur sigma is not animated; opacity is used for blur on/off transitions instead
- [ ] `CustomPainter.shouldRepaint` is implemented and returns `false` when nothing changed
- [ ] `ref.watch` uses `.select(...)` where only a subset of state is needed

### Navigation
- [ ] Route parameters are primitive IDs only; complex objects are loaded from providers inside destination screens
- [ ] Redirect callback guards against `AsyncLoading` state (returns `null` while loading)
- [ ] `context.go()` vs `context.push()` usage is intentional and documented in route config comments
- [ ] Dirty-form back-navigation guard uses `GoRoute.onExit` (not `WillPopScope`)

### UI & Keys
- [ ] All `ListView.builder` / `GridView.builder` items have `key: ValueKey(item.id)`
- [ ] `GlobalKey` instances are declared as class instance variables, never inside `build()`
- [ ] Adaptive breakpoints use `LayoutBuilder`, not `MediaQuery.size`
- [ ] Material 3 `surfaceTintColor` is explicitly set to `Colors.transparent` for components with custom dark backgrounds
- [ ] Font asset files are bundled in `assets/fonts/` to avoid network fetch on cold start

---

## Sources

- [Riverpod auto_dispose documentation](https://riverpod.dev/docs/concepts2/auto_dispose) — HIGH confidence
- [go_router Navigation documentation](https://pub.dev/documentation/go_router/latest/topics/Navigation-topic.html) — HIGH confidence
- [Riverpod source code analysis — DCM rules](https://dcm.dev/blog/2026/03/25/inside-riverpod-source-code-guide-dcm-rules/) — HIGH confidence
- [Riverpod Simplified: 4 Years of Lessons](https://dinkomarinac.dev/blog/riverpod-simplified-lessons-learned-from-4-years-of-development/) — MEDIUM confidence
- [GoRouter + Riverpod Integration Discussion](https://github.com/rrousselGit/riverpod/discussions/1357) — HIGH confidence
- [Robust Flutter App Initialization with Riverpod](https://codewithandrea.com/articles/robust-app-initialization-riverpod/) — HIGH confidence
- [Flutter Bottom Navigation with GoRouter — StatefulShellRoute](https://codewithandrea.com/articles/flutter-bottom-navigation-bar-nested-routes-gorouter/) — HIGH confidence
- [BackdropFilter/Impeller performance regression #126353](https://github.com/flutter/flutter/issues/126353) — HIGH confidence
- [Flutter BackdropFilter optimization](https://trushitkasodiya.medium.com/flutter-backdrop-filter-optimization-improve-ui-performance-81746bc1fd55) — MEDIUM confidence
- [gskinner Flutter Rendering Optimization Tips](https://blog.gskinner.com/archives/2022/09/flutter-rendering-optimization-tips.html) — MEDIUM confidence
- [Flutter Laggy Animations: How Not To setState](https://medium.com/flutter-community/flutter-laggy-animations-how-not-to-setstate-f2dd9873b8fc) — MEDIUM confidence
- [ColorScheme.fromSeed Brightness assertion issue #127523](https://github.com/flutter/flutter/issues/127523) — HIGH confidence
- [Material 3 Card color not respected #122177](https://github.com/flutter/flutter/issues/122177) — HIGH confidence
- [shared_preferences Android race condition #95013](https://github.com/flutter/flutter/issues/95013) — HIGH confidence
- [google_fonts package documentation](https://pub.dev/packages/google_fonts) — HIGH confidence
- [Flutter Keys guide](https://dhruvnakum.xyz/keys-in-flutter-uniquekey-valuekey-objectkey-pagestoragekey-globalkey) — MEDIUM confidence
- [Flutter adaptive layout best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices) — HIGH confidence
- [go_router Redirection documentation](https://docs.page/csells/go_router/redirection) — HIGH confidence
