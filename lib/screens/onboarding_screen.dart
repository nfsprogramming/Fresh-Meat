import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Interactive user preferences gathered during onboarding
  final Set<String> _selectedPreferences = {
    'Mutton Biryani',
    'Tender Chicken',
    'Prime Ribeye',
  };

  final List<OnboardingItem> _pages = const [
    OnboardingItem(
      badge: '100% Certified Halal',
      badgeIcon: Icons.verified_rounded,
      badgeColor: C.gold,
      titleLine1: 'Farm to Table',
      titleLine2: 'Prime Fresh Meat',
      description:
          'Ethically sourced from certified local farms. Never frozen, cut fresh only when you order.',
      imagePath: 'assets/images/beef_ribeye.jpg',
      ringText: '100% HALAL · FARM SOURCED · LAB TESTED · ZERO PRESERVATIVES · ',
      highlights: [
        OnboardingHighlight(Icons.shield_outlined, 'Strict Halal'),
        OnboardingHighlight(Icons.eco_outlined, 'Zero Hormones'),
        OnboardingHighlight(Icons.ac_unit_outlined, 'Never Frozen'),
      ],
    ),
    OnboardingItem(
      badge: 'Artisan Butchery',
      badgeIcon: Icons.content_cut_rounded,
      badgeColor: C.ember,
      titleLine1: 'Master Butchers',
      titleLine2: 'Custom Cut Your Way',
      description:
          'Biryani pieces, curry cuts, steaks, or minced. Custom prepared to your exact weight.',
      imagePath: 'assets/images/mutton_biryani.jpg',
      ringText: 'HAND CUT · CURRY PIECES · BIRYANI CUTS · JUICY CHOPS · ',
      highlights: [
        OnboardingHighlight(Icons.restaurant_menu_rounded, 'Custom Cuts'),
        OnboardingHighlight(Icons.scale_rounded, 'Exact Weight'),
        OnboardingHighlight(Icons.clean_hands_rounded, 'Sterile Prep'),
      ],
    ),
    OnboardingItem(
      badge: 'Chilled Express',
      badgeIcon: Icons.bolt_rounded,
      badgeColor: C.ember,
      titleLine1: 'Chilled Delivery',
      titleLine2: 'Direct to Your Door',
      description:
          'Delivered in 45 minutes in insulated thermal bags with cash on delivery convenience.',
      imagePath: 'assets/images/splash_hero.jpg',
      ringText: '45-MIN EXPRESS · 0°C-4°C CHILLED · CASH ON DELIVERY · ',
      highlights: [
        OnboardingHighlight(Icons.speed_rounded, '45 Mins Express'),
        OnboardingHighlight(Icons.payments_outlined, 'Cash on Delivery'),
        OnboardingHighlight(Icons.thermostat_rounded, '0°C-4°C Insulated'),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fresh_meat_onboarding_seen', true);
      // Save any chosen preferences for the session
      await prefs.setStringList(
        'fresh_meat_user_preferences',
        _selectedPreferences.toList(),
      );
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(fadeRoute(const LoginScreen()));
    }
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPrev() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0306),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: darkBg),
        child: Stack(
          children: [
            // Full-screen PageView Content with bottom scroll clearance
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildPageContent(context, item, index, size);
                },
              ),
            ),

            // Top Bar: Navigation, Progress pill, Skip button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button or Brand mark
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: BouncyPress(
                          onTap: _currentPage > 0 ? _onPrev : null,
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
                      ),

                      // Central Halal Meat Brand Tag
                      Row(
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

                      // Skip Button
                      BouncyPress(
                        onTap: _completeOnboarding,
                        child: Glass(
                          radius: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          opacity: 0.12,
                          child: Text(
                            'Skip',
                            style: body(12, color: C.gold, w: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Gradient Scrim Fade (smoothly dissolves scrolling cards under the floating button)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0B0306).withAlpha(190),
                        const Color(0xFF0B0306),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Action Controls Dock
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom > 20
                  ? (MediaQuery.of(context).padding.bottom + 4)
                  : 18.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dynamic Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: isActive ? emberGradient : null,
                          color: isActive ? null : op(Colors.white, 0.2),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: C.ember.withAlpha(90),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),

                  // Floating CTA Button with Gentle Levitation & Glowing Ambient Halo
                  _FloatingOnboardingButton(
                    onTap: _onNext,
                    isLastPage: isLastPage,
                  ),
                  const SizedBox(height: 12),

                  // Trust Assurance Microcopy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 12, color: C.gold),
                      const SizedBox(width: 6),
                      Text(
                        '100% Halal Certified · Zero Compromise on Freshness',
                        style: body(11, color: op(C.cream, 0.65), w: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    OnboardingItem item,
    int pageIndex,
    Size size,
  ) {
    final ringStyle = body(11, color: C.gold, w: FontWeight.w700);
    final topPadding = MediaQuery.of(context).padding.top + 64.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, 200),
        child: Column(
          children: [
            // Floating Hero Circle with Animated Rotating Ring
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Rotating Ring Text
                  Spin(
                    seconds: 24,
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: RingTextPainter(item.ringText, ringStyle),
                    ),
                  ),

                  // Floating Hero Image Medallion
                  Floating(
                    angle: pageIndex == 1 ? 0.08 : -0.08,
                    child: Container(
                      width: 195,
                      height: 195,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(160),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(color: op(C.gold, 0.5), width: 2.2),
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(item.imagePath, fit: BoxFit.cover, cacheWidth: 600),
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

                  // Floating Badge
                  Positioned(
                    bottom: 12,
                    child: Glass(
                      radius: 20,
                      opacity: 0.25,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.badgeIcon, size: 14, color: item.badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            item.badge,
                            style: body(10, color: C.cream, w: FontWeight.w800)
                                .copyWith(letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Headline
            Reveal(
              key: ValueKey('title_$pageIndex'),
              child: Column(
                children: [
                  Text(
                    item.titleLine1,
                    textAlign: TextAlign.center,
                    style: display(19, color: Colors.white, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  ShaderMask(
                    shaderCallback: (r) => emberGradient.createShader(r),
                    child: Text(
                      item.titleLine2,
                      textAlign: TextAlign.center,
                      style: display(23, color: Colors.white, w: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Reveal(
              delayMs: 150,
              key: ValueKey('desc_$pageIndex'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: body(13, color: op(C.cream, 0.78), h: 1.45, w: FontWeight.w400),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Interactive Taste Preference Customization on Slide 1
            if (pageIndex == 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 13, color: C.gold),
                    const SizedBox(width: 6),
                    Text(
                      'YOUR FAVORITE CUTS (TAP TO SELECT)',
                      style: body(10, color: C.gold, w: FontWeight.w800)
                          .copyWith(letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Mutton Biryani',
                  'Tender Chicken',
                  'Prime Ribeye',
                  'Curry Cut',
                  'Boneless Mince',
                  'Juicy Chops',
                ].map((pref) {
                  final isSelected = _selectedPreferences.contains(pref);
                  return BouncyPress(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSelected) {
                          _selectedPreferences.remove(pref);
                        } else {
                          _selectedPreferences.add(pref);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: isSelected ? emberGradient : null,
                        color: isSelected ? null : op(Colors.white, 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : op(Colors.white, 0.16),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline,
                            size: 13,
                            color: isSelected ? Colors.white : op(C.cream, 0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pref,
                            style: body(11,
                                color: isSelected ? Colors.white : C.cream,
                                w: isSelected ? FontWeight.w700 : FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              // Feature highlights badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: item.highlights.map((h) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: op(Colors.white, 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: op(Colors.white, 0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(h.icon, size: 18, color: C.gold),
                          const SizedBox(height: 6),
                          Text(
                            h.label,
                            textAlign: TextAlign.center,
                            style: body(10, color: C.cream, w: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String badge;
  final IconData badgeIcon;
  final Color badgeColor;
  final String titleLine1;
  final String titleLine2;
  final String description;
  final String imagePath;
  final String ringText;
  final List<OnboardingHighlight> highlights;

  const OnboardingItem({
    required this.badge,
    required this.badgeIcon,
    required this.badgeColor,
    required this.titleLine1,
    required this.titleLine2,
    required this.description,
    required this.imagePath,
    required this.ringText,
    required this.highlights,
  });
}

class OnboardingHighlight {
  final IconData icon;
  final String label;
  const OnboardingHighlight(this.icon, this.label);
}

class _FloatingOnboardingButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLastPage;

  const _FloatingOnboardingButton({
    required this.onTap,
    required this.isLastPage,
  });

  @override
  State<_FloatingOnboardingButton> createState() => _FloatingOnboardingButtonState();
}

class _FloatingOnboardingButtonState extends State<_FloatingOnboardingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final floatY = -5.0 * t;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: C.ember.withAlpha((80 + 50 * t).round()),
                  blurRadius: 18 + 8 * t,
                  spreadRadius: 1,
                  offset: Offset(0, 8 + 4 * t),
                ),
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ShineButton(
        onTap: widget.onTap,
        height: 58,
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isLastPage ? 'Start Shopping' : 'Next Step',
              style: display(13.5, color: Colors.white, w: FontWeight.w800)
                  .copyWith(letterSpacing: 1.1),
            ),
            const SizedBox(width: 10),
            Icon(
              widget.isLastPage
                  ? Icons.shopping_bag_outlined
                  : Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

