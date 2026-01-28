// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एलपीजी वितरण';

  @override
  String get notificationChannelName => 'उच्च महत्व की सूचनाएं';

  @override
  String get notificationChannelDescription => 'यह चैनल महत्वपूर्ण सूचनाओं के लिए उपयोग किया जाता है।';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get profileRefresh => 'प्रोफ़ाइल ताज़ा करें';

  @override
  String get profileMoreOptionsTooltip => 'अधिक विकल्प';

  @override
  String get profileLoading => 'प्रोफ़ाइल लोड हो रही है...';

  @override
  String get profileAccountInformation => 'खाते की जानकारी';

  @override
  String get profileCompanyLabel => 'कंपनी';

  @override
  String get profileAccountLabel => 'खाता';

  @override
  String get profileWarehouseLabel => 'वेयरहाउस';

  @override
  String get profileRoleLabel => 'भूमिका';

  @override
  String get profileRolesLabel => 'भूमिकाएँ';

  @override
  String get profileNotAssigned => 'निर्धारित नहीं';

  @override
  String get profileContactInformation => 'संपर्क जानकारी';

  @override
  String get profilePhoneNumber => 'फ़ोन नंबर';

  @override
  String get profileEmail => 'ईमेल';

  @override
  String get profileVehicleInformation => 'वाहन जानकारी';

  @override
  String get profileVehicleNumber => 'वाहन नंबर';

  @override
  String get profileAppInformation => 'ऐप जानकारी';

  @override
  String get profileCurrentVersion => 'वर्तमान संस्करण';

  @override
  String get profileRequiredUpdate => 'आवश्यक अपडेट - इंस्टॉल करने के लिए टैप करें';

  @override
  String get profileRecommendedUpdate => 'अनुशंसित अपडेट उपलब्ध';

  @override
  String get profileInformUpdate => 'नया संस्करण उपलब्ध';

  @override
  String get profileBecomePartner => 'साझेदार बनें';

  @override
  String get profileEditPassword => 'पासवर्ड बदलें';

  @override
  String get profileLogout => 'लॉग आउट';

  @override
  String get profileLogoutConfirmTitle => 'लॉग आउट की पुष्टि करें';

  @override
  String get profileLogoutConfirmMessage => 'क्या आप वास्तव में अपने खाते से लॉग आउट करना चाहते हैं? ऐप का उपयोग जारी रखने के लिए आपको फिर से लॉग इन करना होगा।';

  @override
  String get profileLogoutConfirmCancel => 'रद्द करें';

  @override
  String get profileLogoutConfirmProceed => 'लॉग आउट';

  @override
  String profileCopyTooltip(Object label) {
    return '$label कॉपी करें';
  }

  @override
  String profileCopyMessage(Object label) {
    return '$label क्लिपबोर्ड पर कॉपी किया गया';
  }

  @override
  String profileVersionPrefix(Object version) {
    return 'संस्करण $version';
  }

  @override
  String get profileActionSheetTitle => 'प्रोफ़ाइल विकल्प';

  @override
  String get profileActionEditProfileTitle => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileActionEditProfileSubtitle => 'अपनी व्यक्तिगत जानकारी अपडेट करें';

  @override
  String get profileActionSwitchCompanyTitle => 'कंपनी बदलें';

  @override
  String get profileActionSwitchCompanySubtitle => 'अपनी सक्रिय कंपनी बदलें';

  @override
  String get profileActionChangePasswordTitle => 'पासवर्ड बदलें';

  @override
  String get profileActionChangePasswordSubtitle => 'अपनी सुरक्षा साख अपडेट करें';

  @override
  String get profileActionChangePasswordMessage => 'पासवर्ड बदलने की सुविधा जल्द ही आ रही है';

  @override
  String get profileActionNotificationSettingsTitle => 'सूचना सेटिंग्स';

  @override
  String get profileActionNotificationSettingsSubtitle => 'अपनी सूचना प्राथमिकताएँ प्रबंधित करें';

  @override
  String get profileActionNotificationSettingsMessage => 'सूचना सेटिंग्स सुविधा जल्द ही आ रही है';

  @override
  String get profileActionHelpTitle => 'सहायता और समर्थन';

  @override
  String get profileActionHelpSubtitle => 'सहायता और समर्थन प्राप्त करें';

  @override
  String get profileActionHelpMessage => 'सहायता और समर्थन सुविधा जल्द ही आ रही है';

  @override
  String get profileActionLogoutTitle => 'लॉग आउट';

  @override
  String get profileActionLogoutSubtitle => 'अपने खाते से साइन आउट करें';

  @override
  String get profileCompanySwitcherTitle => 'कंपनी बदलें';

  @override
  String get profileCompanySwitcherActive => 'सक्रिय';

  @override
  String profileCompanyCode(Object code) {
    return 'कोड: $code';
  }

  @override
  String get profileCompanySwitchButton => 'बदलें';

  @override
  String profileSwitchFailed(Object error) {
    return 'कंपनी बदलने में विफल: $error';
  }

  @override
  String profileCompaniesLoadFailed(Object error) {
    return 'कंपनियाँ लोड करने में विफल: $error';
  }

  @override
  String profileErrorLoading(Object error) {
    return 'प्रोफ़ाइल लोड करने में त्रुटि: $error';
  }

  @override
  String profileOptionalDataError(Object error) {
    return 'वैकल्पिक उपयोगकर्ता डेटा उपलब्ध नहीं: $error';
  }

  @override
  String profileLogoutError(Object error) {
    return 'लॉग आउट में त्रुटि: $error';
  }

  @override
  String profileNavigationError(Object error) {
    return 'नेविगेशन त्रुटि: $error';
  }

  @override
  String profileVersionUpdateFailed(Object error) {
    return 'अपडेट विफल: $error';
  }

  @override
  String get profileSwitchingTo => 'बदल रहे हैं:';

  @override
  String get profileActiveCompanyLabel => 'उपयोगकर्ता';

  @override
  String get profileLanguageToggle => 'भाषा';

  @override
  String get profileLanguageEnglish => 'अंग्रेज़ी';

  @override
  String get profileLanguageHindi => 'हिंदी';

  @override
  String get errorUnableToGetDownloadUrl => 'डाउनलोड URL प्राप्त नहीं किया जा सका';

  @override
  String errorDownloadFailed(Object error) {
    return 'डाउनलोड विफल रहा: $error';
  }

  @override
  String get errorEnterUsernamePassword => 'कृपया उपयोगकर्ता नाम और पासवर्ड दोनों दर्ज करें';

  @override
  String get errorLoginFailed => 'लॉगिन विफल रहा। कृपया पुनः प्रयास करें।';

  @override
  String get errorAppUpdateRequired => 'ऐप अपडेट आवश्यक है। कृपया नवीनतम संस्करण डाउनलोड करें।';

  @override
  String get errorConnectionTimeout => 'कनेक्शन टाइमआउट हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get errorNoInternetConnection => 'कोई इंटरनेट कनेक्शन नहीं है। कृपया अपना नेटवर्क जाँचें।';

  @override
  String get errorDownloadFailedTitle => 'डाउनलोड विफल';

  @override
  String get errorDownloadUpdateFailed => 'अपडेट डाउनलोड नहीं हो सका। कृपया पुनः प्रयास करें या वेबसाइट से डाउनलोड करें।';

  @override
  String get buttonOk => 'ठीक है';

  @override
  String get companyArunGasServices => 'अरुण गैस सेवाएँ';

  @override
  String get loginToYourAccount => 'अपने खाते में लॉगिन करें';

  @override
  String get labelUsername => 'उपयोगकर्ता नाम';

  @override
  String get labelPassword => 'पासवर्ड';

  @override
  String get linkForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get linkSignUpForNewAccount => 'नया खाता पंजीकृत करें';

  @override
  String get buttonLogin => 'लॉगिन';

  @override
  String get errorNoUserRoleAssigned => 'कोई उपयोगकर्ता भूमिका असाइन नहीं है';

  @override
  String get errorContactAdministrator => 'कृपया प्रशासक से संपर्क करें।';

  @override
  String get linkBecomePartner => 'साझेदार बनें';

  @override
  String get linkContinuePartnerRegistration => 'साझेदार पंजीकरण जारी रखें';

  @override
  String get navHome => 'होम';

  @override
  String get navOrders => 'ऑर्डर';

  @override
  String get navCash => 'नकद';

  @override
  String get navInventory => 'इन्वेंट्री';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get dashboardTitle => 'डैशबोर्ड';

  @override
  String get dashboardRefreshTooltip => 'डैशबोर्ड रीफ्रेश करें';

  @override
  String get dashboardLoadingLabel => 'डैशबोर्ड लोड हो रहा है...';

  @override
  String get dashboardRefreshSuccess => 'डैशबोर्ड रीफ्रेश हो गया';

  @override
  String get dashboardRefreshFailure => 'डैशबोर्ड रीफ्रेश करने में विफल';

  @override
  String get dashboardUserLoadFailure => 'उपयोगकर्ता जानकारी लोड करने में विफल';

  @override
  String get dashboardDataLoadFailure => 'डैशबोर्ड डेटा लोड करने में विफल';

  @override
  String get dashboardGreetingMorning => 'सुप्रभात';

  @override
  String get dashboardGreetingAfternoon => 'नमस्कार';

  @override
  String get dashboardGreetingEvening => 'शुभ संध्या';

  @override
  String get dashboardUserFallback => 'उपयोगकर्ता';

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
    return '$count लंबित स्वीकृति';
  }

  @override
  String dashboardPendingApprovalsMultiple(Object count) {
    return '$count लंबित स्वीकृतियाँ';
  }

  @override
  String get dashboardQuickActionsTitle => 'विकल्प सूची';

  @override
  String get dashboardCreateOrderTitle => 'ऑर्डर बनाएँ';

  @override
  String get dashboardCreateOrderSubtitle => 'नया बिक्री ऑर्डर';

  @override
  String get dashboardCashDepositTitle => 'कैश जमा';

  @override
  String get dashboardCashDepositSubtitle => 'संग्रह जमा करें';

  @override
  String get dashboardChallanTitle => 'चालान';

  @override
  String get dashboardChallanSubtitle => 'नया चालान बनाएँ';

  @override
  String get dashboardDepositItemsTitle => 'खाली सिलेंडर जमा करें';

  @override
  String get dashboardDepositItemsSubtitle => 'खाली सिलेंडर जमा करे';

  @override
  String get dashboardInventoryManagementTitle => 'इन्वेंट्री प्रबंधन';

  @override
  String get dashboardProcurementTitle => 'प्रोक्योरमेंट (परचेज इनवॉइस)';

  @override
  String get dashboardProcurementSubtitle => 'वाहन प्रवेश/निकास रिकॉर्ड';

  @override
  String get dashboardInventoryApprovalsTitle => 'इन्वेंट्री स्वीकृतियाँ';

  @override
  String get dashboardInventoryApprovalsSubtitle => 'लंबित अनुरोध देखें';

  @override
  String get dashboardCashManagementTitle => 'कैश प्रबंधन';

  @override
  String get dashboardCashApprovalsTitle => 'कैश स्वीकृतियाँ';

  @override
  String get dashboardCashApprovalsSubtitle => 'लंबित जमा की समीक्षा करें';

  @override
  String get dashboardCustomerSupportTitle => 'ग्राहक सहायता';

  @override
  String get dashboardOpenTicketsTitle => 'खुले टिकट';

  @override
  String get dashboardOpenTicketsSubtitle => 'ग्राहक सहायता अनुरोध';

  @override
  String get dashboardResolvedTodayLabel => 'आज हल किए गए';

  @override
  String get dashboardAverageResponseLabel => 'औसत प्रतिक्रिया';

  @override
  String get dashboardSystemOverviewTitle => 'सिस्टम अवलोकन';

  @override
  String get dashboardTodaysOrdersLabel => 'आज के ऑर्डर';

  @override
  String get dashboardActiveUsersLabel => 'सक्रिय उपयोगकर्ता';

  @override
  String get dashboardAllApprovalsTitle => 'सभी स्वीकृतियाँ';

  @override
  String get dashboardGettingStartedTitle => 'शुरुआत करें';

  @override
  String get dashboardViewProfileTitle => 'प्रोफ़ाइल देखें';

  @override
  String get dashboardViewProfileSubtitle => 'व्यक्तिगत जानकारी';

  @override
  String get dashboardStatusClear => 'साफ़';

  @override
  String dashboardInventoryPendingSubtitle(Object count) {
    return '$count आइटम स्वीकृति चाहते हैं';
  }

  @override
  String dashboardCashPendingSubtitle(Object count) {
    return '$count जमा स्वीकृति चाहते हैं';
  }

  @override
  String get dashboardOrderApprovalsTitle => 'ऑर्डर स्वीकृतियाँ';

  @override
  String dashboardOrdersPendingSubtitle(Object count) {
    return '$count ऑर्डर स्वीकृति चाहते हैं';
  }

  @override
  String get dashboardCseTicketsTitle => 'सीएसई टिकट';

  @override
  String dashboardTicketsPendingSubtitle(Object count) {
    return '$count टिकट ध्यान चाहते हैं';
  }

  @override
  String get dashboardNoPendingNotifications => 'कोई लंबित सूचना नहीं';

  @override
  String get dashboardNotificationsTitle => 'सूचनाएँ';

  @override
  String dashboardPendingCountLabel(Object count) {
    return '$count लंबित';
  }

  @override
  String get dashboardOrderApprovalsComingSoon => 'ऑर्डर स्वीकृतियाँ जल्द उपलब्ध होंगी';

  @override
  String get dashboardCseTicketsComingSoon => 'सीएसई टिकट सुविधा जल्द आ रही है';

  @override
  String dashboardNewApprovalPending(Object module) {
    return 'नई $module स्वीकृति लंबित';
  }

  @override
  String get dashboardModuleInventory => 'इन्वेंट्री';

  @override
  String get dashboardModuleCash => 'कैश';

  @override
  String get dashboardModuleOrders => 'ऑर्डर';

  @override
  String get dashboardModuleCse => 'ग्राहक सहायता';

  @override
  String get dashboardRoleDeliveryBoy => 'डिलीवरी बॉय';

  @override
  String get dashboardRoleWarehouseManager => 'वेयरहाउस प्रबंधक';

  @override
  String get dashboardRoleGeneralManager => 'महाप्रबंधक';

  @override
  String get dashboardRoleCustomerServiceExecutive => 'ग्राहक सेवा कार्यकारी';

  @override
  String get dashboardRoleCashier => 'कैशियर';

  @override
  String dashboardAdditionalRoles(Object firstRole, Object remainingCount) {
    return '$firstRole + $remainingCount और';
  }

  @override
  String get dashboardRolesSeparator => ' और ';

  @override
  String get buttonRetry => 'पुनः प्रयास';

  @override
  String get buttonCancel => 'रद्द करें';

  @override
  String get buttonClose => 'बंद करें';

  @override
  String get buttonApprove => 'स्वीकृत करें';

  @override
  String get buttonReject => 'अस्वीकार करें';

  @override
  String get buttonSave => 'सेव करें';

  @override
  String get buttonSubmit => 'जमा करें';

  @override
  String get buttonDelete => 'हटाएं';

  @override
  String get buttonEdit => 'संपादित करें';

  @override
  String get buttonAdd => 'जोड़ें';

  @override
  String get buttonRemove => 'हटाएं';

  @override
  String get buttonChange => 'Change';

  @override
  String get buttonRefresh => 'रीफ्रेश';

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
  String get statusPending => 'लंबित';

  @override
  String get statusApproved => 'स्वीकृत';

  @override
  String get statusRejected => 'अस्वीकृत';

  @override
  String get statusProcessing => 'प्रक्रिया में';

  @override
  String get statusCompleted => 'पूर्ण';

  @override
  String get statusCancelled => 'रद्द';

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
  String get loginWelcomeTitle => 'वापस स्वागत है';

  @override
  String get loginSubtitle => 'जारी रखने के लिए साइन इन करें';

  @override
  String get loginUsernameHint => 'अपना उपयोगकर्ता नाम दर्ज करें';

  @override
  String get loginPasswordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get loginForgotPassword => 'पासवर्ड भूल गए?';

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
  String get panNumberLabel => 'पैन नंबर';

  @override
  String get panNumberHint => 'ABCDE1234F';

  @override
  String get panNumberRequired => 'PAN number is required';

  @override
  String get panNumberInvalid => 'Invalid PAN format. Use: AAAAA9999A';

  @override
  String get cashPageTitle => 'कैश प्रबंधन';

  @override
  String get cashSearchHint => 'आईडी, नाम, संदर्भ से खोजें...';

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
  String get rejectionReasonOther => 'अन्य';

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
  String get inventoryPageTitle => 'इन्वेंट्री';

  @override
  String get inventorySearchHint => 'आइटम, वाहन, अनुरोध से खोजें...';

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
  String get inventorySelectRejectionReason => 'कृपया अस्वीकृति कारण चुनें:';

  @override
  String get buttonRejectAction => 'Reject';

  @override
  String get dialogFailedToLoadDataTitle => 'Failed to Load Data';

  @override
  String get dialogSelectVehicleTitle => 'वाहन चुनें';

  @override
  String get dialogSelectWarehouseTitle => 'वेयरहाउस चुनें';

  @override
  String get dialogSubmissionFailedTitle => 'Submission Failed';

  @override
  String get dialogFailedToLoadItemsTitle => 'Failed to Load Pending Delivery Items';

  @override
  String get transferOriginWarehouseHint => 'Select origin warehouse';

  @override
  String get transferDestinationWarehouseHint => 'Select destination warehouse';

  @override
  String get ordersPageTitle => 'ऑर्डर';

  @override
  String get ordersSearchHint => 'ऑर्डर आईडी, ग्राहक से खोजें...';

  @override
  String get ordersFilterDeliveryStatus => 'डिलीवरी स्थिति';

  @override
  String get ordersFilterVehicle => 'वाहन';

  @override
  String get ordersFilterWarehouse => 'वेयरहाउस';

  @override
  String get ordersFilterStatus => 'स्थिति';

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
  String get sdmsSearchHint => 'ग्राहक, सिलेंडर से खोजें...';

  @override
  String get reportsPageTitle => 'रिपोर्ट';

  @override
  String get warehouseStockTitle => 'वेयरहाउस स्टॉक';

  @override
  String get warehouseStockDetails => 'स्टॉक विवरण';

  @override
  String get warehouseStockAvailable => 'उपलब्ध';

  @override
  String get warehouseStockReserved => 'आरक्षित';

  @override
  String get warehouseStockProjected => 'अनुमानित';

  @override
  String warehouseStockMergedFrom(Object count) {
    return '$count वेयरहाउस से विलयित';
  }

  @override
  String warehouseStockItems(Object count) {
    return '$count आइटम';
  }

  @override
  String get warehouseStockLoading => 'स्टॉक डेटा लोड हो रहा है...';

  @override
  String get warehouseStockError => 'स्टॉक डेटा लोड करने में त्रुटि';

  @override
  String get warehouseStockNoData => 'कोई स्टॉक डेटा उपलब्ध नहीं है';

  @override
  String get warehouseStockSelectWarehouse => 'वेयरहाउस चुनें';

  @override
  String get warehouseStockUnknownWarehouse => 'अज्ञात वेयरहाउस';

  @override
  String get warehouseStockUnknownItem => 'अज्ञात आइटम';

  @override
  String get ordersEmptyOrders => 'कोई ऑर्डर नहीं मिला';

  @override
  String get inventoryRequestDetailsTitle => 'अनुरोध विवरण';

  @override
  String get inventoryFailedToLoadDetails => 'अनुरोध विवरण लोड करने में विफल';

  @override
  String get inventoryRequestID => 'अनुरोध आईडी';

  @override
  String get inventoryRequestType => 'अनुरोध प्रकार';

  @override
  String get inventoryCreatedAt => 'बनाया गया';

  @override
  String get inventoryRejectionReason => 'अस्वीकृति कारण';

  @override
  String get inventoryNotesLabel => 'नोट्स';

  @override
  String get inventoryTransferDetailsTitle => 'स्थानांतरण विवरण';

  @override
  String get inventoryFromSource => 'से (स्रोत)';

  @override
  String get inventoryToDestination => 'को (गंतव्य)';

  @override
  String get inventoryUnknownWarehouse => 'अज्ञात वेयरहाउस';

  @override
  String get inventoryItemsLabel => 'आइटम';

  @override
  String get inventoryUnlinkedLabel => 'असंबद्ध';

  @override
  String get inventorySalesOrderLabel => 'बिक्री आदेश';

  @override
  String get inventoryMaterialRequestLabel => 'सामग्री अनुरोध';

  @override
  String get inventoryItemDetailsHeader => 'आइटम विवरण';

  @override
  String get inventoryQtyHeader => 'मात्रा';

  @override
  String get inventoryCodeLabel => 'कोड';

  @override
  String get inventoryDefectiveDetailsLabel => 'दोषपूर्ण विवरण';

  @override
  String get inventoryCylinderNumber => 'सिलेंडर नंबर';

  @override
  String get inventoryTareWeight => 'टेयर वजन';

  @override
  String get inventoryGrossWeight => 'सकल वजन';

  @override
  String get inventoryNetWeight => 'शुद्ध वजन';

  @override
  String get inventoryFaultType => 'दोष';

  @override
  String get inventoryConsumerDetailsLabel => 'उपभोक्ता विवरण:';

  @override
  String get inventoryConsumerNumber => 'नंबर';

  @override
  String get inventoryConsumerName => 'नाम';

  @override
  String get inventoryConsumerMobile => 'मोबाइल';

  @override
  String get inventoryRemarksLabel => 'टिप्पणी';

  @override
  String get inventoryAddCommentsHint => 'अनुमोदन/अस्वीकृति के लिए टिप्पणी जोड़ें...';

  @override
  String inventoryStatusApprovedMessage(Object type) {
    return 'यह $type अनुरोध स्वीकृत हो गया है';
  }

  @override
  String inventoryStatusRejectedMessage(Object type) {
    return 'यह $type अनुरोध अस्वीकृत हो गया है';
  }

  @override
  String inventoryStatusPendingMessage(Object type) {
    return 'यह $type अनुरोध अनुमोदन के लिए लंबित है';
  }

  @override
  String inventoryApproveConfirmMessage(Object type) {
    return 'क्या आप वाकई इस $type अनुरोध को स्वीकृत करना चाहते हैं?';
  }

  @override
  String get inventoryCancelRequestButton => 'अनुरोध रद्द करें';

  @override
  String get rejectionReasonIncorrectCount => 'गलत गिनती';

  @override
  String get rejectionReasonWrongItems => 'गलत आइटम';

  @override
  String get rejectionReasonDepositProcessed => 'जमा पहले से संसाधित';

  @override
  String get rejectionReasonDefectiveMissing => 'दोषपूर्ण आइटम गायब';

  @override
  String get rejectionReasonInsufficientStock => 'अपर्याप्त स्टॉक';

  @override
  String get rejectionReasonOrdersNotEligible => 'ऑर्डर पात्र नहीं';

  @override
  String get rejectionReasonVehicleNotAvailable => 'वाहन उपलब्ध नहीं';

  @override
  String get rejectionReasonWarehouseClosed => 'वेयरहाउस बंद';

  @override
  String get rejectionReasonInsufficientStockSource => 'स्रोत पर अपर्याप्त स्टॉक';

  @override
  String get rejectionReasonDestinationFull => 'गंतव्य वेयरहाउस भरा हुआ';

  @override
  String get rejectionReasonTransferBlocked => 'स्थानांतरण मार्ग अवरुद्ध';

  @override
  String get messagePleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get labelUnknown => 'अज्ञात';

  @override
  String get labelID => 'आईडी';

  @override
  String get depositTitle => 'जमा';

  @override
  String get depositTypeLabel => 'प्रकार';

  @override
  String get depositSelectItemsTitle => 'चयन करें';

  @override
  String get depositBackToScreen => 'जमा स्क्रीन पर वापस जाएं';

  @override
  String get depositAddAtLeastOneItem => 'कृपया कम से कम एक आइटम जोड़ें';

  @override
  String get depositSelectWarehouseWarning => 'कृपया एक वेयरहाउस चुनें';

  @override
  String get depositSelectVehicleWarning => 'कृपया एक वाहन चुनें';

  @override
  String get depositConfirmSubmitMessage => 'क्या आप वाकई इस जमा अनुरोध को सबमिट करना चाहते हैं?';

  @override
  String get buttonConfirm => 'पुष्टि करें';

  @override
  String get collectFailedToLoadItems => 'लंबित डिलीवरी आइटम लोड करने में विफल';

  @override
  String get collectSelectDeliveryItems => 'डिलीवरी आइटम चुनें';

  @override
  String get collectSelectedItems => 'चयनित आइटम';

  @override
  String collectAndMoreItems(int count) {
    return 'और $count अधिक आइटम';
  }

  @override
  String get collectTotalQuantity => 'कुल मात्रा:';

  @override
  String get collectBackToChallan => 'चालान पर वापस जाएं';

  @override
  String get collectCollectingFrom => 'से एकत्रित:';

  @override
  String get collectConfirmTitle => 'संग्रहण की पुष्टि करें';

  @override
  String get collectConfirmSubmitMessage => 'क्या आप वाकई इस संग्रहण अनुरोध को सबमिट करना चाहते हैं?';

  @override
  String get collectFromWarehouse => 'वेयरहाउस से';

  @override
  String get depositUnlinked => 'अनलिंक्ड';

  @override
  String get depositSalesOrder => 'विक्रय आदेश';

  @override
  String get depositMaterialRequest => 'सामग्री अनुरोध';

  @override
  String get inventoryRequestedBy => 'द्वारा अनुरोधित:';

  @override
  String get orderStatusLabel => 'स्थिति:';

  @override
  String get inventoryVehicleNumber => 'वाहन नंबर:';

  @override
  String get inventoryEmptyRequests => 'कोई इन्वेंट्री अनुरोध नहीं';

  @override
  String get notificationApprovalRequired => 'अनुमोदन आवश्यक';

  @override
  String get emptyStateCreateFirst => 'अपना पहला आइटम बनाएं';

  @override
  String get emptyStateTryAgain => 'पुनः प्रयास करें';

  @override
  String get errorGeneric => 'एक त्रुटि हुई';

  @override
  String get quotaHistoryTitle => 'कोटा इतिहास';

  @override
  String get stockReportTitle => 'स्टॉक रिपोर्ट';

  @override
  String get quotaHistoryViewHistory => 'कोटा इतिहास देखें';

  @override
  String get quotaHistoryLoading => 'इतिहास लोड हो रहा है...';

  @override
  String get quotaHistoryError => 'इतिहास लोड करने में विफल';

  @override
  String get quotaHistoryEmpty => 'इस अवधि के लिए कोई इतिहास नहीं मिला';

  @override
  String get quotaHistoryLoadingMore => 'और लोड हो रहा है...';

  @override
  String get quotaHistoryRetry => 'पुनः प्रयास करें';

  @override
  String get quotaHistoryFilterTitle => 'तिथि सीमा चुनें';

  @override
  String get quotaHistoryLast7Days => 'पिछले 7 दिन';

  @override
  String get quotaHistoryLast30Days => 'पिछले 30 दिन';

  @override
  String get quotaHistoryThisMonth => 'यह महीना';

  @override
  String get quotaHistoryLastMonth => 'पिछला महीना';

  @override
  String get quotaHistoryCustomRange => 'कस्टम रेंज...';

  @override
  String get quotaHistorySummaryTitle => 'सारांश';

  @override
  String get quotaHistoryNet => 'नेट';

  @override
  String get quotaHistoryOtp => 'ओटीपी';

  @override
  String get quotaHistoryOverride => 'ओवरराइड';

  @override
  String get quotaHistoryBonus => 'बोनस';

  @override
  String get quotaHistoryPostingRatio => 'पोस्टिंग';

  @override
  String get quotaHistoryAllItems => 'सभी आइटम';

  @override
  String get quotaHistoryNetPickup => 'नेट पिकअप';

  @override
  String get quotaHistoryBlankSales => 'ब्लैंक';

  @override
  String get quotaHistoryOpening => 'शुरुआत';

  @override
  String get quotaHistoryClosing => 'समापन';

  @override
  String get quotaHistoryPickups => 'पिकअप';

  @override
  String get quotaHistoryReturns => 'रिटर्न';

  @override
  String get quotaHistoryAdjustment => 'समायोजन';

  @override
  String get quotaHistoryMoreDetails => 'अधिक विवरण';

  @override
  String get quotaHistoryLessDetails => 'कम विवरण';

  @override
  String get quotaHistorySdms => 'एसडीएमएस';

  @override
  String get quotaBonusTitle => 'बोनस सारांश';

  @override
  String get quotaBonusTotalBonus => 'कुल बोनस';

  @override
  String get quotaBonusActiveCount => 'सक्रिय बोनस';

  @override
  String quotaBonusExpiryCountdown(Object days) {
    return '$days दिनों में समाप्त';
  }

  @override
  String get quotaBonusExpiryWarning => 'बोनस जल्द समाप्त हो रहा है!';

  @override
  String get quotaBonusQualified => 'योग्य';

  @override
  String get quotaBonusNotQualified => 'अयोग्य';

  @override
  String get quotaBonusPostingRatioLabel => 'पोस्टिंग अनुपात';

  @override
  String get quotaBonusTargetRatio => 'लक्ष्य: 90%';

  @override
  String get quotaDetailsButton => 'विवरण';

  @override
  String get bonusSchemesTitle => 'बोनस योजनाएं';

  @override
  String get bonusListTitle => 'मेरे बोनस';

  @override
  String get bonusDetailTitle => 'बोनस विवरण';

  @override
  String get bonusSchemeDescription => 'बोनस कैसे काम करता है';

  @override
  String get bonusActiveTab => 'सक्रिय';

  @override
  String get bonusConsumedTab => 'उपयोग किया गया';

  @override
  String get bonusExpiredTab => 'समाप्त';

  @override
  String get bonusAllTab => 'सभी';

  @override
  String get bonusExpiringToday => 'आज समाप्त हो रहा है';

  @override
  String get bonusExpiringTomorrow => 'कल समाप्त हो रहा है';

  @override
  String get bonusExpiringSoon => 'जल्द समाप्त हो रहा है';

  @override
  String get bonusSourceMetricsTitle => 'गणना विवरण';

  @override
  String bonusQualificationRequirement(Object ratio) {
    return '$ratio% पोस्टिंग अनुपात बनाए रखें';
  }

  @override
  String bonusRewardAmount(Object percentage) {
    return 'नेट पिकअप पर $percentage% बोनस अर्जित करें';
  }

  @override
  String bonusValidityPeriod(Object days) {
    return '$days दिनों के लिए वैध';
  }

  @override
  String get bonusViewAllButton => 'सभी बोनस देखें';

  @override
  String get bonusHowItWorksButton => 'बोनस कैसे काम करता है';

  @override
  String get bonusNoSchemesAvailable => 'कोई बोनस योजना उपलब्ध नहीं है';

  @override
  String get bonusNoBonusesFound => 'कोई बोनस नहीं मिला';

  @override
  String get bonusLoadingSchemes => 'योजनाएं लोड हो रही हैं...';

  @override
  String get bonusLoadingBonuses => 'बोनस लोड हो रहे हैं...';

  @override
  String get bonusLoadingDetail => 'बोनस विवरण लोड हो रहा है...';

  @override
  String get bonusErrorLoadingSchemes => 'बोनस योजनाएं लोड करने में विफल';

  @override
  String get bonusErrorLoadingBonuses => 'बोनस लोड करने में विफल';

  @override
  String get bonusErrorLoadingDetail => 'बोनस विवरण लोड करने में विफल';

  @override
  String get bonusSummaryTitle => 'बोनस सारांश';

  @override
  String get bonusQuantityRemaining => 'शेष';

  @override
  String get bonusQuantityEarned => 'अर्जित';

  @override
  String get bonusQuantityConsumed => 'उपयोग किया गया';

  @override
  String get bonusConsumptionLabel => 'उपभोग';

  @override
  String get bonusStatusActive => 'सक्रिय';

  @override
  String get bonusStatusConsumed => 'पूर्ण रूप से उपयोग किया गया';

  @override
  String get bonusStatusExpired => 'समाप्त';

  @override
  String get bonusStatusVoided => 'रद्द';
}
