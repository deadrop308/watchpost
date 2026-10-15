import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../core/models/close_form_model.dart';

/// Renders a checklist (single checks and titled check lists) as checkboxes.
/// Shared by three places so they always look identical:
///  - the operation type builder preview
///  - the worker's close call screen (interactive)
///  - the closed call popup (read-only results)
///
/// Check lists (groups) start COLLAPSED — only the title and a "3/20"
/// counter show. Tap the title to open the list when it's needed
/// (e.g. a part was replaced). Single checks are always visible.
class ChecklistSection extends StatelessWidget {
  /// The checklist structure to render, in display order
  final List<ChecklistElement> elements;

  /// Current state of each checkbox: item ID → checked
  final Map<String, bool> results;

  /// Called when a checkbox is tapped. Pass null for read-only display.
  final void Function(String itemId, bool isChecked)? onChanged;

  const ChecklistSection({
    super.key,
    required this.elements,
    required this.results,
    this.onChanged,
  });

  Widget _buildCheckbox(ChecklistItem item) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: results[item.itemId] ?? false,
      onChanged: onChanged == null
          ? null
          : (bool? isChecked) => onChanged!(item.itemId, isChecked ?? false),
      title: Text(item.label, style: const TextStyle(fontSize: 14)),
    );
  }

  /// A collapsible check list: title + "checked/total" counter,
  /// its checks only appear when opened.
  Widget _buildGroup(BuildContext context, ChecklistElement group) {
    final int total = group.items.length;
    final int checked =
        group.items.where((item) => results[item.itemId] ?? false).length;

    return ExpansionTile(
      /// Keeps each list's open/closed state when the screen rebuilds
      key: PageStorageKey<String>('checklist-group-${group.elementId}'),
      initiallyExpanded: false,
      dense: true,
      visualDensity: VisualDensity.compact,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsetsDirectional.only(start: 16),
      /// No divider lines when opened
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Icon(Icons.checklist, size: 18, color: context.colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              group.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          /// "3/20" — highlighted once anything in the list is checked
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: checked > 0
                  ? context.colors.primaryContainer
                  : context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$checked/$total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: checked > 0
                    ? context.colors.onPrimaryContainer
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      children: group.items.map(_buildCheckbox).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: elements.map((element) {
        if (!element.isGroup) {
          return KeyedSubtree(
            key: ValueKey(element.elementId),
            child: _buildCheckbox(element.checkableItems.first),
          );
        }
        return _buildGroup(context, element);
      }).toList(),
    );
  }
}