import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/localization_extension.dart';
import '../../../core/models/location_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_service.dart';

/// Screen where a manager manages locations for their branch.
/// Allows adding, editing and soft-deleting locations.
class LocationManagementScreen extends ConsumerWidget {
  const LocationManagementScreen({super.key});

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
        return _LocationManagementContent(currentUser: currentUser);
      },
    );
  }
}

/// The actual content of the location management screen.
class _LocationManagementContent extends ConsumerWidget {
  final UserModel currentUser;

  const _LocationManagementContent({required this.currentUser});

  /// Shows a confirmation dialog before deleting a location.
  Future<void> _confirmDeleteLocation(
      BuildContext context,
      WidgetRef ref,
      LocationModel locationToDelete,
      ) async {
    final FirestoreService firestoreService = ref.read(firestoreServiceProvider);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.confirmDeleteLocation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await firestoreService.deactivateLocation(
                  locationToDelete.locationId,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } catch (error) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.failedToDeleteLocation),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirestoreService firestoreService = ref.read(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(context.l10n.locationManagement),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRoutePaths.managerAddEditLocation,
          extra: {
            'currentUser': currentUser,
            'existingLocation': null,
          },
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addLocation),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<LocationModel>>(
            stream: firestoreService.streamActiveLocationsByBranch(
              currentUser.branchId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    '${context.l10n.errorLoadingCalls}: ${snapshot.error}',
                  ),
                );
              }

              final List<LocationModel> activeLocations = snapshot.data ?? [];

              if (activeLocations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        context.l10n.noLocationsCreated,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        context.l10n.tapToAddLocation,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeLocations.length,
                itemBuilder: (context, index) {
                  final LocationModel currentLocation = activeLocations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: const Icon(Icons.location_on_outlined,
                          color: Colors.blue),
                      title: Text(
                        currentLocation.locationName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: currentLocation.address.isNotEmpty
                          ? Text(
                        currentLocation.address,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Edit button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.blue),
                            onPressed: () => context.push(
                              AppRoutePaths.managerAddEditLocation,
                              extra: {
                                'currentUser': currentUser,
                                'existingLocation': currentLocation,
                              },
                            ),
                          ),
                          /// Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _confirmDeleteLocation(
                              context,
                              ref,
                              currentLocation,
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