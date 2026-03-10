import 'dart:async';

class FocusTimerService {
  Timer? _timer;

  bool get isRunning => _timer?.isActive ?? false;

  void start({required void Function() onTick}) {
    stop();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
