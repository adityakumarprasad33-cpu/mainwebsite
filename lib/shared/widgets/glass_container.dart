import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphism container widget.
/// Wraps child in a frosted-glass panel with backdrop blur,
/// translucent fill, and subtle border stroke.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.borderRadius = 16,
    this.opacity = 0.70,
    this.blurSigma = 12,
    this.borderColor,
    this.padding,
    this.margin,
    this.fillColor,
  });

  final Widget child;
  final double borderRadius;
  final double opacity;
  final double blurSigma;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: (fillColor ?? Colors.white).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ??
                  Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
