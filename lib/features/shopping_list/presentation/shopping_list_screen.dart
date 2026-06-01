import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Lista de Compras',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
