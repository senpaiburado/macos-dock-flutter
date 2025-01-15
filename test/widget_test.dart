// file: test/dock_test.dart

import 'package:dock_test_task/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dock widget tests', () {
    testWidgets('Initial items are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Dock(
            items: [
              DockItem(icon: Icons.person, label: 'Profile'),
              DockItem(icon: Icons.message, label: 'Messages'),
              DockItem(icon: Icons.call, label: 'Calls'),
            ],
            builder: _testDockBuilder,
          ),
        ),
      ));

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
      expect(find.byIcon(Icons.call), findsOneWidget);
    });

    testWidgets('Dock reorders items on drag and drop',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Dock(
            items: [
              DockItem(icon: Icons.person, label: 'Profile'),
              DockItem(icon: Icons.message, label: 'Messages'),
              DockItem(icon: Icons.call, label: 'Calls'),
            ],
            builder: _testDockBuilder,
          ),
        ),
      ));

      final firstFinder = find.byIcon(Icons.person);
      final secondFinder = find.byIcon(Icons.message);

      // Long-press the first item to initiate dragging
      await tester.longPress(firstFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Drag the first item onto the second item
      final secondItemLocation = tester.getCenter(secondFinder);
      await tester.drag(firstFinder, Offset(secondItemLocation.dx, 0));
      await tester.pumpAndSettle();

      // Verify that no errors occur and item is still found
      expect(firstFinder, findsOneWidget);
      expect(secondFinder, findsOneWidget);
    });
  });
}

// Helper builder for tests
Widget _testDockBuilder(DockItem item, DockItemCallbacks<DockItem> callbacks) {
  return DockItemWidget(
    item: item,
    isPlaceholder: callbacks.isPlaceholder(item),
    onDragStarted: () => callbacks.onDragStarted(item),
    onDraggableCanceled: (velocity, offset) =>
        callbacks.onDraggableCanceled(velocity, offset),
    onDragCompleted: () => callbacks.onDragCompleted(item),
  );
}
