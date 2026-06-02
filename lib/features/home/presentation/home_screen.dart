import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Home tab placeholder.
/// Uses CustomScrollView + SliverList so scroll position preservation
/// can be verified manually (StatefulShellRoute.indexedStack test).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Home'),
            backgroundColor: AppColors.background,
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(
                key: ValueKey(index),
                title: Text('Item $index'),
              ),
              childCount: 30,
            ),
          ),
        ],
      ),
    );
  }
}
