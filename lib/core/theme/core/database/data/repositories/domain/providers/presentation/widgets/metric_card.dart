import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isAlert;

  const MetricCard({Key? key, required this.title, required this.value, required this.isAlert}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.errorRed.withOpacity(0.12) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAlert ? AppColors.errorRed.withOpacity(0.4) : Colors.transparent,
          width: 1
        )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: isAlert ? AppColors.errorRed : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isAlert ? AppColors.errorRed : null)),
        ],
      ),
    );
  }
}
