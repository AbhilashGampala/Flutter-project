import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../core/widgets/somna_quality_selector.dart';
import '../../../core/widgets/somna_tag_selector.dart';
import '../../../core/widgets/somna_text_field.dart';
import '../../../shared/state/app_state_provider.dart';

class ActiveTrackingScreen extends StatefulWidget {
  const ActiveTrackingScreen({super.key});

  @override
  State<ActiveTrackingScreen> createState() => _ActiveTrackingScreenState();
}

class _ActiveTrackingScreenState extends State<ActiveTrackingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showWakeUpDialog() {
    int? selectedQuality = 4; // Default to 'Restful'
    List<String> selectedTags = [];
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Finalizing your recorded sleep session.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SomnaQualitySelector(
                    selectedRating: selectedQuality,
                    onRatingChanged: (rating) {
                      setModalState(() {
                        selectedQuality = rating;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SomnaTagSelector(
                    selectedTags: selectedTags,
                    onSelectionChanged: (tags) {
                      setModalState(() {
                        selectedTags = tags;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SomnaTextField(
                    controller: notesController,
                    label: 'Notes (Optional)',
                    hintText: 'e.g. Calm night, vivid dreams, woke up once...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),
                  SomnaButton(
                    label: 'Save Sleep Session',
                    onPressed: () async {
                      final appState = context.read<AppStateProvider>();
                      await appState.wakeUpAndFinalizeSession(
                        qualityRating: selectedQuality,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        tags: selectedTags,
                      );
                      if (context.mounted) {
                        Navigator.of(ctx).pop(); // Dismiss sheet
                        Navigator.of(context).pop(); // Return to dashboard
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDiscard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Discard Current Session?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        ),
        content: Text(
          'This will cancel active tracking without recording any sleep history.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Tracking'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AppStateProvider>().discardActiveSession();
              if (context.mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Discard', style: TextStyle(color: AppColors.mutedCoral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final active = state.activeSession;

    if (active == null) {
      return Scaffold(
        backgroundColor: AppColors.nightTrackingBg,
        body: Center(
          child: SomnaButton(
            label: 'Return to Home',
            width: 200,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final Duration elapsed = active.elapsedDuration;
    final String formattedElapsed = TimeUtils.formatDurationDetailed(elapsed);
    final String startedAt = TimeUtils.formatTimeOfDay(active.startTimestamp);

    return Scaffold(
      backgroundColor: AppColors.nightTrackingBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.darkTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Minimize Tracking',
                  ),
                  Text(
                    'Active Sleep Tracking',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.darkTextTertiary),
                    onPressed: _confirmDiscard,
                    tooltip: 'Discard Session',
                  ),
                ],
              ),

              // Ambient Center Display
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.dustyBlue.withOpacity(0.08),
                        border: Border.all(
                          color: AppColors.dustyBlue.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.bedtime_outlined,
                        size: 48,
                        color: AppColors.dustyBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    formattedElapsed,
                    style: AppTypography.heroDuration.copyWith(
                      fontSize: 54,
                      letterSpacing: -2.0,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Started at $startedAt',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),

              // Bottom Action
              Column(
                children: [
                  SomnaButton(
                    label: 'Wake Up',
                    onPressed: _showWakeUpDialog,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Timestamp calculated securely from storage',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.darkTextTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

