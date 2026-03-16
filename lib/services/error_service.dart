import 'package:flutter/material.dart';

class ErrorService {
  ErrorService._();

  static final ErrorService instance = ErrorService._();

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  String? _lastFriendlyMessage;

  String? get lastFriendlyMessage => _lastFriendlyMessage;

  void logException(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    debugPrint('[$context] $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  void showFriendlyError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _lastFriendlyMessage = message;
    final ScaffoldMessengerState? messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  String getFriendlyMessage({
    required String operation,
    bool isNetworkRelated = false,
  }) {
    if (isNetworkRelated) {
      return 'Unable to $operation right now. Check your connection and try again.';
    }
    return 'Something went wrong while trying to $operation. Please try again.';
  }

  void handleException(
    Object error,
    StackTrace stackTrace, {
    required String context,
    required String operation,
    bool isNetworkRelated = false,
    bool showToUser = true,
  }) {
    logException(error, stackTrace, context: context);
    if (!showToUser) {
      return;
    }
    showFriendlyError(
      getFriendlyMessage(
        operation: operation,
        isNetworkRelated: isNetworkRelated,
      ),
    );
  }
}
