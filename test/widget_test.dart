import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('VoiceChat smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VoiceChatApp());

    // Verifica il titolo corretto (aggiornato a "TalkInZone")
    expect(find.text('TalkInZone'), findsOneWidget);

    // Verify that we have a microphone button
    expect(find.byIcon(Icons.mic), findsOneWidget);

    // Verify that we show the "no messages" text initially
    expect(
      find.text('Nessun messaggio vocale nelle vicinanze'),
      findsOneWidget,
    );
  });
}
