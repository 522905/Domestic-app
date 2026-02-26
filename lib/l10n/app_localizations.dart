import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LPG Distribution'**
  String get appTitle;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'High Importance Notifications'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'This channel is used for important notifications.'**
  String get notificationChannelDescription;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh Profile'**
  String get profileRefresh;

  /// No description provided for @profileMoreOptionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get profileMoreOptionsTooltip;

  /// No description provided for @profileLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get profileLoading;

  /// No description provided for @profileAccountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get profileAccountInformation;

  /// No description provided for @profileCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get profileCompanyLabel;

  /// No description provided for @profileAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountLabel;

  /// No description provided for @profileWarehouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get profileWarehouseLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileRolesLabel.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get profileRolesLabel;

  /// No description provided for @profileNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get profileNotAssigned;

  /// No description provided for @profileContactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get profileContactInformation;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileVehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get profileVehicleInformation;

  /// No description provided for @profileVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get profileVehicleNumber;

  /// No description provided for @profileAppInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get profileAppInformation;

  /// No description provided for @profileCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get profileCurrentVersion;

  /// No description provided for @profileRequiredUpdate.
  ///
  /// In en, this message translates to:
  /// **'Required update - Tap to install'**
  String get profileRequiredUpdate;

  /// No description provided for @profileRecommendedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Recommended update available'**
  String get profileRecommendedUpdate;

  /// No description provided for @profileInformUpdate.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get profileInformUpdate;

  /// No description provided for @profileBecomePartner.
  ///
  /// In en, this message translates to:
  /// **'BECOME PARTNER'**
  String get profileBecomePartner;

  /// No description provided for @profileEditPassword.
  ///
  /// In en, this message translates to:
  /// **'EDIT PASSWORD'**
  String get profileEditPassword;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'LOGOUT'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account? You will need to login again to access the app.'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileLogoutConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get profileLogoutConfirmCancel;

  /// No description provided for @profileLogoutConfirmProceed.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogoutConfirmProceed;

  /// No description provided for @profileCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String profileCopyTooltip(Object label);

  /// No description provided for @profileCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String profileCopyMessage(Object label);

  /// No description provided for @profileVersionPrefix.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersionPrefix(Object version);

  /// No description provided for @profileActionSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Options'**
  String get profileActionSheetTitle;

  /// No description provided for @profileActionEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileActionEditProfileTitle;

  /// No description provided for @profileActionEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get profileActionEditProfileSubtitle;

  /// No description provided for @profileActionSwitchCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Company'**
  String get profileActionSwitchCompanyTitle;

  /// No description provided for @profileActionSwitchCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change your active company'**
  String get profileActionSwitchCompanySubtitle;

  /// No description provided for @profileActionChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get profileActionChangePasswordTitle;

  /// No description provided for @profileActionChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your security credentials'**
  String get profileActionChangePasswordSubtitle;

  /// No description provided for @profileActionChangePasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Change password feature coming soon'**
  String get profileActionChangePasswordMessage;

  /// No description provided for @profileActionNotificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get profileActionNotificationSettingsTitle;

  /// No description provided for @profileActionNotificationSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get profileActionNotificationSettingsSubtitle;

  /// No description provided for @profileActionNotificationSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification settings feature coming soon'**
  String get profileActionNotificationSettingsMessage;

  /// No description provided for @profileActionHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileActionHelpTitle;

  /// No description provided for @profileActionHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get assistance and support'**
  String get profileActionHelpSubtitle;

  /// No description provided for @profileActionHelpMessage.
  ///
  /// In en, this message translates to:
  /// **'Help & support feature coming soon'**
  String get profileActionHelpMessage;

  /// No description provided for @profileActionLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileActionLogoutTitle;

  /// No description provided for @profileActionLogoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from your account'**
  String get profileActionLogoutSubtitle;

  /// No description provided for @profileCompanySwitcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Company'**
  String get profileCompanySwitcherTitle;

  /// No description provided for @profileCompanySwitcherActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get profileCompanySwitcherActive;

  /// No description provided for @profileCompanyCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String profileCompanyCode(Object code);

  /// No description provided for @profileCompanySwitchButton.
  ///
  /// In en, this message translates to:
  /// **'SWITCH'**
  String get profileCompanySwitchButton;

  /// No description provided for @profileSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch company: {error}'**
  String profileSwitchFailed(Object error);

  /// No description provided for @profileCompaniesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load companies: {error}'**
  String profileCompaniesLoadFailed(Object error);

  /// No description provided for @profileErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String profileErrorLoading(Object error);

  /// No description provided for @profileOptionalDataError.
  ///
  /// In en, this message translates to:
  /// **'Optional user data not available: {error}'**
  String profileOptionalDataError(Object error);

  /// No description provided for @profileLogoutError.
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String profileLogoutError(Object error);

  /// No description provided for @profileNavigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation error: {error}'**
  String profileNavigationError(Object error);

  /// No description provided for @profileVersionUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed: {error}'**
  String profileVersionUpdateFailed(Object error);

  /// No description provided for @profileSwitchingTo.
  ///
  /// In en, this message translates to:
  /// **'Switching to:'**
  String get profileSwitchingTo;

  /// No description provided for @profileActiveCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileActiveCompanyLabel;

  /// No description provided for @profileLanguageToggle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguageToggle;

  /// No description provided for @profileLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageEnglish;

  /// No description provided for @profileLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get profileLanguageHindi;

  /// No description provided for @errorUnableToGetDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Unable to get download URL'**
  String get errorUnableToGetDownloadUrl;

  /// No description provided for @errorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String errorDownloadFailed(Object error);

  /// No description provided for @errorEnterUsernamePassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both username and password'**
  String get errorEnterUsernamePassword;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get errorLoginFailed;

  /// No description provided for @errorAppUpdateRequired.
  ///
  /// In en, this message translates to:
  /// **'App update required. Please download the latest version.'**
  String get errorAppUpdateRequired;

  /// No description provided for @errorConnectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please try again.'**
  String get errorConnectionTimeout;

  /// No description provided for @errorNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get errorNoInternetConnection;

  /// No description provided for @errorDownloadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get errorDownloadFailedTitle;

  /// No description provided for @errorDownloadUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download update. Please try again or download from website.'**
  String get errorDownloadUpdateFailed;

  /// No description provided for @buttonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get buttonOk;

  /// No description provided for @companyArunGasServices.
  ///
  /// In en, this message translates to:
  /// **'Arun Gas Services'**
  String get companyArunGasServices;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToYourAccount;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get labelUsername;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @linkForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get linkForgotPassword;

  /// No description provided for @linkSignUpForNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign Up for New Account'**
  String get linkSignUpForNewAccount;

  /// No description provided for @buttonLogin.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get buttonLogin;

  /// No description provided for @errorNoUserRoleAssigned.
  ///
  /// In en, this message translates to:
  /// **'No User Role Assigned'**
  String get errorNoUserRoleAssigned;

  /// No description provided for @errorContactAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Please contact administrator.'**
  String get errorContactAdministrator;

  /// No description provided for @linkBecomePartner.
  ///
  /// In en, this message translates to:
  /// **'Become a Partner'**
  String get linkBecomePartner;

  /// No description provided for @linkContinuePartnerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Continue to Partner Registration'**
  String get linkContinuePartnerRegistration;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get navCash;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh Dashboard'**
  String get dashboardRefreshTooltip;

  /// No description provided for @dashboardLoadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get dashboardLoadingLabel;

  /// No description provided for @dashboardRefreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dashboard refreshed'**
  String get dashboardRefreshSuccess;

  /// No description provided for @dashboardRefreshFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh dashboard'**
  String get dashboardRefreshFailure;

  /// No description provided for @dashboardUserLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user information'**
  String get dashboardUserLoadFailure;

  /// No description provided for @dashboardDataLoadFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard data'**
  String get dashboardDataLoadFailure;

  /// No description provided for @dashboardGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGreetingMorning;

  /// No description provided for @dashboardGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGreetingAfternoon;

  /// No description provided for @dashboardGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGreetingEvening;

  /// No description provided for @dashboardUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get dashboardUserFallback;

  /// No description provided for @dashboardGreetingMessage.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}!'**
  String dashboardGreetingMessage(Object greeting, Object name);

  /// No description provided for @dashboardRoleWithCompany.
  ///
  /// In en, this message translates to:
  /// **'{roles} ({company})'**
  String dashboardRoleWithCompany(Object company, Object roles);

  /// No description provided for @dashboardPendingApprovalSingle.
  ///
  /// In en, this message translates to:
  /// **'{count} pending approval'**
  String dashboardPendingApprovalSingle(Object count);

  /// No description provided for @dashboardPendingApprovalsMultiple.
  ///
  /// In en, this message translates to:
  /// **'{count} pending approvals'**
  String dashboardPendingApprovalsMultiple(Object count);

  /// No description provided for @dashboardQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActionsTitle;

  /// No description provided for @dashboardCreateOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get dashboardCreateOrderTitle;

  /// No description provided for @dashboardCreateOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New sale order'**
  String get dashboardCreateOrderSubtitle;

  /// No description provided for @dashboardCashDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Deposit'**
  String get dashboardCashDepositTitle;

  /// No description provided for @dashboardCashDepositSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit collections'**
  String get dashboardCashDepositSubtitle;

  /// No description provided for @dashboardChallanTitle.
  ///
  /// In en, this message translates to:
  /// **'Challan'**
  String get dashboardChallanTitle;

  /// No description provided for @dashboardChallanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a challan'**
  String get dashboardChallanSubtitle;

  /// No description provided for @dashboardDepositItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit Items'**
  String get dashboardDepositItemsTitle;

  /// No description provided for @dashboardDepositItemsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Return inventory'**
  String get dashboardDepositItemsSubtitle;

  /// No description provided for @dashboardInventoryManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get dashboardInventoryManagementTitle;

  /// No description provided for @dashboardProcurementTitle.
  ///
  /// In en, this message translates to:
  /// **'Procurement (Purchase Invoice)'**
  String get dashboardProcurementTitle;

  /// No description provided for @dashboardProcurementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle in/out records'**
  String get dashboardProcurementSubtitle;

  /// No description provided for @dashboardInventoryApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Approvals'**
  String get dashboardInventoryApprovalsTitle;

  /// No description provided for @dashboardInventoryApprovalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending requests'**
  String get dashboardInventoryApprovalsSubtitle;

  /// No description provided for @dashboardCashManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Management'**
  String get dashboardCashManagementTitle;

  /// No description provided for @dashboardCashApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Approvals'**
  String get dashboardCashApprovalsTitle;

  /// No description provided for @dashboardCashApprovalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review pending deposits'**
  String get dashboardCashApprovalsSubtitle;

  /// No description provided for @dashboardCustomerSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Support'**
  String get dashboardCustomerSupportTitle;

  /// No description provided for @dashboardOpenTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get dashboardOpenTicketsTitle;

  /// No description provided for @dashboardOpenTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customer support requests'**
  String get dashboardOpenTicketsSubtitle;

  /// No description provided for @dashboardResolvedTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved Today'**
  String get dashboardResolvedTodayLabel;

  /// No description provided for @dashboardAverageResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get dashboardAverageResponseLabel;

  /// No description provided for @dashboardSystemOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get dashboardSystemOverviewTitle;

  /// No description provided for @dashboardTodaysOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get dashboardTodaysOrdersLabel;

  /// No description provided for @dashboardActiveUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get dashboardActiveUsersLabel;

  /// No description provided for @dashboardAllApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Approvals'**
  String get dashboardAllApprovalsTitle;

  /// No description provided for @dashboardGettingStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get dashboardGettingStartedTitle;

  /// No description provided for @dashboardViewProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get dashboardViewProfileTitle;

  /// No description provided for @dashboardViewProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get dashboardViewProfileSubtitle;

  /// No description provided for @dashboardStatusClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dashboardStatusClear;

  /// No description provided for @dashboardInventoryPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} items need approval'**
  String dashboardInventoryPendingSubtitle(Object count);

  /// No description provided for @dashboardCashPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} deposits need approval'**
  String dashboardCashPendingSubtitle(Object count);

  /// No description provided for @dashboardOrderApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Approvals'**
  String get dashboardOrderApprovalsTitle;

  /// No description provided for @dashboardOrdersPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} orders need approval'**
  String dashboardOrdersPendingSubtitle(Object count);

  /// No description provided for @dashboardCseTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'CSE Tickets'**
  String get dashboardCseTicketsTitle;

  /// No description provided for @dashboardTicketsPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} tickets need attention'**
  String dashboardTicketsPendingSubtitle(Object count);

  /// No description provided for @dashboardNoPendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'No pending notifications'**
  String get dashboardNoPendingNotifications;

  /// No description provided for @dashboardNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotificationsTitle;

  /// No description provided for @dashboardPendingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String dashboardPendingCountLabel(Object count);

  /// No description provided for @dashboardOrderApprovalsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Order approvals feature coming soon'**
  String get dashboardOrderApprovalsComingSoon;

  /// No description provided for @dashboardCseTicketsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'CSE tickets feature coming soon'**
  String get dashboardCseTicketsComingSoon;

  /// No description provided for @dashboardNewApprovalPending.
  ///
  /// In en, this message translates to:
  /// **'New {module} approval pending'**
  String dashboardNewApprovalPending(Object module);

  /// No description provided for @dashboardModuleInventory.
  ///
  /// In en, this message translates to:
  /// **'inventory'**
  String get dashboardModuleInventory;

  /// No description provided for @dashboardModuleCash.
  ///
  /// In en, this message translates to:
  /// **'cash'**
  String get dashboardModuleCash;

  /// No description provided for @dashboardModuleOrders.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get dashboardModuleOrders;

  /// No description provided for @dashboardModuleCse.
  ///
  /// In en, this message translates to:
  /// **'customer support'**
  String get dashboardModuleCse;

  /// No description provided for @dashboardRoleDeliveryBoy.
  ///
  /// In en, this message translates to:
  /// **'Delivery Boy'**
  String get dashboardRoleDeliveryBoy;

  /// No description provided for @dashboardRoleWarehouseManager.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Manager'**
  String get dashboardRoleWarehouseManager;

  /// No description provided for @dashboardRoleGeneralManager.
  ///
  /// In en, this message translates to:
  /// **'General Manager'**
  String get dashboardRoleGeneralManager;

  /// No description provided for @dashboardRoleCustomerServiceExecutive.
  ///
  /// In en, this message translates to:
  /// **'Customer Service Executive'**
  String get dashboardRoleCustomerServiceExecutive;

  /// No description provided for @dashboardRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get dashboardRoleCashier;

  /// No description provided for @dashboardAdditionalRoles.
  ///
  /// In en, this message translates to:
  /// **'{firstRole} + {remainingCount} more'**
  String dashboardAdditionalRoles(Object firstRole, Object remainingCount);

  /// No description provided for @dashboardRolesSeparator.
  ///
  /// In en, this message translates to:
  /// **' & '**
  String get dashboardRolesSeparator;

  /// No description provided for @buttonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// No description provided for @buttonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get buttonApprove;

  /// No description provided for @buttonReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get buttonReject;

  /// No description provided for @buttonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// No description provided for @buttonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get buttonSubmit;

  /// No description provided for @buttonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get buttonDelete;

  /// No description provided for @buttonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get buttonEdit;

  /// No description provided for @buttonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get buttonAdd;

  /// No description provided for @buttonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get buttonRemove;

  /// No description provided for @buttonChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get buttonChange;

  /// No description provided for @buttonRefresh.
  ///
  /// In en, this message translates to:
  /// **'REFRESH'**
  String get buttonRefresh;

  /// No description provided for @buttonCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get buttonCreateNew;

  /// No description provided for @buttonCreateAnother.
  ///
  /// In en, this message translates to:
  /// **'Create Another'**
  String get buttonCreateAnother;

  /// No description provided for @buttonBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to List'**
  String get buttonBackToList;

  /// No description provided for @buttonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get buttonTryAgain;

  /// No description provided for @buttonClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get buttonClearAll;

  /// No description provided for @buttonClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get buttonClearFilters;

  /// No description provided for @buttonUseOrderId.
  ///
  /// In en, this message translates to:
  /// **'Use This Order ID'**
  String get buttonUseOrderId;

  /// No description provided for @buttonScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get buttonScanAgain;

  /// No description provided for @dialogErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get dialogErrorTitle;

  /// No description provided for @dialogSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get dialogSuccessTitle;

  /// No description provided for @dialogConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirmTitle;

  /// No description provided for @dialogWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get dialogWarningTitle;

  /// No description provided for @dialogInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get dialogInfoTitle;

  /// No description provided for @dialogOptionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dialogOptionAll;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @tableHeaderAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get tableHeaderAccount;

  /// No description provided for @tableHeaderLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get tableHeaderLedger;

  /// No description provided for @tableHeaderOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tableHeaderOpen;

  /// No description provided for @tableHeaderAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get tableHeaderAvailable;

  /// No description provided for @loadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get loadingPleaseWait;

  /// No description provided for @loadingSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get loadingSearching;

  /// No description provided for @loadingSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get loadingSubmitting;

  /// No description provided for @loadingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLoading;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number / Username'**
  String get loginUsernameHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get loginButton;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginSignUpButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Up for New Account'**
  String get loginSignUpButtonLabel;

  /// No description provided for @forgotPasswordScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotPasswordScreenTitle;

  /// No description provided for @forgotPasswordAadharLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhar Number'**
  String get forgotPasswordAadharLabel;

  /// No description provided for @forgotPasswordOtpLabel.
  ///
  /// In en, this message translates to:
  /// **'6-Digit OTP'**
  String get forgotPasswordOtpLabel;

  /// No description provided for @forgotPasswordNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get forgotPasswordNewPasswordLabel;

  /// No description provided for @forgotPasswordConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get forgotPasswordConfirmPasswordLabel;

  /// No description provided for @signUpAadharLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhar Number'**
  String get signUpAadharLabel;

  /// No description provided for @signUpPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get signUpPhoneLabel;

  /// No description provided for @signUpAadharRequired.
  ///
  /// In en, this message translates to:
  /// **'Aadhar number is required'**
  String get signUpAadharRequired;

  /// No description provided for @signUpAadharInvalid.
  ///
  /// In en, this message translates to:
  /// **'Aadhar must be exactly 12 digits'**
  String get signUpAadharInvalid;

  /// No description provided for @signUpAadharChecksum.
  ///
  /// In en, this message translates to:
  /// **'Invalid Aadhar number'**
  String get signUpAadharChecksum;

  /// No description provided for @signUpPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get signUpPhoneRequired;

  /// No description provided for @signUpPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be exactly 10 digits'**
  String get signUpPhoneInvalid;

  /// No description provided for @passwordChangeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get passwordChangeScreenTitle;

  /// No description provided for @passwordChangeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get passwordChangeSectionTitle;

  /// No description provided for @passwordChangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password to keep your account secure'**
  String get passwordChangeSubtitle;

  /// No description provided for @passwordChangeCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get passwordChangeCurrentLabel;

  /// No description provided for @passwordChangeCurrentHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get passwordChangeCurrentHint;

  /// No description provided for @passwordChangeNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get passwordChangeNewLabel;

  /// No description provided for @passwordChangeNewHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get passwordChangeNewHint;

  /// No description provided for @passwordChangeConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get passwordChangeConfirmLabel;

  /// No description provided for @passwordChangeConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get passwordChangeConfirmHint;

  /// No description provided for @buttonChangingPassword.
  ///
  /// In en, this message translates to:
  /// **'CHANGING...'**
  String get buttonChangingPassword;

  /// No description provided for @buttonChangePassword.
  ///
  /// In en, this message translates to:
  /// **'CHANGE PASSWORD'**
  String get buttonChangePassword;

  /// No description provided for @passwordChangeCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get passwordChangeCurrentRequired;

  /// No description provided for @passwordChangeNewRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get passwordChangeNewRequired;

  /// No description provided for @passwordChangeNewMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordChangeNewMinLength;

  /// No description provided for @passwordChangeNewDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordChangeNewDifferent;

  /// No description provided for @passwordChangeConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get passwordChangeConfirmRequired;

  /// No description provided for @passwordChangeConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'New Password does not match with Confirm Password'**
  String get passwordChangeConfirmMismatch;

  /// No description provided for @panVerificationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Become Partner'**
  String get panVerificationScreenTitle;

  /// No description provided for @panVerificationHeading.
  ///
  /// In en, this message translates to:
  /// **'Partner Registration'**
  String get panVerificationHeading;

  /// No description provided for @panVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your PAN number to begin the partner verification process'**
  String get panVerificationSubtitle;

  /// No description provided for @panNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get panNumberLabel;

  /// No description provided for @panNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter PAN (e.g., AZJPG7110R)'**
  String get panNumberHint;

  /// No description provided for @panNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'PAN number is required'**
  String get panNumberRequired;

  /// No description provided for @panNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid PAN format. Use: AAAAA9999A'**
  String get panNumberInvalid;

  /// No description provided for @cashPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Management'**
  String get cashPageTitle;

  /// No description provided for @cashSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, name, reference...'**
  String get cashSearchHint;

  /// No description provided for @cashLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading cash data'**
  String get cashLoadingError;

  /// No description provided for @cashAccountBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Balances'**
  String get cashAccountBalancesTitle;

  /// No description provided for @cashDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Data not available'**
  String get cashDataNotAvailable;

  /// No description provided for @cashPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh'**
  String get cashPullToRefresh;

  /// No description provided for @cashNoAccountData.
  ///
  /// In en, this message translates to:
  /// **'No account data available'**
  String get cashNoAccountData;

  /// No description provided for @cashAccountDefault.
  ///
  /// In en, this message translates to:
  /// **'Cash Account'**
  String get cashAccountDefault;

  /// No description provided for @cashViewTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'View Transaction History'**
  String get cashViewTransactionHistory;

  /// No description provided for @cashDepositActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash Deposit'**
  String get cashDepositActionTitle;

  /// No description provided for @cashDepositActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit cash to Manager'**
  String get cashDepositActionSubtitle;

  /// No description provided for @cashHandoverActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Handover Cash'**
  String get cashHandoverActionTitle;

  /// No description provided for @cashHandoverActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handover cash to Manager'**
  String get cashHandoverActionSubtitle;

  /// No description provided for @cashBankDepositActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Deposit'**
  String get cashBankDepositActionTitle;

  /// No description provided for @cashBankDepositActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit cash directly to bank'**
  String get cashBankDepositActionSubtitle;

  /// No description provided for @cashDepositAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get cashDepositAmountHint;

  /// No description provided for @cashDepositAccountSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select Account Paid To'**
  String get cashDepositAccountSelectHint;

  /// No description provided for @cashDepositRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any remarks or notes'**
  String get cashDepositRemarksHint;

  /// No description provided for @handoverAccountSelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select Account for Handover'**
  String get handoverAccountSelectHint;

  /// No description provided for @handoverAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get handoverAmountHint;

  /// No description provided for @handoverRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any remarks or notes'**
  String get handoverRemarksHint;

  /// No description provided for @bankDepositAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get bankDepositAmountHint;

  /// No description provided for @bankDepositReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter receipt or reference number'**
  String get bankDepositReferenceHint;

  /// No description provided for @bankDepositRemarksHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any remarks or notes'**
  String get bankDepositRemarksHint;

  /// No description provided for @transactionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetailsTitle;

  /// No description provided for @transactionApproving.
  ///
  /// In en, this message translates to:
  /// **'Approving transaction...'**
  String get transactionApproving;

  /// No description provided for @transactionRejecting.
  ///
  /// In en, this message translates to:
  /// **'Rejecting transaction...'**
  String get transactionRejecting;

  /// No description provided for @rejectionReasonIncorrectAmount.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Amount'**
  String get rejectionReasonIncorrectAmount;

  /// No description provided for @rejectionReasonAmountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Cash Amount Mismatch'**
  String get rejectionReasonAmountMismatch;

  /// No description provided for @rejectionReasonMissingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Missing Receipt'**
  String get rejectionReasonMissingReceipt;

  /// No description provided for @rejectionReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get rejectionReasonOther;

  /// No description provided for @transactionCommentsHint.
  ///
  /// In en, this message translates to:
  /// **'Additional Comments (Optional)'**
  String get transactionCommentsHint;

  /// No description provided for @buttonVerifyCashReceived.
  ///
  /// In en, this message translates to:
  /// **'VERIFY CASH RECEIVED'**
  String get buttonVerifyCashReceived;

  /// No description provided for @dialogReceiptImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt Image'**
  String get dialogReceiptImageTitle;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get imageLoadError;

  /// No description provided for @dialogBankDepositSlipTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank Deposit Slip'**
  String get dialogBankDepositSlipTitle;

  /// No description provided for @inventoryPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryPageTitle;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Requests...'**
  String get inventorySearchHint;

  /// No description provided for @inventoryDepositUnlinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit Inventory (Unlinked)'**
  String get inventoryDepositUnlinkedTitle;

  /// No description provided for @inventoryDepositUnlinkedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit items for warehouse'**
  String get inventoryDepositUnlinkedSubtitle;

  /// No description provided for @inventoryDepositSaleOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit Inventory (Sale Order)'**
  String get inventoryDepositSaleOrderTitle;

  /// No description provided for @inventoryDepositSaleOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit items against sale orders'**
  String get inventoryDepositSaleOrderSubtitle;

  /// No description provided for @inventoryDepositMaterialRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit Inventory (Material Request)'**
  String get inventoryDepositMaterialRequestTitle;

  /// No description provided for @inventoryDepositMaterialRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit items against material requests'**
  String get inventoryDepositMaterialRequestSubtitle;

  /// No description provided for @inventoryCreateChallanTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Challan'**
  String get inventoryCreateChallanTitle;

  /// No description provided for @inventoryCreateChallanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a inventory challan'**
  String get inventoryCreateChallanSubtitle;

  /// No description provided for @inventoryTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory Transfer'**
  String get inventoryTransferTitle;

  /// No description provided for @inventoryTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer items to another warehouse'**
  String get inventoryTransferSubtitle;

  /// No description provided for @dialogRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get dialogRequestDetailsTitle;

  /// No description provided for @inventoryApproveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve {type}'**
  String inventoryApproveButton(Object type);

  /// No description provided for @inventoryApproveConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this {type} request?'**
  String inventoryApproveConfirmation(Object type);

  /// No description provided for @inventoryRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject {type}'**
  String inventoryRejectButton(Object type);

  /// No description provided for @inventorySelectRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a rejection reason:'**
  String get inventorySelectRejectionReason;

  /// No description provided for @buttonRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get buttonRejectAction;

  /// No description provided for @dialogFailedToLoadDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Data'**
  String get dialogFailedToLoadDataTitle;

  /// No description provided for @dialogSelectVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get dialogSelectVehicleTitle;

  /// No description provided for @dialogSelectWarehouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Warehouse'**
  String get dialogSelectWarehouseTitle;

  /// No description provided for @dialogSubmissionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission Failed'**
  String get dialogSubmissionFailedTitle;

  /// No description provided for @dialogFailedToLoadItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Pending Delivery Items'**
  String get dialogFailedToLoadItemsTitle;

  /// No description provided for @transferOriginWarehouseHint.
  ///
  /// In en, this message translates to:
  /// **'Select origin warehouse'**
  String get transferOriginWarehouseHint;

  /// No description provided for @transferDestinationWarehouseHint.
  ///
  /// In en, this message translates to:
  /// **'Select destination warehouse'**
  String get transferDestinationWarehouseHint;

  /// No description provided for @ordersPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersPageTitle;

  /// No description provided for @ordersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search orders...'**
  String get ordersSearchHint;

  /// No description provided for @ordersFilterDeliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get ordersFilterDeliveryStatus;

  /// No description provided for @ordersFilterVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get ordersFilterVehicle;

  /// No description provided for @ordersFilterWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get ordersFilterWarehouse;

  /// No description provided for @ordersFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ordersFilterStatus;

  /// No description provided for @dialogFailedToLoadWarehousesTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Warehouses'**
  String get dialogFailedToLoadWarehousesTitle;

  /// No description provided for @dialogFailedToLoadPartnersTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Partners'**
  String get dialogFailedToLoadPartnersTitle;

  /// No description provided for @dialogOrderCreationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Creation Failed'**
  String get dialogOrderCreationFailedTitle;

  /// No description provided for @orderTypeRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get orderTypeRefill;

  /// No description provided for @orderTypeNFR.
  ///
  /// In en, this message translates to:
  /// **'NFR'**
  String get orderTypeNFR;

  /// No description provided for @seedCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter Seed Code *'**
  String get seedCodeLabel;

  /// No description provided for @driverPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Phone Number'**
  String get driverPhoneLabel;

  /// No description provided for @driverNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver Name *'**
  String get driverNameLabel;

  /// No description provided for @driverSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching drivers...'**
  String get driverSearching;

  /// No description provided for @buttonCreateNewDriver.
  ///
  /// In en, this message translates to:
  /// **'Create New Driver'**
  String get buttonCreateNewDriver;

  /// No description provided for @dialogSelectDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Driver'**
  String get dialogSelectDriverTitle;

  /// No description provided for @dialogSelectItemsToDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Items to Dispatch'**
  String get dialogSelectItemsToDispatchTitle;

  /// No description provided for @noItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No items available'**
  String get noItemsAvailable;

  /// No description provided for @sdmsCreateTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Create SDMS Transaction'**
  String get sdmsCreateTransactionTitle;

  /// No description provided for @sdmsNoUserCode.
  ///
  /// In en, this message translates to:
  /// **'No SDMS User Code'**
  String get sdmsNoUserCode;

  /// No description provided for @sdmsOnlyPaymentAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only Credit Payment transactions are available'**
  String get sdmsOnlyPaymentAvailable;

  /// No description provided for @sdmsOrderIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter sales order ID'**
  String get sdmsOrderIdHint;

  /// No description provided for @sdmsOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales Order ID *'**
  String get sdmsOrderIdLabel;

  /// No description provided for @sdmsCreateTransactionLabel.
  ///
  /// In en, this message translates to:
  /// **'Create Transaction'**
  String get sdmsCreateTransactionLabel;

  /// No description provided for @sdmsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by Order ID'**
  String get sdmsSearchHint;

  /// No description provided for @reportsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsPageTitle;

  /// No description provided for @warehouseStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Stock'**
  String get warehouseStockTitle;

  /// No description provided for @warehouseStockDetails.
  ///
  /// In en, this message translates to:
  /// **'Stock Details'**
  String get warehouseStockDetails;

  /// No description provided for @warehouseStockAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get warehouseStockAvailable;

  /// No description provided for @warehouseStockReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get warehouseStockReserved;

  /// No description provided for @warehouseStockProjected.
  ///
  /// In en, this message translates to:
  /// **'Projected'**
  String get warehouseStockProjected;

  /// No description provided for @warehouseStockMergedFrom.
  ///
  /// In en, this message translates to:
  /// **'Merged from {count} warehouses'**
  String warehouseStockMergedFrom(Object count);

  /// No description provided for @warehouseStockItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String warehouseStockItems(Object count);

  /// No description provided for @warehouseStockLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading stock data...'**
  String get warehouseStockLoading;

  /// No description provided for @warehouseStockError.
  ///
  /// In en, this message translates to:
  /// **'Error loading stock data'**
  String get warehouseStockError;

  /// No description provided for @warehouseStockNoData.
  ///
  /// In en, this message translates to:
  /// **'No stock data available'**
  String get warehouseStockNoData;

  /// No description provided for @warehouseStockSelectWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Select Warehouse'**
  String get warehouseStockSelectWarehouse;

  /// No description provided for @warehouseStockUnknownWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Unknown Warehouse'**
  String get warehouseStockUnknownWarehouse;

  /// No description provided for @warehouseStockUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get warehouseStockUnknownItem;

  /// No description provided for @ordersEmptyOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get ordersEmptyOrders;

  /// No description provided for @inventoryRequestDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get inventoryRequestDetailsTitle;

  /// No description provided for @inventoryFailedToLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load request details'**
  String get inventoryFailedToLoadDetails;

  /// No description provided for @inventoryRequestID.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get inventoryRequestID;

  /// No description provided for @inventoryRequestType.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get inventoryRequestType;

  /// No description provided for @inventoryCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get inventoryCreatedAt;

  /// No description provided for @inventoryRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get inventoryRejectionReason;

  /// No description provided for @inventoryNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get inventoryNotesLabel;

  /// No description provided for @inventoryTransferDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get inventoryTransferDetailsTitle;

  /// No description provided for @inventoryFromSource.
  ///
  /// In en, this message translates to:
  /// **'From (Source)'**
  String get inventoryFromSource;

  /// No description provided for @inventoryToDestination.
  ///
  /// In en, this message translates to:
  /// **'To (Destination)'**
  String get inventoryToDestination;

  /// No description provided for @inventoryUnknownWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Unknown Warehouse'**
  String get inventoryUnknownWarehouse;

  /// No description provided for @inventoryItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get inventoryItemsLabel;

  /// No description provided for @inventoryUnlinkedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get inventoryUnlinkedLabel;

  /// No description provided for @inventorySalesOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales Order'**
  String get inventorySalesOrderLabel;

  /// No description provided for @inventoryMaterialRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Material Request'**
  String get inventoryMaterialRequestLabel;

  /// No description provided for @inventoryItemDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get inventoryItemDetailsHeader;

  /// No description provided for @inventoryQtyHeader.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get inventoryQtyHeader;

  /// No description provided for @inventoryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get inventoryCodeLabel;

  /// No description provided for @inventoryDefectiveDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'DEFECTIVE DETAILS'**
  String get inventoryDefectiveDetailsLabel;

  /// No description provided for @inventoryCylinderNumber.
  ///
  /// In en, this message translates to:
  /// **'Cylinder number'**
  String get inventoryCylinderNumber;

  /// No description provided for @inventoryTareWeight.
  ///
  /// In en, this message translates to:
  /// **'Tare Wt'**
  String get inventoryTareWeight;

  /// No description provided for @inventoryGrossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Wt'**
  String get inventoryGrossWeight;

  /// No description provided for @inventoryNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Wt'**
  String get inventoryNetWeight;

  /// No description provided for @inventoryFaultType.
  ///
  /// In en, this message translates to:
  /// **'Fault'**
  String get inventoryFaultType;

  /// No description provided for @inventoryConsumerDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumer Details:'**
  String get inventoryConsumerDetailsLabel;

  /// No description provided for @inventoryConsumerNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get inventoryConsumerNumber;

  /// No description provided for @inventoryConsumerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventoryConsumerName;

  /// No description provided for @inventoryConsumerMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get inventoryConsumerMobile;

  /// No description provided for @inventoryRemarksLabel.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get inventoryRemarksLabel;

  /// No description provided for @inventoryAddCommentsHint.
  ///
  /// In en, this message translates to:
  /// **'Add comments for approval/rejection...'**
  String get inventoryAddCommentsHint;

  /// No description provided for @inventoryStatusApprovedMessage.
  ///
  /// In en, this message translates to:
  /// **'This {type} request has been approved'**
  String inventoryStatusApprovedMessage(Object type);

  /// No description provided for @inventoryStatusRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'This {type} request has been rejected'**
  String inventoryStatusRejectedMessage(Object type);

  /// No description provided for @inventoryStatusPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'This {type} request is pending approval'**
  String inventoryStatusPendingMessage(Object type);

  /// No description provided for @inventoryApproveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this {type} request?'**
  String inventoryApproveConfirmMessage(Object type);

  /// No description provided for @inventoryCancelRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get inventoryCancelRequestButton;

  /// No description provided for @rejectionReasonIncorrectCount.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Count'**
  String get rejectionReasonIncorrectCount;

  /// No description provided for @rejectionReasonWrongItems.
  ///
  /// In en, this message translates to:
  /// **'Wrong Items'**
  String get rejectionReasonWrongItems;

  /// No description provided for @rejectionReasonDepositProcessed.
  ///
  /// In en, this message translates to:
  /// **'Deposit Already Processed'**
  String get rejectionReasonDepositProcessed;

  /// No description provided for @rejectionReasonDefectiveMissing.
  ///
  /// In en, this message translates to:
  /// **'Defective item Missing'**
  String get rejectionReasonDefectiveMissing;

  /// No description provided for @rejectionReasonInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock'**
  String get rejectionReasonInsufficientStock;

  /// No description provided for @rejectionReasonOrdersNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Orders Not Eligible'**
  String get rejectionReasonOrdersNotEligible;

  /// No description provided for @rejectionReasonVehicleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Not Available'**
  String get rejectionReasonVehicleNotAvailable;

  /// No description provided for @rejectionReasonWarehouseClosed.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Closed'**
  String get rejectionReasonWarehouseClosed;

  /// No description provided for @rejectionReasonInsufficientStockSource.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock at Source'**
  String get rejectionReasonInsufficientStockSource;

  /// No description provided for @rejectionReasonDestinationFull.
  ///
  /// In en, this message translates to:
  /// **'Destination Warehouse Full'**
  String get rejectionReasonDestinationFull;

  /// No description provided for @rejectionReasonTransferBlocked.
  ///
  /// In en, this message translates to:
  /// **'Transfer Route Blocked'**
  String get rejectionReasonTransferBlocked;

  /// No description provided for @messagePleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait while processing...'**
  String get messagePleaseWait;

  /// No description provided for @labelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labelUnknown;

  /// No description provided for @labelID.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get labelID;

  /// No description provided for @depositTitle.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositTitle;

  /// No description provided for @depositTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get depositTypeLabel;

  /// No description provided for @depositSelectItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get depositSelectItemsTitle;

  /// No description provided for @depositBackToScreen.
  ///
  /// In en, this message translates to:
  /// **'Back to Deposit Screen'**
  String get depositBackToScreen;

  /// No description provided for @depositAddAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one item'**
  String get depositAddAtLeastOneItem;

  /// No description provided for @depositSelectWarehouseWarning.
  ///
  /// In en, this message translates to:
  /// **'Please select a warehouse'**
  String get depositSelectWarehouseWarning;

  /// No description provided for @depositSelectVehicleWarning.
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle'**
  String get depositSelectVehicleWarning;

  /// No description provided for @depositConfirmSubmitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this deposit request?'**
  String get depositConfirmSubmitMessage;

  /// No description provided for @buttonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// No description provided for @collectFailedToLoadItems.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Pending Delivery Items'**
  String get collectFailedToLoadItems;

  /// No description provided for @collectSelectDeliveryItems.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Items'**
  String get collectSelectDeliveryItems;

  /// No description provided for @collectSelectedItems.
  ///
  /// In en, this message translates to:
  /// **'Selected Items'**
  String get collectSelectedItems;

  /// No description provided for @collectAndMoreItems.
  ///
  /// In en, this message translates to:
  /// **'and {count} more items'**
  String collectAndMoreItems(int count);

  /// No description provided for @collectTotalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity:'**
  String get collectTotalQuantity;

  /// No description provided for @collectBackToChallan.
  ///
  /// In en, this message translates to:
  /// **'Back to Challan'**
  String get collectBackToChallan;

  /// No description provided for @collectCollectingFrom.
  ///
  /// In en, this message translates to:
  /// **'Collecting from:'**
  String get collectCollectingFrom;

  /// No description provided for @collectConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Collection'**
  String get collectConfirmTitle;

  /// No description provided for @collectConfirmSubmitMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this collection request?'**
  String get collectConfirmSubmitMessage;

  /// No description provided for @collectFromWarehouse.
  ///
  /// In en, this message translates to:
  /// **'From Warehouse'**
  String get collectFromWarehouse;

  /// No description provided for @depositUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get depositUnlinked;

  /// No description provided for @depositSalesOrder.
  ///
  /// In en, this message translates to:
  /// **'Sales Order'**
  String get depositSalesOrder;

  /// No description provided for @depositMaterialRequest.
  ///
  /// In en, this message translates to:
  /// **'Material Request'**
  String get depositMaterialRequest;

  /// No description provided for @inventoryRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by:'**
  String get inventoryRequestedBy;

  /// No description provided for @orderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get orderStatusLabel;

  /// No description provided for @inventoryVehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number:'**
  String get inventoryVehicleNumber;

  /// No description provided for @inventoryEmptyRequests.
  ///
  /// In en, this message translates to:
  /// **'No inventory requests'**
  String get inventoryEmptyRequests;

  /// No description provided for @notificationApprovalRequired.
  ///
  /// In en, this message translates to:
  /// **'Approval required'**
  String get notificationApprovalRequired;

  /// No description provided for @emptyStateCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your first item'**
  String get emptyStateCreateFirst;

  /// No description provided for @emptyStateTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get emptyStateTryAgain;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorGeneric;

  /// No description provided for @quotaHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quota History'**
  String get quotaHistoryTitle;

  /// No description provided for @stockReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Report'**
  String get stockReportTitle;

  /// No description provided for @quotaHistoryViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View Quota History'**
  String get quotaHistoryViewHistory;

  /// No description provided for @quotaHistoryLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get quotaHistoryLoading;

  /// No description provided for @quotaHistoryError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get quotaHistoryError;

  /// No description provided for @quotaHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history found for this period'**
  String get quotaHistoryEmpty;

  /// No description provided for @quotaHistoryLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get quotaHistoryLoadingMore;

  /// No description provided for @quotaHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get quotaHistoryRetry;

  /// No description provided for @quotaHistoryFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get quotaHistoryFilterTitle;

  /// No description provided for @quotaHistoryLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get quotaHistoryLast7Days;

  /// No description provided for @quotaHistoryLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get quotaHistoryLast30Days;

  /// No description provided for @quotaHistoryThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get quotaHistoryThisMonth;

  /// No description provided for @quotaHistoryLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get quotaHistoryLastMonth;

  /// No description provided for @quotaHistoryCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range...'**
  String get quotaHistoryCustomRange;

  /// No description provided for @quotaHistorySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get quotaHistorySummaryTitle;

  /// No description provided for @quotaHistoryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get quotaHistoryNet;

  /// No description provided for @quotaHistoryOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get quotaHistoryOtp;

  /// No description provided for @quotaHistoryOverride.
  ///
  /// In en, this message translates to:
  /// **'Override'**
  String get quotaHistoryOverride;

  /// No description provided for @quotaHistoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get quotaHistoryBonus;

  /// No description provided for @quotaHistoryPostingRatio.
  ///
  /// In en, this message translates to:
  /// **'Posting'**
  String get quotaHistoryPostingRatio;

  /// No description provided for @quotaHistoryAllItems.
  ///
  /// In en, this message translates to:
  /// **'All Items'**
  String get quotaHistoryAllItems;

  /// No description provided for @quotaHistoryNetPickup.
  ///
  /// In en, this message translates to:
  /// **'Net Pickup'**
  String get quotaHistoryNetPickup;

  /// No description provided for @quotaHistoryBlankSales.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get quotaHistoryBlankSales;

  /// No description provided for @quotaHistoryOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get quotaHistoryOpening;

  /// No description provided for @quotaHistoryClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get quotaHistoryClosing;

  /// No description provided for @quotaHistoryPickups.
  ///
  /// In en, this message translates to:
  /// **'Pickups'**
  String get quotaHistoryPickups;

  /// No description provided for @quotaHistoryReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get quotaHistoryReturns;

  /// No description provided for @quotaHistoryAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adj'**
  String get quotaHistoryAdjustment;

  /// No description provided for @quotaHistoryMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More Details'**
  String get quotaHistoryMoreDetails;

  /// No description provided for @quotaHistoryLessDetails.
  ///
  /// In en, this message translates to:
  /// **'Less Details'**
  String get quotaHistoryLessDetails;

  /// No description provided for @quotaHistorySdms.
  ///
  /// In en, this message translates to:
  /// **'SDMS'**
  String get quotaHistorySdms;

  /// No description provided for @quotaBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Summary'**
  String get quotaBonusTitle;

  /// No description provided for @quotaBonusTotalBonus.
  ///
  /// In en, this message translates to:
  /// **'Total Bonus'**
  String get quotaBonusTotalBonus;

  /// No description provided for @quotaBonusActiveCount.
  ///
  /// In en, this message translates to:
  /// **'Active Bonuses'**
  String get quotaBonusActiveCount;

  /// No description provided for @quotaBonusExpiryCountdown.
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} days'**
  String quotaBonusExpiryCountdown(Object days);

  /// No description provided for @quotaBonusExpiryWarning.
  ///
  /// In en, this message translates to:
  /// **'Bonus expiring soon!'**
  String get quotaBonusExpiryWarning;

  /// No description provided for @quotaBonusQualified.
  ///
  /// In en, this message translates to:
  /// **'Qualified'**
  String get quotaBonusQualified;

  /// No description provided for @quotaBonusNotQualified.
  ///
  /// In en, this message translates to:
  /// **'Not Qualified'**
  String get quotaBonusNotQualified;

  /// No description provided for @quotaBonusPostingRatioLabel.
  ///
  /// In en, this message translates to:
  /// **'Posting Ratio'**
  String get quotaBonusPostingRatioLabel;

  /// No description provided for @quotaBonusTargetRatio.
  ///
  /// In en, this message translates to:
  /// **'Target: 90%'**
  String get quotaBonusTargetRatio;

  /// No description provided for @quotaDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get quotaDetailsButton;

  /// No description provided for @bonusSchemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Schemes'**
  String get bonusSchemesTitle;

  /// No description provided for @bonusListTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bonuses'**
  String get bonusListTitle;

  /// No description provided for @bonusDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Details'**
  String get bonusDetailTitle;

  /// No description provided for @bonusSchemeDescription.
  ///
  /// In en, this message translates to:
  /// **'How Bonuses Work'**
  String get bonusSchemeDescription;

  /// No description provided for @bonusActiveTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bonusActiveTab;

  /// No description provided for @bonusConsumedTab.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get bonusConsumedTab;

  /// No description provided for @bonusExpiredTab.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bonusExpiredTab;

  /// No description provided for @bonusAllTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bonusAllTab;

  /// No description provided for @bonusExpiringToday.
  ///
  /// In en, this message translates to:
  /// **'Expires Today'**
  String get bonusExpiringToday;

  /// No description provided for @bonusExpiringTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Expires Tomorrow'**
  String get bonusExpiringTomorrow;

  /// No description provided for @bonusExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expires Soon'**
  String get bonusExpiringSoon;

  /// No description provided for @bonusSourceMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculation Breakdown'**
  String get bonusSourceMetricsTitle;

  /// No description provided for @bonusQualificationRequirement.
  ///
  /// In en, this message translates to:
  /// **'Maintain {ratio}% posting ratio'**
  String bonusQualificationRequirement(Object ratio);

  /// No description provided for @bonusRewardAmount.
  ///
  /// In en, this message translates to:
  /// **'Earn {percentage}% bonus'**
  String bonusRewardAmount(Object percentage);

  /// No description provided for @bonusValidityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Valid for {days} days'**
  String bonusValidityPeriod(Object days);

  /// No description provided for @bonusViewAllButton.
  ///
  /// In en, this message translates to:
  /// **'View All Bonuses'**
  String get bonusViewAllButton;

  /// No description provided for @bonusHowItWorksButton.
  ///
  /// In en, this message translates to:
  /// **'How Bonuses Work'**
  String get bonusHowItWorksButton;

  /// No description provided for @bonusNoSchemesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No bonus schemes available'**
  String get bonusNoSchemesAvailable;

  /// No description provided for @bonusNoBonusesFound.
  ///
  /// In en, this message translates to:
  /// **'No bonuses found'**
  String get bonusNoBonusesFound;

  /// No description provided for @bonusLoadingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Loading schemes...'**
  String get bonusLoadingSchemes;

  /// No description provided for @bonusLoadingBonuses.
  ///
  /// In en, this message translates to:
  /// **'Loading bonuses...'**
  String get bonusLoadingBonuses;

  /// No description provided for @bonusLoadingDetail.
  ///
  /// In en, this message translates to:
  /// **'Loading bonus details...'**
  String get bonusLoadingDetail;

  /// No description provided for @bonusErrorLoadingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bonus schemes'**
  String get bonusErrorLoadingSchemes;

  /// No description provided for @bonusErrorLoadingBonuses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bonuses'**
  String get bonusErrorLoadingBonuses;

  /// No description provided for @bonusErrorLoadingDetail.
  ///
  /// In en, this message translates to:
  /// **'Failed to load bonus details'**
  String get bonusErrorLoadingDetail;

  /// No description provided for @bonusSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Summary'**
  String get bonusSummaryTitle;

  /// No description provided for @bonusQuantityRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get bonusQuantityRemaining;

  /// No description provided for @bonusQuantityEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get bonusQuantityEarned;

  /// No description provided for @bonusQuantityConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get bonusQuantityConsumed;

  /// No description provided for @bonusConsumptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get bonusConsumptionLabel;

  /// No description provided for @bonusStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bonusStatusActive;

  /// No description provided for @bonusStatusConsumed.
  ///
  /// In en, this message translates to:
  /// **'Fully Consumed'**
  String get bonusStatusConsumed;

  /// No description provided for @bonusStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bonusStatusExpired;

  /// No description provided for @bonusStatusVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get bonusStatusVoided;

  /// No description provided for @commonRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetryButton;

  /// No description provided for @commonCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancelButton;

  /// No description provided for @commonApproveButton.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApproveButton;

  /// No description provided for @commonRejectButton.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get commonRejectButton;

  /// No description provided for @commonRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefreshTooltip;

  /// No description provided for @commonSearchingStatus.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get commonSearchingStatus;

  /// No description provided for @commonSubmittingStatus.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get commonSubmittingStatus;

  /// No description provided for @commonNotAvailableText.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get commonNotAvailableText;

  /// No description provided for @commonItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get commonItemLabel;

  /// No description provided for @commonCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get commonCodeLabel;

  /// No description provided for @commonQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get commonQuantityLabel;

  /// No description provided for @commonJustificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Justification'**
  String get commonJustificationLabel;

  /// No description provided for @commonCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get commonCreatedAtLabel;

  /// No description provided for @commonPartnerDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner Details'**
  String get commonPartnerDetailsLabel;

  /// No description provided for @commonUnknownPartnerName.
  ///
  /// In en, this message translates to:
  /// **'Unknown Partner'**
  String get commonUnknownPartnerName;

  /// No description provided for @commonAvailableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get commonAvailableBalanceLabel;

  /// No description provided for @commonItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get commonItemNameLabel;

  /// No description provided for @commonItemCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Code'**
  String get commonItemCodeLabel;

  /// No description provided for @commonReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get commonReasonLabel;

  /// No description provided for @commonEnterQuantityHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get commonEnterQuantityHintText;

  /// No description provided for @sdmsClaimsFilterOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Orders'**
  String get sdmsClaimsFilterOrdersTitle;

  /// No description provided for @sdmsClaimsMyPartnerOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'My Partner Orders'**
  String get sdmsClaimsMyPartnerOrdersLabel;

  /// No description provided for @sdmsClaimsMyPartnerOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'Show only orders where my partner received the credit'**
  String get sdmsClaimsMyPartnerOrdersDescription;

  /// No description provided for @sdmsClaimsClearFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get sdmsClaimsClearFilterButton;

  /// No description provided for @sdmsClaimsMyOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get sdmsClaimsMyOrdersTitle;

  /// No description provided for @sdmsClaimsActiveTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get sdmsClaimsActiveTabLabel;

  /// No description provided for @sdmsClaimsHistoryTabLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get sdmsClaimsHistoryTabLabel;

  /// No description provided for @sdmsClaimsSearchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search by order ID, consumer name, or REL ID'**
  String get sdmsClaimsSearchHintText;

  /// No description provided for @sdmsClaimsNewOrderButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get sdmsClaimsNewOrderButtonLabel;

  /// No description provided for @sdmsClaimsNoActiveOrdersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Orders'**
  String get sdmsClaimsNoActiveOrdersEmptyTitle;

  /// No description provided for @sdmsClaimsNoActiveOrdersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'You have no active orders at the moment'**
  String get sdmsClaimsNoActiveOrdersEmptyDescription;

  /// No description provided for @sdmsClaimsNoOrderHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Order History'**
  String get sdmsClaimsNoOrderHistoryEmptyTitle;

  /// No description provided for @sdmsClaimsNoOrderHistoryEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No completed orders found'**
  String get sdmsClaimsNoOrderHistoryEmptyDescription;

  /// No description provided for @sdmsClaimsMyPartnerBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'My Partner'**
  String get sdmsClaimsMyPartnerBadgeLabel;

  /// No description provided for @sdmsClaimsOrderDetailsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get sdmsClaimsOrderDetailsAppBarTitle;

  /// No description provided for @sdmsClaimsOrderDetailsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get sdmsClaimsOrderDetailsCardTitle;

  /// No description provided for @sdmsClaimsRejectTransferDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Transfer'**
  String get sdmsClaimsRejectTransferDialogTitle;

  /// No description provided for @sdmsClaimsRejectTransferConfirmationText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this transfer request?'**
  String get sdmsClaimsRejectTransferConfirmationText;

  /// No description provided for @sdmsClaimsRejectTransferReasonHintText.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get sdmsClaimsRejectTransferReasonHintText;

  /// No description provided for @sdmsClaimsOrderNotFoundErrorText.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get sdmsClaimsOrderNotFoundErrorText;

  /// No description provided for @sdmsClaimsServiceOrderItemsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Order Items'**
  String get sdmsClaimsServiceOrderItemsCardTitle;

  /// No description provided for @sdmsClaimsClaimOrderButtonText.
  ///
  /// In en, this message translates to:
  /// **'Claim This Order'**
  String get sdmsClaimsClaimOrderButtonText;

  /// No description provided for @sdmsClaimsSwitchCompanyButtonText.
  ///
  /// In en, this message translates to:
  /// **'Switch Company'**
  String get sdmsClaimsSwitchCompanyButtonText;

  /// No description provided for @sdmsClaimsRetryCurrentCompanyButtonText.
  ///
  /// In en, this message translates to:
  /// **'Retry in Current Company'**
  String get sdmsClaimsRetryCurrentCompanyButtonText;

  /// No description provided for @sdmsClaimsPartnerInformationCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner Information'**
  String get sdmsClaimsPartnerInformationCardTitle;

  /// No description provided for @sdmsClaimsClaimedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed By'**
  String get sdmsClaimsClaimedByLabel;

  /// No description provided for @sdmsClaimsUnclaimedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed'**
  String get sdmsClaimsUnclaimedStatus;

  /// No description provided for @sdmsClaimsYouAreBeneficiaryMessage.
  ///
  /// In en, this message translates to:
  /// **'You are the beneficiary for this order'**
  String get sdmsClaimsYouAreBeneficiaryMessage;

  /// No description provided for @sdmsClaimsTransferHistoryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer History'**
  String get sdmsClaimsTransferHistoryCardTitle;

  /// No description provided for @sdmsClaimsTransferRequestCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Request'**
  String get sdmsClaimsTransferRequestCardTitle;

  /// No description provided for @sdmsClaimsWantsToClaimOrderText.
  ///
  /// In en, this message translates to:
  /// **'wants to claim this order'**
  String get sdmsClaimsWantsToClaimOrderText;

  /// No description provided for @sdmsClaimsTimeRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get sdmsClaimsTimeRemainingLabel;

  /// No description provided for @sdmsClaimsPendingApprovalFromPartnerMessage.
  ///
  /// In en, this message translates to:
  /// **'Pending approval from partner'**
  String get sdmsClaimsPendingApprovalFromPartnerMessage;

  /// No description provided for @sdmsClaimsErpStatusCardTitle.
  ///
  /// In en, this message translates to:
  /// **'ERP Status'**
  String get sdmsClaimsErpStatusCardTitle;

  /// No description provided for @sdmsClaimsErpAccrualLabel.
  ///
  /// In en, this message translates to:
  /// **'Accrual'**
  String get sdmsClaimsErpAccrualLabel;

  /// No description provided for @sdmsClaimsErpAllocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get sdmsClaimsErpAllocationLabel;

  /// No description provided for @sdmsClaimsErpSettlementLabel.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get sdmsClaimsErpSettlementLabel;

  /// No description provided for @sdmsClaimsNewOrderPageTitle.
  ///
  /// In en, this message translates to:
  /// **'SDMS Claims - New Order'**
  String get sdmsClaimsNewOrderPageTitle;

  /// No description provided for @sdmsClaimsOrderDetailsHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get sdmsClaimsOrderDetailsHeaderLabel;

  /// No description provided for @sdmsClaimsConsumerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumer ID'**
  String get sdmsClaimsConsumerIdLabel;

  /// No description provided for @sdmsClaimsConsumerIdHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter 16-digit consumer ID'**
  String get sdmsClaimsConsumerIdHintText;

  /// No description provided for @sdmsClaimsConsumerIdRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Consumer ID is required'**
  String get sdmsClaimsConsumerIdRequiredError;

  /// No description provided for @sdmsClaimsConsumerIdFormatError.
  ///
  /// In en, this message translates to:
  /// **'Must be exactly 16 digits'**
  String get sdmsClaimsConsumerIdFormatError;

  /// No description provided for @sdmsClaimsOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'SDMS Order ID'**
  String get sdmsClaimsOrderIdLabel;

  /// No description provided for @sdmsClaimsOrderIdHintText.
  ///
  /// In en, this message translates to:
  /// **'e.g., 2-005443212575 (full 12-digit format)'**
  String get sdmsClaimsOrderIdHintText;

  /// No description provided for @sdmsClaimsOrderIdRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Order ID is required'**
  String get sdmsClaimsOrderIdRequiredError;

  /// No description provided for @sdmsClaimsOrderIdFormatError.
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Must be full 12-digit format (e.g., 2-005443212575)'**
  String get sdmsClaimsOrderIdFormatError;

  /// No description provided for @sdmsClaimsOrderIdInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter full 12-digit order ID. Short formats like 2-005 are not accepted.'**
  String get sdmsClaimsOrderIdInfoMessage;

  /// No description provided for @sdmsClaimsClaimingForMyselfLabel.
  ///
  /// In en, this message translates to:
  /// **'Claiming for myself'**
  String get sdmsClaimsClaimingForMyselfLabel;

  /// No description provided for @sdmsClaimsClaimingForMyselfHelpText.
  ///
  /// In en, this message translates to:
  /// **'Check this if you are claiming the order for yourself'**
  String get sdmsClaimsClaimingForMyselfHelpText;

  /// No description provided for @sdmsClaimsOrDividerText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get sdmsClaimsOrDividerText;

  /// No description provided for @sdmsClaimsPartnerDeliveryBoyHeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Partner / Delivery Boy'**
  String get sdmsClaimsPartnerDeliveryBoyHeaderLabel;

  /// No description provided for @sdmsClaimsPartnerSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search partner or delivery boy'**
  String get sdmsClaimsPartnerSearchLabel;

  /// No description provided for @sdmsClaimsPartnerSearchHintText.
  ///
  /// In en, this message translates to:
  /// **'Type to search...'**
  String get sdmsClaimsPartnerSearchHintText;

  /// No description provided for @sdmsClaimsSelectedPartnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected Partner'**
  String get sdmsClaimsSelectedPartnerLabel;

  /// No description provided for @sdmsClaimsSelectPartnerValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select a partner or delivery boy to continue'**
  String get sdmsClaimsSelectPartnerValidationMessage;

  /// No description provided for @sdmsClaimsSubmitOrderButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit Order'**
  String get sdmsClaimsSubmitOrderButtonText;

  /// No description provided for @sdmsClaimsDigitalToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get sdmsClaimsDigitalToggleLabel;

  /// No description provided for @sdmsClaimsNcDbcToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'NC & DBC'**
  String get sdmsClaimsNcDbcToggleLabel;

  /// No description provided for @sdmsClaimsDigitalBadgeText.
  ///
  /// In en, this message translates to:
  /// **'DIGITAL'**
  String get sdmsClaimsDigitalBadgeText;

  /// No description provided for @sdmsClaimsOrderTypesLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Types:'**
  String get sdmsClaimsOrderTypesLabel;

  /// No description provided for @sdmsClaimsUnclaimedSearchHintText.
  ///
  /// In en, this message translates to:
  /// **'Search by order ID, consumer, or delivery boy'**
  String get sdmsClaimsUnclaimedSearchHintText;

  /// No description provided for @sdmsClaimsUnclaimedOrdersInfoBannerText.
  ///
  /// In en, this message translates to:
  /// **'These orders are available for claiming across the company'**
  String get sdmsClaimsUnclaimedOrdersInfoBannerText;

  /// No description provided for @sdmsClaimsNoUnclaimedOrdersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Unclaimed Orders'**
  String get sdmsClaimsNoUnclaimedOrdersEmptyTitle;

  /// No description provided for @sdmsClaimsNoUnclaimedOrdersEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'All orders have been claimed! Check back later.'**
  String get sdmsClaimsNoUnclaimedOrdersEmptyDescription;

  /// No description provided for @sdmsClaimsReadyToClaimStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready to claim'**
  String get sdmsClaimsReadyToClaimStatus;

  /// No description provided for @sdmsClaimsClaimButtonText.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get sdmsClaimsClaimButtonText;

  /// No description provided for @creditExtensionMyExtensionsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Extensions'**
  String get creditExtensionMyExtensionsTitle;

  /// No description provided for @creditExtensionRequestExtensionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Request Extension'**
  String get creditExtensionRequestExtensionButtonLabel;

  /// No description provided for @creditExtensionAllStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get creditExtensionAllStatusFilterLabel;

  /// No description provided for @creditExtensionPendingStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get creditExtensionPendingStatusFilterLabel;

  /// No description provided for @creditExtensionApprovedStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get creditExtensionApprovedStatusFilterLabel;

  /// No description provided for @creditExtensionRejectedStatusFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get creditExtensionRejectedStatusFilterLabel;

  /// No description provided for @creditExtensionNoExtensionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No extension requests yet'**
  String get creditExtensionNoExtensionsEmptyTitle;

  /// No description provided for @creditExtensionNoExtensionsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Request one to continue operations during low quota.'**
  String get creditExtensionNoExtensionsEmptyDescription;

  /// No description provided for @creditExtensionDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension Details'**
  String get creditExtensionDetailPageTitle;

  /// No description provided for @creditExtensionNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Extension not found'**
  String get creditExtensionNotFoundMessage;

  /// No description provided for @creditExtensionItemDetailsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Item Details'**
  String get creditExtensionItemDetailsCardTitle;

  /// No description provided for @creditExtensionRequestInfoCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Information'**
  String get creditExtensionRequestInfoCardTitle;

  /// No description provided for @creditExtensionRequestedQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested Quantity'**
  String get creditExtensionRequestedQuantityLabel;

  /// No description provided for @creditExtensionJustificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Justification:'**
  String get creditExtensionJustificationLabel;

  /// No description provided for @creditExtensionVoiceRecordingLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice Recording'**
  String get creditExtensionVoiceRecordingLabel;

  /// No description provided for @creditExtensionNoWrittenJustificationMessage.
  ///
  /// In en, this message translates to:
  /// **'No written justification provided'**
  String get creditExtensionNoWrittenJustificationMessage;

  /// No description provided for @creditExtensionApprovalDetailsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval Details'**
  String get creditExtensionApprovalDetailsCardTitle;

  /// No description provided for @creditExtensionApprovedQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved Quantity'**
  String get creditExtensionApprovedQuantityLabel;

  /// No description provided for @creditExtensionApprovedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved By'**
  String get creditExtensionApprovedByLabel;

  /// No description provided for @creditExtensionApprovedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved At'**
  String get creditExtensionApprovedAtLabel;

  /// No description provided for @creditExtensionValidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get creditExtensionValidUntilLabel;

  /// No description provided for @creditExtensionUsageBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'Usage Breakdown'**
  String get creditExtensionUsageBreakdownLabel;

  /// No description provided for @creditExtensionReservedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get creditExtensionReservedLabel;

  /// No description provided for @creditExtensionConsumedLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get creditExtensionConsumedLabel;

  /// No description provided for @creditExtensionRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get creditExtensionRemainingLabel;

  /// No description provided for @creditExtensionRejectionDetailsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Rejection Details'**
  String get creditExtensionRejectionDetailsCardTitle;

  /// No description provided for @creditExtensionCreateRequestPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Credit Extension'**
  String get creditExtensionCreateRequestPageTitle;

  /// No description provided for @creditExtensionSelectItemCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Item'**
  String get creditExtensionSelectItemCardTitle;

  /// No description provided for @creditExtensionSelectItemHintText.
  ///
  /// In en, this message translates to:
  /// **'Choose an item'**
  String get creditExtensionSelectItemHintText;

  /// No description provided for @creditExtensionSelectItemValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please select an item'**
  String get creditExtensionSelectItemValidationMessage;

  /// No description provided for @creditExtensionQuotaInformationCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Quota Information'**
  String get creditExtensionQuotaInformationCardTitle;

  /// No description provided for @creditExtensionAvailableBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get creditExtensionAvailableBalanceLabel;

  /// No description provided for @creditExtensionCreditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditExtensionCreditLimitLabel;

  /// No description provided for @creditExtensionMaxRequestableLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Requestable'**
  String get creditExtensionMaxRequestableLabel;

  /// No description provided for @creditExtensionQuantityHintText.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get creditExtensionQuantityHintText;

  /// No description provided for @creditExtensionQuantityRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get creditExtensionQuantityRequiredError;

  /// No description provided for @creditExtensionQuantityGreaterThanZeroError.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get creditExtensionQuantityGreaterThanZeroError;

  /// No description provided for @creditExtensionAudioJustificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio Justification (Required)'**
  String get creditExtensionAudioJustificationLabel;

  /// No description provided for @creditExtensionRecordButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get creditExtensionRecordButtonLabel;

  /// No description provided for @creditExtensionStopButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get creditExtensionStopButtonLabel;

  /// No description provided for @creditExtensionPlayButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get creditExtensionPlayButtonLabel;

  /// No description provided for @creditExtensionPauseButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get creditExtensionPauseButtonLabel;

  /// No description provided for @creditExtensionDeleteAudioTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete audio'**
  String get creditExtensionDeleteAudioTooltip;

  /// No description provided for @creditExtensionRecordingStatus.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get creditExtensionRecordingStatus;

  /// No description provided for @creditExtensionAudioRecordedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Audio recorded successfully'**
  String get creditExtensionAudioRecordedSuccessMessage;

  /// No description provided for @creditExtensionTextJustificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Justification (Required)'**
  String get creditExtensionTextJustificationLabel;

  /// No description provided for @creditExtensionTextJustificationHintText.
  ///
  /// In en, this message translates to:
  /// **'Explain why you need this extension'**
  String get creditExtensionTextJustificationHintText;

  /// No description provided for @creditExtensionTextJustificationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Text justification is required'**
  String get creditExtensionTextJustificationRequiredError;

  /// No description provided for @creditExtensionTextJustificationMinError.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 10 characters'**
  String get creditExtensionTextJustificationMinError;

  /// No description provided for @creditExtensionListeningStatus.
  ///
  /// In en, this message translates to:
  /// **'Listening... Tap microphone to stop'**
  String get creditExtensionListeningStatus;

  /// No description provided for @creditExtensionSubmitRequestButtonText.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get creditExtensionSubmitRequestButtonText;

  /// No description provided for @gmCreditApprovalsPendingApprovalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get gmCreditApprovalsPendingApprovalsTitle;

  /// No description provided for @gmCreditApprovalsNoApprovalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Pending Approvals'**
  String get gmCreditApprovalsNoApprovalsEmptyTitle;

  /// No description provided for @gmCreditApprovalsAllProcessedEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'All credit extension requests have been processed'**
  String get gmCreditApprovalsAllProcessedEmptyDescription;

  /// No description provided for @gmCreditExtensionDetailPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit Extension Request'**
  String get gmCreditExtensionDetailPageTitle;

  /// No description provided for @gmCreditExtensionRequestSummaryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Summary'**
  String get gmCreditExtensionRequestSummaryCardTitle;

  /// No description provided for @gmCreditExtensionLiveQuotaSnapshotCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Quota Snapshot'**
  String get gmCreditExtensionLiveQuotaSnapshotCardTitle;

  /// No description provided for @gmCreditExtensionQuotaHistoryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'7-Day Quota History'**
  String get gmCreditExtensionQuotaHistoryCardTitle;

  /// No description provided for @gmCreditExtensionExtensionHistoryCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension History (Same Item)'**
  String get gmCreditExtensionExtensionHistoryCardTitle;

  /// No description provided for @gmCreditExtensionApproveRequestDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Request'**
  String get gmCreditExtensionApproveRequestDialogTitle;

  /// No description provided for @gmCreditExtensionApproveRequestDescription.
  ///
  /// In en, this message translates to:
  /// **'Set approved quantity and expiry date:'**
  String get gmCreditExtensionApproveRequestDescription;

  /// No description provided for @gmCreditExtensionValidUntilDialogLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid Until (Optional)'**
  String get gmCreditExtensionValidUntilDialogLabel;

  /// No description provided for @gmCreditExtensionSelectDatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get gmCreditExtensionSelectDatePlaceholder;

  /// No description provided for @gmCreditExtensionRejectRequestDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get gmCreditExtensionRejectRequestDialogTitle;

  /// No description provided for @gmCreditExtensionSelectRejectionReasonDescription.
  ///
  /// In en, this message translates to:
  /// **'Select rejection reason:'**
  String get gmCreditExtensionSelectRejectionReasonDescription;

  /// No description provided for @quotaSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Quota Status'**
  String get quotaSnapshotTitle;

  /// No description provided for @quotaSnapshotLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading quota data...'**
  String get quotaSnapshotLoading;

  /// No description provided for @quotaSnapshotSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing with SDMS...'**
  String get quotaSnapshotSyncing;

  /// No description provided for @quotaSnapshotRequestCreditExtension.
  ///
  /// In en, this message translates to:
  /// **'Request Credit Extension'**
  String get quotaSnapshotRequestCreditExtension;

  /// No description provided for @quotaSnapshotViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get quotaSnapshotViewHistory;

  /// No description provided for @quotaSnapshotBlocked.
  ///
  /// In en, this message translates to:
  /// **'BLOCKED'**
  String get quotaSnapshotBlocked;

  /// No description provided for @quotaSnapshotNoQuotaAvailable.
  ///
  /// In en, this message translates to:
  /// **'NO Quota Available'**
  String get quotaSnapshotNoQuotaAvailable;

  /// No description provided for @quotaSnapshotKeyBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'KEY BALANCES'**
  String get quotaSnapshotKeyBalancesTitle;

  /// No description provided for @quotaSnapshotTransactionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION DETAILS'**
  String get quotaSnapshotTransactionDetailsTitle;

  /// No description provided for @quotaSnapshotOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening'**
  String get quotaSnapshotOpening;

  /// No description provided for @quotaSnapshotAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get quotaSnapshotAdjustment;

  /// No description provided for @quotaSnapshotOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get quotaSnapshotOrders;

  /// No description provided for @quotaSnapshotPickups.
  ///
  /// In en, this message translates to:
  /// **'Pickups'**
  String get quotaSnapshotPickups;

  /// No description provided for @quotaSnapshotReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get quotaSnapshotReturns;

  /// No description provided for @quotaSnapshotSdmsSales.
  ///
  /// In en, this message translates to:
  /// **'SDMS Sales'**
  String get quotaSnapshotSdmsSales;

  /// No description provided for @quotaSnapshotClosing.
  ///
  /// In en, this message translates to:
  /// **'Closing'**
  String get quotaSnapshotClosing;

  /// No description provided for @quotaSnapshotHowCalculated.
  ///
  /// In en, this message translates to:
  /// **'HOW IT\'S CALCULATED'**
  String get quotaSnapshotHowCalculated;

  /// No description provided for @quotaSnapshotNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get quotaSnapshotNoData;

  /// No description provided for @quotaSnapshotSyncButton.
  ///
  /// In en, this message translates to:
  /// **'Sync SDMS'**
  String get quotaSnapshotSyncButton;

  /// No description provided for @quotaSnapshotSyncingButton.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get quotaSnapshotSyncingButton;

  /// No description provided for @quotaSnapshotLastSyncedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last synced:'**
  String get quotaSnapshotLastSyncedLabel;

  /// No description provided for @quotaSnapshotSyncStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'SYNC STATUS'**
  String get quotaSnapshotSyncStatusTitle;

  /// No description provided for @quotaSnapshotCompanySyncDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Sync Details'**
  String get quotaSnapshotCompanySyncDetailsTitle;

  /// No description provided for @quotaSnapshotCanSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Can sync now'**
  String get quotaSnapshotCanSyncNow;

  /// No description provided for @quotaSnapshotSyncResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'SDMS Sync Response'**
  String get quotaSnapshotSyncResponseTitle;

  /// No description provided for @quotaSnapshotCompanyStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Status:'**
  String get quotaSnapshotCompanyStatusLabel;

  /// No description provided for @quotaSnapshotStatusAllSynced.
  ///
  /// In en, this message translates to:
  /// **'All companies processed'**
  String get quotaSnapshotStatusAllSynced;

  /// No description provided for @quotaSnapshotStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial sync - some companies have issues'**
  String get quotaSnapshotStatusPartial;

  /// No description provided for @quotaSnapshotStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get quotaSnapshotStatusFailed;

  /// No description provided for @bonusFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bonusFilterAll;

  /// No description provided for @bonusFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bonusFilterActive;

  /// No description provided for @bonusFilterConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get bonusFilterConsumed;

  /// No description provided for @bonusFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get bonusFilterExpired;

  /// No description provided for @bonusEmptyActive.
  ///
  /// In en, this message translates to:
  /// **'No active bonuses'**
  String get bonusEmptyActive;

  /// No description provided for @bonusEmptyConsumed.
  ///
  /// In en, this message translates to:
  /// **'No consumed bonuses'**
  String get bonusEmptyConsumed;

  /// No description provided for @bonusEmptyExpired.
  ///
  /// In en, this message translates to:
  /// **'No expired bonuses'**
  String get bonusEmptyExpired;

  /// No description provided for @bonusEmptyGeneric.
  ///
  /// In en, this message translates to:
  /// **'No bonuses found'**
  String get bonusEmptyGeneric;

  /// No description provided for @bonusDetailEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get bonusDetailEarned;

  /// No description provided for @bonusDetailExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get bonusDetailExpires;

  /// No description provided for @bonusDetailChipRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get bonusDetailChipRemaining;

  /// No description provided for @bonusDetailDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'days remaining'**
  String get bonusDetailDaysRemaining;

  /// No description provided for @bonusDetailSchemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Bonus Scheme'**
  String get bonusDetailSchemeTitle;

  /// No description provided for @bonusMetricPickups.
  ///
  /// In en, this message translates to:
  /// **'Pickups'**
  String get bonusMetricPickups;

  /// No description provided for @bonusMetricReturns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get bonusMetricReturns;

  /// No description provided for @bonusMetricNetPickups.
  ///
  /// In en, this message translates to:
  /// **'Net Pickups'**
  String get bonusMetricNetPickups;

  /// No description provided for @bonusMetricOtpSales.
  ///
  /// In en, this message translates to:
  /// **'OTP Sales'**
  String get bonusMetricOtpSales;

  /// No description provided for @bonusMetricOverrideSales.
  ///
  /// In en, this message translates to:
  /// **'Override Sales'**
  String get bonusMetricOverrideSales;

  /// No description provided for @bonusMetricConfirmedSales.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Sales'**
  String get bonusMetricConfirmedSales;

  /// No description provided for @bonusMetricPostingRatio.
  ///
  /// In en, this message translates to:
  /// **'Posting Ratio'**
  String get bonusMetricPostingRatio;

  /// No description provided for @bonusMetricBonusCalculated.
  ///
  /// In en, this message translates to:
  /// **'Bonus Calculated'**
  String get bonusMetricBonusCalculated;

  /// No description provided for @bonusSchemesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bonus schemes available'**
  String get bonusSchemesEmpty;

  /// No description provided for @quotaHistoryFilterLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get quotaHistoryFilterLast7Days;

  /// No description provided for @quotaHistoryFilterLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get quotaHistoryFilterLast30Days;

  /// No description provided for @quotaHistoryFilterThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get quotaHistoryFilterThisMonth;

  /// No description provided for @quotaHistoryFilterLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get quotaHistoryFilterLastMonth;

  /// No description provided for @quotaHistoryFilterCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range...'**
  String get quotaHistoryFilterCustomRange;

  /// No description provided for @quotaHistoryErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get quotaHistoryErrorLoadFailed;

  /// No description provided for @quotaHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get quotaHistoryEmptyTitle;

  /// No description provided for @quotaHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No quota history available for this period'**
  String get quotaHistoryEmptyMessage;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get inventoryFilterPending;

  /// No description provided for @inventoryFilterCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get inventoryFilterCollect;

  /// No description provided for @inventoryFilterDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get inventoryFilterDeposit;

  /// No description provided for @ordersFilterNotDelivered.
  ///
  /// In en, this message translates to:
  /// **'Not Delivered'**
  String get ordersFilterNotDelivered;

  /// No description provided for @ordersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get ordersFilterDateRange;

  /// No description provided for @ordersCardRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Req By:'**
  String get ordersCardRequestedBy;

  /// No description provided for @ordersNoVehicle.
  ///
  /// In en, this message translates to:
  /// **'No Vehicle'**
  String get ordersNoVehicle;

  /// No description provided for @ordersNoWarehouse.
  ///
  /// In en, this message translates to:
  /// **'No Warehouse'**
  String get ordersNoWarehouse;

  /// No description provided for @ordersCardQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty:'**
  String get ordersCardQuantity;

  /// No description provided for @ordersCardCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created:'**
  String get ordersCardCreatedDate;

  /// No description provided for @vehicleHistoryPhoneCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get vehicleHistoryPhoneCopied;

  /// No description provided for @vehicleHistoryLastVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Last visit:'**
  String get vehicleHistoryLastVisitLabel;

  /// No description provided for @vehicleHistoryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get vehicleHistoryErrorTitle;

  /// No description provided for @vehicleHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get vehicleHistoryEmptyTitle;

  /// No description provided for @vehicleHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This vehicle has no previous visits recorded'**
  String get vehicleHistoryEmptyMessage;

  /// No description provided for @vehicleHistorySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Summary'**
  String get vehicleHistorySummaryTitle;

  /// No description provided for @vehicleHistoryTotalVisitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Visits'**
  String get vehicleHistoryTotalVisitsLabel;

  /// No description provided for @vehicleHistoryUniqueDriversLabel.
  ///
  /// In en, this message translates to:
  /// **'Unique Drivers'**
  String get vehicleHistoryUniqueDriversLabel;

  /// No description provided for @vehicleHistoryDriverHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver History'**
  String get vehicleHistoryDriverHistoryTitle;

  /// No description provided for @vehicleHistoryDriverDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Details'**
  String get vehicleHistoryDriverDetailsTitle;

  // Ujjwala Installation Strings
  String get ujjwalaInstallationsTitle;
  String get ujjwalaInstallationsSubtitle;
  String get ujjwalaPendingListTitle;
  String get ujjwalaPendingListEmpty;
  String get ujjwalaApplicationNumber;
  String get ujjwalaConsumerNumber;
  String get ujjwalaConsumerName;
  String get ujjwalaMobileNumber;
  String get ujjwalaAddress;
  String get ujjwalaMaterialDelivered;
  String get ujjwalaSubmitTitle;
  String get ujjwalaApplicantInfo;
  String get ujjwalaPhotosSection;
  String get ujjwalaKitchenPhoto;
  String get ujjwalaGatePhoto;
  String get ujjwalaStovePhoto;
  String get ujjwalaKitchenPhotoInfo;
  String get ujjwalaGatePhotoInfo;
  String get ujjwalaStovePhotoInfo;
  String get ujjwalaTakePhoto;
  String get ujjwalaRetakePhoto;
  String get ujjwalaDeletePhoto;
  String get ujjwalaRotatePhoto;
  String get ujjwalaPhotoUploading;
  String get ujjwalaPhotoUploaded;
  String get ujjwalaPhotoError;
  String get ujjwalaLocationSection;
  String get ujjwalaLatitude;
  String get ujjwalaLongitude;
  String get ujjwalaAccuracy;
  String get ujjwalaRefreshLocation;
  String get ujjwalaFetchingLocation;
  String get ujjwalaLocationError;
  String get ujjwalaLocationRequired;
  String get ujjwalaSubmitButton;
  String get ujjwalaSubmitSuccess;
  String get ujjwalaSubmitError;
  String get ujjwalaAllPhotosRequired;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
