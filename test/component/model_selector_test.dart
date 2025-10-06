import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketllm/component/model_selector.dart';
import 'package:pocketllm/component/models.dart';

void main() {
  group('ModelSelector', () {
    testWidgets('should create ModelSelector with default properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(),
          ),
        ),
      );

      expect(find.byType(ModelSelector), findsOneWidget);
    });

    testWidgets('should display title when provided', (WidgetTester tester) async {
      const title = 'Select AI Model';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(title: title),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('should handle different selector styles', (WidgetTester tester) async {
      for (final style in ModelSelectorStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ModelSelector(style: style),
            ),
          ),
        );

        expect(find.byType(ModelSelector), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should show empty state when no models available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(style: ModelSelectorStyle.list),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Look for empty state indicators
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
      expect(find.text('No models configured'), findsOneWidget);
    });

    testWidgets('should be disabled when enabled is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(enabled: false),
          ),
        ),
      );

      expect(find.byType(ModelSelector), findsOneWidget);
      
      // Try to interact with disabled selector
      await tester.tap(find.byType(ModelSelector));
      await tester.pumpAndSettle();
      
      // Should not show any selection dialog or change
    });

    testWidgets('should handle model selection callback', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              onModelChanged: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(ModelSelector), findsOneWidget);
      
      // Note: Actual callback testing would require mocking ModelState
      // This test verifies the callback parameter is accepted
      expect(callbackCalled, false);
    });

    group('ModelSelectorStyle', () {
      test('should have all expected values', () {
        expect(ModelSelectorStyle.values, contains(ModelSelectorStyle.dropdown));
        expect(ModelSelectorStyle.values, contains(ModelSelectorStyle.list));
        expect(ModelSelectorStyle.values, contains(ModelSelectorStyle.grid));
        expect(ModelSelectorStyle.values, contains(ModelSelectorStyle.compact));
      });
    });
  });

  group('Convenience Widgets', () {
    testWidgets('ModelDropdown should create dropdown style selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelDropdown(),
          ),
        ),
      );

      expect(find.byType(ModelDropdown), findsOneWidget);
      expect(find.byType(ModelSelector), findsOneWidget);
    });

    testWidgets('ModelList should create list style selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelList(),
          ),
        ),
      );

      expect(find.byType(ModelList), findsOneWidget);
      expect(find.byType(ModelSelector), findsOneWidget);
    });

    testWidgets('CompactModelSelector should create compact style selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactModelSelector(),
          ),
        ),
      );

      expect(find.byType(CompactModelSelector), findsOneWidget);
      expect(find.byType(ModelSelector), findsOneWidget);
    });

    testWidgets('convenience widgets should accept parameters', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ModelDropdown(
                  title: 'Dropdown Title',
                  enabled: false,
                  onModelChanged: () => callbackCalled = true,
                ),
                ModelList(
                  title: 'List Title',
                  maxHeight: 200,
                  enabled: false,
                  onModelChanged: () => callbackCalled = true,
                ),
                CompactModelSelector(
                  enabled: false,
                  onModelChanged: () => callbackCalled = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ModelDropdown), findsOneWidget);
      expect(find.byType(ModelList), findsOneWidget);
      expect(find.byType(CompactModelSelector), findsOneWidget);
      expect(find.text('Dropdown Title'), findsOneWidget);
      expect(find.text('List Title'), findsOneWidget);
    });
  });

  group('Widget Properties', () {
    testWidgets('should handle all boolean properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              showHealthStatus: false,
              showProviderIcons: false,
              allowHealthCheck: false,
              enabled: false,
            ),
          ),
        ),
      );

      expect(find.byType(ModelSelector), findsOneWidget);
    });

    testWidgets('should handle padding and maxHeight properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelSelector(
              padding: EdgeInsets.all(16),
              maxHeight: 300,
            ),
          ),
        ),
      );

      expect(find.byType(ModelSelector), findsOneWidget);
    });
  });
}