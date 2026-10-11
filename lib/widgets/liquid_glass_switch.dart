import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Komponen Switch dengan desain Liquid Glass (transparan, efek blur kaca,
/// specular reflection, dan glow) khas iOS modern.
class LiquidGlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final double width;
  final double height;

  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.width = 54.0,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color tintColor = activeColor ?? AppTheme.primaryBlue;
    final double thumbSize = height - 6.0; // 26.0

    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          HapticFeedback.lightImpact();
          onChanged!(!value);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            if (value)
              BoxShadow(
                color: tintColor.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: value
                      ? [
                          tintColor.withValues(alpha: 0.88),
                          tintColor.withValues(alpha: 0.65),
                        ]
                      : [
                          const Color(0xFF64748B).withValues(alpha: 0.32),
                          const Color(0xFF94A3B8).withValues(alpha: 0.18),
                        ],
                ),
                border: Border.all(
                  color: value
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.60),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  // Specular light reflection on top glass track
                  Positioned(
                    top: 1,
                    left: 4,
                    right: 4,
                    height: height * 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(height / 2),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Liquid Glass Thumb
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.92),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 5,
                              spreadRadius: 0,
                              offset: const Offset(0, 2.5),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 2,
                              spreadRadius: 0,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Specular catchlight bead on the thumb
                            Positioned(
                              top: 2.5,
                              left: 4.5,
                              child: Container(
                                width: 8,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.85),
                                      Colors.white.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adaptive SwitchListTile: Otomatis menampilkan [LiquidGlassSwitch] jika
/// di platform iOS, dan fallback ke standar Material [SwitchListTile] di Android/platform lain.
class LiquidGlassSwitchListTile extends StatelessWidget {
  final Widget? secondary;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const LiquidGlassSwitchListTile({
    super.key,
    this.secondary,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS) {
      return ListTile(
        leading: secondary,
        title: title,
        subtitle: subtitle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        trailing: LiquidGlassSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor ?? AppTheme.primaryBlue,
        ),
        onTap: onChanged != null ? () => onChanged!(!value) : null,
      );
    }

    return SwitchListTile(
      secondary: secondary,
      title: title,
      subtitle: subtitle,
      value: value,
      activeColor: activeColor ?? AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }
}
