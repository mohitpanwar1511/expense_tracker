import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PremiumCircularChart extends StatelessWidget {
  final double totalSpending;
  final double unwarrantedSpending;

  const PremiumCircularChart({Key? key, required this.totalSpending, required this.unwarrantedSpending}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double cleanSpending = totalSpending - unwarrantedSpending;
    
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 60,
        sections: [
          PieChartSectionData(
            color: AppColors.emeraldGreen,
            value: cleanSpending <= 0 ? 1 : cleanSpending,
            title: '',
            radius: 22,
          ),
          PieChartSectionData(
            color: AppColors.errorRed,
            value: unwarrantedSpending,
            title: '',
            radius: 26,
          ),
        ],
      ),
    );
  }
}
