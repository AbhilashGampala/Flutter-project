import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:somna/features/home/presentation/home_screen.dart';
import 'package:somna/shared/state/app_state_provider.dart';
import '../repositories/mock_preferences_repository.dart';
import '../repositories/mock_sleep_repository.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late AppStateProvider appState;

    setUp(() async {
      appState = AppStateProvider(
        sleepRepository: MockSleepRepository(),
        preferencesRepository: MockPreferencesRepository(),
      );
      await appState.initialize();
    });

    testWidgets('Renders empty state cleanly when no sleep records exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appState,
            child: HomeScreen(
              onNavigateToProfile: () {},
              onNavigateToInsights: () {},
            ),
          ),
        ),
      );

      // Verify header and primary action
      expect(find.text('Start Sleep'), findsOneWidget);
      expect(find.text('No Sleep Sessions Yet'), findsOneWidget);
      expect(find.text('7-Day Overview'), findsOneWidget);
    });

    testWidgets('Renders last recorded sleep when data is logged', (tester) async {
      final now = DateTime(2026, 11, 9, 7, 0);
      await appState.addManualSession(
        startTimestamp: now.subtract(const Duration(hours: 7, minutes: 30)),
        endTimestamp: now,
        qualityRating: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppStateProvider>.value(
            value: appState,
            child: HomeScreen(
              onNavigateToProfile: () {},
              onNavigateToInsights: () {},
            ),
          ),
        ),
      );

      expect(find.text('Last Recorded Sleep'), findsOneWidget);
      expect(find.text('7h 30m'), findsOneWidget);
      expect(find.text('Restful'), findsOneWidget); // Quality label for 4
    });
  });
}
