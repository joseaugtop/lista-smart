import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PriceComparisonScreen extends StatelessWidget {
  const PriceComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Comparar Precos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
