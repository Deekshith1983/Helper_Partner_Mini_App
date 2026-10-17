import 'package:flutter_test/flutter_test.dart';
import 'package:helper_partner/app.dart';
import 'package:helper_partner/core/constants.dart';

void main() {
  testWidgets('App renders brand title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HelperPartnerApp());
    expect(find.text(AppStrings.appName), findsWidgets);
  });
}
