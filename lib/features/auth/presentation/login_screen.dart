import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/providers/user_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    ref.read(userNotifierProvider.notifier).login();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Stack(
        children: [
          // Blob 1: top-right
          Positioned(
            top: -80,
            right: -60,
            child: ClipOval(
              child: Container(
                width: 300,
                height: 300,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
          // Blob 2: bottom-left
          Positioned(
            bottom: -60,
            left: -80,
            child: ClipOval(
              child: Container(
                width: 220,
                height: 220,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // BackdropFilter ABOVE blobs — blurs them
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Login card ABOVE filter — not blurred
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lista Smart',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingS),
                  Text(
                    'Faça compras mais inteligentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingXL),
                  // Glassmorphic card
                  Container(
                    decoration: BoxDecoration(
                      color: context.appColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      border: Border.all(
                        color: context.appColors.glassBorder,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: context.appColors.textMain),
                          decoration: InputDecoration(
                            hintText: 'seu@email.com',
                            hintStyle: TextStyle(color: context.appColors.textSecondary),
                            prefixIcon: Icon(LucideIcons.mail, color: context.appColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                              borderSide: BorderSide(color: context.appColors.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingM),
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: TextStyle(color: context.appColors.textMain),
                          decoration: InputDecoration(
                            hintText: 'senha',
                            hintStyle: TextStyle(color: context.appColors.textSecondary),
                            prefixIcon: Icon(LucideIcons.lock, color: context.appColors.textSecondary),
                            suffixIcon: Tooltip(
                              message: _isPasswordVisible ? 'Ocultar senha' : 'Mostrar senha',
                              child: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                                  color: context.appColors.textSecondary,
                                ),
                                onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                              borderSide: BorderSide(color: context.appColors.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacingL),
                        // Submit button or loading
                        _isLoading
                            ? const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _handleLogin,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: context.appColors.background,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSizes.spacingM,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                                    ),
                                  ),
                                  child: const Text('Avançar'),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
