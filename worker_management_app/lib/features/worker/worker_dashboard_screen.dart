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
import '../diary/diary_screens.dart';

/// The main dashboard screen for worker users.
/// Displays all currently open calls for the logged in worker.
/// Workers can open new calls or tap an existing call for its actions.
/// A drawer switches between Main (open calls) and Diary (machine notes).
class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

    return authenticatedUserAsyncValue.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _WorkerDashboardContent(currentUser: currentUser);
      },
    );
  }
}

/// The sections a worker can switch between from the drawer.
enum _WorkerSection { main, diary }

/// The actual content of the worker dashboard once the user is loaded.
/// Holds which section is shown (Main = open calls, Diary = machine notes).
class _WorkerDashboardContent extends ConsumerStatefulWidget {
  /// The currently logged in worker
  final UserModel currentUser;

  const _WorkerDashboardContent({required this.currentUser});

  @override
  ConsumerState<_WorkerDashboardContent> createState() =>
      _WorkerDashboardContentState();
}

class _WorkerDashboardContentState
    extends ConsumerState<_WorkerDashboardContent> {
  /// The section currently shown in the body
  _WorkerSection _currentSection = _WorkerSection.main;

  /// Stream of open calls for this worker, created once so switching
  /// sections or changing theme/language doesn't resubscribe
  late final Stream<List<CallModel>> _openCallsStream;

  @override
  void initState() {
    super.initState();
    final FirestoreService firestoreService = ref.read(
      firestoreServiceProvider,
    );
    _openCallsStream = firestoreService.streamWorkerActiveCalls(
      widget.currentUser.userId,
    );
  }

  /// Called by the drawer when a section is picked
  void _selectSection(_WorkerSection section) {
    setState(() => _currentSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMain = _currentSection == _WorkerSection.main;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMain
              ? context.l10n.helloUser(widget.currentUser.fullName)
              : context.l10n.diary,
        ),
      ),

      /// Adding a drawer makes Flutter show the hamburger icon automatically
      drawer: _WorkerNavigationDrawer(
        currentUser: widget.currentUser,
        currentSection: _currentSection,
        onSectionSelected: _selectSection,
      ),

      /// Open Call button only belongs to the calls list
      floatingActionButton: isMain
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutePaths.workerOpenCall),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.openCall),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          /// Constrain width to keep mobile-first design even on web
          constraints: const BoxConstraints(maxWidth: 480),
          child: isMain
              ? _OpenCallsList(openCallsStream: _openCallsStream)
              : DiaryBusinessesView(currentUser: widget.currentUser),
        ),
      ),
    );
  }
}

/// Side navigation drawer for workers: Main, Diary and Settings.
class _WorkerNavigationDrawer extends StatelessWidget {
  final UserModel currentUser;
  final _WorkerSection currentSection;
  final ValueChanged<_WorkerSection> onSectionSelected;

  const _WorkerNavigationDrawer({
    required this.currentUser,
    required this.currentSection,
    required this.onSectionSelected,
  });

  /// Closes the drawer, then switches section
  void _pickSection(BuildContext context, _WorkerSection section) {
    Navigator.of(context).pop();
    onSectionSelected(section);
  }

  /// Closes the drawer, then opens Settings.
  /// The router is captured first because the drawer is removed
  /// from the screen as soon as it closes.
  void _openSettings(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutePaths.settings);
  }

  @override
  Widget build(BuildContext context) {
    final String trimmedName = currentUser.fullName.trim();
    final String initial = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : '?';

    /// The drawer header uses the same colors as the AppBar
    /// (type is AppBarThemeData in newer Flutter, `final` avoids naming it)
    final appBarTheme = Theme.of(context).appBarTheme;
    final Color headerBackground =
        appBarTheme.backgroundColor ?? context.colors.primary;
    final Color headerForeground =
        appBarTheme.foregroundColor ?? context.colors.onPrimary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// Header with the worker's name and email
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

          /// Main: the open calls list
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(context.l10n.mainMenu),
            selected: currentSection == _WorkerSection.main,
            onTap: () => _pickSection(context, _WorkerSection.main),
          ),

          /// Diary: technician notes per machine
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(context.l10n.diary),
            selected: currentSection == _WorkerSection.diary,
            onTap: () => _pickSection(context, _WorkerSection.diary),
          ),
          const Divider(),

          /// Settings (language, dark mode, privacy policy, logout)
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(context.l10n.settings),
            onTap: () => _openSettings(context),
          ),
        ],
      ),
    );
  }
}

/// The list of the worker's open calls (the Main section).
class _OpenCallsList extends StatelessWidget {
  final Stream<List<CallModel>> openCallsStream;

  const _OpenCallsList({required this.openCallsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CallModel>>(
      stream: openCallsStream,
      builder: (context, snapshot) {
        /// Spinner only on the very first load. On rebuilds (theme or
        /// language change) the old list stays visible, no flicker.
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

        final List<CallModel> openCalls = snapshot.data ?? [];

        if (openCalls.isEmpty) {
          final Color mutedColor = context.colors.onSurfaceVariant;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: mutedColor),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noOpenCalls,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.tapBelowToOpenCall,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: mutedColor),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          /// Extra bottom padding so the FAB never covers the last card
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: openCalls.length,
          itemBuilder: (context, index) {
            final CallModel currentCall = openCalls[index];
            return _OpenCallCard(call: currentCall);
          },
        );
      },
    );
  }
}

/// A card widget representing a single open call in the worker dashboard list.
/// Tapping the card opens the call popup (navigate / arrived / pause / close).
class _OpenCallCard extends ConsumerWidget {
  final CallModel call;

  const _OpenCallCard({required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color mutedColor = context.colors.onSurfaceVariant;

    /// Show "Client - Location" when the call has a client
    final String locationLabel = call.clientName.isNotEmpty
        ? '${call.clientName} - ${call.locationName}'
        : call.locationName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showCallPopup(
          context: context,
          ref: ref,
          call: call,
          isReadOnly: false,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Operation name + status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      call.operationName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CallStatusBadge(status: call.status),
                ],
              ),
              const SizedBox(height: 8),

              /// Client - Location
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      locationLabel,
                      style: TextStyle(fontSize: 14, color: mutedColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              /// Start time
              Row(
                children: [
                  Icon(Icons.access_time_outlined, size: 16, color: mutedColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${context.l10n.started}: ${_formatDateTime(call.startTime)}',
                      style: TextStyle(fontSize: 14, color: mutedColor),
                    ),
                  ),
                ],
              ),

              /// Small hint that the call came with manager instructions
              if (call.managerInstructions != null &&
                  call.managerInstructions!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        context.l10n.managerInstructionsTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Formats a [DateTime] into a readable string for display.
  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
