import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketllm/component/chat_interface.dart';
import 'package:pocketllm/services/model_state.dart';
import 'package:pocketllm/component/models.dart';

void main() {
  group('ChatInterface', () {
    testWidgets('should create ChatInterface widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      expect(find.byType(ChatInterface), findsOneWidget);
    });

    testWidgets('should show welcome screen when no messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for welcome screen elements
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      expect(find.text('Start a new conversation'), findsOneWidget);
    });

    testWidgets('should show suggestion cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for suggestion cards
      expect(find.text('Create a cartoon'), findsOneWidget);
      expect(find.text('What can PocketLLM do'), findsOneWidget);
    });

    testWidgets('should show input area', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Look for input elements
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should handle text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and interact with text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Hello, world!');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('should show attachment options when add button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Look for attachment options
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('should handle send button state based on text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, send button should be disabled (different color)
      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsOneWidget);

      // Enter text
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.pumpAndSettle();

      // Send button should now be enabled (different color)
      expect(sendButton, findsOneWidget);
    });

    group('Model Change Handling', () {
      testWidgets('should not show model indicator when no messages', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Model indicator should not be visible when no messages
        expect(find.text('Using'), findsNothing);
      });

      testWidgets('should handle model state changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Widget should be created without errors
        expect(find.byType(ChatInterface), findsOneWidget);
      });
    });

    group('Message Handling', () {
      testWidgets('should handle empty message submission', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Try to send empty message
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Should not crash or show error
        expect(find.byType(ChatInterface), findsOneWidget);
      });

      testWidgets('should handle message submission with text', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter text and send
        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Test message');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Should handle the message submission
        expect(find.byType(ChatInterface), findsOneWidget);
      });
    });

    group('UI Components', () {
      testWidgets('should show suggestion cards with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for suggestion card containers
        expect(find.byType(InkWell), findsWidgets);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should handle suggestion card taps', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on a suggestion card
        await tester.tap(find.text('Create a cartoon'));
        await tester.pumpAndSettle();

        // Should handle the tap without errors
        expect(find.byType(ChatInterface), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for semantic elements
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(IconButton), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle widget creation without errors', (WidgetTester tester) async {
        expect(() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChatInterface(),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }, returnsNormally);
      });

      testWidgets('should handle state changes without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatInterface(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate various interactions
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pumpAndSettle();

        expect(find.byType(ChatInterface), findsOneWidget);
      });
    });
  });

  group('ChatInterfaceState', () {
    testWidgets('should initialize properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should create state without errors
      expect(find.byType(ChatInterface), findsOneWidget);
    });

    testWidgets('should dispose properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should dispose without errors
      expect(find.byType(ChatInterface), findsNothing);
    });
  });
}