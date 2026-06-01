import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Login',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
