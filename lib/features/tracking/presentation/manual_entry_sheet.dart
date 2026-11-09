import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../core/widgets/somna_quality_selector.dart';
import '../../../core/widgets/somna_tag_selector.dart';
import '../../../core/widgets/somna_text_field.dart';
import '../../../shared/models/sleep_session.dart';
import '../../../shared/state/app_state_provider.dart';

class ManualEntrySheet extends StatefulWidget {
  final SleepSession? existingSession; // Non-null if editing

  const ManualEntrySheet({super.key, this.existingSession});

  @override
  State<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<ManualEntrySheet> {
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  int? _qualityRating;
  List<String> _selectedTags = [];
  late TextEditingController _notesController;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSession != null) {
      final s = widget.existingSession!;
      _startDate = DateTime(s.startTimestamp.year, s.startTimestamp.month, s.startTimestamp.day);
      _startTime = TimeOfDay(hour: s.startTimestamp.hour, minute: s.startTimestamp.minute);
      _endDate = DateTime(s.endTimestamp.year, s.endTimestamp.month, s.endTimestamp.day);
      _endTime = TimeOfDay(hour: s.endTimestamp.hour, minute: s.endTimestamp.minute);
      _qualityRating = s.qualityRating;
      _selectedTags = List<String>.from(s.tags);
      _notesController = TextEditingController(text: s.notes);
    } else {
      // Default: Last night 23:00 to Today 07:00
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _endDate = today;
      _endTime = const TimeOfDay(hour: 7, minute: 0);

      _startDate = today.subtract(const Duration(days: 1));
      _startTime = const TimeOfDay(hour: 23, minute: 0);
      _qualityRating = 4;
      _selectedTags = [];
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final DateTime start = _combineDateAndTime(_startDate, _startTime);
    final DateTime end = _combineDateAndTime(_endDate, _endTime);

    // 1. Start before End validation
    if (!start.isBefore(end)) {
      setState(() {
        _errorMessage = 'Sleep start time must precede wake-up time.';
        _isLoading = false;
      });
      return;
    }

    // 2. Future date check
    if (end.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
      setState(() {
        _errorMessage = 'Wake-up time cannot be set in the future.';
        _isLoading = false;
      });
      return;
    }

    // 3. Max duration check (24h)
    if (end.difference(start).inHours > 24) {
      setState(() {
        _errorMessage = 'A single sleep session cannot exceed 24 hours.';
        _isLoading = false;
      });
      return;
    }

    try {
      final state = context.read<AppStateProvider>();
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      if (widget.existingSession != null) {
        final updated = widget.existingSession!.copyWith(
          startTimestamp: start,
          endTimestamp: end,
          qualityRating: _qualityRating,
          notes: notes,
          tags: _selectedTags,
        );
        await state.updateSession(updated);
      } else {
        await state.addManualSession(
          startTimestamp: start,
          endTimestamp: end,
          qualityRating: _qualityRating,
          notes: notes,
          tags: _selectedTags,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on SessionOverlapException catch (e) {
      setState(() {
        _errorMessage = '${e.message} Conflicts with ${TimeUtils.formatDateElegantly(e.conflictingStart)}.';
        _isLoading = false;
      });
    } on AppException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while saving: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Duration duration = _combineDateAndTime(_endDate, _endTime).difference(
      _combineDateAndTime(_startDate, _startTime),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingSession != null ? 'Edit Sleep Session' : 'Log Sleep Session',
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
            const SizedBox(height: 16),

            // Duration Pill
            if (duration.inMinutes > 0 && duration.inHours <= 24)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Calculated Duration: ',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      TimeUtils.formatDurationMinutes(duration.inMinutes),
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Start Date & Time
            Text(
              'Bedtime (Start)',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildPickerButton(
                    label: DateFormat('EEE, MMM d').format(_startDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildPickerButton(
                    label: _startTime.format(context),
                    icon: Icons.access_time,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) {
                        setState(() => _startTime = picked);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // End Date & Time
            Text(
              'Wake Time (End)',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildPickerButton(
                    label: DateFormat('EEE, MMM d').format(_endDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildPickerButton(
                    label: _endTime.format(context),
                    icon: Icons.access_time,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) {
                        setState(() => _endTime = picked);
                      }
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quality Selector
            SomnaQualitySelector(
              selectedRating: _qualityRating,
              onRatingChanged: (r) => setState(() => _qualityRating = r),
            ),
            const SizedBox(height: 20),

            // Tag Factor Selector
            SomnaTagSelector(
              selectedTags: _selectedTags,
              onSelectionChanged: (tags) => setState(() => _selectedTags = tags),
            ),
            const SizedBox(height: 20),

            // Notes field
            SomnaTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hintText: 'e.g., Caffeine late in the afternoon, room was cool...',
              maxLines: 2,
            ),

            // Error display
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mutedCoral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.mutedCoral.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.mutedCoral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.mutedCoral,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Save Action
            SomnaButton(
              label: widget.existingSession != null ? 'Update Session' : 'Save Session',
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

