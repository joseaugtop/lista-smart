import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PriceRegistrationScreen extends StatelessWidget {
  const PriceRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Center(
        child: Text(
          'Cadastrar Preco',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
