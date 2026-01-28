// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LPG Distribution';

  @override
  String get notificationChannelName => 'High Importance Notifications';

  @override
  String get notificationChannelDescription => 'This channel is used for important notifications.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileRefresh => 'Refresh Profile';

  @override
  String get profileMoreOptionsTooltip => 'More Options';

  @override
  String get profileLoading => 'Loading profile...';

  @override
  String get profileAccountInformation => 'Account Information';

  @override
  String get profileCompanyLabel => 'Company';

  @override
  String get profileAccountLabel => 'Account';

  @override
  String get profileWarehouseLabel => 'Warehouse';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileRolesLabel => 'Roles';

  @override
  String get profileNotAssigned => 'Not assigned';

  @override
  String get profileContactInformation => 'Contact Information';

  @override
  String get profilePhoneNumber => 'Phone Number';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileVehicleInformation => 'Vehicle Information';

  @override
  String get profileVehicleNumber => 'Vehicle Number';

  @override
  String get profileAppInformation => 'App Information';

  @override
  String get profileCurrentVersion => 'Current Version';

  @override
  String get profileRequiredUpdate => 'Required update - Tap to install';

  @override
  String get profileRecommendedUpdate => 'Recommended update available';

  @override
  String get profileInformUpdate => 'New version available';

  @override
  String get profileBecomePartner => 'BECOME PARTNER';

  @override
  String get profileEditPassword => 'EDIT PASSWORD';

  @override
  String get profileLogout => 'LOGOUT';

  @override
  String get profileLogoutConfirmTitle => 'Confirm Logout';

  @override
  String get profileLogoutConfirmMessage => 'Are you sure you want to logout from your account? You will need to login again to access the app.';

  @override
  String get profileLogoutConfirmCancel => 'CANCEL';

  @override
  String get profileLogoutConfirmProceed => 'Logout';

  @override
  String profileCopyTooltip(Object label) {
    return 'Copy $label';
  }

  @override
  String profileCopyMessage(Object label) {
    return '$label copied to clipboard';
  }

  @override
  String profileVersionPrefix(Object version) {
    return 'Version $version';
  }

  @override
  String get profileActionSheetTitle => 'Profile Options';

  @override
  String get profileActionEditProfileTitle => 'Edit Profile';

  @override
  String get profileActionEditProfileSubtitle => 'Update your personal information';

  @override
  String get profileActionSwitchCompanyTitle => 'Switch Company';

  @override
  String get profileActionSwitchCompanySubtitle => 'Change your active company';

  @override
  String get profileActionChangePasswordTitle => 'Change Password';

  @override
  String get profileActionChangePasswordSubtitle => 'Update your security credentials';

  @override
  String get profileActionChangePasswordMessage => 'Change password feature coming soon';

  @override
  String get profileActionNotificationSettingsTitle => 'Notification Settings';

  @override
  String get profileActionNotificationSettingsSubtitle => 'Manage your notification preferences';

  @override
  String get profileActionNotificationSettingsMessage => 'Notification settings feature coming soon';

  @override
  String get profileActionHelpTitle => 'Help & Support';

  @override
  String get profileActionHelpSubtitle => 'Get assistance and support';

  @override
  String get profileActionHelpMessage => 'Help & support feature coming soon';

  @override
  String get profileActionLogoutTitle => 'Logout';

  @override
  String get profileActionLogoutSubtitle => 'Sign out from your account';

  @override
  String get profileCompanySwitcherTitle => 'Switch Company';

  @override
  String get profileCompanySwitcherActive => 'ACTIVE';

  @override
  String profileCompanyCode(Object code) {
    return 'Code: $code';
  }

  @override
  String get profileCompanySwitchButton => 'SWITCH';

  @override
  String profileSwitchFailed(Object error) {
    return 'Failed to switch company: $error';
  }

  @override
  String profileCompaniesLoadFailed(Object error) {
    return 'Failed to load companies: $error';
  }

  @override
  String profileErrorLoading(Object error) {
    return 'Error loading profile: $error';
  }

  @override
  String profileOptionalDataError(Object error) {
    return 'Optional user data not available: $error';
  }

  @override
  String profileLogoutError(Object error) {
    return 'Error logging out: $error';
  }

  @override
  String profileNavigationError(Object error) {
    return 'Navigation error: $error';
  }

  @override
  String profileVersionUpdateFailed(Object error) {
    return 'Update failed: $error';
  }

  @override
  String get profileSwitchingTo => 'Switching to:';

  @override
  String get profileActiveCompanyLabel => 'User';

  @override
  String get profileLanguageToggle => 'Language';

  @override
  String get profileLanguageEnglish => 'English';

  @override
  String get profileLanguageHindi => 'Hindi';

  @override
  String get errorUnableToGetDownloadUrl => 'Unable to get download URL';

  @override
  String errorDownloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get errorEnterUsernamePassword => 'Please enter both username and password';

  @override
  String get errorLoginFailed => 'Login failed. Please try again.';

  @override
  String get errorAppUpdateRequired => 'App update required. Please download the latest version.';

  @override
  String get errorConnectionTimeout => 'Connection timeout. Please try again.';

  @override
  String get errorNoInternetConnection => 'No internet connection. Please check your network.';

  @override
  String get errorDownloadFailedTitle => 'Download Failed';

  @override
  String get errorDownloadUpdateFailed => 'Failed to download update. Please try again or download from website.';

  @override
  String get buttonOk => 'OK';

  @override
  String get companyArunGasServices => 'Arun Gas Services';

  @override
  String get loginToYourAccount => 'Login to your account';

  @override
  String get labelUsername => 'Username';

  @override
  String get labelPassword => 'Password';

  @override
  String get linkForgotPassword => 'Forgot Password?';

  @override
  String get linkSignUpForNewAccount => 'Sign Up for New Account';

  @override
  String get buttonLogin => 'LOGIN';

  @override
  String get errorNoUserRoleAssigned => 'No User Role Assigned';

  @override
  String get errorContactAdministrator => 'Please contact administrator.';

  @override
  String get linkBecomePartner => 'Become a Partner';

  @override
  String get linkContinuePartnerRegistration => 'Continue to Partner Registration';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navCash => 'Cash';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navProfile => 'Profile';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRefreshTooltip => 'Refresh Dashboard';

  @override
  String get dashboardLoadingLabel => 'Loading dashboard...';

  @override
  String get dashboardRefreshSuccess => 'Dashboard refreshed';

  @override
  String get dashboardRefreshFailure => 'Failed to refresh dashboard';

  @override
  String get dashboardUserLoadFailure => 'Failed to load user information';

  @override
  String get dashboardDataLoadFailure => 'Failed to load dashboard data';

  @override
  String get dashboardGreetingMorning => 'Good morning';

  @override
  String get dashboardGreetingAfternoon => 'Good afternoon';

  @override
  String get dashboardGreetingEvening => 'Good evening';

  @override
  String get dashboardUserFallback => 'User';

  @override
  String dashboardGreetingMessage(Object greeting, Object name) {
    return '$greeting, $name!';
  }

  @override
  String dashboardRoleWithCompany(Object company, Object roles) {
    return '$roles ($company)';
  }

  @override
  String dashboardPendingApprovalSingle(Object count) {
    return '$count pending approval';
  }

  @override
  String dashboardPendingApprovalsMultiple(Object count) {
    return '$count pending approvals';
  }

  @override
  String get dashboardQuickActionsTitle => 'Quick Actions';

  @override
  String get dashboardCreateOrderTitle => 'Create Order';

  @override
  String get dashboardCreateOrderSubtitle => 'New sale order';

  @override
  String get dashboardCashDepositTitle => 'Cash Deposit';

  @override
  String get dashboardCashDepositSubtitle => 'Deposit collections';

  @override
  String get dashboardChallanTitle => 'Challan';

  @override
  String get dashboardChallanSubtitle => 'Create a challan';

  @override
  String get dashboardDepositItemsTitle => 'Deposit Items';

  @override
  String get dashboardDepositItemsSubtitle => 'Return inventory';

  @override
  String get dashboardInventoryManagementTitle => 'Inventory Management';

  @override
  String get dashboardProcurementTitle => 'Procurement (Purchase Invoice)';

  @override
  String get dashboardProcurementSubtitle => 'Vehicle in/out records';

  @override
  String get dashboardInventoryApprovalsTitle => 'Inventory Approvals';

  @override
  String get dashboardInventoryApprovalsSubtitle => 'Review pending requests';

  @override
  String get dashboardCashManagementTitle => 'Cash Management';

  @override
  String get dashboardCashApprovalsTitle => 'Cash Approvals';

  @override
  String get dashboardCashApprovalsSubtitle => 'Review pending deposits';

  @override
  String get dashboardCustomerSupportTitle => 'Customer Support';

  @override
  String get dashboardOpenTicketsTitle => 'Open Tickets';

  @override
  String get dashboardOpenTicketsSubtitle => 'Customer support requests';

  @override
  String get dashboardResolvedTodayLabel => 'Resolved Today';

  @override
  String get dashboardAverageResponseLabel => 'Avg Response';

  @override
  String get dashboardSystemOverviewTitle => 'System Overview';

  @override
  String get dashboardTodaysOrdersLabel => 'Today\'s Orders';

  @override
  String get dashboardActiveUsersLabel => 'Active Users';

  @override
  String get dashboardAllApprovalsTitle => 'All Approvals';

  @override
  String get dashboardGettingStartedTitle => 'Getting Started';

  @override
  String get dashboardViewProfileTitle => 'View Profile';

  @override
  String get dashboardViewProfileSubtitle => 'Personal information';

  @override
  String get dashboardStatusClear => 'Clear';

  @override
  String dashboardInventoryPendingSubtitle(Object count) {
    return '$count items need approval';
  }

  @override
  String dashboardCashPendingSubtitle(Object count) {
    return '$count deposits need approval';
  }

  @override
  String get dashboardOrderApprovalsTitle => 'Order Approvals';

  @override
  String dashboardOrdersPendingSubtitle(Object count) {
    return '$count orders need approval';
  }

  @override
  String get dashboardCseTicketsTitle => 'CSE Tickets';

  @override
  String dashboardTicketsPendingSubtitle(Object count) {
    return '$count tickets need attention';
  }

  @override
  String get dashboardNoPendingNotifications => 'No pending notifications';

  @override
  String get dashboardNotificationsTitle => 'Notifications';

  @override
  String dashboardPendingCountLabel(Object count) {
    return '$count pending';
  }

  @override
  String get dashboardOrderApprovalsComingSoon => 'Order approvals feature coming soon';

  @override
  String get dashboardCseTicketsComingSoon => 'CSE tickets feature coming soon';

  @override
  String dashboardNewApprovalPending(Object module) {
    return 'New $module approval pending';
  }

  @override
  String get dashboardModuleInventory => 'inventory';

  @override
  String get dashboardModuleCash => 'cash';

  @override
  String get dashboardModuleOrders => 'orders';

  @override
  String get dashboardModuleCse => 'customer support';

  @override
  String get dashboardRoleDeliveryBoy => 'Delivery Boy';

  @override
  String get dashboardRoleWarehouseManager => 'Warehouse Manager';

  @override
  String get dashboardRoleGeneralManager => 'General Manager';

  @override
  String get dashboardRoleCustomerServiceExecutive => 'Customer Service Executive';

  @override
  String get dashboardRoleCashier => 'Cashier';

  @override
  String dashboardAdditionalRoles(Object firstRole, Object remainingCount) {
    return '$firstRole + $remainingCount more';
  }

  @override
  String get dashboardRolesSeparator => ' & ';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonClose => 'Close';

  @override
  String get buttonApprove => 'Approve';

  @override
  String get buttonReject => 'Reject';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonSubmit => 'Submit';

  @override
  String get buttonDelete => 'Delete';

  @override
  String get buttonEdit => 'Edit';

  @override
  String get buttonAdd => 'Add';

  @override
  String get buttonRemove => 'Remove';

  @override
  String get buttonChange => 'Change';

  @override
  String get buttonRefresh => 'REFRESH';

  @override
  String get buttonCreateNew => 'Create New';

  @override
  String get buttonCreateAnother => 'Create Another';

  @override
  String get buttonBackToList => 'Back to List';

  @override
  String get buttonTryAgain => 'Try Again';

  @override
  String get buttonClearAll => 'Clear All';

  @override
  String get buttonClearFilters => 'Clear Filters';

  @override
  String get buttonUseOrderId => 'Use This Order ID';

  @override
  String get buttonScanAgain => 'Scan Again';

  @override
  String get dialogErrorTitle => 'Error';

  @override
  String get dialogSuccessTitle => 'Success';

  @override
  String get dialogConfirmTitle => 'Confirm';

  @override
  String get dialogWarningTitle => 'Warning';

  @override
  String get dialogInfoTitle => 'Information';

  @override
  String get dialogOptionAll => 'All';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String get statusProcessing => 'Processing';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get tableHeaderAccount => 'Account';

  @override
  String get tableHeaderLedger => 'Ledger';

  @override
  String get tableHeaderOpen => 'Open';

  @override
  String get tableHeaderAvailable => 'Available';

  @override
  String get loadingPleaseWait => 'Please wait...';

  @override
  String get loadingSearching => 'Searching...';

  @override
  String get loadingSubmitting => 'Submitting...';

  @override
  String get loadingLoading => 'Loading...';

  @override
  String get loginWelcomeTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginUsernameHint => 'Enter Mobile Number / Username';

  @override
  String get loginPasswordHint => 'Enter Password';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginSignUpButtonLabel => 'Sign Up for New Account';

  @override
  String get forgotPasswordScreenTitle => 'Reset Password';

  @override
  String get forgotPasswordAadharLabel => 'Aadhar Number';

  @override
  String get forgotPasswordOtpLabel => '6-Digit OTP';

  @override
  String get forgotPasswordNewPasswordLabel => 'New Password';

  @override
  String get forgotPasswordConfirmPasswordLabel => 'Confirm New Password';

  @override
  String get signUpAadharLabel => 'Aadhar Number';

  @override
  String get signUpPhoneLabel => 'Phone Number';

  @override
  String get signUpAadharRequired => 'Aadhar number is required';

  @override
  String get signUpAadharInvalid => 'Aadhar must be exactly 12 digits';

  @override
  String get signUpAadharChecksum => 'Invalid Aadhar number';

  @override
  String get signUpPhoneRequired => 'Phone number is required';

  @override
  String get signUpPhoneInvalid => 'Phone number must be exactly 10 digits';

  @override
  String get passwordChangeScreenTitle => 'Change Password';

  @override
  String get passwordChangeSectionTitle => 'Change Password';

  @override
  String get passwordChangeSubtitle => 'Update your account password to keep your account secure';

  @override
  String get passwordChangeCurrentLabel => 'Current Password';

  @override
  String get passwordChangeCurrentHint => 'Enter current password';

  @override
  String get passwordChangeNewLabel => 'New Password';

  @override
  String get passwordChangeNewHint => 'Enter new password';

  @override
  String get passwordChangeConfirmLabel => 'Confirm New Password';

  @override
  String get passwordChangeConfirmHint => 'Confirm new password';

  @override
  String get buttonChangingPassword => 'CHANGING...';

  @override
  String get buttonChangePassword => 'CHANGE PASSWORD';

  @override
  String get passwordChangeCurrentRequired => 'Current password is required';

  @override
  String get passwordChangeNewRequired => 'New password is required';

  @override
  String get passwordChangeNewMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordChangeNewDifferent => 'New password must be different from current password';

  @override
  String get passwordChangeConfirmRequired => 'Please confirm your new password';

  @override
  String get passwordChangeConfirmMismatch => 'New Password does not match with Confirm Password';

  @override
  String get panVerificationScreenTitle => 'Become Partner';

  @override
  String get panVerificationHeading => 'Partner Registration';

  @override
  String get panVerificationSubtitle => 'Enter your PAN number to begin the partner verification process';

  @override
  String get panNumberLabel => 'PAN Number';

  @override
  String get panNumberHint => 'Enter PAN (e.g., AZJPG7110R)';

  @override
  String get panNumberRequired => 'PAN number is required';

  @override
  String get panNumberInvalid => 'Invalid PAN format. Use: AAAAA9999A';

  @override
  String get cashPageTitle => 'Cash Management';

  @override
  String get cashSearchHint => 'Search by ID, name, reference...';

  @override
  String get cashLoadingError => 'Error loading cash data';

  @override
  String get cashAccountBalancesTitle => 'Account Balances';

  @override
  String get cashDataNotAvailable => 'Data not available';

  @override
  String get cashPullToRefresh => 'Pull down to refresh';

  @override
  String get cashNoAccountData => 'No account data available';

  @override
  String get cashAccountDefault => 'Cash Account';

  @override
  String get cashViewTransactionHistory => 'View Transaction History';

  @override
  String get cashDepositActionTitle => 'Cash Deposit';

  @override
  String get cashDepositActionSubtitle => 'Deposit cash to Manager';

  @override
  String get cashHandoverActionTitle => 'Handover Cash';

  @override
  String get cashHandoverActionSubtitle => 'Handover cash to Manager';

  @override
  String get cashBankDepositActionTitle => 'Bank Deposit';

  @override
  String get cashBankDepositActionSubtitle => 'Deposit cash directly to bank';

  @override
  String get cashDepositAmountHint => 'Enter amount';

  @override
  String get cashDepositAccountSelectHint => 'Select Account Paid To';

  @override
  String get cashDepositRemarksHint => 'Enter any remarks or notes';

  @override
  String get handoverAccountSelectHint => 'Select Account for Handover';

  @override
  String get handoverAmountHint => 'Enter amount';

  @override
  String get handoverRemarksHint => 'Enter any remarks or notes';

  @override
  String get bankDepositAmountHint => 'Enter amount';

  @override
  String get bankDepositReferenceHint => 'Enter receipt or reference number';

  @override
  String get bankDepositRemarksHint => 'Enter any remarks or notes';

  @override
  String get transactionDetailsTitle => 'Transaction Details';

  @override
  String get transactionApproving => 'Approving transaction...';

  @override
  String get transactionRejecting => 'Rejecting transaction...';

  @override
  String get rejectionReasonIncorrectAmount => 'Incorrect Amount';

  @override
  String get rejectionReasonAmountMismatch => 'Cash Amount Mismatch';

  @override
  String get rejectionReasonMissingReceipt => 'Missing Receipt';

  @override
  String get rejectionReasonOther => 'Other';

  @override
  String get transactionCommentsHint => 'Additional Comments (Optional)';

  @override
  String get buttonVerifyCashReceived => 'VERIFY CASH RECEIVED';

  @override
  String get dialogReceiptImageTitle => 'Receipt Image';

  @override
  String get imageLoadError => 'Failed to load image';

  @override
  String get dialogBankDepositSlipTitle => 'Bank Deposit Slip';

  @override
  String get inventoryPageTitle => 'Inventory';

  @override
  String get inventorySearchHint => 'Search Requests...';

  @override
  String get inventoryDepositUnlinkedTitle => 'Deposit Inventory (Unlinked)';

  @override
  String get inventoryDepositUnlinkedSubtitle => 'Deposit items for warehouse';

  @override
  String get inventoryDepositSaleOrderTitle => 'Deposit Inventory (Sale Order)';

  @override
  String get inventoryDepositSaleOrderSubtitle => 'Deposit items against sale orders';

  @override
  String get inventoryDepositMaterialRequestTitle => 'Deposit Inventory (Material Request)';

  @override
  String get inventoryDepositMaterialRequestSubtitle => 'Deposit items against material requests';

  @override
  String get inventoryCreateChallanTitle => 'Create Challan';

  @override
  String get inventoryCreateChallanSubtitle => 'Create a inventory challan';

  @override
  String get inventoryTransferTitle => 'Inventory Transfer';

  @override
  String get inventoryTransferSubtitle => 'Transfer items to another warehouse';

  @override
  String get dialogRequestDetailsTitle => 'Request Details';

  @override
  String inventoryApproveButton(Object type) {
    return 'Approve $type';
  }

  @override
  String inventoryApproveConfirmation(Object type) {
    return 'Are you sure you want to approve this $type request?';
  }

  @override
  String inventoryRejectButton(Object type) {
    return 'Reject $type';
  }

  @override
  String get inventorySelectRejectionReason => 'Please select a rejection reason:';

  @override
  String get buttonRejectAction => 'Reject';

  @override
  String get dialogFailedToLoadDataTitle => 'Failed to Load Data';

  @override
  String get dialogSelectVehicleTitle => 'Select vehicle';

  @override
  String get dialogSelectWarehouseTitle => 'Select Warehouse';

  @override
  String get dialogSubmissionFailedTitle => 'Submission Failed';

  @override
  String get dialogFailedToLoadItemsTitle => 'Failed to Load Pending Delivery Items';

  @override
  String get transferOriginWarehouseHint => 'Select origin warehouse';

  @override
  String get transferDestinationWarehouseHint => 'Select destination warehouse';

  @override
  String get ordersPageTitle => 'Orders';

  @override
  String get ordersSearchHint => 'Search orders...';

  @override
  String get ordersFilterDeliveryStatus => 'Delivery Status';

  @override
  String get ordersFilterVehicle => 'Vehicle';

  @override
  String get ordersFilterWarehouse => 'Warehouse';

  @override
  String get ordersFilterStatus => 'Status';

  @override
  String get dialogFailedToLoadWarehousesTitle => 'Failed to Load Warehouses';

  @override
  String get dialogFailedToLoadPartnersTitle => 'Failed to Load Partners';

  @override
  String get dialogOrderCreationFailedTitle => 'Order Creation Failed';

  @override
  String get orderTypeRefill => 'Refill';

  @override
  String get orderTypeNFR => 'NFR';

  @override
  String get seedCodeLabel => 'Enter Seed Code *';

  @override
  String get driverPhoneLabel => 'Driver Phone Number';

  @override
  String get driverNameLabel => 'Driver Name *';

  @override
  String get driverSearching => 'Searching drivers...';

  @override
  String get buttonCreateNewDriver => 'Create New Driver';

  @override
  String get dialogSelectDriverTitle => 'Select Driver';

  @override
  String get dialogSelectItemsToDispatchTitle => 'Select Items to Dispatch';

  @override
  String get noItemsAvailable => 'No items available';

  @override
  String get sdmsCreateTransactionTitle => 'Create SDMS Transaction';

  @override
  String get sdmsNoUserCode => 'No SDMS User Code';

  @override
  String get sdmsOnlyPaymentAvailable => 'Only Credit Payment transactions are available';

  @override
  String get sdmsOrderIdHint => 'Enter sales order ID';

  @override
  String get sdmsOrderIdLabel => 'Sales Order ID *';

  @override
  String get sdmsCreateTransactionLabel => 'Create Transaction';

  @override
  String get sdmsSearchHint => 'Search by Order ID';

  @override
  String get reportsPageTitle => 'Reports';

  @override
  String get warehouseStockTitle => 'Warehouse Stock';

  @override
  String get warehouseStockDetails => 'Stock Details';

  @override
  String get warehouseStockAvailable => 'Available';

  @override
  String get warehouseStockReserved => 'Reserved';

  @override
  String get warehouseStockProjected => 'Projected';

  @override
  String warehouseStockMergedFrom(Object count) {
    return 'Merged from $count warehouses';
  }

  @override
  String warehouseStockItems(Object count) {
    return '$count items';
  }

  @override
  String get warehouseStockLoading => 'Loading stock data...';

  @override
  String get warehouseStockError => 'Error loading stock data';

  @override
  String get warehouseStockNoData => 'No stock data available';

  @override
  String get warehouseStockSelectWarehouse => 'Select Warehouse';

  @override
  String get warehouseStockUnknownWarehouse => 'Unknown Warehouse';

  @override
  String get warehouseStockUnknownItem => 'Unknown Item';

  @override
  String get ordersEmptyOrders => 'No orders found';

  @override
  String get inventoryRequestDetailsTitle => 'Request Details';

  @override
  String get inventoryFailedToLoadDetails => 'Failed to load request details';

  @override
  String get inventoryRequestID => 'Request ID';

  @override
  String get inventoryRequestType => 'Request Type';

  @override
  String get inventoryCreatedAt => 'Created At';

  @override
  String get inventoryRejectionReason => 'Rejection Reason';

  @override
  String get inventoryNotesLabel => 'Notes';

  @override
  String get inventoryTransferDetailsTitle => 'Transfer Details';

  @override
  String get inventoryFromSource => 'From (Source)';

  @override
  String get inventoryToDestination => 'To (Destination)';

  @override
  String get inventoryUnknownWarehouse => 'Unknown Warehouse';

  @override
  String get inventoryItemsLabel => 'Items';

  @override
  String get inventoryUnlinkedLabel => 'Unlinked';

  @override
  String get inventorySalesOrderLabel => 'Sales Order';

  @override
  String get inventoryMaterialRequestLabel => 'Material Request';

  @override
  String get inventoryItemDetailsHeader => 'Item Details';

  @override
  String get inventoryQtyHeader => 'Qty';

  @override
  String get inventoryCodeLabel => 'Code';

  @override
  String get inventoryDefectiveDetailsLabel => 'DEFECTIVE DETAILS';

  @override
  String get inventoryCylinderNumber => 'Cylinder number';

  @override
  String get inventoryTareWeight => 'Tare Wt';

  @override
  String get inventoryGrossWeight => 'Gross Wt';

  @override
  String get inventoryNetWeight => 'Net Wt';

  @override
  String get inventoryFaultType => 'Fault';

  @override
  String get inventoryConsumerDetailsLabel => 'Consumer Details:';

  @override
  String get inventoryConsumerNumber => 'Number';

  @override
  String get inventoryConsumerName => 'Name';

  @override
  String get inventoryConsumerMobile => 'Mobile';

  @override
  String get inventoryRemarksLabel => 'Remarks';

  @override
  String get inventoryAddCommentsHint => 'Add comments for approval/rejection...';

  @override
  String inventoryStatusApprovedMessage(Object type) {
    return 'This $type request has been approved';
  }

  @override
  String inventoryStatusRejectedMessage(Object type) {
    return 'This $type request has been rejected';
  }

  @override
  String inventoryStatusPendingMessage(Object type) {
    return 'This $type request is pending approval';
  }

  @override
  String inventoryApproveConfirmMessage(Object type) {
    return 'Are you sure you want to approve this $type request?';
  }

  @override
  String get inventoryCancelRequestButton => 'Cancel Request';

  @override
  String get rejectionReasonIncorrectCount => 'Incorrect Count';

  @override
  String get rejectionReasonWrongItems => 'Wrong Items';

  @override
  String get rejectionReasonDepositProcessed => 'Deposit Already Processed';

  @override
  String get rejectionReasonDefectiveMissing => 'Defective item Missing';

  @override
  String get rejectionReasonInsufficientStock => 'Insufficient Stock';

  @override
  String get rejectionReasonOrdersNotEligible => 'Orders Not Eligible';

  @override
  String get rejectionReasonVehicleNotAvailable => 'Vehicle Not Available';

  @override
  String get rejectionReasonWarehouseClosed => 'Warehouse Closed';

  @override
  String get rejectionReasonInsufficientStockSource => 'Insufficient Stock at Source';

  @override
  String get rejectionReasonDestinationFull => 'Destination Warehouse Full';

  @override
  String get rejectionReasonTransferBlocked => 'Transfer Route Blocked';

  @override
  String get messagePleaseWait => 'Please wait while processing...';

  @override
  String get labelUnknown => 'Unknown';

  @override
  String get labelID => 'ID';

  @override
  String get depositTitle => 'Deposit';

  @override
  String get depositTypeLabel => 'Type';

  @override
  String get depositSelectItemsTitle => 'Select';

  @override
  String get depositBackToScreen => 'Back to Deposit Screen';

  @override
  String get depositAddAtLeastOneItem => 'Please add at least one item';

  @override
  String get depositSelectWarehouseWarning => 'Please select a warehouse';

  @override
  String get depositSelectVehicleWarning => 'Please select a vehicle';

  @override
  String get depositConfirmSubmitMessage => 'Are you sure you want to submit this deposit request?';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get collectFailedToLoadItems => 'Failed to Load Pending Delivery Items';

  @override
  String get collectSelectDeliveryItems => 'Select Delivery Items';

  @override
  String get collectSelectedItems => 'Selected Items';

  @override
  String collectAndMoreItems(int count) {
    return 'and $count more items';
  }

  @override
  String get collectTotalQuantity => 'Total Quantity:';

  @override
  String get collectBackToChallan => 'Back to Challan';

  @override
  String get collectCollectingFrom => 'Collecting from:';

  @override
  String get collectConfirmTitle => 'Confirm Collection';

  @override
  String get collectConfirmSubmitMessage => 'Are you sure you want to submit this collection request?';

  @override
  String get collectFromWarehouse => 'From Warehouse';

  @override
  String get depositUnlinked => 'Unlinked';

  @override
  String get depositSalesOrder => 'Sales Order';

  @override
  String get depositMaterialRequest => 'Material Request';

  @override
  String get inventoryRequestedBy => 'Requested by:';

  @override
  String get orderStatusLabel => 'Status:';

  @override
  String get inventoryVehicleNumber => 'Vehicle Number:';

  @override
  String get inventoryEmptyRequests => 'No inventory requests';

  @override
  String get notificationApprovalRequired => 'Approval required';

  @override
  String get emptyStateCreateFirst => 'Create your first item';

  @override
  String get emptyStateTryAgain => 'Try again';

  @override
  String get errorGeneric => 'An error occurred';

  @override
  String get quotaHistoryTitle => 'Quota History';

  @override
  String get stockReportTitle => 'Stock Report';

  @override
  String get quotaHistoryViewHistory => 'View Quota History';

  @override
  String get quotaHistoryLoading => 'Loading history...';

  @override
  String get quotaHistoryError => 'Failed to load history';

  @override
  String get quotaHistoryEmpty => 'No history found for this period';

  @override
  String get quotaHistoryLoadingMore => 'Loading more...';

  @override
  String get quotaHistoryRetry => 'Retry';

  @override
  String get quotaHistoryFilterTitle => 'Select Date Range';

  @override
  String get quotaHistoryLast7Days => 'Last 7 Days';

  @override
  String get quotaHistoryLast30Days => 'Last 30 Days';

  @override
  String get quotaHistoryThisMonth => 'This Month';

  @override
  String get quotaHistoryLastMonth => 'Last Month';

  @override
  String get quotaHistoryCustomRange => 'Custom Range...';

  @override
  String get quotaHistorySummaryTitle => 'Summary';

  @override
  String get quotaHistoryNet => 'Net';

  @override
  String get quotaHistoryOtp => 'OTP';

  @override
  String get quotaHistoryOverride => 'Override';

  @override
  String get quotaHistoryBonus => 'Bonus';

  @override
  String get quotaHistoryPostingRatio => 'Posting';

  @override
  String get quotaHistoryAllItems => 'All Items';

  @override
  String get quotaHistoryNetPickup => 'Net Pickup';

  @override
  String get quotaHistoryBlankSales => 'Blank';

  @override
  String get quotaHistoryOpening => 'Opening';

  @override
  String get quotaHistoryClosing => 'Closing';

  @override
  String get quotaHistoryPickups => 'Pickups';

  @override
  String get quotaHistoryReturns => 'Returns';

  @override
  String get quotaHistoryAdjustment => 'Adj';

  @override
  String get quotaHistoryMoreDetails => 'More Details';

  @override
  String get quotaHistoryLessDetails => 'Less Details';

  @override
  String get quotaHistorySdms => 'SDMS';

  @override
  String get quotaBonusTitle => 'Bonus Summary';

  @override
  String get quotaBonusTotalBonus => 'Total Bonus';

  @override
  String get quotaBonusActiveCount => 'Active Bonuses';

  @override
  String quotaBonusExpiryCountdown(Object days) {
    return 'Expires in $days days';
  }

  @override
  String get quotaBonusExpiryWarning => 'Bonus expiring soon!';

  @override
  String get quotaBonusQualified => 'Qualified';

  @override
  String get quotaBonusNotQualified => 'Not Qualified';

  @override
  String get quotaBonusPostingRatioLabel => 'Posting Ratio';

  @override
  String get quotaBonusTargetRatio => 'Target: 90%';

  @override
  String get quotaDetailsButton => 'Details';

  @override
  String get bonusSchemesTitle => 'Bonus Schemes';

  @override
  String get bonusListTitle => 'My Bonuses';

  @override
  String get bonusDetailTitle => 'Bonus Details';

  @override
  String get bonusSchemeDescription => 'How Bonuses Work';

  @override
  String get bonusActiveTab => 'Active';

  @override
  String get bonusConsumedTab => 'Consumed';

  @override
  String get bonusExpiredTab => 'Expired';

  @override
  String get bonusAllTab => 'All';

  @override
  String get bonusExpiringToday => 'Expires Today';

  @override
  String get bonusExpiringTomorrow => 'Expires Tomorrow';

  @override
  String get bonusExpiringSoon => 'Expires Soon';

  @override
  String get bonusSourceMetricsTitle => 'Calculation Breakdown';

  @override
  String bonusQualificationRequirement(Object ratio) {
    return 'Maintain $ratio% posting ratio';
  }

  @override
  String bonusRewardAmount(Object percentage) {
    return 'Earn $percentage% bonus';
  }

  @override
  String bonusValidityPeriod(Object days) {
    return 'Valid for $days days';
  }

  @override
  String get bonusViewAllButton => 'View All Bonuses';

  @override
  String get bonusHowItWorksButton => 'How Bonuses Work';

  @override
  String get bonusNoSchemesAvailable => 'No bonus schemes available';

  @override
  String get bonusNoBonusesFound => 'No bonuses found';

  @override
  String get bonusLoadingSchemes => 'Loading schemes...';

  @override
  String get bonusLoadingBonuses => 'Loading bonuses...';

  @override
  String get bonusLoadingDetail => 'Loading bonus details...';

  @override
  String get bonusErrorLoadingSchemes => 'Failed to load bonus schemes';

  @override
  String get bonusErrorLoadingBonuses => 'Failed to load bonuses';

  @override
  String get bonusErrorLoadingDetail => 'Failed to load bonus details';

  @override
  String get bonusSummaryTitle => 'Bonus Summary';

  @override
  String get bonusQuantityRemaining => 'Remaining';

  @override
  String get bonusQuantityEarned => 'Earned';

  @override
  String get bonusQuantityConsumed => 'Consumed';

  @override
  String get bonusConsumptionLabel => 'Consumption';

  @override
  String get bonusStatusActive => 'Active';

  @override
  String get bonusStatusConsumed => 'Fully Consumed';

  @override
  String get bonusStatusExpired => 'Expired';

  @override
  String get bonusStatusVoided => 'Voided';
}
