import 'package:book/features/bookDetails/ui/paged_pdf_reader_screen.dart';
import 'package:book/features/home/data/models/books_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The online (not downloaded) reader shows server-rendered page images in a
// PageView. These tests make sure pinch-zoom works there without breaking
// page swipes.
/// Runs enough frames for page and zoom animations to finish. (A single
/// long pump is only one frame.)
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  const pages = [
    BookPdfPage(pageNumber: 1, imageUrl: 'https://example.com/1.png'),
    BookPdfPage(pageNumber: 2, imageUrl: 'https://example.com/2.png'),
    BookPdfPage(pageNumber: 3, imageUrl: 'https://example.com/3.png'),
  ];

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpReader(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: PagedPdfReaderScreen(
          title: 'Test book',
          pages: pages,
          bookId: 'zoom-test',
        ),
      ),
    );
    // Let the saved page load and the PageView appear.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  double currentScale(WidgetTester tester) {
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer).hitTestable().first,
    );
    return viewer.transformationController!.value.getMaxScaleOnAxis();
  }

  Future<void> pinchOut(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(PageView));
    final first = await tester.startGesture(
      center - const Offset(40, 0),
      pointer: 1,
    );
    await tester.pump();
    final second = await tester.startGesture(
      center + const Offset(40, 0),
      pointer: 2,
    );
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await first.moveBy(const Offset(-12, 0));
      await second.moveBy(const Offset(12, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await first.up();
    await second.up();
    await settle(tester);
  }

  Future<void> swipe(WidgetTester tester, Offset delta) async {
    await tester.fling(find.byType(PageView), delta, 1500);
    await settle(tester);
  }

  testWidgets('pinch zooms the page', (tester) async {
    await pumpReader(tester);
    expect(currentScale(tester), closeTo(1, 0.001));

    await pinchOut(tester);

    expect(currentScale(tester), greaterThan(1.5));
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('dragging a zoomed page pans it instead of turning the page', (
    tester,
  ) async {
    await pumpReader(tester);
    await pinchOut(tester);

    await swipe(tester, const Offset(-300, 0));
    await swipe(tester, const Offset(0, -300));

    expect(find.text('1 / 3'), findsOneWidget);
    expect(currentScale(tester), greaterThan(1.5));
  });

  testWidgets('double-tap zooms in and out', (tester) async {
    await pumpReader(tester);
    final center = tester.getCenter(find.byType(PageView));

    Future<void> doubleTap() async {
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(center);
      await settle(tester);
    }

    await doubleTap();
    expect(currentScale(tester), closeTo(2.5, 0.01));

    await doubleTap();
    expect(currentScale(tester), closeTo(1, 0.01));
  });

  testWidgets('swipes still turn pages when not zoomed', (tester) async {
    await pumpReader(tester);

    await swipe(tester, const Offset(-300, 0));
    expect(find.text('2 / 3'), findsOneWidget);

    // Vertical swipe up goes to the next page too.
    await swipe(tester, const Offset(0, -300));
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('a pinch-zoomed page resets after turning the page', (
    tester,
  ) async {
    await pumpReader(tester);
    await pinchOut(tester);
    expect(currentScale(tester), greaterThan(1.5));

    // Next-page button in the bottom bar still works while zoomed.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(currentScale(tester), closeTo(1, 0.001));

    // And swiping works again on the new, unzoomed page.
    await swipe(tester, const Offset(-300, 0));
    expect(find.text('3 / 3'), findsOneWidget);
  });
}
