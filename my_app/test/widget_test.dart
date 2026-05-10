import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/gx_financial_app.dart';

void main() {
  testWidgets('login and adoption flow opens dashboard', (tester) async {
    await tester.pumpWidget(const GXFinancialApp());

    expect(find.text('GX Financial Cat'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    expect(find.text('Adopt your GX-Cat'), findsOneWidget);
    expect(find.text('Start resilience journey'), findsOneWidget);

    await tester.tap(find.text('Start resilience journey'));
    await tester.pumpAndSettle();

    expect(find.text('GX Financial Cat'), findsOneWidget);
    expect(find.text('Nudge Engine'), findsOneWidget);
    expect(find.text('Feed with Round-up'), findsOneWidget);
  });

  testWidgets('BNPL action surfaces hissing state', (tester) async {
    await tester.pumpWidget(const GXFinancialApp());
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start resilience journey'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate BNPL Checkout'));
    await tester.pump();

    expect(find.textContaining('BNPL Hiss'), findsWidgets);
    expect(find.text('BNPL alert: fashion checkout'), findsOneWidget);
  });

  testWidgets('profile tab updates cat name', (tester) async {
    await tester.pumpWidget(const GXFinancialApp());
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start resilience journey'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Cat name'), 'Luna');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Meet Luna'), findsOneWidget);
  });
}
