import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_theme.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/services/cloud_functions_service.dart';
import '../../../core/services/firestore_service.dart';

/// Screen where a manager manages worker accounts for their branch.
/// Allows creating new workers and deactivating existing ones.
class WorkerManagementScreen extends ConsumerWidget {
  const WorkerManagementScreen({super.key});

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
        return _WorkerManagementContent(currentUser: currentUser);
      },
    );
  }
}

/// The actual content of the worker management screen.
class _WorkerManagementContent extends ConsumerStatefulWidget {
  final UserModel currentUser;

  const _WorkerManagementContent({required this.currentUser});

  @override
  ConsumerState<_WorkerManagementContent> createState() =>
      _WorkerManagementContentState();
}

class _WorkerManagementContentState
    extends ConsumerState<_WorkerManagementContent> {
  /// Key that changes to force the workers list to refresh
  int _refreshKey = 0;

  /// Opens a dialog to create a new worker account.
  Future<void> _showCreateWorkerDialog(BuildContext context) async {
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final CloudFunctionsService cloudFunctionsService =
    ref.read(cloudFunctionsServiceProvider);
    bool isCreating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.addWorker),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Full name input
                TextFormField(
                  controller: fullNameController,
                  maxLength: 30,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.fullName,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterFullName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                /// Email input
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.emailAddress,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.pleaseEnterEmail;
                    }
                    if (!value.contains('@')) {
                      return context.l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),

                /// Loading indicator shown while creating the account
                if (isCreating) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(context.l10n.creatingWorker),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isCreating
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() => isCreating = true);

                try {
                  await cloudFunctionsService.createWorkerAccount(
                    emailAddress: emailController.text.trim(),
                    fullName: fullNameController.text.trim(),
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        Text(context.l10n.workerCreatedSuccess),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                } catch (error) {
                  /// The dialog may already be closed — only update it if not
                  if (dialogContext.mounted) {
                    setDialogState(() => isCreating = false);
                  }
                  if (context.mounted) {
                    final String errorMessage =
                    error.toString().contains('already-exists')
                        ? context.l10n.emailAlreadyExists
                        : context.l10n.failedToCreateWorker;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: context.colors.error,
                      ),
                    );
                  }
                }
              },
              /// Colors come from the theme
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before deactivating a worker.
  Future<void> _confirmDeactivateWorker(
      BuildContext context,
      UserModel workerToDeactivate,
      ) async {
    /// Deactivation goes through the setUserActive Cloud Function, which
    /// also disables the login and ends any open session immediately
    final CloudFunctionsService cloudFunctionsService =
    ref.read(cloudFunctionsServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteWorker),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await cloudFunctionsService.setUserActive(
                  userId: workerToDeactivate.userId,
                  isActive: false,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) setState(() => _refreshKey++);
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text(context.l10n.failedToDeactivateWorker),
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
  Widget build(BuildContext context) {
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.workerManagement),
      ),
      /// Colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkerDialog(context),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(context.l10n.addWorker),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FutureBuilder<List<UserModel>>(
            key: ValueKey(_refreshKey),
            future: firestoreService.fetchWorkersByBranch(
              widget.currentUser.branchId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                      '${context.l10n.errorLoadingCalls}: ${snapshot.error}'),
                );
              }

              final List<UserModel> workers = snapshot.data ?? [];

              if (workers.isEmpty) {
                final Color mutedColor = context.colors.onSurfaceVariant;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: mutedColor),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noWorkersFound,
                        style: TextStyle(fontSize: 18, color: mutedColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                /// Extra bottom padding so the FAB never covers the last
                /// worker's deactivate button
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final UserModel currentWorker = workers[index];
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
                        child: Icon(Icons.person_outline,
                            color: context.colors.onPrimaryContainer),
                      ),
                      title: Text(
                        currentWorker.fullName,
                        style:
                        const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        currentWorker.emailAddress,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: context.l10n.deactivate,
                        icon: Icon(Icons.person_remove_outlined,
                            color: context.colors.error),
                        onPressed: () => _confirmDeactivateWorker(
                          context,
                          currentWorker,
                        ),
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