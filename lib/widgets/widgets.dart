import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ─── Avatar (letter-based, no images) ────────────────────────────────────────

class LetterAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? bg;
  final Color? fg;
  const LetterAvatar({
    super.key, required this.name,
    this.radius = 22, this.bg, this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg ?? AppColors.primarySubtle,
      child: Text(
        letter,
        style: TextStyle(
          color: fg ?? AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label = status.toUpperCase();
    switch (status.toLowerCase()) {
      case 'paid':     bg = const Color(0xFFE8F5E9); fg = AppColors.success; break;
      case 'partial':  bg = const Color(0xFFFFF3E0); fg = AppColors.warning; break;
      case 'unpaid':   bg = const Color(0xFFFFEBEE); fg = AppColors.error;   break;
      case 'active':   bg = const Color(0xFFE8F5E9); fg = AppColors.success; break;
      case 'inactive': bg = const Color(0xFFFFEBEE); fg = AppColors.error;   break;
      case 'paused':   bg = const Color(0xFFFFF3E0); fg = AppColors.warning; break;
      default:         bg = AppColors.primarySubtle;  fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBg;
  final VoidCallback? onTap;
  const StatCard({
    super.key, required this.label, required this.value, required this.icon,
    this.iconColor, this.iconBg, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 19),
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGray)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grayText)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? btnLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key, required this.icon, required this.title, required this.subtitle,
    this.btnLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(color: AppColors.primarySubtle, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.darkGray), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.grayText), textAlign: TextAlign.center),
            if (btnLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              SizedBox(width: 180, child: ElevatedButton(onPressed: onAction, child: Text(btnLabel!))),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      );
}

// ─── App Text Field ───────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key, required this.label, this.hint, required this.controller,
    this.validator, this.keyboardType = TextInputType.text,
    this.obscureText = false, this.prefixIcon, this.suffixIcon,
    this.maxLines = 1, this.enabled = true, this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      );
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkGray)),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(action!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      );
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.grayText, fontSize: 11)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── White Card ──────────────────────────────────────────────────────────────

class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  const WhiteCard({super.key, required this.child, this.padding, this.radius = 16});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: child,
      );
}
