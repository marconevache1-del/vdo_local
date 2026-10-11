import 'package:flutter_test/flutter_test.dart';
import 'package:vdo_local_claude/main.dart';

void main() {
  testWidgets('La home mostra i pulsanti Trasmetti e Ricevi', (tester) async {
    await tester.pumpWidget(const VdoLocalApp());
    expect(find.text('TRASMETTI'), findsOneWidget);
    expect(find.text('RICEVI'), findsOneWidget);
  });
}
