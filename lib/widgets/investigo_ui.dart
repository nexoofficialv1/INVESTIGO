import 'package:flutter/material.dart';

/// INVESTIGO v207 visual system.
/// Keeps the app officer-friendly: large touch targets, high contrast,
/// low information density and consistent spacing.
class InvestigoUi {
  InvestigoUi._();

  static const Color primary = Color(0xFF2447D8);
  static const Color primaryDark = Color(0xFF132E9C);
  static const Color accent = Color(0xFF6D5CE7);
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color text = Color(0xFF14213D);
  static const Color muted = Color(0xFF667085);
  static const Color success = Color(0xFF168A5B);
  static const Color warning = Color(0xFFB7791F);
  static const double radius = 20;

  static BoxDecoration cardDecoration({Color color = surface}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE7EBF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B1F4D),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      );

  static ButtonStyle primaryButtonStyle() => FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      );
}

class InvestigoPageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const InvestigoPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: InvestigoUi.text,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: InvestigoUi.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class InvestigoActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const InvestigoActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(InvestigoUi.radius),
        onTap: onTap,
        child: Ink(
          decoration: InvestigoUi.cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (iconColor ?? InvestigoUi.primary).withOpacity(.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? InvestigoUi.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: InvestigoUi.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: InvestigoUi.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InvestigoStatPill extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const InvestigoStatPill({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: InvestigoUi.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: InvestigoUi.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: InvestigoUi.text,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: InvestigoUi.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InvestigoProgressHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int current;
  final int total;

  const InvestigoProgressHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final safeCurrent = current.clamp(1, safeTotal).toInt();
    return Container(
      decoration: InvestigoUi.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: InvestigoUi.text,
                  ),
                ),
              ),
              Text(
                '$safeCurrent/$safeTotal',
                style: const TextStyle(
                  color: InvestigoUi.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: InvestigoUi.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: safeCurrent / safeTotal,
              backgroundColor: const Color(0xFFE8ECF7),
              valueColor: const AlwaysStoppedAnimation(InvestigoUi.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class InvestigoStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const InvestigoStatusChip({
    super.key,
    required this.label,
    this.color = InvestigoUi.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
