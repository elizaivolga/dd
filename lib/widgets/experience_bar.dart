import 'package:flutter/material.dart';

class ExperienceBar extends StatelessWidget {
  final int currentXP;
  final int maxXP;

  const ExperienceBar({
    Key? key,
    required this.currentXP,
    required this.maxXP,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / maxXP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 20,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentXP / $maxXP XP',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}