import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../core/localization_extension.dart';
import '../../core/models/call_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import 'checklist_section.dart';

/// Picks a readable shade of a status color for light or dark mode.
/// Light mode → darker shade (on a light background),
/// dark mode → lighter shade (on a dark background).
Color _readableShade(BuildContext context, MaterialColor color) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? color.shade300 : color.shade700;
}

/// Shows the call action popup for a given call.
/// Workers and managers use this to navigate, mark arrival,
/// pause/resume, or close a call.
Future<void> showCallPopup({
  required BuildContext context,
  required WidgetRef ref,
  required CallModel call,
  required bool isReadOnly,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _CallPopupContent(
      call: call,
      isReadOnly: isReadOnly,
      parentRef: ref,
    ),
  );
}

/// A small colored pill showing a call's status (Open / Arrived / ...).
/// Public so the dashboards can show the same badge.
class CallStatusBadge extends StatelessWidget {
  final CallStatus status;

  const CallStatusBadge({super.key, required this.status});

  /// The base color for each status
  static MaterialColor colorFor(CallStatus status) {
    switch (status) {
      case CallStatus.open:
        return Colors.blue;
      case CallStatus.arrived:
        return Colors.green;
      case CallStatus.paused:
        return Colors.orange;
      case CallStatus.closed:
        return Colors.grey;
    }
  }

