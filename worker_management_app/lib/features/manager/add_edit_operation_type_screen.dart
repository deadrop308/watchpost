import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/app_theme.dart';
import '../../core/localization_extension.dart';
import '../../core/models/close_form_model.dart';
import '../../core/models/operation_type_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';
import '../shared/checklist_section.dart';
import '../shared/message_box.dart';

/// Screen for adding or editing an operation type, including the
/// close-call form builder (notes, signature and checklist).
class AddEditOperationTypeScreen extends ConsumerStatefulWidget {
  /// The current manager
  final UserModel currentUser;

  /// The operation type to edit, null when adding a new one
  final OperationTypeModel? existingOperationType;

  const AddEditOperationTypeScreen({
    super.key,
    required this.currentUser,
    this.existingOperationType,
  });

  @override
  ConsumerState<AddEditOperationTypeScreen> createState() =>
      _AddEditOperationTypeScreenState();
}

class _AddEditOperationTypeScreenState
    extends ConsumerState<AddEditOperationTypeScreen> {
  /// Controls the operation name input
  final TextEditingController _nameController = TextEditingController();

  /// Used to validate the name before saving
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// The close-call form being built
  late CloseFormConfig _closeForm;

  /// Local checkbox state for the checklist preview only — never saved
  final Map<String, bool> _previewResults = {};

  /// Whether a save is in progress
  bool _isSaving = false;

  /// Validation or save error shown above the save button
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final OperationTypeModel? existing = widget.existingOperationType;
    _nameController.text = existing?.operationTypeName ?? '';
    _closeForm = existing?.closeForm ?? CloseFormConfig.defaultConfig;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CHECKLIST EDITING HELPERS
  // ─────────────────────────────────────────────

  /// Asks the manager for a short piece of text (a check name or list title).
  /// Returns null if cancelled.
  Future<String?> _promptForText({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    /// Local controller — not disposed manually (see SPEC: dialog controllers)
    final TextEditingController textController = TextEditingController(
      text: initialValue,
    );
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        /// Validates, then closes the dialog returning the text
        void submit() {
          if (!dialogFormKey.currentState!.validate()) return;
          Navigator.of(dialogContext).pop(textController.text.trim());
        }

        return AlertDialog(
          title: Text(title),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              maxLength: 40,

              /// Pressing Enter saves — quick when adding many checks
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => submit(),
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.formPleaseEnterText;
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),

            /// Colors come from the theme
            ElevatedButton(onPressed: submit, child: Text(context.l10n.save)),
          ],
        );
      },
    );
  }

  /// Replaces the whole checklist and clears any validation error.
  void _setElements(List<ChecklistElement> updatedElements) {
    /// The screen may have closed while a dialog was open
    if (!mounted) return;
    setState(() {
      _closeForm = _closeForm.copyWith(checklistElements: updatedElements);
      _errorMessage = null;
    });
  }

  /// Replaces one element (matched by ID) with an updated version.
  void _replaceElement(ChecklistElement updatedElement) {
    _setElements(
      _closeForm.checklistElements
          .map(
            (element) => element.elementId == updatedElement.elementId
                ? updatedElement
                : element,
          )
          .toList(),
    );
  }

  Future<void> _addSingleCheck() async {
    final String? label = await _promptForText(
      title: context.l10n.formAddSingleCheck,
      label: context.l10n.formCheckName,
    );
    if (label == null) return;
    _setElements([
      ..._closeForm.checklistElements,
      ChecklistElement.newSingle(label),
    ]);
  }

  Future<void> _addCheckList() async {
    final String? title = await _promptForText(
      title: context.l10n.formAddCheckList,
      label: context.l10n.formCheckListTitle,
    );
    if (title == null) return;
    _setElements([
      ..._closeForm.checklistElements,
      ChecklistElement.newGroup(title),
    ]);
  }

  Future<void> _renameElement(ChecklistElement element) async {
    final String? newLabel = await _promptForText(
      title: context.l10n.formEdit,
      label: element.isGroup
          ? context.l10n.formCheckListTitle
          : context.l10n.formCheckName,
      initialValue: element.label,
    );
    if (newLabel == null) return;
    _replaceElement(element.copyWith(label: newLabel));
  }

  void _deleteElement(ChecklistElement element) {
    _setElements(
      _closeForm.checklistElements
          .where((existing) => existing.elementId != element.elementId)
          .toList(),
    );
  }

  Future<void> _addCheckToList(ChecklistElement group) async {
    final String? label = await _promptForText(
      title: context.l10n.formAddCheck,
      label: context.l10n.formCheckName,
    );
    if (label == null) return;
    _replaceElement(
      group.copyWith(items: [...group.items, ChecklistItem.create(label)]),
    );
  }

  Future<void> _renameCheckInList(
    ChecklistElement group,
    ChecklistItem item,
  ) async {
    final String? newLabel = await _promptForText(
      title: context.l10n.formEdit,
      label: context.l10n.formCheckName,
      initialValue: item.label,
    );
    if (newLabel == null) return;
    _replaceElement(
      group.copyWith(
        items: group.items
            .map(
              (existing) => existing.itemId == item.itemId
                  ? existing.copyWith(label: newLabel)
                  : existing,
            )
            .toList(),
      ),
    );
  }

  void _deleteCheckFromList(ChecklistElement group, ChecklistItem item) {
    _replaceElement(
      group.copyWith(
        items: group.items
            .where((existing) => existing.itemId != item.itemId)
            .toList(),
      ),
    );
  }

  /// Sorts the checks inside a check list alphabetically (A→Z / א→ת),
  /// ignoring upper/lower case. The new order is saved with the form,
  /// so workers see the list sorted too.
  void _sortCheckList(ChecklistElement group) {
    final List<ChecklistItem> sortedItems = [...group.items]
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    _replaceElement(group.copyWith(items: sortedItems));
  }

  // ─────────────────────────────────────────────
  // COPY FROM AN EXISTING OPERATION TYPE
  // ─────────────────────────────────────────────

  /// Makes an independent copy of a form: same settings and checks, but
  /// fresh IDs — so the new operation type never shares items with the one
  /// it was copied from, and editing one never affects the other.
  CloseFormConfig _cloneForm(CloseFormConfig source) {
    final List<ChecklistElement> clonedElements = source.checklistElements.map((
      element,
    ) {
      if (!element.isGroup) {
        return ChecklistElement.newSingle(element.label);
      }
      return ChecklistElement.newGroup(element.label).copyWith(
        items: element.items
            .map((item) => ChecklistItem.create(item.label))
            .toList(),
      );
    }).toList();

    return source.copyWith(checklistElements: clonedElements);
  }

  /// Lets the manager pick an existing operation type and copies its whole
  /// close form (notes, signature and checklist) into this new one.
  /// The operation name is not copied — the manager types a new one.
  Future<void> _copyFormFromExisting() async {
    final FirestoreService firestoreService = ref.read(
      firestoreServiceProvider,
    );

    /// One-time read of the branch's operation types
    List<OperationTypeModel> operationTypes;
    try {
      operationTypes = await firestoreService
          .streamActiveOperationTypesByBranch(widget.currentUser.branchId)
          .first;
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.l10n.formCopyLoadFailed);
      return;
    }

    if (!mounted) return;

    if (operationTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noOperationTypesCreated)),
      );
      return;
    }

    /// Pick the source (the list scrolls if there are many types)
    final OperationTypeModel? source = await showDialog<OperationTypeModel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.formCopyFromTitle),
        children: operationTypes
            .map(
              (type) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(type),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(type.operationTypeName),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (source == null || !mounted) return;

    /// Don't silently throw away checks already added to this form
    if (_closeForm.checklistElements.isNotEmpty) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(context.l10n.formCopyReplaceConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.formCopy),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _closeForm = _cloneForm(source.closeForm);
      _previewResults.clear();
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.formCopiedFrom(source.operationTypeName)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────

  /// Validates the form and saves the operation type to Firestore.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_closeForm.checklistEnabled) {
      if (_closeForm.checklistElements.isEmpty) {
        setState(() => _errorMessage = context.l10n.formChecklistEmpty);
        return;
      }
      final bool hasEmptyCheckList = _closeForm.checklistElements.any(
        (element) => element.isGroup && element.items.isEmpty,
      );
      if (hasEmptyCheckList) {
        setState(() => _errorMessage = context.l10n.formGroupEmpty);
        return;
      }
    }

    /// A hidden section can't be mandatory
    final CloseFormConfig formToSave = _closeForm.copyWith(
      notesMandatory: _closeForm.notesEnabled && _closeForm.notesMandatory,
      signatureMandatory:
          _closeForm.signatureEnabled && _closeForm.signatureMandatory,
    );

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final FirestoreService firestoreService = ref.read(
        firestoreServiceProvider,
      );
      final String operationName = _nameController.text.trim();

      if (widget.existingOperationType == null) {
        await firestoreService.createOperationType(
          OperationTypeModel(
            operationTypeId: const Uuid().v4(),
            operationTypeName: operationName,
            branchId: widget.currentUser.branchId,
            isActive: true,
            createdAt: DateTime.now(),
            closeForm: formToSave,
          ),
        );
      } else {
        await firestoreService.updateOperationType(
          operationTypeId: widget.existingOperationType!.operationTypeId,
          newOperationTypeName: operationName,
          newCloseForm: formToSave,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = context.l10n.formFailedToSave;
          _isSaving = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // UI BUILDING BLOCKS
  // ─────────────────────────────────────────────

  /// A card for one form section (Notes / Signature / Checklist)
  /// with an on/off switch. Its contents only show when switched on.
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(icon, color: context.colors.primary),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                context.l10n.formShowOnCloseScreen,
                style: const TextStyle(fontSize: 12),
              ),
              value: isEnabled,
              onChanged: onToggle,
            ),
            if (isEnabled) ...children,
          ],
        ),
      ),
    );
  }

  /// Small grey "Worker preview" caption above each preview.
  Widget _buildPreviewCaption() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        context.l10n.formPreview,
        style: TextStyle(
          fontSize: 12,
          color: context.colors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Label for a preview field, with a red asterisk when mandatory.
  String _previewLabel(String label, bool isMandatory) =>
      isMandatory ? '$label *' : label;

  /// One row in the checklist editor (single check or a check inside a list).
  Widget _buildEditorRow({
    required String label,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    double indent = 0,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Row(
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: context.colors.primary,
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.formEdit,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: context.colors.error,
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.delete,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  /// Editor for a titled check list and the checks inside it.
  Widget _buildCheckListEditor(ChecklistElement group) {
    return Container(
      key: ValueKey(group.elementId),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
      decoration: BoxDecoration(
        /// Light blue tint in light mode, dark blue tint in dark mode
        color: context.colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Check list title row
          Row(
            children: [
              Icon(Icons.checklist, size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              /// Sort A→Z — only worth showing with 2+ checks
              if (group.items.length > 1)
                IconButton(
                  icon: const Icon(Icons.sort_by_alpha, size: 18),
                  color: context.colors.primary,
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.formSortAZ,
                  onPressed: () => _sortCheckList(group),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: context.colors.primary,
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.formEdit,
                onPressed: () => _renameElement(group),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: context.colors.error,
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.delete,
                onPressed: () => _deleteElement(group),
              ),
            ],
          ),

          if (group.items.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 28, bottom: 4),
              child: Text(
                context.l10n.formNoChecksYet,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),

          /// Checks inside this list
          ...group.items.map(
            (item) => _buildEditorRow(
              label: item.label,
              indent: 28,
              onEdit: () => _renameCheckInList(group, item),
              onDelete: () => _deleteCheckFromList(group, item),
            ),
          ),

          /// Add a check to this list
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 20),
            child: TextButton.icon(
              onPressed: () => _addCheckToList(group),
              icon: const Icon(Icons.add, size: 18),
              label: Text(context.l10n.formAddCheck),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingOperationType != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? context.l10n.formEditorTitleEdit
              : context.l10n.formEditorTitleAdd,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Operation name
                  TextFormField(
                    controller: _nameController,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: context.l10n.formOperationName,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.formPleaseEnterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// A new type can start as a copy of an existing one's form
                  if (!isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: _copyFormFromExisting,
                      icon: const Icon(Icons.copy_all_outlined, size: 18),
                      label: Text(context.l10n.formCopyFrom),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── NOTES ──
                  _buildSectionCard(
                    icon: Icons.notes_outlined,
                    title: context.l10n.formNotesSection,
                    isEnabled: _closeForm.notesEnabled,
                    onToggle: (isOn) => setState(
                      () =>
                          _closeForm = _closeForm.copyWith(notesEnabled: isOn),
                    ),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(context.l10n.formMandatory),
                        value: _closeForm.notesMandatory,
                        onChanged: (isOn) => setState(
                          () => _closeForm = _closeForm.copyWith(
                            notesMandatory: isOn,
                          ),
                        ),
                      ),
                      _buildPreviewCaption(),
                      TextField(
                        enabled: false,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: _previewLabel(
                            context.l10n.notes,
                            _closeForm.notesMandatory,
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),

                  // ── SIGNATURE ──
                  _buildSectionCard(
                    icon: Icons.draw_outlined,
                    title: context.l10n.formSignatureSection,
                    isEnabled: _closeForm.signatureEnabled,
                    onToggle: (isOn) => setState(
                      () => _closeForm = _closeForm.copyWith(
                        signatureEnabled: isOn,
                      ),
                    ),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(context.l10n.formMandatory),
                        value: _closeForm.signatureMandatory,
                        onChanged: (isOn) => setState(
                          () => _closeForm = _closeForm.copyWith(
                            signatureMandatory: isOn,
                          ),
                        ),
                      ),
                      _buildPreviewCaption(),

                      /// White in both themes — same as the real signature pad
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.colors.outline),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.gesture, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              Text(
                                _previewLabel(
                                  context.l10n.formSignatureHint,
                                  _closeForm.signatureMandatory,
                                ),
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── CHECKLIST ──
                  _buildSectionCard(
                    icon: Icons.checklist,
                    title: context.l10n.formChecklistSection,
                    isEnabled: _closeForm.checklistEnabled,
                    onToggle: (isOn) => setState(() {
                      _closeForm = _closeForm.copyWith(checklistEnabled: isOn);
                      _errorMessage = null;
                    }),
                    children: [
                      if (_closeForm.checklistElements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.l10n.formNoChecksYet,
                            style: TextStyle(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),

                      /// Editor rows, in the order they were added
                      ..._closeForm.checklistElements.map(
                        (element) => element.isGroup
                            ? _buildCheckListEditor(element)
                            : KeyedSubtree(
                                key: ValueKey(element.elementId),
                                child: _buildEditorRow(
                                  label: element.label,
                                  onEdit: () => _renameElement(element),
                                  onDelete: () => _deleteElement(element),
                                ),
                              ),
                      ),

                      /// Add buttons — always available
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addSingleCheck,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(context.l10n.formAddSingleCheck),
                          ),
                          OutlinedButton.icon(
                            onPressed: _addCheckList,
                            icon: const Icon(Icons.playlist_add, size: 18),
                            label: Text(context.l10n.formAddCheckList),
                          ),
                        ],
                      ),

                      /// Live preview using the same widget the worker sees
                      if (_closeForm.hasChecklist) ...[
                        _buildPreviewCaption(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).cardTheme.color ??
                                context.colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.colors.outlineVariant,
                            ),
                          ),
                          child: ChecklistSection(
                            elements: _closeForm.checklistElements,
                            results: _previewResults,
                            onChanged: (itemId, isChecked) => setState(
                              () => _previewResults[itemId] = isChecked,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  /// Validation / save error
                  if (_errorMessage != null) ...[
                    MessageBox.error(_errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  /// Save button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,

                      /// Colors come from the theme
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: context.colors.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(context.l10n.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
