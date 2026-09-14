import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isSecondary;
  final bool isDanger;
  final double? width;

  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDanger = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isSecondary
        ? Colors.transparent
        : (isDanger ? AppColors.error : AppColors.primary);
    final Color fg = isSecondary ? (isDanger ? AppColors.error : AppColors.primary) : Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: isSecondary
          ? OutlinedButton(
              onPressed: isLoading || onPressed == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDanger ? AppColors.error : AppColors.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _buildChild(fg),
            )
          : ElevatedButton(
              onPressed: isLoading || onPressed == null
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onPressed!();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _buildChild(fg),
            ),
    );
  }

  Widget _buildChild(Color fg) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.2),
          ),
        ],
      );
    }

    return Text(
      label,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg, letterSpacing: -0.2),
    );
  }
}
