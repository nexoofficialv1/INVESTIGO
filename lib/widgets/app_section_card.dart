import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData? icon;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
