import 'package:flutter/material.dart';

void showAppSnack(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  bool error = false,
}) =>
    showAppSnackOn(ScaffoldMessenger.of(context), message, icon: icon, error: error);

void showAppSnackOn(
  ScaffoldMessengerState messenger,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  bool error = false,
}) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: error ? const Color(0xFFB03838) : const Color(0xFF0D5A5C),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
