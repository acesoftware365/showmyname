import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showmyname/features/home/widgets/scrollable_mode_dock.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('Dock hints follow overflow and resizing: $direction',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(260, 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Directionality(
        textDirection: direction,
        child: Scaffold(
            body: Center(
                child: ScrollableModeDock(
                    child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5,
              (i) => SizedBox(width: 100, height: 60, child: Text('Mode $i'))),
        )))),
      )));
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('dock-more-next'));
      final previous = find.byKey(const ValueKey('dock-more-previous'));
      expect(next, findsOneWidget);
      expect(previous, findsNothing);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(previous, findsOneWidget);
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(next, findsNothing);
      expect(previous, findsOneWidget);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(next, findsOneWidget);
      tester.view.physicalSize = const Size(800, 300);
      await tester.pumpAndSettle();
      expect(next, findsNothing);
      expect(previous, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selected dock item is brought into view', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(260, 120);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final itemKeys = List.generate(5, (_) => GlobalKey());
    var selectedIndex = 0;
    late StateSetter update;

    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return Scaffold(
            body: SizedBox(
              height: 72,
              child: ScrollableModeDock(
                selectedItemKey: itemKeys[selectedIndex],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < itemKeys.length; index++)
                      KeyedSubtree(
                        key: itemKeys[index],
                        child: SizedBox(
                          width: 100,
                          height: 60,
                          child: Text('Mode $index'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ));
    await tester.pumpAndSettle();

    update(() => selectedIndex = 4);
    await tester.pumpAndSettle();

    final viewport =
        tester.getRect(find.byKey(const ValueKey('sign-mode-bar')));
    final selected = tester.getRect(find.byKey(itemKeys[4]));
    expect(selected.left, greaterThanOrEqualTo(viewport.left));
    expect(selected.right, lessThanOrEqualTo(viewport.right));
  });
}
