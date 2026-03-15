import 'package:flutter/foundation.dart';

class Command {
  const Command({required this.title, required this.action});

  final String title;
  final VoidCallback action;
}
