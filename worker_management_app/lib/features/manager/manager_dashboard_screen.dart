import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../core/models/call_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import '../../core/localization_extension.dart';
import '../shared/call_popup.dart';

/// Screen width from which the web layout (top bar + table) is used.
/// Below this the AppBar can't fit all 6 buttons, so the mobile layout
/// (drawer + cards) is used instead.
const double _webLayoutMinWidth = 1100;

/// Formats a [DateTime] as dd/MM/yyyy HH:mm.
String _formatDateTime(DateTime dateTime) {
  final String day = dateTime.day.toString().padLeft(2, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String year = dateTime.year.toString();
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

/// The main dashboard screen for manager users.
/// Displays a live table of all calls for today in the manager's branch.
/// Automatically switches between mobile and web layouts based on screen width.
class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

    return authenticatedUserAsyncValue.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _ManagerDashboardContent(currentUser: currentUser);
      },
    );
  }
}

/// The actual content of the manager dashboard once the user is loaded.
/// Uses [LayoutBuilder] to switch between mobile and web layouts.
class _ManagerDashboardContent extends ConsumerWidget {
  /// The currently logged in manager
  final UserModel currentUser;

  const _ManagerDashboardContent({required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWebLayout = constraints.maxWidth >= _webLayoutMinWidth;

        if (isWebLayout) {
          return _ManagerDashboardWebLayout(currentUser: currentUser);
        } else {
          return _ManagerDashboardMobileLayout(currentUser: currentUser);
        }
      },
    );
  }
}

/// Shared builder for the live calls stream: spinner on first load,
/// error text, empty text, or the given content.
Widget _buildCallsStream({
  required BuildContext context,
  required Stream<List<CallModel>> stream,
  required Widget Function(List<CallModel> calls) builder,
}) {
  return StreamBuilder<List<CallModel>>(
    stream: stream,
    builder: (context, snapshot) {
      /// Spinner only on the very first load — rebuilds (theme/language
      /// change, window resize) keep showing the last data, no flicker
      if (!snapshot.hasData && !snapshot.hasError) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${context.l10n.errorLoadingCalls}: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }

      final List<CallModel> todayCalls = snapshot.data ?? [];

      if (todayCalls.isEmpty) {
        return Center(
          child: Text(
            context.l10n.noCallsRecordedToday,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        );
      }

      return builder(todayCalls);
    },
  );
}

// ─────────────────────────────────────────────
// WEB LAYOUT
// ─────────────────────────────────────────────

/// The web layout for the manager dashboard.
/// Shows a full navigation bar and an excel-like call table.
class _ManagerDashboardWebLayout extends ConsumerWidget {
  final UserModel currentUser;

  const _ManagerDashboardWebLayout({required this.currentUser});

