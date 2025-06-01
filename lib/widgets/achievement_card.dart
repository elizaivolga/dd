import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final int currentXP;

  const AchievementCard({
    Key? key,
    required this.achievement,
    required this.currentXP,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / achievement.xpRequired;
    final isUnlocked = achievement.isUnlocked;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  achievement.iconPath,
                  width: 64,
                  height: 64,
                  color: isUnlocked ? null : Colors.grey,
                ),
                if (!isUnlocked)
                  const Icon(
                    Icons.lock,
                    size: 32,
                    color: Colors.grey,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isUnlocked ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isUnlocked ? null : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (!isUnlocked) ...[
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentXP}/${achievement.xpRequired} XP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else
              Text(
                'Получено ${achievement.unlockedAt?.toString().split(' ')[0] ?? ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}