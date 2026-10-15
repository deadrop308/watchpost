import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../app/router.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/close_form_model.dart';
import '../../../core/models/operation_type_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_service.dart';

/// Screen where a manager manages operation types for their branch.
/// Adding and editing open the full form builder screen;
/// deleting soft-deletes the operation type.
class OperationTypeManagementScreen extends ConsumerWidget {
  const OperationTypeManagementScreen({super.key});

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
        return _OperationTypeManagementContent(currentUser: currentUser);
      },
    );
  }
}

/// The actual content of the operation type management screen.
class _OperationTypeManagementContent extends ConsumerWidget {
  final UserModel currentUser;

  const _OperationTypeManagementContent({required this.currentUser});

  /// Opens the form builder screen.
  /// Pass [existingOperationType] to edit, or null to create a new one.
  void _openFormBuilder(
      BuildContext context, {
        OperationTypeModel? existingOperationType,
      }) {
    context.push(
      AppRoutePaths.managerAddEditOperationType,
      extra: {
        'currentUser': currentUser,
        'existingOperationType': existingOperationType,
      },
    );
  }

  /// Builds a short summary of the close form, e.g.
  /// "Notes · Signature · Checklist (5)", shown under each operation name.
  String _buildFormSummary(BuildContext context, CloseFormConfig closeForm) {
    final List<String> parts = [];
    if (closeForm.notesEnabled) {
      parts.add(context.l10n.formNotesSection);
    }
    if (closeForm.signatureEnabled) {
      parts.add(context.l10n.formSignatureSection);
    }
    if (closeForm.hasChecklist) {
      parts.add(
          '${context.l10n.formChecklistSection} (${closeForm.allCheckableItems.length})');
    }
    return parts.join(' · ');
  }

  /// Shows a confirmation dialog before deleting an operation type.
  Future<void> _confirmDeleteOperationType(
      BuildContext context,
      WidgetRef ref,
      OperationTypeModel operationTypeToDelete,
      ) async {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteOperationType),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestoreService.deactivateOperationType(
                  operationTypeToDelete.operationTypeId,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                        Text(context.l10n.failedToDeleteOperationType)),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.operationTypeManagement),
      ),
      /// Colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormBuilder(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addOperationType),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<OperationTypeModel>>(
            stream: firestoreService.streamActiveOperationTypesByBranch(
              currentUser.branchId,
            ),
            builder: (context, snapshot) {
              /// Spinner only on the very first load (no flicker on rebuilds)
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                      '${context.l10n.errorLoadingCalls}: ${snapshot.error}'),
                );
              }

              final List<OperationTypeModel> activeOperationTypes =
                  snapshot.data ?? [];

              if (activeOperationTypes.isEmpty) {
                final Color mutedColor = context.colors.onSurfaceVariant;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_off_outlined,
                            size: 64, color: mutedColor),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.noOperationTypesCreated,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: mutedColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.tapToAddOperationType,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: activeOperationTypes.length,
                itemBuilder: (context, index) {
                  final OperationTypeModel currentOperationType =
                  activeOperationTypes[index];
                  final String formSummary = _buildFormSummary(
                      context, currentOperationType.closeForm);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Icon(Icons.work_outline,
                          color: context.colors.primary),
                      title: Text(
                        currentOperationType.operationTypeName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      /// What the worker fills in when closing this type
                      subtitle: formSummary.isNotEmpty
                          ? Text(
                        formSummary,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceVariant),
                      )
                          : null,
                      onTap: () => _openFormBuilder(
                        context,
                        existingOperationType: currentOperationType,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Edit button — opens the form builder
                          IconButton(
                            tooltip: context.l10n.formEdit,
                            icon: Icon(Icons.edit_outlined,
                                color: context.colors.primary),
                            onPressed: () => _openFormBuilder(
                              context,
                              existingOperationType: currentOperationType,
                            ),
                          ),
                          /// Delete button
                          IconButton(
                            tooltip: context.l10n.delete,
                            icon: Icon(Icons.delete_outline,
                                color: context.colors.error),
                            onPressed: () => _confirmDeleteOperationType(
                              context,
                              ref,
                              currentOperationType,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}