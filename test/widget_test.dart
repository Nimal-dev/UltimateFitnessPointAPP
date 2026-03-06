import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_gym_app/main.dart';
import 'package:provider/provider.dart';
import 'package:ultimate_gym_app/providers/auth_provider.dart';
import 'package:ultimate_gym_app/providers/member_provider.dart';
import 'package:ultimate_gym_app/providers/diet_provider.dart';
import 'package:ultimate_gym_app/providers/owner_provider.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => MemberProvider()),
          ChangeNotifierProvider(create: (_) => DietProvider()),
          ChangeNotifierProvider(create: (_) => OwnerProvider()),
        ],
        child: const UltimateGymApp(),
      ),
    );
    expect(find.byType(UltimateGymApp), findsOneWidget);
  });
}
