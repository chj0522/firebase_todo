import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_todo_list_app/main.dart';

void main() {
  testWidgets('Todo home screen opens add dialog', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Firebase Todo Lists'), findsOneWidget);
    expect(find.byIcon(Icons.add_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_outlined));
    await tester.pump();

    expect(find.text('Todo List'), findsOneWidget);
    expect(find.text('추가할 내용'), findsOneWidget);
  }, skip: true);
}
