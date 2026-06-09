import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/mock_data.dart';
import '../../../core/providers/coin_notifier.dart';
import '../../../core/providers/theme_notifier.dart';
import '../../../core/providers/user_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _efficiencyCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _vehicleCtrl = TextEditingController(
      text: user?.vehicleModel.isNotEmpty == true
          ? user!.vehicleModel
          : MockData.vehicle.model,
    );
    _efficiencyCtrl = TextEditingController(
      text: user?.fuelEfficiency != 0.0
          ? user!.fuelEfficiency.toString()
          : MockData.vehicle.fuelEfficiencyKmPerLiter.toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _vehicleCtrl.dispose();
    _efficiencyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(userNotifierProvider.notifier).updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          vehicleModel: _vehicleCtrl.text.trim(),
          fuelEfficiency: double.tryParse(_efficiencyCtrl.text) ?? 0.0,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final coinState = ref.watch(coinProvider);
    final scannedCount = coinState.transactions
        .where((tx) => tx.description == AppStrings.scanReceiptDescription)
        .length;

    final userName = user?.name ?? '';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: context.appColors.background,
            title: Text(
              'Perfil',
              style: TextStyle(
                color: context.appColors.textMain,
                fontWeight: FontWeight.w700,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _AvatarHeader(
                userName: userName,
                userEmail: userEmail,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
              ).copyWith(bottom: AppSizes.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileSection(
                    title: 'Dados Pessoais',
                    children: [
                      _buildField(
                        label: 'Nome completo',
                        icon: LucideIcons.user,
                        controller: _nameCtrl,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      _buildField(
                        label: 'E-mail',
                        icon: LucideIcons.mail,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      _buildField(
                        label: 'Endereço',
                        icon: LucideIcons.mapPin,
                        controller: _addressCtrl,
                        keyboardType: TextInputType.streetAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  _ProfileSection(
                    title: 'Veículo',
                    children: [
                      _buildField(
                        label: 'Modelo do veículo',
                        icon: LucideIcons.car,
                        controller: _vehicleCtrl,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: AppSizes.spacingM),
                      _buildField(
                        label: 'Consumo médio (km/L)',
                        icon: LucideIcons.fuel,
                        controller: _efficiencyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  _ImpactSection(scannedCount: scannedCount),
                  const SizedBox(height: AppSizes.spacingM),
                  _AppearanceSection(),
                  const SizedBox(height: AppSizes.spacingL),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: context.appColors.background,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.save, size: 18),
                        SizedBox(width: AppSizes.spacingS),
                        Text(
                          'Salvar Alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingL),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: context.appColors.textMain),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.appColors.textSecondary),
        prefixIcon: Icon(icon, color: context.appColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide:
              BorderSide(color: context.appColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor:
            context.appColors.surfaceElevated.withValues(alpha: 0.4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar Header
// ---------------------------------------------------------------------------

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.userName,
    required this.userEmail,
  });

  final String userName;
  final String userEmail;

  String get _initials {
    return userName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.spacingL),
          Semantics(
            label: 'Avatar de $userName',
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            userName,
            style: TextStyle(
              color: context.appColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            userEmail,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile Section (glassmorphic card with title + fields)
// ---------------------------------------------------------------------------

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: context.appColors.glassBorder,
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.appColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Impact Section
// ---------------------------------------------------------------------------

class _ImpactSection extends StatelessWidget {
  const _ImpactSection({required this.scannedCount});

  final int scannedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: context.appColors.glassBorder,
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impacto Social',
            style: TextStyle(
              color: context.appColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '$scannedCount notas escaneadas',
                  child: _StatChip(
                    icon: LucideIcons.fileText,
                    value: scannedCount.toString(),
                    label: 'notas\nescaneadas',
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              const Expanded(
                child: _StatChip(
                  icon: LucideIcons.search,
                  value: '47',
                  label: 'buscas\nefetuadas',
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              const Expanded(
                child: _StatChip(
                  icon: LucideIcons.trendingDown,
                  value: 'R\$ 342',
                  label: 'economia\nestimada',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance Section
// ---------------------------------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: context.appColors.glassBorder),
      ),
      padding: const EdgeInsets.all(AppSizes.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aparência',
            style: TextStyle(
              color: context.appColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingM),
          SegmentedButton<ThemeMode>(
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.15),
              selectedForegroundColor: AppColors.primary,
              foregroundColor: context.appColors.textSecondary,
              side: BorderSide(color: context.appColors.glassBorder),
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(LucideIcons.monitor, size: 16),
                label: Text('Sistema'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(LucideIcons.sun, size: 16),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(LucideIcons.moon, size: 16),
                label: Text('Escuro'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (set) =>
                ref.read(themeModeProvider.notifier).setMode(set.first),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Chip
// ---------------------------------------------------------------------------

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.spacingM,
        horizontal: AppSizes.spacingS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            value,
            style: TextStyle(
              color: context.appColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXS),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
