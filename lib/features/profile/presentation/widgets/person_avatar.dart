import 'package:flutter/material.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.person,
    this.size = 48,
    this.borderColor = Colors.white,
    this.borderWidth = 3,
    this.shadow = true,
  });

  final Person person;
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
        image: DecorationImage(image: AssetImage(person.avatarAsset), fit: BoxFit.cover),
      ),
    );
  }
}
