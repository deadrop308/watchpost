// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Worker Management';

  @override
  String get signIn => 'Sign In';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get invalidEmailOrPassword =>
      'Invalid email or password. Please try again.';

  @override
  String get pleaseEnterEmail => 'Please enter your email address';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get noOpenCalls => 'No open calls';

  @override
  String get tapBelowToOpenCall => 'Tap the button below to open a new call';

  @override
  String get tapToCloseCall => 'Tap to close call';

  @override
  String get openCall => 'Open Call';

  @override
  String get openNewCall => 'Open New Call';

  @override
  String get operationType => 'Operation Type';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get startTime => 'Start Time';

  @override
  String get failedToOpenCall => 'Failed to open call. Please try again.';

  @override
  String get pleaseSelectOperationType => 'Please select an operation type';

  @override
  String get pleaseSelectLocation => 'Please select a location';

  @override
  String get noOperationTypesAvailable =>
      'No operation types available for your branch. Please contact your manager.';

  @override
  String get noLocationsAvailable =>
      'No locations available for your branch. Please contact your manager.';

  @override
  String get closeCall => 'Close Call';

  @override
  String get signature => 'Signature';

  @override
  String get signBelow =>
      'Please sign below to confirm the completion of this call';

  @override
  String get clearSignature => 'Clear Signature';

  @override
  String get endTime => 'End Time';

  @override
  String get pleaseProvideSignature =>
      'Please provide a signature before closing the call';

  @override
  String get failedToCloseCall => 'Failed to close call. Please try again.';

  @override
  String get started => 'Started';

  @override
  String get todaysActivity => 'Today\'s Activity';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String helloUser(String name) {
    return 'Hello, $name';
  }

  @override
  String get noCallsRecordedToday => 'No calls recorded today';

  @override
  String get errorLoadingCalls => 'Error loading calls';

  @override
  String get worker => 'Worker';

  @override
  String get operation => 'Operation';

  @override
  String get location => 'Location';

  @override
  String get status => 'Status';

  @override
  String get startTimeColumn => 'Start Time';

  @override
  String get endTimeColumn => 'End Time';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get settings => 'Settings';

  @override
  String get workers => 'Workers';

  @override
  String get operations => 'Operations';

  @override
  String get locations => 'Locations';

  @override
  String get report => 'Report';

  @override
  String get locationManagement => 'Location Management';

  @override
  String get addLocation => 'Add Location';

  @override
  String get editLocation => 'Edit Location';

  @override
  String get deleteLocation => 'Delete Location';

  @override
  String get locationName => 'Location Name';

  @override
  String get pleaseEnterLocationName => 'Please enter a location name';

  @override
  String get failedToSaveLocation =>
      'Failed to save location. Please try again.';

  @override
  String get failedToDeleteLocation =>
      'Failed to delete location. Please try again.';

  @override
  String get noLocationsCreated => 'No locations created yet';

  @override
  String get tapToAddLocation => 'Tap the button below to add a location';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteLocation =>
      'Are you sure you want to delete this location?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get operationTypeManagement => 'Operation Type Management';

  @override
  String get addOperationType => 'Add Operation Type';

  @override
  String get editOperationType => 'Edit Operation Type';

  @override
  String get operationTypeName => 'Operation Type Name';

  @override
  String get pleaseEnterOperationTypeName =>
      'Please enter an operation type name';

  @override
  String get failedToSaveOperationType =>
      'Failed to save operation type. Please try again.';

  @override
  String get failedToDeleteOperationType =>
      'Failed to delete operation type. Please try again.';

  @override
  String get noOperationTypesCreated => 'No operation types created yet';

  @override
  String get tapToAddOperationType =>
      'Tap the button below to add an operation type';

  @override
  String get confirmDeleteOperationType =>
      'Are you sure you want to delete this operation type?';

  @override
  String get reportScreen => 'Activity Report';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get filterByMonth => 'Filter by month';

  @override
  String get noCallsForPeriod => 'No calls found for this period';

  @override
  String get allCalls => 'All Calls';

  @override
  String get duration => 'Duration';

  @override
  String get minutes => 'min';

  @override
  String get hours => 'h';

  @override
  String get workerManagement => 'Worker Management';

  @override
  String get addWorker => 'Add Worker';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterFullName => 'Please enter a full name';

  @override
  String get creatingWorker => 'Creating worker account...';

  @override
  String get workerCreatedSuccess =>
      'Worker account created and credentials sent to their email';

  @override
  String get failedToCreateWorker =>
      'Failed to create worker account. Please try again.';

  @override
  String get confirmDeleteWorker =>
      'Are you sure you want to deactivate this worker account?';

  @override
  String get failedToDeactivateWorker =>
      'Failed to deactivate worker. Please try again.';

  @override
  String get noWorkersFound => 'No workers found for this branch';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get emailAlreadyExists =>
      'An account with this email address already exists.';

  @override
  String get adminDashboard => 'Manager Management';

  @override
  String get addManager => 'Add Manager';

  @override
  String get selectBranch => 'Select Branch';

  @override
  String get pleaseSelectBranch => 'Please select a branch';

  @override
  String get creatingManager => 'Creating manager account...';

  @override
  String get managerCreatedSuccess =>
      'Manager account created and credentials sent to their email';

  @override
  String get failedToCreateManager =>
      'Failed to create manager account. Please try again.';

  @override
  String get confirmDeleteManager =>
      'Are you sure you want to deactivate this manager account?';

  @override
  String get failedToDeactivateManager =>
      'Failed to deactivate manager. Please try again.';

  @override
  String get noManagersFound => 'No managers found';

  @override
  String get managerManagement => 'Manager Management';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get loggedInAs => 'Logged in as';

  @override
  String get navigate => 'Navigate';

  @override
  String get arrived => 'Arrived';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get callDetails => 'Call Details';

  @override
  String get arrivedAt => 'Arrived at';

  @override
  String get callStatus => 'Status';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusArrived => 'Arrived';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusClosed => 'Closed';

  @override
  String get notes => 'Notes';

  @override
  String get noNotes => 'No notes';

  @override
  String get sendCall => 'Send Call';

  @override
  String get sendCallTitle => 'Assign Call to Worker';

  @override
  String get selectWorker => 'Select Worker';

  @override
  String get pleaseSelectWorker => 'Please select a worker';

  @override
  String get managerInstructions => 'Instructions (optional)';

  @override
  String get callAssignedSuccess => 'Call assigned successfully';

  @override
  String get failedToAssignCall => 'Failed to assign call. Please try again.';

  @override
  String get clientsAndLocations => 'Clients & Locations';

  @override
  String get clients => 'Clients';

  @override
  String get addClient => 'Add Client';

  @override
  String get editClient => 'Edit Client';

  @override
  String get clientName => 'Client Name';

  @override
  String get pleaseEnterClientName => 'Please enter a client name';

  @override
  String get failedToSaveClient => 'Failed to save client. Please try again.';

  @override
  String get failedToDeleteClient =>
      'Failed to delete client. Please try again.';

  @override
  String get noClientsCreated => 'No clients created yet';

  @override
  String get tapToAddClient => 'Tap the button below to add a client';

  @override
  String get confirmDeleteClient =>
      'Are you sure you want to delete this client?';

  @override
  String get selectClient => 'Select Client';

  @override
  String get pleaseSelectClient => 'Please select a client';

  @override
  String get noLocationsForClient => 'No locations for this client yet';

  @override
  String get client => 'Client';

  @override
  String get filterByClient => 'Client';

  @override
  String get filterByLocation => 'Location';

  @override
  String get filterByEmployee => 'Employee';

  @override
  String get allClients => 'All Clients';

  @override
  String get allLocations => 'All Locations';

  @override
  String get allEmployees => 'All Employees';

  @override
  String get clearFilters => 'Clear';

  @override
  String get monthView => 'Month';

  @override
  String get yearView => 'Year (CSV)';

  @override
  String get exportYear => 'Export Year';

  @override
  String get callClosedSuccess => 'Call closed successfully';

  @override
  String get managersTab => 'Managers';

  @override
  String get branchesTab => 'Branches';

  @override
  String get addBranch => 'Add Branch';

  @override
  String get editBranch => 'Edit Branch';

  @override
  String get branchName => 'Branch Name';

  @override
  String get pleaseEnterBranchName => 'Please enter a branch name';

  @override
  String get failedToSaveBranch => 'Failed to save branch. Please try again.';

  @override
  String get failedToDeleteBranch =>
      'Failed to deactivate branch. Please try again.';

  @override
  String get noBranchesCreated => 'No branches created yet';

  @override
  String get confirmDeleteBranch =>
      'Are you sure you want to deactivate this branch? It will no longer be available when creating managers.';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get addNote => 'Add Note';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get noteText => 'Note';

  @override
  String get pleaseEnterNote => 'Please enter a note';

  @override
  String get confirmDeleteNote => 'Delete this note? This cannot be undone.';

  @override
  String get failedToSaveNote => 'Failed to save note. Please try again.';

  @override
  String get failedToDeleteNote => 'Failed to delete note. Please try again.';

  @override
  String get formEditorTitleAdd => 'Add Operation Type';

  @override
  String get formEditorTitleEdit => 'Edit Operation Type';

  @override
  String get formOperationName => 'Operation Name';

  @override
  String get formPleaseEnterName => 'Please enter an operation name';

  @override
  String get formNotesSection => 'Notes';

  @override
  String get formSignatureSection => 'Signature';

  @override
  String get formChecklistSection => 'Checklist';

  @override
  String get formShowOnCloseScreen => 'Show on the close call screen';

  @override
  String get formMandatory => 'Mandatory';

  @override
  String get formPreview => 'Worker preview';

  @override
  String get formSignatureHint => 'Signature';

  @override
  String get formAddSingleCheck => 'Add single check';

  @override
  String get formAddCheckList => 'Add check list';

  @override
  String get formAddCheck => 'Add check';

  @override
  String get formCheckName => 'Check name';

  @override
  String get formCheckListTitle => 'Check list title';

  @override
  String get formPleaseEnterText => 'Please enter a name';

  @override
  String get formEdit => 'Edit';

  @override
  String get formNoChecksYet => 'No checks added yet';

  @override
  String get formChecklistEmpty =>
      'Add at least one check, or turn the checklist off';

  @override
  String get formGroupEmpty => 'Every check list needs at least one check';

  @override
  String get formFailedToSave =>
      'Failed to save operation type. Please try again.';

  @override
  String get closeNotesRequired => 'Please add notes before closing this call';

  @override
  String get endTimeBeforeStartTime =>
      'End time can\'t be before the start time';

  @override
  String get timeCannotBeInFuture => 'Time can\'t be in the future';

  @override
  String get roleManager => 'Manager';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get yearExportHint =>
      'Click Export CSV to download the full year report';

  @override
  String get address => 'Address';

  @override
  String get pleaseSelectAddress =>
      'Please select an address from the suggestions';

  @override
  String selectedAddressLabel(String address) {
    return 'Selected: $address';
  }

  @override
  String get failedToLoadBranches =>
      'Failed to load branches. Please try again.';

  @override
  String get managerInstructionsTitle => 'Manager instructions';

  @override
  String get formSortAZ => 'Sort A–Z';

  @override
  String get formCopyFrom => 'Copy form from another operation type';

  @override
  String get formCopyFromTitle => 'Copy the form from…';

  @override
  String get formCopyReplaceConfirm =>
      'This replaces the checklist you\'ve built so far. Continue?';

  @override
  String get formCopy => 'Copy';

  @override
  String get formCopyLoadFailed =>
      'Couldn\'t load operation types. Please try again.';

  @override
  String formCopiedFrom(String name) {
    return 'Form copied from $name';
  }

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordInfo =>
      'Enter your email and we\'ll send you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetLinkSent =>
      'If an account exists for this email, we\'ve sent a password reset link. Check your inbox (and spam folder).';

  @override
  String get resetLinkFailed =>
      'Couldn\'t send the reset email. Please try again later.';

  @override
  String get resetTooManyRequests =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get couldNotOpenLink =>
      'Couldn\'t open the link. Check your internet connection and try again.';
}
