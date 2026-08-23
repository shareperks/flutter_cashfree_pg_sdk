import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/screens/main/CompanySearchScreen.dart';
import 'package:shareperks/utils/company_format.dart';

/// Centre-line check: the widget's painted box shares the screen's centre.
void expectHorizontallyCentred(WidgetTester tester, Finder finder) {
  final box = tester.getRect(finder);
  final screen = tester.getRect(find.byType(MaterialApp));
  expect((box.center.dx - screen.center.dx).abs(), lessThan(1.0));
}

void main() {
  group('companyInitials', () {
    test('drops the corporate suffix', () {
      expect(companyInitials('ITC Ltd', 'ITC'), 'IT');
      expect(companyInitials('Infosys Limited', 'INFY'), 'IN');
    });

    test('takes one letter from each of the first two words', () {
      expect(companyInitials('Tata Consultancy Services', 'TCS'), 'TC');
    });

    test('falls back to the symbol when the name has no words', () {
      expect(companyInitials('', '543806'), '54');
      expect(companyInitials('', ''), '?');
    });
  });

  group('CompanySearchScreen', () {
    testWidgets('opens on a centred hero', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CompanySearchScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Research any'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('ITC'), findsOneWidget);

      expectHorizontallyCentred(tester, find.textContaining('Research any'));
      expectHorizontallyCentred(tester, find.text('POPULAR'));
      expectHorizontallyCentred(
        tester,
        find.textContaining('Search by company name'),
      );
    });

    testWidgets('the hero lifts away once the query is long enough', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CompanySearchScreen()));
      await tester.pumpAndSettle();

      // One character is still the idle state — most of the market matches it.
      await tester.enterText(find.byType(TextField), 'I');
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.textContaining('Research any'), findsOneWidget);
      expect(find.textContaining('Keep typing'), findsOneWidget);

      // Two collapses the hero. Everything here stays inside the 250ms
      // debounce, and clearing the field cancels it — the test must not depend
      // on a company-data-service being up.
      await tester.enterText(find.byType(TextField), 'IT');
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.textContaining('Research any'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.textContaining('Research any'), findsOneWidget);
    });

    testWidgets('keeps the field alive across the transition', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CompanySearchScreen()));
      await tester.pumpAndSettle();

      final before = tester.element(find.byType(TextField));
      expect(FocusScope.of(before).hasFocus, isTrue);

      await tester.enterText(find.byType(TextField), 'IT');
      await tester.pump(const Duration(milliseconds: 40));

      // Same element, so the keyboard and caret survive the hero collapsing —
      // this is why the layout animates rather than being swapped out.
      expect(identical(tester.element(find.byType(TextField)), before), isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'IT',
      );

      // Cancel the pending debounce before the test ends.
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
    });
  });
}
