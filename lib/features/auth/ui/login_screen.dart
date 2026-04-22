import 'package:book/core/helpers/extension.dart';
import 'package:book/features/auth/ui/widgets/anonymous_login_button.dart';
import 'package:book/features/auth/ui/widgets/auth_divider.dart';
import 'package:book/features/auth/ui/widgets/auth_header.dart';
import 'package:book/features/auth/ui/widgets/auth_navigation_text.dart';
import 'package:book/features/auth/ui/widgets/custom_auth_button.dart';
import 'package:book/features/auth/ui/widgets/custom_text_field.dart';
import 'package:book/features/auth/ui/widgets/password_visibility_toggle_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:book/features/auth/logic/auth_cubit.dart';
import 'package:book/core/routing/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isAnonymousLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAnonymousLogin() async {
    setState(() => _isAnonymousLoading = true);

    try {
      // Implement your anonymous login logic here
      // Example: await context.read<AuthCubit>().anonymousLogin();

      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('anonymous_login_success')),
            backgroundColor: const Color(0xFF8B4513),
          ),
        );
        context.pushReplacementNamed(Routes.homeScreen);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('anonymous_login_error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnonymousLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoginSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('login_success')),
                backgroundColor: const Color(0xFF8B4513),
              ),
            );
            if(state.response.role == "user"){
              context.pushReplacementNamed(Routes.homeScreen);
            }else{
              context.pushReplacementNamed(Routes.dashboardScreen);
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      AuthHeader(
                        icon: Icons.menu_book_rounded,
                        titleKey: context.tr('welcome_back'),
                        subtitleKey: context.tr('login_subtitle'),
                        iconBackgroundColor: const Color(0xFF8B4513),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        labelKey: context.tr('email'),
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('email_required');
                          }
                          if (!value.contains('@')) {
                            return context.tr('email_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        labelKey: context.tr('password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: PasswordVisibilityIcon(
                          obscureText: _obscurePassword,
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('password_required');
                          }
                          if (value.length < 6) {
                            return context.tr('password_min_length');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: TextButton(
                      //     onPressed: () {
                      //       // Navigate to forgot password
                      //     },
                      //     child: Text(
                      //       context.tr('forgot_password'),
                      //       style: const TextStyle(
                      //         color: Color(0xFF8B4513),
                      //         fontWeight: FontWeight.w600,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 24),

                      // Login Button
                      CustomAuthButton(
                        textKey: context.tr('login'),
                        backgroundColor: const Color(0xFF8B4513),
                        isLoading: isLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthCubit>().login(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      AuthDivider(textKey: context.tr('or')),
                      const SizedBox(height: 24),

                      // Anonymous Login Button
                      AnonymousLoginButton(
                        onPressed: _handleAnonymousLogin,
                        isLoading: _isAnonymousLoading,
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      AuthNavigationText(
                        questionKey: context.tr('no_account'),
                        actionKey: context.tr('register'),
                        onPressed: () {
                          context.pushNamed(Routes.registerScreen);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}