import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'data_sources/local_task_source.dart';
import 'data_sources/remote_task_source.dart';
import 'repositories/task_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/behavior_prediction_service.dart';
import 'services/error_service.dart';
import 'services/focus_integrity_service.dart';
import 'services/focus_room_service.dart';
import 'services/focus_timer_service.dart';
import 'services/productivity_coach_service.dart';
import 'services/sync_service.dart';
import 'services/task_history_service.dart';
import 'services/task_service.dart';
import 'services/schedule_planner_service.dart';
import 'state/analytics_provider.dart';
import 'state/focus_provider.dart';
import 'state/focus_rooms_provider.dart';
import 'state/planner_provider.dart';
import 'state/productivity_coach_provider.dart';
import 'state/task_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('tasks')) {
    await Hive.openBox<Map>('tasks');
  }

  if (!Hive.isBoxOpen(TaskHistoryService.boxName)) {
    await Hive.openBox<Map>(TaskHistoryService.boxName);
  }

  if (!Hive.isBoxOpen(FocusIntegrityService.boxName)) {
    await Hive.openBox<Map>(FocusIntegrityService.boxName);
  }

  if (!Hive.isBoxOpen(BehaviorPredictionService.boxName)) {
    await Hive.openBox<Map>(BehaviorPredictionService.boxName);
  }

  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: ErrorService.instance.scaffoldMessengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.data == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: ErrorService.instance.scaffoldMessengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: LoginScreen(authService: _authService),
          );
        }

        return TodoApp(authService: _authService);
      },
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({
    super.key,
    this.enableBackgroundMonitors = true,
    this.authService,
  });

  final bool enableBackgroundMonitors;
  final AuthService? authService;

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late final SyncService _syncService;
  late final TaskProvider _taskProvider;
  late final PlannerProvider _plannerProvider;
  late final AnalyticsProvider _analyticsProvider;
  late final FocusProvider _focusProvider;
  late final FocusRoomService _focusRoomService;
  late final FocusRoomsProvider _focusRoomsProvider;
  late final ProductivityCoachProvider _productivityCoachProvider;

  @override
  void initState() {
    super.initState();

    final AuthService authService = widget.authService ?? AuthService();

    final LocalTaskSource localTaskSource = LocalTaskSource();
    final RemoteTaskSource remoteTaskSource = RemoteTaskSource();
    _syncService = SyncService(
      localTaskSource: localTaskSource,
      remoteTaskSource: remoteTaskSource,
      authService: authService,
    );
    final TaskRepository taskRepository = TaskRepositoryImpl(
      localSource: localTaskSource,
      remoteSource: remoteTaskSource,
      syncService: _syncService,
      authService: authService,
    );

    final TaskHistoryService historyService = TaskHistoryService();
    final BehaviorPredictionService behaviorPredictionService =
        BehaviorPredictionService();
    final SchedulePlannerService plannerService = SchedulePlannerService(
      historyService: historyService,
      behaviorPredictionService: behaviorPredictionService,
    );

    _taskProvider = TaskProvider(
      taskService: TaskService(taskRepository),
      enableSyncMonitor: widget.enableBackgroundMonitors,
    );
    _plannerProvider = PlannerProvider(
      taskProvider: _taskProvider,
      plannerService: plannerService,
      enableDriftMonitor: widget.enableBackgroundMonitors,
    );
    _analyticsProvider = AnalyticsProvider(
      focusIntegrityService: FocusIntegrityService(),
      behaviorPredictionService: behaviorPredictionService,
    );
    _focusProvider = FocusProvider(
      focusTimerService: FocusTimerService(),
      historyService: historyService,
      taskProvider: _taskProvider,
      plannerProvider: _plannerProvider,
      analyticsProvider: _analyticsProvider,
    );
    _focusRoomService = FocusRoomService();
    _focusRoomsProvider = FocusRoomsProvider(
      focusRoomService: _focusRoomService,
    );
    _productivityCoachProvider = ProductivityCoachProvider(
      coachService: ProductivityCoachService(historyService: historyService),
      analyticsProvider: _analyticsProvider,
      taskProvider: _taskProvider,
    );

    _taskProvider.attachDependencies(
      plannerProvider: _plannerProvider,
      analyticsProvider: _analyticsProvider,
    );

    unawaited(_plannerProvider.initialize());
    unawaited(_taskProvider.loadTasks());
  }

  @override
  void dispose() {
    _productivityCoachProvider.dispose();
    _focusRoomsProvider.dispose();
    _focusRoomService.dispose();
    _focusProvider.dispose();
    _analyticsProvider.dispose();
    _plannerProvider.dispose();
    _taskProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TaskProvider>.value(value: _taskProvider),
        ChangeNotifierProvider<PlannerProvider>.value(value: _plannerProvider),
        ChangeNotifierProvider<AnalyticsProvider>.value(
          value: _analyticsProvider,
        ),
        ChangeNotifierProvider<FocusProvider>.value(value: _focusProvider),
        ChangeNotifierProvider<FocusRoomsProvider>.value(
          value: _focusRoomsProvider,
        ),
        ChangeNotifierProvider<ProductivityCoachProvider>.value(
          value: _productivityCoachProvider,
        ),
      ],
      child: MaterialApp(
        title: 'Layered Todo',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: ErrorService.instance.scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: HomeScreen(syncService: _syncService),
      ),
    );
  }
}
