import 'package:flutter/material.dart';

class NaraLogo extends StatelessWidget {
  const NaraLogo({
    this.size = 48,
    this.padding = 8,
    this.backgroundColor,
    super.key,
  });

  final double size;
  final double padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Logo Nara',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerLow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001B3D).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/nara_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
