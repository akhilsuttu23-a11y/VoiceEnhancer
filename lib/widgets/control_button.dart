import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? color;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isActive,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? (isActive ? Colors.red : Colors.white);
    
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: buttonColor.withOpacity(0.9),
            elevation: 8,
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.blue.shade900,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}