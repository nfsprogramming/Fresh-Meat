import 'package:flutter/material.dart';

import '../models.dart';
import '../screens/login_screen.dart';
import '../theme.dart';

/// Renders a real Google Profile Avatar for [UserProfile], loading high-res
/// Google profile photos or displaying authentic Google monogram avatars with
/// fallback to a signed-out Google silhouette.
class GoogleUserAvatar extends StatelessWidget {
  final UserProfile? user;
  final double size;
  final double borderWidth;
  final Color? borderColor;
  final bool showGoogleBadge;

  const GoogleUserAvatar({
    super.key,
    required this.user,
    this.size = 46,
    this.borderWidth = 2,
    this.borderColor,
    this.showGoogleBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? (user != null ? C.gold : C.ember);
    final badgeSize = (size * 0.38).clamp(14.0, 22.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Outer circular avatar
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B070E),
              border: Border.all(color: effectiveBorderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
            ),
          ),

          // Google "G" emblem badge
          if (showGoogleBadge)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: GoogleLogo(size: badgeSize * 0.70),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // 1. Signed in user
    if (user != null) {
      final photo = user!.photoUrl?.trim();

      // Case A: Real Google Account Network Photo URL (e.g. lh3.googleusercontent.com)
      if (photo != null && (photo.startsWith('http://') || photo.startsWith('https://'))) {
        return Image.network(
          photo,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildGoogleInitial();
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildGoogleInitial();
          },
        );
      }

      // Case B: Local asset path
      if (photo != null && photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _buildGoogleInitial(),
        );
      }

      // Case C: Authentic Google Colorful Monogram Circle
      return _buildGoogleInitial();
    }

    // 2. Guest / Unauthenticated State
    return Container(
      color: const Color(0xFF280D15),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.60,
          color: op(Colors.white, 0.85),
        ),
      ),
    );
  }

  Widget _buildGoogleInitial() {
    final initial = (user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()[0].toUpperCase()
        : 'G';
    final bgColor = user?.avatarBgColor ?? const Color(0xFF4285F4);

    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.46,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
