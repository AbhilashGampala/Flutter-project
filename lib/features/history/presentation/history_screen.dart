import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_badge.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../core/widgets/somna_empty_state.dart';
import '../../../shared/models/sleep_session.dart';
import '../../../shared/state/app_state_provider.dart';
import '../../tracking/presentation/manual_entry_sheet.dart';
import 'session_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All'; // 'All', '7 Days', '30 Days'

  List<SleepSession> _filterSessions(List<SleepSession> sessions) {
    if (_selectedFilter == '7 Days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      return sessions.where((s) => s.startTimestamp.isAfter(cutoff)).toList();
    } else if (_selectedFilter == '30 Days') {
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      return sessions.where((s) => s.startTimestamp.isAfter(cutoff)).toList();
    }
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppStateProvider>();
    final filtered = _filterSessions(state.sessions);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Sleep History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Log Sleep',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ManualEntrySheet(),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: ['All', '7 Days', '30 Days'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                      selectedColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Session List or Empty State
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: SomnaEmptyState(
                        title: 'No History Recorded',
                        description: state.sessions.isEmpty
                            ? 'Your nightly sleep sessions will appear here chronologically once recorded.'
                            : 'No sessions found within the selected filter period.',
                        actionLabel: state.sessions.isEmpty ? 'Log Sleep Now' : null,
                        onAction: state.sessions.isEmpty
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const ManualEntrySheet(),
                                );
                              }
                            : null,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final session = filtered[index];
                        final durationStr = TimeUtils.formatDurationMinutes(session.durationInMinutes);
                        final dateStr = TimeUtils.formatDateElegantly(session.endTimestamp);
                        final bedtimeStr = TimeUtils.formatTimeOfDay(session.startTimestamp);
                        final wakeStr = TimeUtils.formatTimeOfDay(session.endTimestamp);

                        return SomnaCard(
                          padding: const EdgeInsets.all(16.0),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SessionDetailSheet(session: session),
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          dateStr,
                                          style: AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        if (session.qualityRating != null) ...[
                                          const SizedBox(width: 8),
                                          SomnaBadge(
                                            label: Formatters.formatQualityLabel(session.qualityRating),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$bedtimeStr - $wakeStr',
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    if (session.notes != null && session.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        session.notes!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                durationStr,
                                style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

