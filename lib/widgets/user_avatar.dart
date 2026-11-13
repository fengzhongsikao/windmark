import 'package:flutter/material.dart';

import 'package:windmark/features/profile/user_profile.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.profile,
    this.size = 64,
    this.onTap,
    this.circle = true,
  });

  final UserProfile profile;
  final double size;
  final VoidCallback? onTap;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final file = profile.avatarFile;
    final image = file == null
        ? Image.asset(
            'assets/icon/icon.png',
            width: size,
            height: size,
            fit: circle ? BoxFit.cover : BoxFit.contain,
          )
        : Image.file(
            file,
            key: ValueKey(profile.revision),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/icon/icon.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
              );
            },
          );
    final clipped = file != null || circle;
    final child = clipped
        ? ClipOval(
            child: SizedBox(width: size, height: size, child: image),
          )
        : image;
    if (onTap == null) {
      return child;
    }
    return Semantics(
      button: true,
      label: '头像',
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}
