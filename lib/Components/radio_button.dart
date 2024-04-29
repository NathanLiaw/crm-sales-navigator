import 'package:flutter/material.dart';

class RoundRadioButton extends StatelessWidget {
  final bool selected;
  final double size;

  const RoundRadioButton({super.key,
    required this.selected,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8.0,
      height: size + 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xff004c87),
          width: 1.0,
        ),
        color: selected ? Colors.white : Colors.transparent,
      ),
      child: selected
          ? Center(
        child: Container(
          width: size - 3.0,
          height: size - 3.0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xff004c87),
          ),
        ),
      )
          : null,
    );
  }
}