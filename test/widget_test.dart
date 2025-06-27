import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notes/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: LocalNotesApp()));

    // Wait for initial frame
    await tester.pump();

    // Should show loading initially or the app content
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Give it a bit more time and check for app content
    await tester.pump(const Duration(seconds: 1));
    
    // Now check if we can find either loading or content
    final hasLocalNotes = find.text('Local Notes');
    final hasLoading = find.byType(CircularProgressIndicator);
    
    expect(hasLocalNotes.evaluate().isNotEmpty || hasLoading.evaluate().isNotEmpty, isTrue);
  });
}