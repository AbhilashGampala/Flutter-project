import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/somna_button.dart';
import '../../../core/widgets/somna_card.dart';
import '../../../shared/services/export_service.dart';
import '../../../shared/state/app_state_provider.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isExporting = false;

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    final sessions = context.read<AppStateProvider>().sessions;
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recorded sleep sessions to export.')),
      );
      setState(() => _isExporting = false);
      return;
    }

    final success = await ExportService.shareExport(sessions: sessions, isCsv: true);
    setState(() => _isExporting = false);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share CSV file.')),
      );
    }
  }

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);
    final sessions = context.read<AppStateProvider>().sessions;
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recorded sleep sessions to export.')),
      );
      setState(() => _isExporting = false);
      return;
    }

    final success = await ExportService.shareExport(sessions: sessions, isCsv: false);
    setState(() => _isExporting = false);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to share JSON file.')),
      );
    }
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Sleep Data?'),
        content: const Text(
          'This action will permanently erase every recorded sleep session, active timer, and analytics history from your device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Second confirmation for destructive bulk deletion
              _secondConfirmDeleteAll();
            },
            child: const Text('Proceed', style: TextStyle(color: AppColors.mutedCoral)),
          ),
        ],
      ),
    );
  }

  void _secondConfirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'Are you completely sure? All local records will be deleted now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Data'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AppStateProvider>().clearAllData();
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All sleep data erased successfully.')),
                );
              }
            },
            child: const Text('Delete Everything', style: TextStyle(color: AppColors.mutedCoral, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _seedSampleData() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed 14-Day Realistic Data?'),
        content: const Text(
          'This will populate your database with 14 realistic nights of sleep data with varied bedtimes, wake times, and perceived ratings. Perfect for exploring analytics and trends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AppStateProvider>().seedRealisticSampleData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('14 sample nights loaded successfully.')),
                );
              }
            },
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalSessions = context.watch<AppStateProvider>().sessions.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Data Management')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Recorded Sessions',
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$totalSessions',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 32,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.storage_outlined,
                      size: 32,
                      color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export Data Section
              Text(
                'Export Your Records',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Extract your full sleep history to standard open file formats for research, analysis, or personal backup.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildActionRow(
                      Icons.table_chart_outlined,
                      'Export as CSV (RFC 4180)',
                      'Standard comma-separated format compatible with Excel, Google Sheets, and data tools.',
                      _isExporting ? null : _exportCsv,
                      isDark,
                    ),
                    const Divider(height: 24),
                    _buildActionRow(
                      Icons.code_outlined,
                      'Export as JSON',
                      'Structured JSON object with full ISO timestamps and duration metadata.',
                      _isExporting ? null : _exportJson,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Test Data Generation
              Text(
                'Evaluation & Testing',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Easily seed realistic sample records to verify charts, circular consistency, and insight rules.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SomnaCard(
                padding: const EdgeInsets.all(20),
                child: _buildActionRow(
                  Icons.auto_awesome_outlined,
                  'Seed 14 Days of Sample Sleep Records',
                  'Fills database with realistic nighttime entries to explore analytics without waiting 2 weeks.',
                  _seedSampleData,
                  isDark,
                ),
              ),
              const SizedBox(height: 32),

              // Danger Zone
              Text(
                'Danger Zone',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedCoral,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Permanently removes all database tables and cached sleep sessions from device storage.',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SomnaButton(
                label: 'Delete All Sleep Records',
                variant: SomnaButtonVariant.destructive,
                onPressed: _confirmDeleteAll,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(
    IconData icon,
    String title,
    String desc,
    VoidCallback? onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: isDark ? AppColors.dustyBlue : AppColors.brandPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

