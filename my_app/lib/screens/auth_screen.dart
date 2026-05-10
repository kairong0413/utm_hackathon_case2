import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/app_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onAuthenticated});

  final Future<void> Function(AuthCredentials credentials) onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Student Saver');
  final _emailController = TextEditingController(text: 'student@gxcat.my');
  final _phoneController = TextEditingController(text: '+60 12-345 6789');
  final _passwordController = TextEditingController(text: 'password123');

  AuthMode _mode = AuthMode.login;
  bool _studentMode = true;
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onAuthenticated(
        AuthCredentials(
          mode: _mode,
          name: _nameController.text.trim().isEmpty ? 'GX Saver' : _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          studentMode: _studentMode,
        ),
      );
    } catch (error) {
      setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyAuthError(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      final code = error.code;
      final message = switch (code) {
        'invalid-credential' || 'user-not-found' || 'wrong-password' => 'No matching account found for this email and password.',
        'email-already-in-use' => 'This email already has an account.',
        'weak-password' => 'Use a stronger password.',
        'network-request-failed' => 'Network error. Check your Firebase connection.',
        'user-disabled' => 'This account has been disabled in Firebase Authentication.',
        'operation-not-allowed' => 'Email/password login is not enabled in Firebase Authentication.',
        'too-many-requests' => 'Too many failed attempts. Wait a bit, then try again.',
        _ => 'Authentication failed.',
      };
      return '$message Firebase code: $code';
    }
    final text = error.toString();
    if (text.contains('user-not-found') || text.contains('invalid-credential')) {
      return 'No matching account found. Try signup first.';
    }
    if (text.contains('email-already-in-use')) return 'This email already has an account.';
    if (text.contains('weak-password')) return 'Use a stronger password.';
    if (text.contains('network')) return 'Network error. Check your Firebase connection.';
    return 'Authentication failed. Please check the details and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = _mode == AuthMode.signup;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                Text(
                  'GX Financial Cat',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to keep your cat, savings streak, and Meow-Points protected.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;
                    final intro = AppSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.pets_rounded, size: 54, color: Color(0xFF18A999)),
                          const SizedBox(height: 16),
                          Text(
                            'A banking buddy that reacts to your choices.',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 12),
                          const _FeatureLine(icon: Icons.savings_rounded, text: 'Round-ups feed your cat.'),
                          const _FeatureLine(icon: Icons.warning_rounded, text: 'BNPL risk triggers a hiss.'),
                          const _FeatureLine(icon: Icons.account_circle_rounded, text: 'Profile stores your cat and goals.'),
                        ],
                      ),
                    );
                    final form = _authForm(isSignup);
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: intro),
                              const SizedBox(width: 16),
                              Expanded(child: form),
                            ],
                          )
                        : Column(
                            children: [
                              intro,
                              const SizedBox(height: 14),
                              form,
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _authForm(bool isSignup) {
    return AppSurface(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<AuthMode>(
              segments: const [
                ButtonSegment(value: AuthMode.login, label: Text('Login'), icon: Icon(Icons.login_rounded)),
                ButtonSegment(value: AuthMode.signup, label: Text('Signup'), icon: Icon(Icons.person_add_rounded)),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() => _mode = value.first),
            ),
            const SizedBox(height: 18),
            if (isSignup) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_rounded)),
                validator: (value) => value == null || value.trim().length < 2 ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_rounded)),
              validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            if (isSignup) ...[
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_rounded)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a phone number' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
              validator: (value) => value != null && value.length >= 8 ? null : 'Use at least 8 characters',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _studentMode,
              onChanged: (value) => setState(() => _studentMode = value),
              title: const Text('Student / fresh graduate mode'),
            ),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Color(0xFFE63946), fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isSignup ? Icons.person_add_rounded : Icons.login_rounded),
              label: Text(_loading ? 'Please wait...' : (isSignup ? 'Create account' : 'Login')),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087E6F)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
