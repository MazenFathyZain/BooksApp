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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'user';
  bool _isAnonymousLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          if (state is AuthRegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr('register_success')),
                backgroundColor: const Color(0xFF8B4513),
              ),
            );
            Navigator.pop(context);
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
                        icon: Icons.person_add_rounded,
                        titleKey: context.tr('create_account'),
                        subtitleKey: context.tr('register_subtitle'),
                        iconBackgroundColor: const Color(0xFF6D4C41),
                      ),
                      const SizedBox(height: 32),

                      // Name Field
                      CustomTextField(
                        controller: _nameController,
                        labelKey: context.tr('full_name'),
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('name_required');
                          }
                          if (value.length < 3) {
                            return context.tr('name_min_length');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelKey: context.tr('confirm_password'),
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: PasswordVisibilityIcon(
                          obscureText: _obscureConfirmPassword,
                          onPressed: () {
                            setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('confirm_password_required');
                          }
                          if (value != _passwordController.text) {
                            return context.tr('password_mismatch');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Role Selection
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: context.tr('account_type'),
                            prefixIcon: const Icon(
                              Icons.admin_panel_settings_outlined,
                              color: Color(0xFF8B4513),
                            ),
                            border: InputBorder.none,
                          ),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF5D4037)),
                          items: [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text(context.tr('user')),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text(context.tr('admin')),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRole = value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Register Button
                      CustomAuthButton(
                        textKey: context.tr('create_account_button'),
                        backgroundColor: const Color(0xFF6D4C41),
                        isLoading: isLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthCubit>().register(
                              _nameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text,
                              _selectedRole,
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

                      // Login Link
                      AuthNavigationText(
                        questionKey: context.tr('already_have_account'),
                        actionKey: context.tr('login'),
                        onPressed: () {
                          Navigator.pop(context);
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