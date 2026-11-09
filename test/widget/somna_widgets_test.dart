import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somna/core/widgets/somna_button.dart';
import 'package:somna/core/widgets/somna_card.dart';
import 'package:somna/core/widgets/somna_progress_ring.dart';
import 'package:somna/core/widgets/somna_quality_selector.dart';

void main() {
  group('SOMNA Core Widgets Tests', () {
    testWidgets('SomnaCard renders child widget and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SomnaCard(
              onTap: () => tapped = true,
              child: const Text('Sleep Metric Content'),
            ),
          ),
        ),
      );

      expect(find.text('Sleep Metric Content'), findsOneWidget);
      await tester.tap(find.text('Sleep Metric Content'));
      expect(tapped, true);
    });

    testWidgets('SomnaButton triggers callback and shows label', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SomnaButton(
              label: 'Start Sleep',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Sleep'), findsOneWidget);
      await tester.tap(find.text('Start Sleep'));
      expect(pressed, true);
    });

    testWidgets('SomnaQualitySelector updates selection upon tapping a rating', (tester) async {
      int? selected = 3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SomnaQualitySelector(
                  selectedRating: selected,
                  onRatingChanged: (r) => setState(() => selected = r),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Good'), findsOneWidget); // Rating 3 label
      // Tap rating 5
      await tester.tap(find.text('5'));
      await tester.pump();

      expect(find.text('Optimal'), findsOneWidget); // Rating 5 label
      expect(selected, 5);
    });

    testWidgets('SomnaProgressRing renders without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SomnaProgressRing(
              progress: 0.85,
              centerWidget: Text('85%'),
            ),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);
    });
  });
}

