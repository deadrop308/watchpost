import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/app_theme.dart';
import '../../core/localization_extension.dart';
import '../../core/models/call_model.dart';
import '../../core/models/client_model.dart';
import '../../core/models/location_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import '../shared/call_popup.dart';
import 'report_csv_stub.dart'
if (dart.library.html) 'report_csv_web.dart';

/// The report screen for manager users.
/// Shows a monthly breakdown of calls with advanced filtering options.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

/// Short checklist summary for a table cell, e.g. "3/5".
/// Returns null when the call has no checklist or isn't closed yet.
String? _checklistCount(CallModel call) {
  if (!call.closeForm.hasChecklist || call.status != CallStatus.closed) {
    return null;
  }
  final int total = call.closeForm.allCheckableItems.length;
  final int checked = call.closeForm.checkedCount(call.checklistResults);
  return '$checked/$total';
}

/// Full checklist results as text, for tooltips and the CSV.
/// Returns an empty string when there's nothing to show.
String _checklistDescription(CallModel call) {
  if (!call.closeForm.hasChecklist || call.status != CallStatus.closed) {
    return '';
  }
  return call.closeForm.describeResults(call.checklistResults);
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  /// The currently selected month for filtering
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Whether we are in year export mode
  bool _isYearMode = false;

  /// Whether a CSV export is in progress
  bool _isExporting = false;

  /// Active filters
  ClientModel? _selectedClient;
  LocationModel? _selectedLocation;
  UserModel? _selectedEmployee;

  // ─── Cached Firestore fetches ───────────────────────────────
  // Before, every setState (every filter change!) re-ran ALL the
  // fetches — the whole month of calls was downloaded again, and the
  // dropdowns briefly had no items, which could crash them.
  // Now each fetch runs once and only re-runs when its input changes.

  /// The branch the cached fetches belong to
  String? _cachedBranchId;
  Future<List<ClientModel>>? _clientsFuture;
  Future<List<UserModel>>? _membersFuture;

  /// Locations — re-fetched only when the selected client changes
  Future<List<LocationModel>>? _locationsFuture;
  String? _cachedLocationsClientId;

  /// The month's calls — re-fetched only when the month changes
  Future<List<CallModel>>? _monthCallsFuture;
  DateTime? _cachedCallsMonth;

  /// Creates (or reuses) the cached fetches for the current selections.
  void _prepareFetches(String branchId, FirestoreService firestoreService) {
    if (_cachedBranchId != branchId) {
      _cachedBranchId = branchId;
      _clientsFuture = firestoreService.fetchAllActiveClientsByBranch(branchId);
      _membersFuture = firestoreService.fetchAllBranchMembers(branchId);
      _locationsFuture = null;
      _monthCallsFuture = null;
    }

    final String? clientId = _selectedClient?.clientId;
    if (_locationsFuture == null || _cachedLocationsClientId != clientId) {
      _cachedLocationsClientId = clientId;
      _locationsFuture = clientId != null
          ? firestoreService.fetchActiveLocationsByClient(
        branchId: branchId,
        clientId: clientId,
      )
          : firestoreService.fetchAllActiveLocationsByBranch(branchId);
    }

    if (_monthCallsFuture == null || _cachedCallsMonth != _selectedMonth) {
      _cachedCallsMonth = _selectedMonth;
      _monthCallsFuture = firestoreService.fetchBranchCallsByMonth(
        branchId: branchId,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
    }
  }

  /// Formats a [DateTime] into a readable month/year string.
  String _formatMonth(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$month/$year';
  }

  /// Formats a [DateTime] into a readable date/time string.
  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Calculates the duration of a call in hours as a decimal.
  double? _calculateDurationInHours(CallModel call) {
    if (call.endTime == null) return null;
    final int totalMinutes =
        call.endTime!.difference(call.startTime).inMinutes;
    return double.parse((totalMinutes / 60).toStringAsFixed(1));
  }

  /// Wraps a value as a CSV cell. Quotes inside the text are doubled,
  /// so notes like 'replaced "main" belt' don't break the file.
  String _csvCell(Object? value) {
    final String text = (value ?? '').toString().replaceAll('"', '""');
    return '"$text"';
  }

  /// Short month name in the app's language ("Jan" / "ינו׳").
  String _monthName(int month) {
    final String languageCode = Localizations.localeOf(context).languageCode;
    return DateFormat.MMM(languageCode).format(DateTime(2000, month));
  }

  /// Opens the custom month picker dialog.
  Future<void> _pickMonth() async {
    int selectedYear = _selectedMonth.year;
    int selectedMonthIndex = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.selectMonth),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setDialogState(() => selectedYear--),
                    ),
                    Text(
                      '$selectedYear',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: selectedYear >= DateTime.now().year
                          ? null
                          : () => setDialogState(() => selectedYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final int monthNumber = index + 1;
                    final bool isSelected = monthNumber == selectedMonthIndex;
                    final bool isFuture = DateTime(selectedYear, monthNumber)
                        .isAfter(DateTime.now());

                    final Color tileColor = isSelected
                        ? context.colors.primary
                        : isFuture
                        ? context.colors.surfaceContainerLow
                        : context.colors.surfaceContainerHighest;
                    final Color textColor = isSelected
                        ? context.colors.onPrimary
                        : isFuture
                        ? context.colors.onSurface.withValues(alpha: 0.38)
                        : context.colors.onSurface;

                    return InkWell(
                      onTap: isFuture
                          ? null
                          : () => setDialogState(
                              () => selectedMonthIndex = monthNumber),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: tileColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _monthName(monthNumber),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                DateTime pickedMonth =
                DateTime(selectedYear, selectedMonthIndex);

                /// e.g. Dec picked, then year switched to this year →
                /// a future month. Fall back to the current month.
                final DateTime now = DateTime.now();
                if (pickedMonth.isAfter(now)) {
                  pickedMonth = DateTime(now.year, now.month);
                }

                setState(() {
                  _selectedMonth = pickedMonth;
                  _isYearMode = false;
                });
                Navigator.of(dialogContext).pop();
              },
              /// Colors come from the theme
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies client-side filters to the call list.
  List<CallModel> _applyFilters(List<CallModel> calls) {
    return calls.where((call) {
      if (_selectedClient != null &&
          call.clientId != _selectedClient!.clientId) {
        return false;
      }
      if (_selectedLocation != null) {
        /// Match the name AND the client — two clients can both have
        /// a location called e.g. "Main office"
        if (call.locationName != _selectedLocation!.locationName) {
          return false;
        }
        if (_selectedLocation!.clientId.isNotEmpty &&
            call.clientId != _selectedLocation!.clientId) {
          return false;
        }
      }
      if (_selectedEmployee != null &&
          call.workerUserId != _selectedEmployee!.userId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Clears all active filters.
  void _clearFilters() {
    setState(() {
      _selectedClient = null;
      _selectedLocation = null;
      _selectedEmployee = null;
    });
  }

  bool get _hasActiveFilters =>
      _selectedClient != null ||
          _selectedLocation != null ||
          _selectedEmployee != null;

  /// Generates a CSV and triggers download.
  void _exportToCsv(List<CallModel> calls) {
    setState(() => _isExporting = true);

    try {
      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln([
        'Worker',
        'Operation',
        'Client',
        'Location',
        'Status',
        'Start Time',
        'End Time',
        'Duration',
        'Notes',
        'Checklist',
      ].map(_csvCell).join(','));

      for (final CallModel call in calls) {
        final double? durationInHours = _calculateDurationInHours(call);
        csvBuffer.writeln([
          call.workerFullName,
          call.operationName,
          call.clientName,
          call.locationName,
          callStatusToString(call.status),
          _formatDateTime(call.startTime),
          call.endTime != null ? _formatDateTime(call.endTime!) : '',
          durationInHours ?? '',
          call.notes ?? '',
          _checklistDescription(call),
        ].map(_csvCell).join(','));
      }

      if (kIsWeb) {
        final String label = _isYearMode
            ? '${_selectedMonth.year}'
            : _formatMonth(_selectedMonth);
        downloadCsvOnWeb(csvBuffer.toString(), label);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Exports the entire year as CSV.
  Future<void> _exportYearToCsv(
      String branchId, FirestoreService firestoreService) async {
    setState(() => _isExporting = true);

    try {
      /// Fetch all months of the selected year up to now
      final List<CallModel> allYearCalls = [];
      for (int month = 1; month <= 12; month++) {
        if (DateTime(_selectedMonth.year, month).isAfter(DateTime.now())) {
          break;
        }
        final List<CallModel> monthCalls =
        await firestoreService.fetchBranchCallsByMonth(
          branchId: branchId,
          year: _selectedMonth.year,
          month: month,
        );
        allYearCalls.addAll(monthCalls);
      }

      if (!mounted) return;
      _exportToCsv(_applyFilters(allYearCalls));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUserAsyncValue = ref.watch(authenticatedUserProvider);

    return authenticatedUserAsyncValue.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (UserModel? currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        return _buildScreen(currentUser);
      },
    );
  }

  /// The green "Export CSV" button (green on purpose, in both themes).
  Widget _buildExportButton(VoidCallback? onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      icon: _isExporting
          ? SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          color: context.colors.onSurfaceVariant,
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.download_outlined),
      label: Text(context.l10n.exportCsv),
    );
  }

  Widget _buildScreen(UserModel currentUser) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);
    _prepareFetches(currentUser.branchId, firestoreService);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reportScreen),
      ),
      body: Column(
        children: [
          /// Filter bar
          Container(
            /// Same color as cards: white in light mode, dark grey in dark
            color: Theme.of(context).cardTheme.color ?? context.colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                /// View mode + month picker row
                Row(
                  children: [
                    _ViewModeButton(
                      label: context.l10n.monthView,
                      isSelected: !_isYearMode,
                      onTap: () => setState(() => _isYearMode = false),
                    ),
                    const SizedBox(width: 8),
                    _ViewModeButton(
                      label: context.l10n.yearView,
                      isSelected: _isYearMode,
                      onTap: () => setState(() => _isYearMode = true),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickMonth,
                      icon:
                      const Icon(Icons.calendar_month_outlined, size: 16),
                      label: Text(_isYearMode
                          ? '${_selectedMonth.year}'
                          : _formatMonth(_selectedMonth)),
                    ),
                    const Spacer(),

                    /// Year export button (month export lives in the table)
                    if (_isYearMode)
                      _buildExportButton(
                        _isExporting
                            ? null
                            : () => _exportYearToCsv(
                            currentUser.branchId, firestoreService),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                /// Filter dropdowns row
                Row(
                  children: [
                    /// Client filter
                    Expanded(
                      child: FutureBuilder<List<ClientModel>>(
                        future: _clientsFuture,
                        builder: (context, snapshot) {
                          return _FilterDropdown<ClientModel>(
                            label: context.l10n.filterByClient,
                            hint: context.l10n.allClients,
                            value: _selectedClient,
                            items: snapshot.data ?? [],
                            itemLabel: (c) => c.clientName,
                            onChanged: (client) => setState(() {
                              _selectedClient = client;
                              _selectedLocation = null;
                            }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    /// Location filter — fresh for each client (key)
                    Expanded(
                      child: FutureBuilder<List<LocationModel>>(
                        key: ValueKey(_selectedClient?.clientId),
                        future: _locationsFuture,
                        builder: (context, snapshot) {
                          return _FilterDropdown<LocationModel>(
                            label: context.l10n.filterByLocation,
                            hint: context.l10n.allLocations,
                            value: _selectedLocation,
                            items: snapshot.data ?? [],
                            /// With no client chosen, show "Client — Location"
                            /// so same-named locations can be told apart
                            itemLabel: (l) =>
                            _selectedClient == null && l.clientName.isNotEmpty
                                ? '${l.clientName} — ${l.locationName}'
                                : l.locationName,
                            onChanged: (location) =>
                                setState(() => _selectedLocation = location),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    /// Employee filter
                    Expanded(
                      child: FutureBuilder<List<UserModel>>(
                        future: _membersFuture,
                        builder: (context, snapshot) {
                          return _FilterDropdown<UserModel>(
                            label: context.l10n.filterByEmployee,
                            hint: context.l10n.allEmployees,
                            value: _selectedEmployee,
                            items: snapshot.data ?? [],
                            itemLabel: (u) => u.fullName,
                            onChanged: (user) =>
                                setState(() => _selectedEmployee = user),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    /// Clear filters button
                    if (_hasActiveFilters)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text(context.l10n.clearFilters),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.error,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          /// Calls table
          Expanded(
            child: _isYearMode
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_download_outlined,
                        size: 64,
                        color: context.colors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.yearExportHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : _MonthlyCallsTable(
              callsFuture: _monthCallsFuture!,
              applyFilters: _applyFilters,
              exportButtonBuilder: (filteredCalls) => _buildExportButton(
                _isExporting ? null : () => _exportToCsv(filteredCalls),
              ),
              formatDateTime: _formatDateTime,
              calculateDurationInHours: _calculateDurationInHours,
            ),
          ),
        ],
      ),
    );
  }
}

/// A toggle button for switching between Month and Year view modes.
class _ViewModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? context.colors.onPrimary
                : context.colors.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// A generic filter dropdown widget. The first item ("All ...") means no filter.
class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    /// Guard: while items are still loading (or the item was deleted),
    /// the value isn't in the list — show "All" instead of crashing
    final T? safeValue = value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text(hint, style: const TextStyle(fontSize: 13)),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text(hint, style: const TextStyle(fontSize: 13)),
        ),
        ...items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        )),
      ],
      onChanged: onChanged,
    );
  }
}

/// The monthly calls table with export button.
class _MonthlyCallsTable extends StatelessWidget {
  /// The month's calls (cached by the parent — fetched once per month)
  final Future<List<CallModel>> callsFuture;
  final List<CallModel> Function(List<CallModel>) applyFilters;
  final Widget Function(List<CallModel> filteredCalls) exportButtonBuilder;
  final String Function(DateTime) formatDateTime;
  final double? Function(CallModel) calculateDurationInHours;

  const _MonthlyCallsTable({
    required this.callsFuture,
    required this.applyFilters,
    required this.exportButtonBuilder,
    required this.formatDateTime,
    required this.calculateDurationInHours,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CallModel>>(
      future: callsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('${context.l10n.errorLoadingCalls}: ${snapshot.error}'),
          );
        }

        final List<CallModel> filteredCalls =
        applyFilters(snapshot.data ?? []);

        if (filteredCalls.isEmpty) {
          return Center(
            child: Text(
              context.l10n.noCallsForPeriod,
              style: TextStyle(
                fontSize: 16,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          children: [
            /// Summary and export row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredCalls.length} ${context.l10n.allCalls}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  exportButtonBuilder(filteredCalls),
                ],
              ),
            ),

            /// Table — heading colors come from the theme.
            /// Scrolls sideways too, so 10 columns never overflow.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    /// At least full width, so the table still fills
                    /// wide screens like before
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth - 32,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        columnSpacing: 16,
                        columns: [
                          DataColumn(label: Text(context.l10n.worker)),
                          DataColumn(label: Text(context.l10n.operation)),
                          DataColumn(label: Text(context.l10n.client)),
                          DataColumn(label: Text(context.l10n.location)),
                          DataColumn(label: Text(context.l10n.status)),
                          DataColumn(label: Text(context.l10n.startTimeColumn)),
                          DataColumn(label: Text(context.l10n.endTimeColumn)),
                          DataColumn(label: Text(context.l10n.duration)),
                          DataColumn(
                              label: Text(context.l10n.formChecklistSection)),
                          DataColumn(label: Text(context.l10n.notes)),
                        ],
                        rows: filteredCalls.map((call) {
                          final double? durationInHours =
                          calculateDurationInHours(call);
                          final String? checklistCount = _checklistCount(call);

                          return DataRow(
                            cells: [
                              DataCell(Text(call.workerFullName)),
                              DataCell(Text(call.operationName)),
                              DataCell(Text(call.clientName.isNotEmpty
                                  ? call.clientName
                                  : '—')),
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    call.locationName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(CallStatusBadge(status: call.status)),
                              DataCell(Text(formatDateTime(call.startTime))),
                              DataCell(Text(
                                call.endTime != null
                                    ? formatDateTime(call.endTime!)
                                    : '—',
                              )),
                              DataCell(Text(
                                durationInHours != null ? '$durationInHours' : '—',
                              )),

                              /// "3/5" — hover to see exactly what was checked
                              DataCell(
                                checklistCount == null
                                    ? const Text('—')
                                    : Tooltip(
                                  message: _checklistDescription(call),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.checklist,
                                          size: 16,
                                          color: context.colors.primary),
                                      const SizedBox(width: 4),
                                      Text(checklistCount),
                                    ],
                                  ),
                                ),
                              ),

                              /// Long notes are cut — hover to read them all
                              DataCell(
                                call.notes == null || call.notes!.isEmpty
                                    ? const Text('—')
                                    : Tooltip(
                                  message: call.notes!,
                                  child: SizedBox(
                                    width: 200,
                                    child: Text(
                                      call.notes!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}