import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class IntroScreen extends StatefulWidget {
  final VoidCallback onStart;
  const IntroScreen({super.key, required this.onStart});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: .90, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    height: 118,
                    width: 118,
                    decoration: BoxDecoration(
                      color: AppTheme.deepGreen,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8))],
                    ),
                    child: const Icon(Icons.local_police_rounded, color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Investigation & Process',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.deepGreen),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mobile Investigation Diary • CD Writer • Statement • Forms • IF5',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.4, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                    child: const Column(
                      children: [
                        _IntroLine(icon: Icons.edit_document, text: 'Question based CD generation'),
                        _IntroLine(icon: Icons.picture_as_pdf, text: 'Official A4 PDF export'),
                        _IntroLine(icon: Icons.offline_bolt, text: 'Offline-first mobile workflow'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onStart,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Start'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Dev: Bappa Roy', style: TextStyle(color: AppTheme.deepGreen, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IntroLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppTheme.cream, child: Icon(icon, color: AppTheme.deepGreen, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
