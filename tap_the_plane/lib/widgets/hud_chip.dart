import 'package:flutter/material.dart';

class HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const HudChip({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}