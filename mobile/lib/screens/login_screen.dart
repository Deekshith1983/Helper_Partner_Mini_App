import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/error_banner.dart';
import 'jobs_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'helper1');
  final _passwordController = TextEditingController(text: 'Demo@1234');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final success = await auth.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const JobsListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontalPadding,
              vertical: AppSpacing.s24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Brand Header
                _buildBrandHeader(),
                const SizedBox(height: AppSpacing.s32),

                // 2. Form Card
                _buildFormCard(),
                const SizedBox(height: AppSpacing.s24),

                // 3. Demo Credentials Hint Card
                _buildDemoCredentialsHint(),
                const SizedBox(height: AppSpacing.s32),

                // 4. Footer
                const Text(
                  AppStrings.appVersion,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.handshake_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          AppStrings.appTagline,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    AppStrings.loginTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error banner if any error
                  if (auth.errorMessage != null) ...[
                    ErrorBanner(message: auth.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    enabled: !auth.isLoading,
                    decoration: const InputDecoration(
                      labelText: AppStrings.usernameLabel,
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.usernameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field with Show/Hide Toggle
                  TextFormField(
                    controller: _passwordController,
                    enabled: !auth.isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return AppStrings.passwordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(AppStrings.loginTitle),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDemoCredentialsHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.demoCredentialsHint,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
