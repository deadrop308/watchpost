import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/models/user_model.dart';
import '../core/providers.dart';
import '../core/models/call_model.dart';
import '../core/models/location_model.dart';
import '../features/settings_screen.dart';
import '../features/login/login_screen.dart';
import '../features/worker/worker_dashboard_screen.dart';
import '../features/manager/manager_dashboard_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/worker/open_call_screen.dart';
import '../features/worker/close_call_screen.dart';
import '../features/manager/report_screen.dart';
import '../features/manager/operation_type_management_screen.dart';
import '../features/manager/location_management/add_edit_location_screen.dart';
import '../features/manager/worker_management/worker_management_screen.dart';
import '../features/manager/send_call_screen.dart';
import '../features/manager/location_management/clients_and_locations_screen.dart';
import '../core/models/client_model.dart';
import '../features/manager/add_edit_operation_type_screen.dart';
import '../core/models/operation_type_model.dart';

part 'router.g.dart';

/// Named route paths used throughout the app.
/// Using constants prevents typos when navigating.
class AppRoutePaths {
  static const String login = '/login';
  static const String settings = '/settings';
  static const String workerDashboard = '/worker/dashboard';
  static const String workerOpenCall = '/worker/open-call';
  static const String workerCloseCall = '/worker/close-call';
  static const String managerDashboard = '/manager/dashboard';
  static const String managerActivityLog = '/manager/activity-log';
  static const String managerWorkerManagement = '/manager/workers';
  static const String managerCreateWorker = '/manager/workers/create';
  static const String managerLocationManagement = '/manager/locations';
  static const String managerAddEditLocation = '/manager/locations/edit';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateManager = '/admin/managers/create';
  static const String managerOperationTypeManagement = '/manager/operations';
  static const String managerReport = '/manager/report';
  static const String managerSendCall = '/manager/send-call';
  static const String managerAddEditOperationType = '/manager/operation-types/edit';
}

/// Provides the [GoRouter] instance used for navigation throughout the app.
/// Automatically redirects based on authentication state and user role.
@riverpod
GoRouter appRouter(Ref ref) {
  /// We listen to the authenticated user stream to react to login/logout
  final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

  return GoRouter(
    initialLocation: AppRoutePaths.login,
    /// Redirect logic runs before every navigation event
    redirect: (BuildContext context, GoRouterState routerState) {
      final bool isOnLoginScreen =
          routerState.matchedLocation == AppRoutePaths.login;

      return authenticatedUserAsyncValue.when(
        /// While Firebase is checking auth state, stay on current screen
        loading: () => null,

        /// If there is an auth error, send user to login
        error: (error, stackTrace) => AppRoutePaths.login,

        /// Once we have the auth state, decide where to send the user
        data: (UserModel? currentUser) {
          /// No user logged in — send to login screen
          if (currentUser == null) return AppRoutePaths.login;

          /// User is logged in but on login screen — redirect to their dashboard
          if (isOnLoginScreen) {
            switch (currentUser.role) {
              case UserRole.worker:
                return AppRoutePaths.workerDashboard;
              case UserRole.manager:
                return AppRoutePaths.managerDashboard;
              case UserRole.admin:
                return AppRoutePaths.adminDashboard;
            }
          }

          /// User is logged in and on a valid screen — no redirect needed
          return null;
        },
      );
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.workerDashboard,
        builder: (context, state) => const WorkerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerDashboard,
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.workerOpenCall,
        builder: (context, state) => const OpenCallScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.workerCloseCall,
        builder: (context, state) {
          /// Retrieve the call passed as extra data during navigation
          final CallModel callToClose = state.extra as CallModel;
          return CloseCallScreen(callToClose: callToClose);
        },
      ),
      GoRoute(
        path: AppRoutePaths.managerReport,
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerOperationTypeManagement,
        builder: (context, state) => const OperationTypeManagementScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerLocationManagement,
        builder: (context, state) => const ClientsAndLocationsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerAddEditLocation,
        builder: (context, state) {
          final Map<String, dynamic> arguments =
          state.extra as Map<String, dynamic>;
          return AddEditLocationScreen(
            currentUser: arguments['currentUser'] as UserModel,
            existingLocation: arguments['existingLocation'] as LocationModel?,
            selectedClient: arguments['selectedClient'] as ClientModel?,
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.managerWorkerManagement,
        builder: (context, state) => const WorkerManagementScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerSendCall,
        builder: (context, state) => const SendCallScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.managerAddEditOperationType,
        builder: (context, state) {
          final Map<String, dynamic> arguments =
          state.extra as Map<String, dynamic>;
          return AddEditOperationTypeScreen(
            currentUser: arguments['currentUser'] as UserModel,
            existingOperationType:
            arguments['existingOperationType'] as OperationTypeModel?,
          );
        },
      ),
    ],
  );
}