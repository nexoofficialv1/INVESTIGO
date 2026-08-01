import 'package:flutter/material.dart';

class HomeGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const HomeGridCard({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 7),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, height: 1.08, fontWeight: FontWeight.w900, color: Color(0xFF303030)),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, height: 1.05, fontWeight: FontWeight.w700, color: Color(0xFF777777)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
