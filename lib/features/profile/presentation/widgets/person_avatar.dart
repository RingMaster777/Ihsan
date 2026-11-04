import 'package:flutter/material.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.profile,
    this.size = 48,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.shadow = true,
  });

  final Profile profile;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3))]
            : null,
        image: profile.avatarAsset == null
            ? null
            : DecorationImage(image: AssetImage(profile.avatarAsset!), fit: BoxFit.cover),
        gradient: profile.avatarAsset == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [profile.accent, Color.lerp(profile.accent, Colors.black, 0.28)!],
              )
            : null,
      ),
      alignment: Alignment.center,
      child: profile.avatarAsset == null
          ? Text(
              profile.initials,
              style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            )
          : null,
    );
  }
}
