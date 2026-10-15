import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../app/app_theme.dart';
import '../../core/localization_extension.dart';
import '../../core/models/branch_model.dart';
import '../../core/providers.dart';
import '../../core/services/firestore_service.dart';

/// Admin tab for managing company branches.
/// Allows adding, renaming and deactivating (soft-deleting) branches.
class BranchManagementTab extends ConsumerWidget {
  const BranchManagementTab({super.key});

  /// Opens a dialog to add a new branch or rename an existing one.
  /// If [existingBranch] is provided, the dialog is in edit mode.
  Future<void> _showBranchDialog(
      BuildContext context,
      WidgetRef ref, {
        BranchModel? existingBranch,
      }) async {
    /// Local controller — not disposed manually (see SPEC: dialog controllers)
    final TextEditingController branchNameController =
    TextEditingController(text: existingBranch?.branchName ?? '');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          /// Saves the branch. isSaving blocks a double tap from
          /// creating the same branch twice.
          Future<void> save() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => isSaving = true);
            try {
              if (existingBranch == null) {
                await firestoreService.createBranch(BranchModel(
                  branchId: const Uuid().v4(),
                  branchName: branchNameController.text.trim(),
                  isActive: true,
                  createdAt: DateTime.now(),
                ));
              } else {
                await firestoreService.updateBranchName(
                  branchId: existingBranch.branchId,
                  newBranchName: branchNameController.text.trim(),
                );
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            } catch (error) {
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.failedToSaveBranch),
                    backgroundColor: context.colors.error,
                  ),
                );
              }
            }
          }

          return AlertDialog(
            title: Text(
              existingBranch == null
                  ? context.l10n.addBranch
                  : context.l10n.editBranch,
            ),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: branchNameController,
                maxLength: 40,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => save(),
                decoration: InputDecoration(
                  labelText: context.l10n.branchName,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.l10n.pleaseEnterBranchName;
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                isSaving ? null : () => Navigator.of(dialogContext).pop(),
                child: Text(context.l10n.cancel),
              ),
              /// Colors come from the theme
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: Text(context.l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shows a confirmation dialog before deactivating a branch.
  Future<void> _confirmDeactivateBranch(
      BuildContext context,
      WidgetRef ref,
      BranchModel branchToDeactivate,
      ) async {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteBranch),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestoreService
                    .deactivateBranch(branchToDeactivate.branchId);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.failedToDeleteBranch),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            child: Text(context.l10n.deactivate),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    /// Each tab has its own Scaffold so it can have its own FAB
    return Scaffold(
      /// Colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addBranchFab',
        onPressed: () => _showBranchDialog(context, ref),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(context.l10n.addBranch),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<BranchModel>>(
            stream: firestoreService.streamActiveBranches(),
            builder: (context, snapshot) {
              /// Spinner only on the very first load (no flicker on rebuilds)
              if (!snapshot.hasData && !snapshot.hasError) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final List<BranchModel> branches = snapshot.data ?? [];

              if (branches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory_outlined,
                          size: 64, color: context.colors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noBranchesCreated,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                /// Extra bottom padding so the FAB never covers the last card
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: branches.length,
                itemBuilder: (context, index) {
                  final BranchModel branch = branches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: context.colors.primaryContainer,
                        child: Icon(Icons.store_outlined,
                            color: context.colors.onPrimaryContainer),
                      ),
                      title: Text(
                        branch.branchName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.l10n.editBranch,
                            icon: Icon(Icons.edit_outlined,
                                color: context.colors.primary),
                            onPressed: () => _showBranchDialog(
                              context,
                              ref,
                              existingBranch: branch,
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.deactivate,
                            icon: Icon(Icons.delete_outline,
                                color: context.colors.error),
                            onPressed: () => _confirmDeactivateBranch(
                              context,
                              ref,
                              branch,
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