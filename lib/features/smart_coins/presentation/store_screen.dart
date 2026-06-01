import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Loja Smart Coins',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
