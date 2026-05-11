import 'dart:math' as math;

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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Student Saver');
  final _emailController = TextEditingController(text: 'student@gxcat.my');
  final _phoneController = TextEditingController(text: '+60 12-345 6789');
  final _passwordController = TextEditingController(text: 'password123');
  late final AnimationController _motionController;

  AuthMode _mode = AuthMode.login;
  bool _studentMode = true;
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motionController.dispose();
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
      body: AnimatedBuilder(
        animation: _motionController,
        builder: (context, _) {
          return CustomPaint(
            painter: _AuthBackgroundPainter(_motionController.value),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 760;
                      final content = wide
                          ? Row(
                              children: [
                                Expanded(child: _HeroPanel(progress: _motionController.value)),
                                const SizedBox(width: 18),
                                Expanded(child: _authForm(isSignup)),
                              ],
                            )
                          : Column(
                              children: [
                                _HeroPanel(progress: _motionController.value, compact: true),
                                const SizedBox(height: 14),
                                _authForm(isSignup),
                              ],
                            );
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: content,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
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
            Row(
              children: [
                const Icon(Icons.pets_rounded, color: Color(0xFF18A999)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSignup ? 'Start saving' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AuthMode>(
                segments: const [
                  ButtonSegment(value: AuthMode.login, label: Text('Login'), icon: Icon(Icons.login_rounded)),
                  ButtonSegment(value: AuthMode.signup, label: Text('Signup'), icon: Icon(Icons.person_add_rounded)),
                ],
                selected: {_mode},
                onSelectionChanged: (value) => setState(() => _mode = value.first),
              ),
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
              title: const Text('Student mode'),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.progress, this.compact = false});

  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 260 : 520,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6).withValues(alpha: .92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 24,
            child: Text(
              'GX Cat',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Positioned(
            left: 28,
            top: compact ? 78 : 86,
            child: Text(
              'Save. Grow. Flex.',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black54, fontWeight: FontWeight.w800),
            ),
          ),
          Positioned.fill(
            top: compact ? 76 : 110,
            child: CustomPaint(painter: _LoginCatPainter(progress)),
          ),
        ],
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  _AuthBackgroundPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF7F4EF));
    final teal = Paint()..color = const Color(0xFF18A999).withValues(alpha: .18);
    final gold = Paint()..color = const Color(0xFFFFB703).withValues(alpha: .18);
    final red = Paint()..color = const Color(0xFFE63946).withValues(alpha: .08);
    canvas.drawCircle(Offset(size.width * .1, size.height * (.16 + progress * .025)), 130, teal);
    canvas.drawCircle(Offset(size.width * .88, size.height * (.18 - progress * .02)), 160, gold);
    canvas.drawCircle(Offset(size.width * .76, size.height * (.86 + progress * .02)), 190, red);
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) => oldDelegate.progress != progress;
}

class _LoginCatPainter extends CustomPainter {
  _LoginCatPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bob = -10 + progress * 20;
    final center = Offset(size.width / 2, size.height * .56 + bob);
    final shadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, size.height * .86), width: 210, height: 30), shadow);

    for (var i = 0; i < 6; i++) {
      final angle = i * .9 + progress * .8;
      final coinCenter = Offset(
        center.dx + math.cos(angle) * (118 + i * 5),
        center.dy - 70 + math.sin(angle) * 42,
      );
      canvas.drawCircle(coinCenter, 14, Paint()..color = const Color(0xFFFFB703));
      canvas.drawCircle(
        coinCenter,
        8,
        Paint()
          ..color = Colors.white.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final body = Paint()..color = const Color(0xFFFFC857);
    final line = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawOval(const Rect.fromLTWH(-82, -2, 164, 118), body);
    canvas.drawOval(const Rect.fromLTWH(-70, -96, 140, 120), body);
    canvas.drawPath(Path()..moveTo(-52, -80)..lineTo(-86, -138)..lineTo(-22, -98)..close(), body);
    canvas.drawPath(Path()..moveTo(52, -80)..lineTo(86, -138)..lineTo(22, -98)..close(), body);
    canvas.drawCircle(const Offset(-30, -42), 9, Paint()..color = const Color(0xFF2B2B2B));
    canvas.drawCircle(const Offset(30, -42), 9, Paint()..color = const Color(0xFF2B2B2B));
    canvas.drawOval(const Rect.fromLTWH(-8, -24, 16, 11), Paint()..color = const Color(0xFFFF8FAB));
    canvas.drawArc(const Rect.fromLTWH(-20, -20, 20, 20), 0, math.pi, false, line);
    canvas.drawArc(const Rect.fromLTWH(0, -20, 20, 20), 0, math.pi, false, line);
    canvas.drawLine(const Offset(-18, -18), const Offset(-72, -28), line);
    canvas.drawLine(const Offset(18, -18), const Offset(72, -28), line);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-48, -2, 96, 14), const Radius.circular(99)), Paint()..color = const Color(0xFF18A999));
    canvas.drawCircle(const Offset(0, 12), 10, Paint()..color = const Color(0xFFFFB703));
    canvas.drawPath(Path()..moveTo(62, 48)..cubicTo(132, 18, 102, -46, 70, -18), line..strokeWidth = 25);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoginCatPainter oldDelegate) => oldDelegate.progress != progress;
}
