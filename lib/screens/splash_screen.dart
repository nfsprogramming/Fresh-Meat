import 'dart:async';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;
  bool _onboardingSeen = false;
  Future<void>? _onboardingCheck;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _onboardingCheck = _checkOnboardingStatus();
    _t = Timer(const Duration(milliseconds: 3400), _navigateNext);
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingSeen = prefs.getBool('fresh_meat_onboarding_seen') ?? false;
    } catch (_) {}
  }

  Future<void> _navigateNext() async {
    if (_navigated) return;
    _navigated = true;
    _t?.cancel();
    if (_onboardingCheck != null) {
      await _onboardingCheck;
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        fadeRoute(_onboardingSeen ? const HomeScreen() : const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _skip() {
    _navigateNext();
  }

  @override
  Widget build(BuildContext context) {
    final ringStyle = body(13, color: C.gold, w: FontWeight.w700);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Container(
          decoration: const BoxDecoration(gradient: darkBg),
          child: Stack(children: [
          Align(
            alignment: const Alignment(0, -.35),
            child: SizedBox(
              width: 360,
              height: 360,
              child: Stack(alignment: Alignment.center, children: [
                Spin(
                  seconds: 26,
                  child: CustomPaint(
                    size: const Size(360, 360),
                    painter: RingTextPainter('FRESH · HALAL · HYGIENIC · LOCAL · ' * 2, ringStyle),
                  ),
                ),
                Floating(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(160),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: op(C.gold, .45), width: 2.5),
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Semantics(
                            label: 'Prime fresh cut steak with rosemary and sea salt garnish',
                            image: true,
                            child: Image.asset(
                              'assets/images/splash_hero.jpg',
                              fit: BoxFit.cover,
                              cacheWidth: 600,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.restaurant_rounded, color: C.gold, size: 64),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.9,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Align(
            alignment: const Alignment(0, .55),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Reveal(
                child: ShaderMask(
                  shaderCallback: (r) => emberGradient.createShader(r),
                  child: Text('FRESH MEAT', style: display(38)),
                ),
              ),
              const SizedBox(height: 12),
              Reveal(delayMs: 500, child: Text('Cut fresh. Delivered local.', style: body(14, color: C.gold))),
            ]),
          ),
          Positioned(
            bottom: 70,
            left: 120,
            right: 120,
            child: Container(
              height: 4,
              decoration: BoxDecoration(color: op(Colors.white, .15), borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 3200),
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(decoration: BoxDecoration(gradient: emberGradient, borderRadius: BorderRadius.circular(2))),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 38,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'TAP ANYWHERE TO ENTER',
                style: body(10, color: op(Colors.white, .45), w: FontWeight.w700).copyWith(letterSpacing: 2),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}
}
