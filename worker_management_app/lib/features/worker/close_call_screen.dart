import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../app/app_theme.dart';
import '../../core/localization_extension.dart';
import '../../core/models/call_model.dart';
import '../../core/models/close_form_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import '../shared/checklist_section.dart';
import '../shared/message_box.dart';

/// Screen where a worker closes an existing work call.
/// The fields shown (notes, checklist, signature) come from the
/// close form copied onto the call when it was opened, so each
/// operation type can have its own closing requirements.
class CloseCallScreen extends ConsumerStatefulWidget {
  /// The call that is being closed
  final CallModel callToClose;

  const CloseCallScreen({super.key, required this.callToClose});

  @override
  ConsumerState<CloseCallScreen> createState() => _CloseCallScreenState();
}

class _CloseCallScreenState extends ConsumerState<CloseCallScreen> {
  /// Controls the signature pad widget
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  /// Controls the notes input field
  final TextEditingController _notesController = TextEditingController();

  /// Checklist state: item ID → checked.
  /// Every item starts unchecked, so unchecked items are saved too
  /// (an unchecked box is information in the report).
  late final Map<String, bool> _checklistResults;

  /// The end time of the call, defaults to now but can be changed manually
  DateTime _selectedEndTime = DateTime.now();

  /// Whether the form submission is currently in progress
  bool _isSubmitting = false;

  /// Error message to display if submission fails
  String? _errorMessage;

  /// The form this call must be closed with
  CloseFormConfig get _closeForm => widget.callToClose.closeForm;

  @override
  void initState() {
    super.initState();
    _checklistResults = {
      for (final ChecklistItem item in _closeForm.allCheckableItems)
        item.itemId: false,
    };
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Opens a date and time picker so the worker can manually set the end time.
  Future<void> _pickEndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndTime,
      firstDate: widget.callToClose.startTime,
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedEndTime),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _errorMessage = null;
      _selectedEndTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
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

  /// Adds a red asterisk marker to a label when the field is mandatory.
  String _fieldLabel(String label, bool isMandatory) =>
      isMandatory ? '$label *' : label;

  /// Uploads the drawn signature to Firebase Storage and returns its URL.
  /// Returns null when the signature section is off or left empty.
  Future<String?> _uploadSignatureIfDrawn() async {
    if (!_closeForm.signatureEnabled || _signatureController.isEmpty) {
      return null;
    }

    final signatureImageBytes = await _signatureController.toPngBytes();
    if (signatureImageBytes == null) {
      throw Exception('Failed to export signature image');
    }

    /// Stored under signatures/{callId}.png
    final Reference storageReference = FirebaseStorage.instance.ref().child(
      'signatures/${widget.callToClose.callId}.png',
    );

    await storageReference.putData(
      signatureImageBytes,
      SettableMetadata(contentType: 'image/png'),
    );

    return storageReference.getDownloadURL();
  }

