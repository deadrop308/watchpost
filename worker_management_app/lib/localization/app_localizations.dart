import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Worker Management'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get invalidEmailOrPassword;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @noOpenCalls.
  ///
  /// In en, this message translates to:
  /// **'No open calls'**
  String get noOpenCalls;

  /// No description provided for @tapBelowToOpenCall.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to open a new call'**
  String get tapBelowToOpenCall;

  /// No description provided for @tapToCloseCall.
  ///
  /// In en, this message translates to:
  /// **'Tap to close call'**
  String get tapToCloseCall;

  /// No description provided for @openCall.
  ///
  /// In en, this message translates to:
  /// **'Open Call'**
  String get openCall;

  /// No description provided for @openNewCall.
  ///
  /// In en, this message translates to:
  /// **'Open New Call'**
  String get openNewCall;

  /// No description provided for @operationType.
  ///
  /// In en, this message translates to:
  /// **'Operation Type'**
  String get operationType;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @failedToOpenCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to open call. Please try again.'**
  String get failedToOpenCall;

  /// No description provided for @pleaseSelectOperationType.
  ///
  /// In en, this message translates to:
  /// **'Please select an operation type'**
  String get pleaseSelectOperationType;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectLocation;

  /// No description provided for @noOperationTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No operation types available for your branch. Please contact your manager.'**
  String get noOperationTypesAvailable;

  /// No description provided for @noLocationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No locations available for your branch. Please contact your manager.'**
  String get noLocationsAvailable;

  /// No description provided for @closeCall.
  ///
  /// In en, this message translates to:
  /// **'Close Call'**
  String get closeCall;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @signBelow.
  ///
  /// In en, this message translates to:
  /// **'Please sign below to confirm the completion of this call'**
  String get signBelow;

  /// No description provided for @clearSignature.
  ///
  /// In en, this message translates to:
  /// **'Clear Signature'**
  String get clearSignature;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @pleaseProvideSignature.
  ///
  /// In en, this message translates to:
  /// **'Please provide a signature before closing the call'**
  String get pleaseProvideSignature;

  /// No description provided for @failedToCloseCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to close call. Please try again.'**
  String get failedToCloseCall;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @todaysActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get todaysActivity;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(String name);

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloUser(String name);

  /// No description provided for @noCallsRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'No calls recorded today'**
  String get noCallsRecordedToday;

  /// No description provided for @errorLoadingCalls.
  ///
  /// In en, this message translates to:
  /// **'Error loading calls'**
  String get errorLoadingCalls;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operation;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @startTimeColumn.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeColumn;

  /// No description provided for @endTimeColumn.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeColumn;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operations;

  /// No description provided for @locations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locations;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @locationManagement.
  ///
  /// In en, this message translates to:
  /// **'Location Management'**
  String get locationManagement;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @editLocation.
  ///
  /// In en, this message translates to:
  /// **'Edit Location'**
  String get editLocation;

  /// No description provided for @deleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Delete Location'**
  String get deleteLocation;

  /// No description provided for @locationName.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get locationName;

  /// No description provided for @pleaseEnterLocationName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location name'**
  String get pleaseEnterLocationName;

  /// No description provided for @failedToSaveLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to save location. Please try again.'**
  String get failedToSaveLocation;

  /// No description provided for @failedToDeleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete location. Please try again.'**
  String get failedToDeleteLocation;

  /// No description provided for @noLocationsCreated.
  ///
  /// In en, this message translates to:
  /// **'No locations created yet'**
  String get noLocationsCreated;

  /// No description provided for @tapToAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add a location'**
  String get tapToAddLocation;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteLocation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this location?'**
  String get confirmDeleteLocation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @operationTypeManagement.
  ///
  /// In en, this message translates to:
  /// **'Operation Type Management'**
  String get operationTypeManagement;

  /// No description provided for @addOperationType.
  ///
  /// In en, this message translates to:
  /// **'Add Operation Type'**
  String get addOperationType;

  /// No description provided for @editOperationType.
  ///
  /// In en, this message translates to:
  /// **'Edit Operation Type'**
  String get editOperationType;

  /// No description provided for @operationTypeName.
  ///
  /// In en, this message translates to:
  /// **'Operation Type Name'**
  String get operationTypeName;

  /// No description provided for @pleaseEnterOperationTypeName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an operation type name'**
  String get pleaseEnterOperationTypeName;

  /// No description provided for @failedToSaveOperationType.
  ///
  /// In en, this message translates to:
  /// **'Failed to save operation type. Please try again.'**
  String get failedToSaveOperationType;

  /// No description provided for @failedToDeleteOperationType.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete operation type. Please try again.'**
  String get failedToDeleteOperationType;

  /// No description provided for @noOperationTypesCreated.
  ///
  /// In en, this message translates to:
  /// **'No operation types created yet'**
  String get noOperationTypesCreated;

  /// No description provided for @tapToAddOperationType.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add an operation type'**
  String get tapToAddOperationType;

  /// No description provided for @confirmDeleteOperationType.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this operation type?'**
  String get confirmDeleteOperationType;

  /// No description provided for @reportScreen.
  ///
  /// In en, this message translates to:
  /// **'Activity Report'**
  String get reportScreen;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @filterByMonth.
  ///
  /// In en, this message translates to:
  /// **'Filter by month'**
  String get filterByMonth;

  /// No description provided for @noCallsForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No calls found for this period'**
  String get noCallsForPeriod;

  /// No description provided for @allCalls.
  ///
  /// In en, this message translates to:
  /// **'All Calls'**
  String get allCalls;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @workerManagement.
  ///
  /// In en, this message translates to:
  /// **'Worker Management'**
  String get workerManagement;

  /// No description provided for @addWorker.
  ///
  /// In en, this message translates to:
  /// **'Add Worker'**
  String get addWorker;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a full name'**
  String get pleaseEnterFullName;

  /// No description provided for @creatingWorker.
  ///
  /// In en, this message translates to:
  /// **'Creating worker account...'**
  String get creatingWorker;

  /// No description provided for @workerCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Worker account created and credentials sent to their email'**
  String get workerCreatedSuccess;

  /// No description provided for @failedToCreateWorker.
  ///
  /// In en, this message translates to:
  /// **'Failed to create worker account. Please try again.'**
  String get failedToCreateWorker;

  /// No description provided for @confirmDeleteWorker.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this worker account?'**
  String get confirmDeleteWorker;

  /// No description provided for @failedToDeactivateWorker.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate worker. Please try again.'**
  String get failedToDeactivateWorker;

  /// No description provided for @noWorkersFound.
  ///
  /// In en, this message translates to:
  /// **'No workers found for this branch'**
  String get noWorkersFound;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email address already exists.'**
  String get emailAlreadyExists;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Manager Management'**
  String get adminDashboard;

  /// No description provided for @addManager.
  ///
  /// In en, this message translates to:
  /// **'Add Manager'**
  String get addManager;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select Branch'**
  String get selectBranch;

  /// No description provided for @pleaseSelectBranch.
  ///
  /// In en, this message translates to:
  /// **'Please select a branch'**
  String get pleaseSelectBranch;

  /// No description provided for @creatingManager.
  ///
  /// In en, this message translates to:
  /// **'Creating manager account...'**
  String get creatingManager;

  /// No description provided for @managerCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Manager account created and credentials sent to their email'**
  String get managerCreatedSuccess;

  /// No description provided for @failedToCreateManager.
  ///
  /// In en, this message translates to:
  /// **'Failed to create manager account. Please try again.'**
  String get failedToCreateManager;

  /// No description provided for @confirmDeleteManager.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this manager account?'**
  String get confirmDeleteManager;

  /// No description provided for @failedToDeactivateManager.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate manager. Please try again.'**
  String get failedToDeactivateManager;

  /// No description provided for @noManagersFound.
  ///
  /// In en, this message translates to:
  /// **'No managers found'**
  String get noManagersFound;

  /// No description provided for @managerManagement.
  ///
  /// In en, this message translates to:
  /// **'Manager Management'**
  String get managerManagement;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @loggedInAs.
  ///
  /// In en, this message translates to:
  /// **'Logged in as'**
  String get loggedInAs;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @callDetails.
  ///
  /// In en, this message translates to:
  /// **'Call Details'**
  String get callDetails;

  /// No description provided for @arrivedAt.
  ///
  /// In en, this message translates to:
  /// **'Arrived at'**
  String get arrivedAt;

  /// No description provided for @callStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get callStatus;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get statusArrived;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @sendCall.
  ///
  /// In en, this message translates to:
  /// **'Send Call'**
  String get sendCall;

  /// No description provided for @sendCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Call to Worker'**
  String get sendCallTitle;

  /// No description provided for @selectWorker.
  ///
  /// In en, this message translates to:
  /// **'Select Worker'**
  String get selectWorker;

  /// No description provided for @pleaseSelectWorker.
  ///
  /// In en, this message translates to:
  /// **'Please select a worker'**
  String get pleaseSelectWorker;

  /// No description provided for @managerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions (optional)'**
  String get managerInstructions;

  /// No description provided for @callAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Call assigned successfully'**
  String get callAssignedSuccess;

  /// No description provided for @failedToAssignCall.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign call. Please try again.'**
  String get failedToAssignCall;

  /// No description provided for @clientsAndLocations.
  ///
  /// In en, this message translates to:
  /// **'Clients & Locations'**
  String get clientsAndLocations;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @addClient.
  ///
  /// In en, this message translates to:
  /// **'Add Client'**
  String get addClient;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @pleaseEnterClientName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a client name'**
  String get pleaseEnterClientName;

  /// No description provided for @failedToSaveClient.
  ///
  /// In en, this message translates to:
  /// **'Failed to save client. Please try again.'**
  String get failedToSaveClient;

  /// No description provided for @failedToDeleteClient.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete client. Please try again.'**
  String get failedToDeleteClient;

  /// No description provided for @noClientsCreated.
  ///
  /// In en, this message translates to:
  /// **'No clients created yet'**
  String get noClientsCreated;

  /// No description provided for @tapToAddClient.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add a client'**
  String get tapToAddClient;

  /// No description provided for @confirmDeleteClient.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this client?'**
  String get confirmDeleteClient;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get selectClient;

  /// No description provided for @pleaseSelectClient.
  ///
  /// In en, this message translates to:
  /// **'Please select a client'**
  String get pleaseSelectClient;

  /// No description provided for @noLocationsForClient.
  ///
  /// In en, this message translates to:
  /// **'No locations for this client yet'**
  String get noLocationsForClient;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @filterByClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get filterByClient;

  /// No description provided for @filterByLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get filterByLocation;

  /// No description provided for @filterByEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get filterByEmployee;

  /// No description provided for @allClients.
  ///
  /// In en, this message translates to:
  /// **'All Clients'**
  String get allClients;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @allEmployees.
  ///
  /// In en, this message translates to:
  /// **'All Employees'**
  String get allEmployees;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearFilters;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthView;

  /// No description provided for @yearView.
  ///
  /// In en, this message translates to:
  /// **'Year (CSV)'**
  String get yearView;

  /// No description provided for @exportYear.
  ///
  /// In en, this message translates to:
  /// **'Export Year'**
  String get exportYear;

  /// No description provided for @callClosedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Call closed successfully'**
  String get callClosedSuccess;

  /// No description provided for @managersTab.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get managersTab;

  /// No description provided for @branchesTab.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTab;

  /// No description provided for @addBranch.
  ///
  /// In en, this message translates to:
  /// **'Add Branch'**
  String get addBranch;

  /// No description provided for @editBranch.
  ///
  /// In en, this message translates to:
  /// **'Edit Branch'**
  String get editBranch;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchName;

  /// No description provided for @pleaseEnterBranchName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a branch name'**
  String get pleaseEnterBranchName;

  /// No description provided for @failedToSaveBranch.
  ///
  /// In en, this message translates to:
  /// **'Failed to save branch. Please try again.'**
  String get failedToSaveBranch;

  /// No description provided for @failedToDeleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate branch. Please try again.'**
  String get failedToDeleteBranch;

  /// No description provided for @noBranchesCreated.
  ///
  /// In en, this message translates to:
  /// **'No branches created yet'**
  String get noBranchesCreated;

  /// No description provided for @confirmDeleteBranch.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this branch? It will no longer be available when creating managers.'**
  String get confirmDeleteBranch;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteText;

  /// No description provided for @pleaseEnterNote.
  ///
  /// In en, this message translates to:
  /// **'Please enter a note'**
  String get pleaseEnterNote;

  /// No description provided for @confirmDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete this note? This cannot be undone.'**
  String get confirmDeleteNote;

  /// No description provided for @failedToSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to save note. Please try again.'**
  String get failedToSaveNote;

  /// No description provided for @failedToDeleteNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete note. Please try again.'**
  String get failedToDeleteNote;

  /// No description provided for @formEditorTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Operation Type'**
  String get formEditorTitleAdd;

  /// No description provided for @formEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Operation Type'**
  String get formEditorTitleEdit;

  /// No description provided for @formOperationName.
  ///
  /// In en, this message translates to:
  /// **'Operation Name'**
  String get formOperationName;

  /// No description provided for @formPleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an operation name'**
  String get formPleaseEnterName;

  /// No description provided for @formNotesSection.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get formNotesSection;

  /// No description provided for @formSignatureSection.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get formSignatureSection;

  /// No description provided for @formChecklistSection.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get formChecklistSection;

  /// No description provided for @formShowOnCloseScreen.
  ///
  /// In en, this message translates to:
  /// **'Show on the close call screen'**
  String get formShowOnCloseScreen;

  /// No description provided for @formMandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory'**
  String get formMandatory;

  /// No description provided for @formPreview.
  ///
  /// In en, this message translates to:
  /// **'Worker preview'**
  String get formPreview;

  /// No description provided for @formSignatureHint.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get formSignatureHint;

  /// No description provided for @formAddSingleCheck.
  ///
  /// In en, this message translates to:
  /// **'Add single check'**
  String get formAddSingleCheck;

  /// No description provided for @formAddCheckList.
  ///
  /// In en, this message translates to:
  /// **'Add check list'**
  String get formAddCheckList;

  /// No description provided for @formAddCheck.
  ///
  /// In en, this message translates to:
  /// **'Add check'**
  String get formAddCheck;

  /// No description provided for @formCheckName.
  ///
  /// In en, this message translates to:
  /// **'Check name'**
  String get formCheckName;

  /// No description provided for @formCheckListTitle.
  ///
  /// In en, this message translates to:
  /// **'Check list title'**
  String get formCheckListTitle;

  /// No description provided for @formPleaseEnterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get formPleaseEnterText;

  /// No description provided for @formEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get formEdit;

  /// No description provided for @formNoChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No checks added yet'**
  String get formNoChecksYet;

  /// No description provided for @formChecklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add at least one check, or turn the checklist off'**
  String get formChecklistEmpty;

  /// No description provided for @formGroupEmpty.
  ///
  /// In en, this message translates to:
  /// **'Every check list needs at least one check'**
  String get formGroupEmpty;

  /// No description provided for @formFailedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save operation type. Please try again.'**
  String get formFailedToSave;

  /// No description provided for @closeNotesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add notes before closing this call'**
  String get closeNotesRequired;

  /// No description provided for @endTimeBeforeStartTime.
  ///
  /// In en, this message translates to:
  /// **'End time can\'t be before the start time'**
  String get endTimeBeforeStartTime;

  /// No description provided for @timeCannotBeInFuture.
  ///
  /// In en, this message translates to:
  /// **'Time can\'t be in the future'**
  String get timeCannotBeInFuture;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @yearExportHint.
  ///
  /// In en, this message translates to:
  /// **'Click Export CSV to download the full year report'**
  String get yearExportHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @pleaseSelectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select an address from the suggestions'**
  String get pleaseSelectAddress;

  /// No description provided for @selectedAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected: {address}'**
  String selectedAddressLabel(String address);

  /// No description provided for @failedToLoadBranches.
  ///
  /// In en, this message translates to:
  /// **'Failed to load branches. Please try again.'**
  String get failedToLoadBranches;

  /// No description provided for @managerInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager instructions'**
  String get managerInstructionsTitle;

  /// No description provided for @formSortAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort A–Z'**
  String get formSortAZ;

  /// No description provided for @formCopyFrom.
  ///
  /// In en, this message translates to:
  /// **'Copy form from another operation type'**
  String get formCopyFrom;

  /// No description provided for @formCopyFromTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the form from…'**
  String get formCopyFromTitle;

  /// No description provided for @formCopyReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'This replaces the checklist you\'ve built so far. Continue?'**
  String get formCopyReplaceConfirm;

  /// No description provided for @formCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get formCopy;

  /// No description provided for @formCopyLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load operation types. Please try again.'**
  String get formCopyLoadFailed;

  /// No description provided for @formCopiedFrom.
  ///
  /// In en, this message translates to:
  /// **'Form copied from {name}'**
  String formCopiedFrom(String name);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to choose a new password.'**
  String get resetPasswordInfo;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we\'ve sent a password reset link. Check your inbox (and spam folder).'**
  String get resetLinkSent;

  /// No description provided for @resetLinkFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the reset email. Please try again later.'**
  String get resetLinkFailed;

  /// No description provided for @resetTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get resetTooManyRequests;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link. Check your internet connection and try again.'**
  String get couldNotOpenLink;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
