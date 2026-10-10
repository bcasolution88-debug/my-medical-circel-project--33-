import 'package:flutter_test/flutter_test.dart';
import 'package:health_circle/main.dart';

void main() {
  testWidgets('Home renders 活动报名 section', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthCircleApp(skipSplash: true));
    await tester.pump();
    expect(find.text('活动报名'), findsOneWidget);
    expect(find.text('热门健康圈'), findsOneWidget);
  });
}