  /// Validates the form, then closes the call in Firestore.
  Future<void> _submitCloseCall() async {
    final String notesText = _notesController.text.trim();

    /// Mandatory notes
    if (_closeForm.notesEnabled &&
        _closeForm.notesMandatory &&
        notesText.isEmpty) {
      setState(() => _errorMessage = context.l10n.closeNotesRequired);
      return;
    }

    /// Mandatory signature
    if (_closeForm.signatureEnabled &&
        _closeForm.signatureMandatory &&
        _signatureController.isEmpty) {
      setState(() => _errorMessage = context.l10n.signBelow);
      return;
    }

    /// The time picker allows any hour - block impossible end times
    if (_selectedEndTime.isBefore(widget.callToClose.startTime)) {
      setState(() => _errorMessage = context.l10n.endTimeBeforeStartTime);
      return;
    }
    if (_selectedEndTime.isAfter(DateTime.now())) {
      setState(() => _errorMessage = context.l10n.timeCannotBeInFuture);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final FirestoreService firestoreService = ref.read(
        firestoreServiceProvider,
      );

      final String? signatureDownloadUrl = await _uploadSignatureIfDrawn();

      await firestoreService.closeCall(
        callId: widget.callToClose.callId,
        endTime: _selectedEndTime,
        signatureImageUrl: signatureDownloadUrl,
        notes: _closeForm.notesEnabled && notesText.isNotEmpty
            ? notesText
            : null,
        checklistResults: _closeForm.hasChecklist
            ? Map.of(_checklistResults)
            : const {},
      );

      if (!mounted) return;

      /// Grab the messenger before leaving - this screen's context
      /// is gone once it's popped
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      final String successText = context.l10n.callClosedSuccess;

      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(successText),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.failedToCloseCall;
        _isSubmitting = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // SECTIONS
  // ─────────────────────────────────────────────

  /// A bold heading above a form section.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildCallSummaryCard() {
    final CallModel call = widget.callToClose;
    final String locationLabel = call.clientName.isNotEmpty
        ? '${call.clientName} - ${call.locationName}'
        : call.locationName;
    final Color mutedColor = context.colors.onSurfaceVariant;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call.operationName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: mutedColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: TextStyle(color: mutedColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 16, color: mutedColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${context.l10n.started}: ${_formatDateTime(call.startTime)}',
                    style: TextStyle(color: mutedColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return TextFormField(
      controller: _notesController,
      maxLength: 300,
      maxLines: 6,
      onChanged: (_) {
        if (_errorMessage != null) setState(() => _errorMessage = null);
      },
      decoration: InputDecoration(
        labelText: _fieldLabel(context.l10n.notes, _closeForm.notesMandatory),
        hintText: _closeForm.notesMandatory ? null : context.l10n.noNotes,

        /// Keeps the label at the top of a tall multi-line box
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context.l10n.formChecklistSection),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            /// Same color as cards: white in light mode, dark grey in dark
            color: Theme.of(context).cardTheme.color ?? context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: ChecklistSection(
            elements: _closeForm.checklistElements,
            results: _checklistResults,
            onChanged: (itemId, isChecked) =>
                setState(() => _checklistResults[itemId] = isChecked),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
          _fieldLabel(context.l10n.signature, _closeForm.signatureMandatory),
        ),
        Text(
          context.l10n.signBelow,
          style: TextStyle(
            fontSize: 13,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        /// Signature drawing area - stays WHITE in dark mode on purpose:
        /// the pen is black and the saved PNG has a white background
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: _signatureController,
              height: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        /// Clear signature button
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () {
              _signatureController.clear();
              setState(() => _errorMessage = null);
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(context.l10n.clearSignature),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// End time field - styled like the other form fields
  Widget _buildEndTimePicker() {
    return InkWell(
      onTap: _pickEndTime,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.l10n.endTime,
          prefixIcon: const Icon(Icons.access_time_outlined),
          suffixIcon: Icon(
            Icons.edit_outlined,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        child: Text(
          _formatDateTime(_selectedEndTime),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.closeCall)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            /// Extra bottom padding keeps the last button above the Android
            /// navigation bar (the app draws edge-to-edge behind it)
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCallSummaryCard(),
                const SizedBox(height: 24),

                /// Each section appears only if the operation type enables it
                if (_closeForm.notesEnabled) ...[
                  _buildNotesSection(),
                  const SizedBox(height: 16),
                ],

                if (_closeForm.hasChecklist) ...[
                  _buildChecklistSection(),
                  const SizedBox(height: 24),
                ],

                if (_closeForm.signatureEnabled) ...[
                  _buildSignatureSection(),
                  const SizedBox(height: 16),
                ],

                _buildEndTimePicker(),
                const SizedBox(height: 16),

                /// Error message display
                if (_errorMessage != null) ...[
                  MessageBox.error(_errorMessage!),
                  const SizedBox(height: 16),
                ],

                /// Close call button - red (error color) because it ends the call
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCloseCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.error,
                      foregroundColor: context.colors.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: context.colors.error,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            context.l10n.closeCall,
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
