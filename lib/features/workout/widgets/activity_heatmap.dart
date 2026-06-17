import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<DateTime> activeDates;

  const ActivityHeatmap({
    super.key,
    required this.activeDates,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    
    // We will show 3 months. For simplicity, Current Month, and 2 Previous.
    final months = [
      DateTime(now.year, now.month - 2),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2E).withValues(alpha: 0.8),
            const Color(0xFF18181B).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: months.map((m) {
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMonthName(m.month),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMonthGrid(m, theme),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month, ThemeData theme) {
    // Generate a 4x7 grid for aesthetics (28 days approx)
    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (col) {
              final dayIndex = (row * 7) + col + 1;
              final date = DateTime(month.year, month.month, dayIndex);
              
              // Check if this date is active
              final isActive = activeDates.any((d) => 
                d.year == date.year && d.month == date.month && d.day == date.day
              );

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}
