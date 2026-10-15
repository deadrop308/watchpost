import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────
// CLOSE CALL FORM CONFIGURATION
// Defines which fields the worker fills in when closing a call.
// Configured per operation type by the manager, and copied onto each
// call when it's opened, so later edits never affect calls in progress.
// ─────────────────────────────────────────────

/// A single checkbox the worker can tick, e.g. "Ink".
class ChecklistItem {
  /// Stable hidden ID — results are stored by this ID, so renaming
  /// the label later doesn't break existing results
  final String itemId;

  /// The text shown next to the checkbox
  final String label;

  const ChecklistItem({required this.itemId, required this.label});

  /// Creates a new item with a fresh unique ID.
  factory ChecklistItem.create(String label) =>
      ChecklistItem(itemId: const Uuid().v4(), label: label);

  ChecklistItem copyWith({String? label}) =>
      ChecklistItem(itemId: itemId, label: label ?? this.label);

  factory ChecklistItem.fromMap(Map<dynamic, dynamic> map) => ChecklistItem(
    itemId: map['itemId'] as String? ?? '',
    label: map['label'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'itemId': itemId, 'label': label};
}

/// The two kinds of elements a checklist can contain.
enum ChecklistElementType { single, group }

/// One entry in the checklist: either a single check,
/// or a titled check list that holds single checks.
/// Check lists cannot contain other check lists (one level only).
class ChecklistElement {
  /// Stable hidden ID. For a single check, this is also the ID
  /// its result is stored under.
  final String elementId;

  /// Whether this is a single check or a titled check list
  final ChecklistElementType type;

  /// For a single check: the checkbox label.
  /// For a check list: the list's title.
  final String label;

  /// The checks inside a check list. Always empty for a single check.
  final List<ChecklistItem> items;

  const ChecklistElement({
    required this.elementId,
    required this.type,
    required this.label,
    this.items = const [],
  });

  /// Creates a new single check with a fresh unique ID.
  factory ChecklistElement.newSingle(String label) => ChecklistElement(
    elementId: const Uuid().v4(),
    type: ChecklistElementType.single,
    label: label,
  );

  /// Creates a new, empty check list with a fresh unique ID.
  factory ChecklistElement.newGroup(String title) => ChecklistElement(
    elementId: const Uuid().v4(),
    type: ChecklistElementType.group,
    label: title,
  );

  bool get isGroup => type == ChecklistElementType.group;

  /// Every checkbox this element produces.
  /// A single check produces one checkbox (using its own ID);
  /// a check list produces one per item.
  List<ChecklistItem> get checkableItems => isGroup
      ? items
      : [ChecklistItem(itemId: elementId, label: label)];

  ChecklistElement copyWith({String? label, List<ChecklistItem>? items}) =>
      ChecklistElement(
        elementId: elementId,
        type: type,
        label: label ?? this.label,
        items: items ?? this.items,
      );

  factory ChecklistElement.fromMap(Map<dynamic, dynamic> map) {
    final dynamic rawItems = map['items'];
    return ChecklistElement(
      elementId: map['elementId'] as String? ?? '',
      type: map['type'] == 'group'
          ? ChecklistElementType.group
          : ChecklistElementType.single,
      label: map['label'] as String? ?? '',
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map((itemMap) => ChecklistItem.fromMap(itemMap))
          .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'elementId': elementId,
    'type': isGroup ? 'group' : 'single',
    'label': label,
    'items': items.map((item) => item.toMap()).toList(),
  };
}

/// The full close-call form for an operation type.
class CloseFormConfig {
  /// Whether the notes field is shown
  final bool notesEnabled;

  /// Whether notes must be filled in before closing
  final bool notesMandatory;

  /// Whether the signature pad is shown
  final bool signatureEnabled;

  /// Whether a signature must be drawn before closing
  final bool signatureMandatory;

  /// Whether the checklist section is shown
  final bool checklistEnabled;

  /// Single checks and check lists, in the order they were added
  final List<ChecklistElement> checklistElements;

  /// Defaults match how the app behaved before this feature existed:
  /// optional notes, mandatory signature, no checklist.
  const CloseFormConfig({
    this.notesEnabled = true,
    this.notesMandatory = false,
    this.signatureEnabled = true,
    this.signatureMandatory = true,
    this.checklistEnabled = false,
    this.checklistElements = const [],
  });

  /// Used for operation types and calls created before this feature.
  static const CloseFormConfig defaultConfig = CloseFormConfig();

  /// True if the worker will actually see at least one checkbox.
  bool get hasChecklist =>
      checklistEnabled &&
          checklistElements.any((element) => element.checkableItems.isNotEmpty);

  /// Every checkbox across all elements, flattened, in display order.
  List<ChecklistItem> get allCheckableItems => checklistElements
      .expand((element) => element.checkableItems)
      .toList();

  /// How many checkboxes were ticked in [results].
  int checkedCount(Map<String, bool> results) => allCheckableItems
      .where((item) => results[item.itemId] == true)
      .length;

  /// One-line readable summary of the results, for reports and CSV,
  /// e.g. "Cleaned exterior ✓ | Reagents: Ink ✓, Camera ✗"
  String describeResults(Map<String, bool> results) {
    String mark(ChecklistItem item) =>
        '${item.label} ${results[item.itemId] == true ? '✓' : '✗'}';
    return checklistElements
        .where((element) => element.checkableItems.isNotEmpty)
        .map((element) => element.isGroup
        ? '${element.label}: ${element.items.map(mark).join(', ')}'
        : mark(element.checkableItems.first))
        .join(' | ');
  }

  CloseFormConfig copyWith({
    bool? notesEnabled,
    bool? notesMandatory,
    bool? signatureEnabled,
    bool? signatureMandatory,
    bool? checklistEnabled,
    List<ChecklistElement>? checklistElements,
  }) =>
      CloseFormConfig(
        notesEnabled: notesEnabled ?? this.notesEnabled,
        notesMandatory: notesMandatory ?? this.notesMandatory,
        signatureEnabled: signatureEnabled ?? this.signatureEnabled,
        signatureMandatory: signatureMandatory ?? this.signatureMandatory,
        checklistEnabled: checklistEnabled ?? this.checklistEnabled,
        checklistElements: checklistElements ?? this.checklistElements,
      );

  /// Parses the 'closeForm' field from Firestore.
  /// Falls back to [defaultConfig] when the field is missing.
  factory CloseFormConfig.fromMap(dynamic raw) {
    if (raw is! Map) return defaultConfig;
    final dynamic rawElements = raw['checklistElements'];
    return CloseFormConfig(
      notesEnabled: raw['notesEnabled'] as bool? ?? true,
      notesMandatory: raw['notesMandatory'] as bool? ?? false,
      signatureEnabled: raw['signatureEnabled'] as bool? ?? true,
      signatureMandatory: raw['signatureMandatory'] as bool? ?? true,
      checklistEnabled: raw['checklistEnabled'] as bool? ?? false,
      checklistElements: rawElements is List
          ? rawElements
          .whereType<Map>()
          .map((elementMap) => ChecklistElement.fromMap(elementMap))
          .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'notesEnabled': notesEnabled,
    'notesMandatory': notesMandatory,
    'signatureEnabled': signatureEnabled,
    'signatureMandatory': signatureMandatory,
    'checklistEnabled': checklistEnabled,
    'checklistElements':
    checklistElements.map((element) => element.toMap()).toList(),
  };
}