import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await auth.register(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );
    }

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _guestLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginAsGuest();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.08),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primaryGreenGradient,
                  ),
                  child: const Center(
                    child: Text('♚', style: TextStyle(fontSize: 40, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('OpenChess Arena', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(_isLogin ? 'Welcome back!' : 'Create your account', style: const TextStyle(color: AppTheme.textSecondary)),
                SizedBox(height: size.height * 0.06),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isLogin)
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person,
                          validator: (v) => v!.isEmpty ? 'Enter username' : null,
                        ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v!.isEmpty) return 'Enter email';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscure: true,
                        validator: (v) {
                          if (v!.isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_isLogin ? 'Sign In' : 'Create Account'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: auth.isLoading ? null : _guestLogin,
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Continue as Guest'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? "Don't have an account? Sign Up" : 'Already have an account? Sign In',
                          style: const TextStyle(color: AppTheme.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth.error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ? _obscurePassword : false,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
        suffixIcon: obscure
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
      ),
    );
  }
}
