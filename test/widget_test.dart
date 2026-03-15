// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:todo_app/main.dart';

void main() {
  testWidgets('Shows layered todo home screen', (WidgetTester tester) async {
    final String hivePath = (await Directory.systemTemp.createTemp()).path;
    Hive.init(hivePath);
    await Hive.openBox('tasks');
    await Hive.openBox('focus_sessions');
    await Hive.openBox('focus_events');
    await Hive.openBox('task_behavior');

    await tester.pumpWidget(const TodoApp());
    await tester.pump();

    expect(find.text('Layered Todo'), findsOneWidget);
    expect(find.text('Focus Timer'), findsOneWidget);

    await Hive.box('tasks').clear();
    await Hive.box('focus_sessions').clear();
    await Hive.box('focus_events').clear();
    await Hive.box('task_behavior').clear();
    await Hive.close();
  });
}