  /// The localized label for each status
  static String labelFor(BuildContext context, CallStatus status) {
    switch (status) {
      case CallStatus.open:
        return context.l10n.statusOpen;
      case CallStatus.arrived:
        return context.l10n.statusArrived;
      case CallStatus.paused:
        return context.l10n.statusPaused;
      case CallStatus.closed:
        return context.l10n.statusClosed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MaterialColor baseColor = colorFor(status);
    final Color textColor = _readableShade(context, baseColor);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor),
      ),
      child: Text(
        labelFor(context, status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// The content of the call popup bottom sheet.
class _CallPopupContent extends ConsumerStatefulWidget {
  final CallModel call;
  final bool isReadOnly;
  final WidgetRef parentRef;

  const _CallPopupContent({
    required this.call,
    required this.isReadOnly,
    required this.parentRef,
  });

  @override
  ConsumerState<_CallPopupContent> createState() => _CallPopupContentState();
}

class _CallPopupContentState extends ConsumerState<_CallPopupContent> {
  /// Whether an action is currently in progress
  bool _isProcessing = false;

  /// Formats a [DateTime] into a readable string for display.
  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Opens navigation to the call location using the device's maps app.
  Future<void> _navigateToLocation() async {
    final String latitude = widget.call.locationLatitude.toString();
    final String longitude = widget.call.locationLongitude.toString();
    final String locationName = Uri.encodeComponent(widget.call.locationName);

    /// Try to open with coordinates if available, otherwise use name search
    final Uri mapsUrl = widget.call.locationLatitude != 0.0
        ? Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude')
        : Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$locationName');

    /// Launch directly — canLaunchUrl() returns false on Android 11+
    /// unless the manifest declares <queries>, which silently broke the button
    try {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      /// No app can open the link — nothing else to do
    }
  }

  /// Marks the worker as arrived at the location.
  Future<void> _markAsArrived() async {
    /// Arrival is recorded only once — never overwrite the first arrival
    if (widget.call.arrivedAt != null) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(firestoreServiceProvider).markCallAsArrived(
        callId: widget.call.callId,
        arrivedAt: DateTime.now(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Pauses or resumes the call depending on current status.
  Future<void> _togglePause() async {
    setState(() => _isProcessing = true);
    try {
      final FirestoreService firestoreService =
      ref.read(firestoreServiceProvider);

      if (widget.call.status == CallStatus.paused) {
        /// Resume — restore previous status
        await firestoreService.resumeCall(
          callId: widget.call.callId,
          previousStatus: widget.call.previousStatus ?? 'open',
        );
      } else {
        /// Pause — store current status
        await firestoreService.pauseCall(
          callId: widget.call.callId,
          currentStatus: callStatusToString(widget.call.status),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Closes the popup and opens the close call screen.
  void _openCloseCallScreen() {
    /// Grab the router before popping — the popup's context goes away
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(AppRoutePaths.workerCloseCall, extra: widget.call);
  }

  /// One "icon + text" row inside the info card.
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final Color rowColor = color ?? context.colors.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 16, color: rowColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: TextStyle(color: rowColor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final CallModel call = widget.call;
    final bool isPaused = call.status == CallStatus.paused;
    final bool isClosed = call.status == CallStatus.closed;

    /// Show "Client — Location" when the call has a client
    final String locationLabel = call.clientName.isNotEmpty
        ? '${call.clientName} — ${call.locationName}'
        : call.locationName;

    /// Height of the phone's own navigation bar (the ⦀ ○ ‹ buttons or the
    /// gesture strip). The sheet is drawn behind it, so without this the
    /// action buttons end up hidden underneath.
    final double systemBottomInset = MediaQuery.viewPaddingOf(context).bottom;

    /// Scrollable so long checklists never overflow on small phones
    return SingleChildScrollView(
      child: Padding(
        /// Top padding is small — the drag handle already adds space
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + systemBottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Title
            Text(
              context.l10n.callDetails,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            /// Call info card
            Card(
              elevation: 0,
              color: context.colors.surfaceContainerHigh,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Operation name
                    Text(
                      call.operationName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    /// Status badge
                    CallStatusBadge(status: call.status),
                    const SizedBox(height: 12),

                    /// Location
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      text: locationLabel,
                    ),
                    const SizedBox(height: 4),

                    /// Start time
                    _buildInfoRow(
                      icon: Icons.access_time_outlined,
                      text:
                      '${context.l10n.started}: ${_formatDateTime(call.startTime)}',
                    ),

                    /// Arrived time if available
                    if (call.arrivedAt != null) ...[
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        icon: Icons.place_outlined,
                        text:
                        '${context.l10n.arrivedAt}: ${_formatDateTime(call.arrivedAt!)}',
                        color: _readableShade(context, Colors.green),
                      ),
                    ],

                    /// End time if closed
                    if (call.endTime != null) ...[
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        icon: Icons.check_circle_outline,
                        text:
                        '${context.l10n.endTimeColumn}: ${_formatDateTime(call.endTime!)}',
                      ),
                    ],

                    /// Manager instructions if this call was assigned by a manager
                    if (call.managerInstructions != null &&
                        call.managerInstructions!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: context.colors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16,
                                    color: context.colors.onPrimaryContainer),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.managerInstructionsTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.onPrimaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              call.managerInstructions!,
                              style: TextStyle(
                                  color: context.colors.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ],

                    /// Notes if closed and has notes
                    if (isClosed &&
                        call.notes != null &&
                        call.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.notes,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        call.notes!,
                        style:
                        TextStyle(color: context.colors.onSurfaceVariant),
                      ),
                    ],

                    /// Checklist results for closed calls (read-only)
                    if (isClosed && call.closeForm.hasChecklist) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${context.l10n.formChecklistSection} '
                            '(${call.closeForm.checkedCount(call.checklistResults)}'
                            '/${call.closeForm.allCheckableItems.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ChecklistSection(
                        elements: call.closeForm.checklistElements,
                        results: call.checklistResults,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Action buttons — only shown for non-read-only and non-closed calls
            if (!widget.isReadOnly && !isClosed) ...[
              Row(
                children: [
                  /// Navigate button
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.navigation_outlined,
                      label: context.l10n.navigate,
                      color: Colors.blue,
                      onTap: _isProcessing ? null : _navigateToLocation,
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// Pause/Resume button
                  Expanded(
                    child: _ActionButton(
                      icon: isPaused
                          ? Icons.play_arrow_outlined
                          : Icons.pause_outlined,
                      label:
                      isPaused ? context.l10n.resume : context.l10n.pause,
                      color: Colors.orange,
                      onTap: _isProcessing ? null : _togglePause,
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// Arrived OR Close Call button — mutually exclusive.
                  /// Disabled while paused (resume first).
                  Expanded(
                    child: call.arrivedAt != null
                        ? _ActionButton(
                      icon: Icons.check_circle_outline,
                      label: context.l10n.closeCall,
                      color: Colors.red,
                      onTap: (_isProcessing || isPaused)
                          ? null
                          : _openCloseCallScreen,
                    )
                        : _ActionButton(
                      icon: Icons.place_outlined,
                      label: context.l10n.arrived,
                      color: Colors.green,
                      onTap: (_isProcessing || isPaused)
                          ? null
                          : _markAsArrived,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single action button in the call popup.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    final Color contentColor = isEnabled
        ? _readableShade(context, color)
        : context.colors.onSurface.withValues(alpha: 0.38);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isEnabled
              ? color.withValues(alpha: 0.1)
              : context.colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: contentColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: contentColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: contentColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}