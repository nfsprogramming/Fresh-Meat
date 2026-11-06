import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../models.dart';
import '../widgets/common.dart';
import '../widgets/google_user_avatar.dart';
import 'home_screen.dart';

/// Pixel-perfect vector Google 'G' icon with official brand geometry & colors.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Google logo',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _GoogleLogoPainter(),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // 1. Red sector (top arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24.0, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.62, 0.0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
      ..close();
    canvas.drawPath(redPath, paint);

    // 2. Blue sector (center bar & right curve)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.60, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.50, 32.16, 36.20)
      ..lineTo(39.89, 42.20)
      ..cubicTo(44.40, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, paint);

    // 3. Yellow sector (left curve)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.60, 9.77, 24.0)
      ..cubicTo(9.77, 22.40, 10.04, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
      ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 4. Green sector (bottom arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24.0, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final bool showSkip;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.showSkip = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      final profile = await AuthService.instance.signInWithGoogle();

      if (profile == null) {
        // User cancelled Google sign-in dialog or requires profile selection
        if (mounted) {
          setState(() => _isLoading = false);
          _promptGoogleAccountPicker();
        }
        return;
      }

      if (!mounted) return;
      final appState = context.read<AppState>();
      await appState.signInWithGoogle(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        photoUrl: profile.photoUrl,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final isAdmin = appState.isAdmin;
      _onSignedInSuccess(profile.name, isAdmin: isAdmin);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSignInError(e);
    }
  }

  void _onSignedInSuccess(String displayName, {bool isAdmin = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E0A10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isAdmin ? C.gold : C.ember, width: 1.5),
        ),
        content: Row(
          children: [
            Icon(isAdmin ? Icons.verified_user_rounded : Icons.check_circle_rounded, color: C.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAdmin ? 'Signed in as $displayName (Firebase Admin)' : 'Signed in as $displayName',
                style: body(13, color: Colors.white, w: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
    }
  }

  void _showSignInError(Object error) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B070E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: op(C.ember, 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(240),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(ctx).padding.bottom),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: op(Colors.white, 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: op(C.ember, 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: op(C.ember, 0.5)),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: C.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Google Sign-In',
                      style: display(15, color: Colors.white, w: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Could not authenticate with Google Play Services ($error). You can choose a Google account or retry.',
                style: body(12, color: op(C.cream, 0.75), h: 1.4),
              ),
              const SizedBox(height: 20),
              BouncyPress(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final selected = await showModalBottomSheet<Map<String, String>>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (bCtx) => _buildGoogleAccountPicker(bCtx),
                  );
                  if (selected != null && mounted) {
                    final appState = context.read<AppState>();
                    await appState.signInWithGoogle(
                      id: selected['id'],
                      name: selected['name'],
                      email: selected['email'],
                      photoUrl: selected['photo'],
                    );
                    _onSignedInSuccess(selected['name'] ?? 'Customer');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: emberGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GoogleLogo(size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Choose Google Account',
                        style: body(13, color: Colors.white, w: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BouncyPress(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleGoogleSignIn();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: op(Colors.white, 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: op(Colors.white, 0.15)),
                  ),
                  child: Center(
                    child: Text(
                      'Retry Google Sign-In',
                      style: body(13, color: C.cream, w: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptGoogleAccountPicker() async {
    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bCtx) => _buildGoogleAccountPicker(bCtx),
    );
    if (selected != null && mounted) {
      final appState = context.read<AppState>();
      await appState.signInWithGoogle(
        id: selected['id'],
        name: selected['name'],
        email: selected['email'],
        photoUrl: selected['photo'],
      );
      _onSignedInSuccess(selected['name'] ?? 'Customer');
    }
  }

  Widget _buildGoogleAccountPicker(BuildContext context) {
    final accounts = [
      {
        'id': 'g_100',
        'name': 'Mohammed Nifras',
        'email': 'mohammed.nifras.000555@gmail.com',
        'photo': '', // Uses Google monogram avatar with initial 'M' on Google Blue
        'initial': 'M',
        'color': '0xFF4285F4',
      },
      {
        'id': 'g_101',
        'name': 'Nawaz Rahman',
        'email': 'nawaz.rahman@gmail.com',
        'photo': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
        'initial': 'N',
        'color': '0xFF4285F4',
      },
      {
        'id': 'g_102',
        'name': 'Aisha Siddiqua',
        'email': 'aisha.siddiqua@gmail.com',
        'photo': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        'initial': 'A',
        'color': '0xFFEA4335',
      },
      {
        'id': 'g_103',
        'name': 'Rashid Khan',
        'email': 'rashid.khan@gmail.com',
        'photo': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
        'initial': 'R',
        'color': '0xFF34A853',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B070E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: op(Colors.white, 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(240),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: op(Colors.white, 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const GoogleLogo(size: 22),
                const SizedBox(width: 12),
              Text(
                'Choose a Google Account',
                style: display(15, color: Colors.white, w: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'To continue to Fresh Meat',
            style: body(12, color: op(C.cream, 0.7)),
          ),
          const SizedBox(height: 18),
          ...accounts.map((acc) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(acc),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: op(Colors.white, 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: op(Colors.white, 0.1)),
                    ),
                    child: Row(
                      children: [
                        GoogleUserAvatar(
                          user: UserProfile(
                            id: acc['id']!,
                            name: acc['name']!,
                            email: acc['email']!,
                            photoUrl: acc['photo'],
                          ),
                          size: 40,
                          borderWidth: 1.5,
                          showGoogleBadge: false,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                acc['name']!,
                                style: body(13, color: Colors.white, w: FontWeight.w700),
                              ),
                              Text(
                                acc['email']!,
                                style: body(11, color: op(C.cream, 0.65)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: C.gold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            'To continue, Google will share your name, email address, and profile picture with Fresh Meat.',
            style: body(10, color: op(Colors.white, 0.45), h: 1.4),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final ringStyle = body(11, color: C.gold, w: FontWeight.w700);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0306),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: darkBg),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip / Browse as Guest
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (Navigator.of(context).canPop())
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: BouncyPress(
                          onTap: () => Navigator.of(context).pop(),
                          child: Glass(
                            radius: 12,
                            padding: const EdgeInsets.all(10),
                            opacity: 0.12,
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 36),

                    // Central Brand Mark
                    Semantics(
                      header: true,
                      label: 'Fresh Meat brand',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: C.ember,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 2),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FRESH MEAT',
                            style: display(11, color: C.cream, w: FontWeight.w700)
                                .copyWith(letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 36),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Floating Hero Circle with Animated Rotating Ring
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Semantics(
                              excludeSemantics: true,
                              child: Spin(
                                seconds: 24,
                                child: CustomPaint(
                                  size: const Size(250, 250),
                                  painter: RingTextPainter(
                                    'AUTHENTIC · 100% HALAL · SECURE LOGIN · FRESH CUTS · ',
                                    ringStyle,
                                  ),
                                ),
                              ),
                            ),
                            Floating(
                              angle: 0.05,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(160),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  border: Border.all(color: op(C.gold, 0.55), width: 2.2),
                                ),
                                child: ClipOval(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Semantics(
                                        label: 'Fresh Meat logo',
                                        image: true,
                                        child: Image.asset(
                                          'assets/images/app_logo.png',
                                          fit: BoxFit.cover,
                                          cacheWidth: 510,
                                        ),
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: Alignment.center,
                                            radius: 0.9,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withAlpha(60),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              child: Semantics(
                                label: '100% Certified Halal quality guarantee',
                                child: Glass(
                                  radius: 20,
                                  opacity: 0.25,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 14, color: C.gold),
                                      const SizedBox(width: 6),
                                      Text(
                                        '100% Certified Halal',
                                        style: body(10, color: C.cream, w: FontWeight.w800)
                                            .copyWith(letterSpacing: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Headlines
                      Reveal(
                        child: Column(
                          children: [
                            Text(
                              'Sign in to',
                              style: display(18, color: Colors.white, w: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            ShaderMask(
                              shaderCallback: (r) => emberGradient.createShader(r),
                              child: Text(
                                'Fresh Meat',
                                style: display(23, color: Colors.white, w: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Save your orders and track live butcher deliveries.',
                                textAlign: TextAlign.center,
                                style: body(12, color: op(C.cream, 0.78), h: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Trust Features Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: op(Colors.white, 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: op(Colors.white, 0.12)),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              Icons.bolt_rounded,
                              'Instant Access',
                              'No passwords needed.',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Divider(color: Color(0x22FFFFFF), height: 1),
                            ),
                            _buildFeatureRow(
                              Icons.location_on_outlined,
                              'Saved Addresses',
                              'Fast one-tap delivery.',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Divider(color: Color(0x22FFFFFF), height: 1),
                            ),
                            _buildFeatureRow(
                              Icons.receipt_long_outlined,
                              'Live Tracking',
                              'Track cold-chain cuts.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Google Only Action Area
                      if (_isLoading) ...[
                        Container(
                          height: 58,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(C.gold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Connecting to Google...',
                                style: body(13, color: C.cream, w: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Semantics(
                          button: true,
                          label: 'Continue with Google account',
                          child: BouncyPress(
                            onTap: _handleGoogleSignIn,
                            child: Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogo(size: 22),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F1F1F),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Privacy and Security Guarantee Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 13, color: C.gold),
                          const SizedBox(width: 6),
                          Text(
                            'Direct & Secure Google Sign-In',
                            style: body(11, color: op(C.cream, 0.65), w: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Your account details are safely protected.',
                          textAlign: TextAlign.center,
                          style: body(10, color: op(Colors.white, 0.4), h: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Semantics(
      label: '$title: $subtitle',
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: op(C.ember, 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: op(C.ember, 0.3)),
            ),
            child: Icon(icon, size: 18, color: C.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: body(12, color: Colors.white, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: body(10, color: op(C.cream, 0.65)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
