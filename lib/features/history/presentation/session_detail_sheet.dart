import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_badge.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../shared/models/sleep_session.dart';
import '../../../shared/state/app_state_provider.dart';
import '../../tracking/presentation/manual_entry_sheet.dart';

class SessionDetailSheet extends StatelessWidget {
  final SleepSession session;

  const SessionDetailSheet({super.key, required this.session});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'This sleep record will be permanently deleted from your local device database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (session.id != null) {
                await context.read<AppStateProvider>().deleteSession(session.id!);
              }
              if (context.mounted) {
                Navigator.of(ctx).pop(); // Dismiss dialog
                Navigator.of(context).pop(); // Dismiss detail sheet
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.mutedCoral)),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context).pop(); // Dismiss detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualEntrySheet(existingSession: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final durationStr = TimeUtils.formatDurationMinutes(session.durationInMinutes);
    final fullDate = TimeUtils.formatFullDate(session.endTimestamp);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Session Details',
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullDate,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Duration & Quality Badges
          Row(
            children: [
              Text(
                durationStr,
                style: AppTypography.heroDuration.copyWith(
                  fontSize: 38,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              if (session.qualityRating != null)
                SomnaBadge(
                  label: '${Formatters.formatQualityLabel(session.qualityRating)} (${session.qualityRating}/5)',
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  textColor: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Schedule Rows
          _buildInfoRow('Bedtime', TimeUtils.formatTimeOfDay(session.startTimestamp), isDark),
          const SizedBox(height: 12),
          _buildInfoRow('Wake Up', TimeUtils.formatTimeOfDay(session.endTimestamp), isDark),
          const SizedBox(height: 12),
          _buildInfoRow('Log Source', session.source == 'timer' ? 'Active Sleep Timer' : 'Manual Entry', isDark),
          if (session.isOvernight) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Type', 'Overnight Sleep Session', isDark),
          ],
          if (session.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Pre-Sleep Factors',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: session.tags.map((t) => SomnaBadge(label: t)).toList(),
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Session Notes',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.notes!,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Action Buttons: Edit and Delete
          Row(
            children: [
              Expanded(
                child: SomnaButton(
                  label: 'Edit',
                  variant: SomnaButtonVariant.secondary,
                  onPressed: () => _openEdit(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SomnaButton(
                  label: 'Delete',
                  variant: SomnaButtonVariant.destructive,
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

