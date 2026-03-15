import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data_sources/local_task_source.dart';
import 'data_sources/remote_task_source.dart';
import 'repositories/task_repository.dart';
import 'screens/home_screen.dart';
import 'services/behavior_prediction_service.dart';
import 'services/focus_integrity_service.dart';
import 'services/focus_timer_service.dart';
import 'services/sync_service.dart';
import 'services/task_history_service.dart';
import 'services/task_service.dart';
import 'state/todo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasks');
  await Hive.openBox(TaskHistoryService.boxName);
  await Hive.openBox(FocusIntegrityService.boxName);
  await Hive.openBox(BehaviorPredictionService.boxName);

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocalTaskSource localTaskSource = LocalTaskSource();
    final RemoteTaskSource remoteTaskSource = RemoteTaskSource();
    final SyncService syncService = SyncService(
      localTaskSource: localTaskSource,
      remoteTaskSource: remoteTaskSource,
    );
    final TaskRepository taskRepository = TaskRepositoryImpl(
      localSource: localTaskSource,
      remoteSource: remoteTaskSource,
      syncService: syncService,
    );

    return ChangeNotifierProvider<TodoProvider>(
      create: (_) => TodoProvider(
        taskService: TaskService(taskRepository),
        focusTimerService: FocusTimerService(),
        historyService: TaskHistoryService(),
        focusIntegrityService: FocusIntegrityService(),
        behaviorPredictionService: BehaviorPredictionService(),
      )..loadTasks(),
      child: MaterialApp(
        title: 'Layered Todo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
