import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_theme.dart';
import '../../app/router.dart';
import '../../core/localization_extension.dart';
import '../../core/models/branch_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers.dart';
import '../../core/services/cloud_functions_service.dart';
import '../../core/services/firestore_service.dart';
import 'branch_management_tab.dart';

/// The main dashboard screen for admin users.
/// Has two tabs: Managers (create/deactivate manager accounts)
/// and Branches (create/rename/deactivate company branches).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// Tabs use the same color as the AppBar text (white in light mode)
    final Color headerForeground =
        Theme.of(context).appBarTheme.foregroundColor ??
            context.colors.onSurface;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.adminPanel),
          actions: [
            /// Settings button — language, dark mode and logout
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: context.l10n.settings,
              onPressed: () => context.push(AppRoutePaths.settings),
            ),
          ],
          bottom: TabBar(
            labelColor: headerForeground,
            unselectedLabelColor: headerForeground.withValues(alpha: 0.7),
            indicatorColor: headerForeground,
            tabs: [
              Tab(
                icon: const Icon(Icons.manage_accounts_outlined),
                text: context.l10n.managersTab,
              ),
              Tab(
                icon: const Icon(Icons.store_outlined),
                text: context.l10n.branchesTab,
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ManagersTab(),
            BranchManagementTab(),
          ],
        ),
      ),
    );
  }
}

/// Admin tab for managing manager accounts.
/// Each tab has its own Scaffold so it can have its own FAB.
class _ManagersTab extends ConsumerStatefulWidget {
  const _ManagersTab();

  @override
  ConsumerState<_ManagersTab> createState() => _ManagersTabState();
}

class _ManagersTabState extends ConsumerState<_ManagersTab> {
  /// Key that changes to force the managers list to refresh
  /// after creating or deactivating a manager
  int _refreshKey = 0;

  /// Opens a dialog to create a new manager account.
  Future<void> _showCreateManagerDialog(BuildContext context) async {
    /// Local controllers — not disposed manually (see SPEC: dialog controllers)
    final TextEditingController fullNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final CloudFunctionsService cloudFunctionsService =
    ref.read(cloudFunctionsServiceProvider);
    final FirestoreService firestoreService =
    ref.read(firestoreServiceProvider);
    BranchModel? selectedBranch;
    bool isCreating = false;

    /// Fetch branches before showing dialog
    List<BranchModel> availableBranches = [];
    try {
      availableBranches = await firestoreService.fetchAllActiveBranches();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToLoadBranches),
            backgroundColor: context.colors.error,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(context.l10n.addManager),
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
                const SizedBox(height: 16),

                /// Branch selection dropdown
                DropdownButtonFormField<BranchModel>(
                  value: selectedBranch,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.selectBranch,
                  ),
                  items: availableBranches.map((branch) {
                    return DropdownMenuItem<BranchModel>(
                      value: branch,
                      child: Text(branch.branchName),
                    );
                  }).toList(),
                  onChanged: (BranchModel? branch) {
                    setDialogState(() => selectedBranch = branch);
                  },
                  validator: (value) {
                    if (value == null) {
                      return context.l10n.pleaseSelectBranch;
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
                      Text(context.l10n.creatingManager),
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
                  await cloudFunctionsService.createManagerAccount(
                    emailAddress: emailController.text.trim(),
                    fullName: fullNameController.text.trim(),
                    branchId: selectedBranch!.branchId,
                  );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (context.mounted) {
                    /// Refresh the list so the new manager appears
                    setState(() => _refreshKey++);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                        Text(context.l10n.managerCreatedSuccess),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isCreating = false);
                  }
                  if (context.mounted) {
                    final String errorMessage =
                    error.toString().contains('already-exists')
                        ? context.l10n.emailAlreadyExists
                        : context.l10n.failedToCreateManager;
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

  /// Shows a confirmation dialog before deactivating a manager.
  Future<void> _confirmDeactivateManager(
      BuildContext context,
      UserModel managerToDeactivate,
      ) async {
    /// Deactivation goes through the setUserActive Cloud Function, which
    /// also disables the login and ends any open session immediately
    final CloudFunctionsService cloudFunctionsService =
    ref.read(cloudFunctionsServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteManager),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await cloudFunctionsService.setUserActive(
                  userId: managerToDeactivate.userId,
                  isActive: false,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                /// Refresh the list so the deactivated manager disappears
                if (mounted) setState(() => _refreshKey++);
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.failedToDeactivateManager),
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
      /// Colors come from the theme
      floatingActionButton: FloatingActionButton.extended(
        /// Unique hero tag — two FABs exist side by side in the TabBarView
        heroTag: 'addManagerFab',
        onPressed: () => _showCreateManagerDialog(context),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(context.l10n.addManager),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FutureBuilder<List<UserModel>>(
            key: ValueKey(_refreshKey),
            future: firestoreService.fetchAllManagers(),
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

              final List<UserModel> managers = snapshot.data ?? [];

              if (managers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: context.colors.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noManagersFound,
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
                itemCount: managers.length,
                itemBuilder: (context, index) {
                  final UserModel currentManager = managers[index];
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
                        child: Icon(Icons.manage_accounts_outlined,
                            color: context.colors.onPrimaryContainer),
                      ),
                      title: Text(
                        currentManager.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        currentManager.emailAddress,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: context.l10n.deactivate,
                        icon: Icon(Icons.person_remove_outlined,
                            color: context.colors.error),
                        onPressed: () => _confirmDeactivateManager(
                            context, currentManager),
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