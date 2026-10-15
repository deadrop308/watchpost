// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'ניהול עובדים';

  @override
  String get signIn => 'התחברות';

  @override
  String get signInToAccount => 'התחבר לחשבון שלך';

  @override
  String get emailAddress => 'כתובת אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get invalidEmailOrPassword => 'אימייל או סיסמה שגויים. נסה שוב.';

  @override
  String get pleaseEnterEmail => 'נא להזין כתובת אימייל';

  @override
  String get pleaseEnterValidEmail => 'נא להזין כתובת אימייל תקינה';

  @override
  String get pleaseEnterPassword => 'נא להזין סיסמה';

  @override
  String get noOpenCalls => 'אין קריאות פתוחות';

  @override
  String get tapBelowToOpenCall => 'לחץ על הכפתור למטה כדי לפתוח קריאה חדשה';

  @override
  String get tapToCloseCall => 'לחץ לסגירת קריאה';

  @override
  String get openCall => 'פתח קריאה';

  @override
  String get openNewCall => 'פתח קריאה חדשה';

  @override
  String get operationType => 'סוג פעולה';

  @override
  String get selectLocation => 'בחר מיקום';

  @override
  String get startTime => 'זמן התחלה';

  @override
  String get failedToOpenCall => 'פתיחת הקריאה נכשלה. נסה שוב.';

  @override
  String get pleaseSelectOperationType => 'נא לבחור סוג פעולה';

  @override
  String get pleaseSelectLocation => 'נא לבחור מיקום';

  @override
  String get noOperationTypesAvailable =>
      'אין סוגי פעולות זמינים לסניף שלך. פנה למנהל.';

  @override
  String get noLocationsAvailable => 'אין מיקומים זמינים לסניף שלך. פנה למנהל.';

  @override
  String get closeCall => 'סגור קריאה';

  @override
  String get signature => 'חתימה';

  @override
  String get signBelow => 'נא לחתום למטה כדי לאשר את סיום הקריאה';

  @override
  String get clearSignature => 'נקה חתימה';

  @override
  String get endTime => 'זמן סיום';

  @override
  String get pleaseProvideSignature => 'נא לספק חתימה לפני סגירת הקריאה';

  @override
  String get failedToCloseCall => 'סגירת הקריאה נכשלה. נסה שוב.';

  @override
  String get started => 'התחיל';

  @override
  String get todaysActivity => 'פעילות היום';

  @override
  String welcomeUser(String name) {
    return 'ברוך הבא, $name';
  }

  @override
  String helloUser(String name) {
    return 'שלום, $name';
  }

  @override
  String get noCallsRecordedToday => 'לא נרשמו קריאות היום';

  @override
  String get errorLoadingCalls => 'שגיאה בטעינת קריאות';

  @override
  String get worker => 'עובד';

  @override
  String get operation => 'פעולה';

  @override
  String get location => 'מיקום';

  @override
  String get status => 'סטטוס';

  @override
  String get startTimeColumn => 'זמן התחלה';

  @override
  String get endTimeColumn => 'זמן סיום';

  @override
  String get open => 'פתוח';

  @override
  String get closed => 'סגור';

  @override
  String get settings => 'הגדרות';

  @override
  String get workers => 'עובדים';

  @override
  String get operations => 'פעולות';

  @override
  String get locations => 'מיקומים';

  @override
  String get report => 'דוח';

  @override
  String get locationManagement => 'ניהול מיקומים';

  @override
  String get addLocation => 'הוסף מיקום';

  @override
  String get editLocation => 'ערוך מיקום';

  @override
  String get deleteLocation => 'מחק מיקום';

  @override
  String get locationName => 'שם מיקום';

  @override
  String get pleaseEnterLocationName => 'נא להזין שם מיקום';

  @override
  String get failedToSaveLocation => 'שמירת המיקום נכשלה. נסה שוב.';

  @override
  String get failedToDeleteLocation => 'מחיקת המיקום נכשלה. נסה שוב.';

  @override
  String get noLocationsCreated => 'לא נוצרו מיקומים עדיין';

  @override
  String get tapToAddLocation => 'לחץ על הכפתור למטה להוספת מיקום';

  @override
  String get confirmDelete => 'אשר מחיקה';

  @override
  String get confirmDeleteLocation => 'האם אתה בטוח שברצונך למחוק מיקום זה?';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחק';

  @override
  String get save => 'שמור';

  @override
  String get operationTypeManagement => 'ניהול סוגי פעולות';

  @override
  String get addOperationType => 'הוסף סוג פעולה';

  @override
  String get editOperationType => 'ערוך סוג פעולה';

  @override
  String get operationTypeName => 'שם סוג פעולה';

  @override
  String get pleaseEnterOperationTypeName => 'נא להזין שם סוג פעולה';

  @override
  String get failedToSaveOperationType => 'שמירת סוג הפעולה נכשלה. נסה שוב.';

  @override
  String get failedToDeleteOperationType => 'מחיקת סוג הפעולה נכשלה. נסה שוב.';

  @override
  String get noOperationTypesCreated => 'לא נוצרו סוגי פעולות עדיין';

  @override
  String get tapToAddOperationType => 'לחץ על הכפתור למטה להוספת סוג פעולה';

  @override
  String get confirmDeleteOperationType =>
      'האם אתה בטוח שברצונך למחוק סוג פעולה זה?';

  @override
  String get reportScreen => 'דוח פעילות';

  @override
  String get exportCsv => 'ייצא CSV';

  @override
  String get filterByMonth => 'סנן לפי חודש';

  @override
  String get noCallsForPeriod => 'לא נמצאו קריאות לתקופה זו';

  @override
  String get allCalls => 'כל הקריאות';

  @override
  String get duration => 'משך';

  @override
  String get minutes => 'דק\'';

  @override
  String get hours => 'ש\'';

  @override
  String get workerManagement => 'ניהול עובדים';

  @override
  String get addWorker => 'הוסף עובד';

  @override
  String get fullName => 'שם מלא';

  @override
  String get pleaseEnterFullName => 'נא להזין שם מלא';

  @override
  String get creatingWorker => 'יוצר חשבון עובד...';

  @override
  String get workerCreatedSuccess =>
      'חשבון העובד נוצר ופרטי ההתחברות נשלחו לאימייל שלו';

  @override
  String get failedToCreateWorker => 'יצירת חשבון העובד נכשלה. נסה שוב.';

  @override
  String get confirmDeleteWorker =>
      'האם אתה בטוח שברצונך לבטל את חשבון העובד הזה?';

  @override
  String get failedToDeactivateWorker => 'ביטול העובד נכשל. נסה שוב.';

  @override
  String get noWorkersFound => 'לא נמצאו עובדים לסניף זה';

  @override
  String get deactivate => 'בטל';

  @override
  String get emailAlreadyExists => 'חשבון עם כתובת אימייל זו כבר קיים.';

  @override
  String get adminDashboard => 'ניהול מנהלים';

  @override
  String get addManager => 'הוסף מנהל';

  @override
  String get selectBranch => 'בחר סניף';

  @override
  String get pleaseSelectBranch => 'נא לבחור סניף';

  @override
  String get creatingManager => 'יוצר חשבון מנהל...';

  @override
  String get managerCreatedSuccess =>
      'חשבון המנהל נוצר ופרטי ההתחברות נשלחו לאימייל שלו';

  @override
  String get failedToCreateManager => 'יצירת חשבון המנהל נכשלה. נסה שוב.';

  @override
  String get confirmDeleteManager =>
      'האם אתה בטוח שברצונך לבטל את חשבון המנהל הזה?';

  @override
  String get failedToDeactivateManager => 'ביטול המנהל נכשל. נסה שוב.';

  @override
  String get noManagersFound => 'לא נמצאו מנהלים';

  @override
  String get managerManagement => 'ניהול מנהלים';

  @override
  String get language => 'שפה';

  @override
  String get english => 'אנגלית';

  @override
  String get hebrew => 'עברית';

  @override
  String get darkMode => 'מצב לילה';

  @override
  String get logout => 'התנתק';

  @override
  String get logoutConfirm => 'האם אתה בטוח שברצונך להתנתק?';

  @override
  String get loggedInAs => 'מחובר כ';

  @override
  String get navigate => 'נווט';

  @override
  String get arrived => 'הגעתי';

  @override
  String get pause => 'השהה';

  @override
  String get resume => 'המשך';

  @override
  String get callDetails => 'פרטי קריאה';

  @override
  String get arrivedAt => 'הגיע בשעה';

  @override
  String get callStatus => 'סטטוס';

  @override
  String get statusOpen => 'פתוח';

  @override
  String get statusArrived => 'הגיע';

  @override
  String get statusPaused => 'מושהה';

  @override
  String get statusClosed => 'סגור';

  @override
  String get notes => 'הערות';

  @override
  String get noNotes => 'אין הערות';

  @override
  String get sendCall => 'שלח קריאה';

  @override
  String get sendCallTitle => 'הקצה קריאה לעובד';

  @override
  String get selectWorker => 'בחר עובד';

  @override
  String get pleaseSelectWorker => 'נא לבחור עובד';

  @override
  String get managerInstructions => 'הוראות (אופציונלי)';

  @override
  String get callAssignedSuccess => 'הקריאה הוקצתה בהצלחה';

  @override
  String get failedToAssignCall => 'הקצאת הקריאה נכשלה. נסה שוב.';

  @override
  String get clientsAndLocations => 'לקוחות ומיקומים';

  @override
  String get clients => 'לקוחות';

  @override
  String get addClient => 'הוסף לקוח';

  @override
  String get editClient => 'ערוך לקוח';

  @override
  String get clientName => 'שם לקוח';

  @override
  String get pleaseEnterClientName => 'נא להזין שם לקוח';

  @override
  String get failedToSaveClient => 'שמירת הלקוח נכשלה. נסה שוב.';

  @override
  String get failedToDeleteClient => 'מחיקת הלקוח נכשלה. נסה שוב.';

  @override
  String get noClientsCreated => 'לא נוצרו לקוחות עדיין';

  @override
  String get tapToAddClient => 'לחץ על הכפתור למטה להוספת לקוח';

  @override
  String get confirmDeleteClient => 'האם אתה בטוח שברצונך למחוק לקוח זה?';

  @override
  String get selectClient => 'בחר לקוח';

  @override
  String get pleaseSelectClient => 'נא לבחור לקוח';

  @override
  String get noLocationsForClient => 'אין מיקומים ללקוח זה עדיין';

  @override
  String get client => 'לקוח';

  @override
  String get filterByClient => 'לקוח';

  @override
  String get filterByLocation => 'מיקום';

  @override
  String get filterByEmployee => 'עובד';

  @override
  String get allClients => 'כל הלקוחות';

  @override
  String get allLocations => 'כל המיקומים';

  @override
  String get allEmployees => 'כל העובדים';

  @override
  String get clearFilters => 'נקה';

  @override
  String get monthView => 'חודש';

  @override
  String get yearView => 'שנה (CSV)';

  @override
  String get exportYear => 'ייצא שנה';

  @override
  String get callClosedSuccess => 'הקריאה נסגרה בהצלחה';

  @override
  String get managersTab => 'מנהלים';

  @override
  String get branchesTab => 'סניפים';

  @override
  String get addBranch => 'הוסף סניף';

  @override
  String get editBranch => 'ערוך סניף';

  @override
  String get branchName => 'שם סניף';

  @override
  String get pleaseEnterBranchName => 'נא להזין שם סניף';

  @override
  String get failedToSaveBranch => 'שמירת הסניף נכשלה. נסה שוב.';

  @override
  String get failedToDeleteBranch => 'ביטול הסניף נכשל. נסה שוב.';

  @override
  String get noBranchesCreated => 'לא נוצרו סניפים עדיין';

  @override
  String get confirmDeleteBranch =>
      'האם אתה בטוח שברצונך לבטל סניף זה? הוא לא יהיה זמין יותר ביצירת מנהלים.';

  @override
  String get adminPanel => 'ניהול מערכת';

  @override
  String get addNote => 'הוסף הערה';

  @override
  String get noNotesYet => 'אין הערות עדיין';

  @override
  String get noteText => 'הערה';

  @override
  String get pleaseEnterNote => 'נא להזין הערה';

  @override
  String get confirmDeleteNote => 'למחוק את ההערה? לא ניתן לבטל פעולה זו.';

  @override
  String get failedToSaveNote => 'שמירת ההערה נכשלה. נסה שוב.';

  @override
  String get failedToDeleteNote => 'מחיקת ההערה נכשלה. נסה שוב.';

  @override
  String get formEditorTitleAdd => 'הוסף סוג פעולה';

  @override
  String get formEditorTitleEdit => 'ערוך סוג פעולה';

  @override
  String get formOperationName => 'שם הפעולה';

  @override
  String get formPleaseEnterName => 'נא להזין שם פעולה';

  @override
  String get formNotesSection => 'הערות';

  @override
  String get formSignatureSection => 'חתימה';

  @override
  String get formChecklistSection => 'רשימת בדיקה';

  @override
  String get formShowOnCloseScreen => 'הצג במסך סגירת הקריאה';

  @override
  String get formMandatory => 'חובה';

  @override
  String get formPreview => 'תצוגה מקדימה לעובד';

  @override
  String get formSignatureHint => 'חתימה';

  @override
  String get formAddSingleCheck => 'הוסף בדיקה בודדת';

  @override
  String get formAddCheckList => 'הוסף רשימת בדיקה';

  @override
  String get formAddCheck => 'הוסף בדיקה';

  @override
  String get formCheckName => 'שם הבדיקה';

  @override
  String get formCheckListTitle => 'כותרת הרשימה';

  @override
  String get formPleaseEnterText => 'נא להזין שם';

  @override
  String get formEdit => 'ערוך';

  @override
  String get formNoChecksYet => 'לא נוספו בדיקות עדיין';

  @override
  String get formChecklistEmpty =>
      'הוסף לפחות בדיקה אחת, או כבה את רשימת הבדיקה';

  @override
  String get formGroupEmpty => 'כל רשימת בדיקה צריכה לפחות בדיקה אחת';

  @override
  String get formFailedToSave => 'שמירת סוג הפעולה נכשלה. נסה שוב.';

  @override
  String get closeNotesRequired => 'נא להוסיף הערות לפני סגירת הקריאה';

  @override
  String get endTimeBeforeStartTime =>
      'שעת הסיום לא יכולה להיות לפני שעת ההתחלה';

  @override
  String get timeCannotBeInFuture => 'הזמן לא יכול להיות בעתיד';

  @override
  String get roleManager => 'מנהל';

  @override
  String get selectMonth => 'בחר חודש';

  @override
  String get yearExportHint => 'לחץ על ייצוא CSV כדי להוריד את הדוח השנתי המלא';

  @override
  String get address => 'כתובת';

  @override
  String get pleaseSelectAddress => 'נא לבחור כתובת מתוך ההצעות';

  @override
  String selectedAddressLabel(String address) {
    return 'נבחר: $address';
  }

  @override
  String get failedToLoadBranches => 'טעינת הסניפים נכשלה. נסה שוב.';

  @override
  String get managerInstructionsTitle => 'הוראות מנהל';

  @override
  String get formSortAZ => 'מיון א–ת';

  @override
  String get formCopyFrom => 'העתק טופס מסוג פעולה אחר';

  @override
  String get formCopyFromTitle => 'העתק את הטופס מ…';

  @override
  String get formCopyReplaceConfirm =>
      'פעולה זו תחליף את רשימת הבדיקה שבנית עד עכשיו. להמשיך?';

  @override
  String get formCopy => 'העתק';

  @override
  String get formCopyLoadFailed => 'טעינת סוגי הפעולה נכשלה. נסה שוב.';

  @override
  String formCopiedFrom(String name) {
    return 'הטופס הועתק מ־$name';
  }

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get resetPasswordTitle => 'איפוס סיסמה';

  @override
  String get resetPasswordInfo =>
      'הזן את כתובת האימייל שלך ונשלח לך קישור לבחירת סיסמה חדשה.';

  @override
  String get sendResetLink => 'שלח קישור';

  @override
  String get resetLinkSent =>
      'אם קיים חשבון עם האימייל הזה, שלחנו אליו קישור לאיפוס הסיסמה. בדוק את תיבת הדואר (וגם את תיקיית הספאם).';

  @override
  String get resetLinkFailed => 'שליחת האימייל נכשלה. נסה שוב מאוחר יותר.';

  @override
  String get resetTooManyRequests =>
      'יותר מדי ניסיונות. המתן כמה דקות ונסה שוב.';

  @override
  String get privacyPolicy => 'מדיניות פרטיות';

  @override
  String get couldNotOpenLink =>
      'לא ניתן לפתוח את הקישור. בדקו את החיבור לאינטרנט ונסו שוב.';
}