  /// One text+icon button in the AppBar, colored like the AppBar text.
  Widget _appBarButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routePath,
  }) {
    final Color headerForeground =
        Theme.of(context).appBarTheme.foregroundColor ??
            context.colors.onSurface;

    return TextButton.icon(
      onPressed: () => context.push(routePath),
      style: TextButton.styleFrom(foregroundColor: headerForeground),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.welcomeUser(currentUser.fullName)),
        actions: [
          /// Workers management
          _appBarButton(
            context: context,
            icon: Icons.people_outline,
            label: context.l10n.worker,
            routePath: AppRoutePaths.managerWorkerManagement,
          ),
          /// Operation types management
          _appBarButton(
            context: context,
            icon: Icons.work_outline,
            label: context.l10n.operations,
            routePath: AppRoutePaths.managerOperationTypeManagement,
          ),
          /// Clients & Locations management
          _appBarButton(
            context: context,
            icon: Icons.location_on_outlined,
            label: context.l10n.clientsAndLocations,
            routePath: AppRoutePaths.managerLocationManagement,
          ),
          /// Report
          _appBarButton(
            context: context,
            icon: Icons.bar_chart_outlined,
            label: context.l10n.report,
            routePath: AppRoutePaths.managerReport,
          ),
          /// Open call — for when the manager goes to the field
          _appBarButton(
            context: context,
            icon: Icons.add_circle_outline,
            label: context.l10n.openCall,
            routePath: AppRoutePaths.workerOpenCall,
          ),
          /// Send call — assign a call to a specific worker
          _appBarButton(
            context: context,
            icon: Icons.send_outlined,
            label: context.l10n.sendCall,
            routePath: AppRoutePaths.managerSendCall,
          ),
          /// Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settings,
            onPressed: () => context.push(AppRoutePaths.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Dashboard title showing today's date
            Row(
              children: [
                Text(
                  context.l10n.todaysActivity,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(DateTime.now()),
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// Live call table
            Expanded(
              child: _buildCallsStream(
                context: context,
                stream: firestoreService.streamBranchDashboardCalls(
                  currentUser.branchId,
                ),
                builder: (calls) => _CallsTable(calls: calls),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a [DateTime] into a readable date string for the dashboard title.
  String _formatDate(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$day/$month/$year';
  }
}

// ─────────────────────────────────────────────
// MOBILE LAYOUT
// ─────────────────────────────────────────────

/// The mobile layout for the manager dashboard.
/// Shows a compact list of today's calls, with a navigation drawer
/// (hamburger menu) giving access to all manager screens.
class _ManagerDashboardMobileLayout extends ConsumerWidget {
  final UserModel currentUser;

  const _ManagerDashboardMobileLayout({required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    return Scaffold(
      /// Adding a drawer makes Flutter show the hamburger icon automatically.
      /// In Hebrew (RTL) it opens from the right side automatically.
      drawer: _ManagerNavigationDrawer(currentUser: currentUser),
      appBar: AppBar(
        title: Text(context.l10n.welcomeUser(currentUser.fullName)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settings,
            onPressed: () => context.push(AppRoutePaths.settings),
          ),
        ],
      ),
      /// Colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutePaths.workerOpenCall),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.openCall),
      ),
      body: Center(
        child: ConstrainedBox(
          /// Keeps cards readable on tablets / narrow browser windows
          constraints: const BoxConstraints(maxWidth: 700),
          child: _buildCallsStream(
            context: context,
            stream: firestoreService.streamBranchDashboardCalls(
              currentUser.branchId,
            ),
            builder: (calls) => ListView.builder(
              /// Extra bottom padding so the last card isn't hidden by the FAB
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: calls.length,
              itemBuilder: (context, index) =>
                  _MobileCallCard(call: calls[index]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Side navigation drawer for managers on mobile.
/// Mirrors the navigation buttons from the web AppBar.
class _ManagerNavigationDrawer extends StatelessWidget {
  final UserModel currentUser;

  const _ManagerNavigationDrawer({required this.currentUser});

  /// Closes the drawer, then opens the given route.
  /// The router is captured first because the drawer is removed
  /// from the screen as soon as it closes.
  void _navigateTo(BuildContext context, String routePath) {
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(routePath);
  }

  @override
  Widget build(BuildContext context) {
    final String trimmedName = currentUser.fullName.trim();
    final String initial =
    trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';

    /// The drawer header uses the same colors as the AppBar
    /// (type is AppBarThemeData in newer Flutter — `final` avoids naming it)
    final appBarTheme = Theme.of(context).appBarTheme;
    final Color headerBackground =
        appBarTheme.backgroundColor ?? context.colors.primary;
    final Color headerForeground =
        appBarTheme.foregroundColor ?? context.colors.onPrimary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// Header with the manager's name and email
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: headerBackground),
            accountName: Text(
              currentUser.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: headerForeground,
              ),
            ),
            accountEmail: Text(
              currentUser.emailAddress,
              style: TextStyle(color: headerForeground),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
          ),

          /// Call actions
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(context.l10n.openCall),
            onTap: () => _navigateTo(context, AppRoutePaths.workerOpenCall),
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: Text(context.l10n.sendCall),
            onTap: () => _navigateTo(context, AppRoutePaths.managerSendCall),
          ),
          const Divider(),

          /// Management screens
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(context.l10n.worker),
            onTap: () =>
                _navigateTo(context, AppRoutePaths.managerWorkerManagement),
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: Text(context.l10n.operations),
            onTap: () => _navigateTo(
                context, AppRoutePaths.managerOperationTypeManagement),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(context.l10n.clientsAndLocations),
            onTap: () =>
                _navigateTo(context, AppRoutePaths.managerLocationManagement),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: Text(context.l10n.report),
            onTap: () => _navigateTo(context, AppRoutePaths.managerReport),
          ),
          const Divider(),

          /// Settings (language, dark mode, logout)
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(context.l10n.settings),
            onTap: () => _navigateTo(context, AppRoutePaths.settings),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────

/// An excel-like table displaying all calls for today.
/// Used in the web layout. Heading colors come from the theme.
class _CallsTable extends ConsumerWidget {
  final List<CallModel> calls;

  const _CallsTable({required this.calls});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        /// Same color as cards: white in light mode, dark grey in dark
        color: Theme.of(context).cardTheme.color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 24,
              columns: [
                DataColumn(label: Text(context.l10n.worker)),
                DataColumn(label: Text(context.l10n.operation)),
                DataColumn(label: Text(context.l10n.client)),
                DataColumn(label: Text(context.l10n.location)),
                DataColumn(label: Text(context.l10n.status)),
                DataColumn(label: Text(context.l10n.startTimeColumn)),
                DataColumn(label: Text(context.l10n.endTimeColumn)),
              ],
              rows: calls.map((call) {
                return DataRow(
                  onSelectChanged: (_) => showCallPopup(
                    context: context,
                    ref: ref,
                    call: call,
                    isReadOnly: call.status == CallStatus.closed,
                  ),
                  cells: [
                    DataCell(Text(call.workerFullName)),
                    DataCell(Text(call.operationName)),
                    DataCell(Text(
                        call.clientName.isNotEmpty ? call.clientName : '—')),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          call.locationName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(CallStatusBadge(status: call.status)),
                    DataCell(Text(_formatDateTime(call.startTime))),
                    DataCell(Text(
                      call.endTime != null
                          ? _formatDateTime(call.endTime!)
                          : '—',
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact card widget for displaying a single call in the mobile layout.
class _MobileCallCard extends ConsumerWidget {
  final CallModel call;

  const _MobileCallCard({required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color mutedColor = context.colors.onSurfaceVariant;
    final TextStyle mutedStyle = TextStyle(fontSize: 13, color: mutedColor);

    /// Show "Client — Location" when the call has a client
    final String locationLabel = call.clientName.isNotEmpty
        ? '${call.clientName} — ${call.locationName}'
        : call.locationName;

    /// "start → end" once the call has ended
    final String timeLabel = call.endTime != null
        ? '${_formatDateTime(call.startTime)} → ${_formatDateTime(call.endTime!)}'
        : _formatDateTime(call.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showCallPopup(
          context: context,
          ref: ref,
          call: call,
          isReadOnly: call.status == CallStatus.closed,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      call.operationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CallStatusBadge(status: call.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      call.workerFullName,
                      overflow: TextOverflow.ellipsis,
                      style: mutedStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationLabel,
                      overflow: TextOverflow.ellipsis,
                      style: mutedStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 14, color: mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(timeLabel, style: mutedStyle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}