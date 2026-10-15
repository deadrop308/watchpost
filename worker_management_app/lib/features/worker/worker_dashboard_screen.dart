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

/// The main dashboard screen for worker users.
/// Displays all currently open calls for the logged in worker.
/// Workers can open new calls or tap an existing call for its actions.
class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

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
        return _WorkerDashboardContent(currentUser: currentUser);
      },
    );
  }
}

/// The actual content of the worker dashboard once the user is loaded.
class _WorkerDashboardContent extends ConsumerWidget {
  /// The currently logged in worker
  final UserModel currentUser;

  const _WorkerDashboardContent({required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService = ref.read(firestoreServiceProvider);

    /// Stream of open calls for this worker, updates in real time
    final openCallsStream = firestoreService.streamWorkerActiveCalls(
      currentUser.userId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.helloUser(currentUser.fullName)),
        actions: [
          /// Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settings,
            onPressed: () => context.push(AppRoutePaths.settings),
          ),
        ],
      ),

      /// Open Call floating action button — colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutePaths.workerOpenCall),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.openCall),
      ),
      body: Center(
        child: ConstrainedBox(
          /// Constrain width to keep mobile-first design even on web
          constraints: const BoxConstraints(maxWidth: 480),
          child: StreamBuilder<List<CallModel>>(
            stream: openCallsStream,
            builder: (context, snapshot) {
              /// Spinner only on the very first load. On rebuilds (theme or
              /// language change) the old list stays visible — no flicker.
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
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: mutedColor,
                        ),
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
          ),
        ),
      ),
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

    /// Show "Client — Location" when the call has a client
    final String locationLabel = call.clientName.isNotEmpty
        ? '${call.clientName} — ${call.locationName}'
        : call.locationName;

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

              /// Client — Location
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
                  Icon(Icons.access_time_outlined,
                      size: 16, color: mutedColor),
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
                    Icon(Icons.info_outline,
                        size: 16, color: context.colors.primary),
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