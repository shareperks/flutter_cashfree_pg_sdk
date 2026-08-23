import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shareperks/components/company/company_shareholding_view.dart';
import 'package:shareperks/repository/models/company_data_model.dart';

const _columns = ['Mar 2025', 'Jun 2025', 'Sep 2025'];

ShareholdingCategory _category(
  String name,
  double value, {
  List<ShareholdingCategory> holders = const [],
}) {
  return ShareholdingCategory(
    name: name,
    values: {for (final column in _columns) column: value},
    holders: holders,
  );
}

/// ITC's shape: a handful of categories, most of them carrying named holders.
CompanyShareholding _data() {
  return CompanyShareholding(
    period: ReportPeriod.quarterly,
    columns: _columns,
    categories: [
      _category(
        'Non-institutions',
        15.17,
        holders: [
          _category('HUF', 0.28),
          _category('Trusts', 0.07),
          _category('Clearing Members', 0.01),
        ],
      ),
      _category(
        'Institutions foreign',
        37.39,
        holders: [
          _category('Gqg Partners Emerging Markets Equity Fund', 2.1),
          _category('Government Of Singapore', 0.5),
        ],
      ),
      _category('Government', 0.04),
    ],
    pledge: const [],
  );
}

Widget _host() {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: CompanyShareholdingView(data: _data()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('opens with every category collapsed', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    // Categories, with a count of what is folded inside.
    expect(find.text('Non-institutions  (3)'), findsOneWidget);
    expect(find.text('Institutions foreign  (2)'), findsOneWidget);
    // No holders, so no count and no control.
    expect(find.text('Government'), findsOneWidget);

    expect(find.text('HUF'), findsNothing);
    expect(find.text('Government Of Singapore'), findsNothing);
    expect(find.text('Tap a category to see who holds it'), findsOneWidget);
  });

  testWidgets('a category opens and closes on tap', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Non-institutions  (3)'));
    await tester.pumpAndSettle();

    expect(find.text('HUF'), findsOneWidget);
    expect(find.text('Trusts'), findsOneWidget);
    // Opening one group leaves the others alone.
    expect(
      find.text('Gqg Partners Emerging Markets Equity Fund'),
      findsNothing,
    );
    expect(find.text('Tap a category to collapse it'), findsOneWidget);

    await tester.tap(find.text('Non-institutions  (3)'));
    await tester.pumpAndSettle();
    expect(find.text('HUF'), findsNothing);
  });

  testWidgets('groups open independently of one another', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Non-institutions  (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Institutions foreign  (2)'));
    await tester.pumpAndSettle();

    expect(find.text('HUF'), findsOneWidget);
    expect(find.text('Government Of Singapore'), findsOneWidget);
  });

  testWidgets('a category with no holders is not a tap target', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final before = find.byType(InkWell).evaluate().length;
    await tester.tap(find.text('Government'));
    await tester.pumpAndSettle();

    // Nothing opened, nothing changed.
    expect(find.byType(InkWell).evaluate().length, before);
    expect(find.text('Tap a category to see who holds it'), findsOneWidget);
  });
}
