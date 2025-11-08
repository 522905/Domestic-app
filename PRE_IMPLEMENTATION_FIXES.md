# Pre-Implementation Fixes & Complete Translations

**Version:** 1.0
**Date:** November 8, 2025
**Purpose:** Address responsive issues, add complete translations, identify duplicate code before UI implementation

---

## 📋 Table of Contents

1. [Critical Responsive Fixes Required](#critical-responsive-fixes-required)
2. [Complete Translation Keys](#complete-translation-keys)
3. [Duplicate Widget Analysis](#duplicate-widget-analysis)
4. [Code Optimization Guidelines](#code-optimization-guidelines)

---

## 🚨 CRITICAL RESPONSIVE FIXES REQUIRED

### Summary
- **92 dialogs/popups found** across 45 files
- **12 critical issues** that will overflow on small screens
- **8 files** need immediate fixes

### Issue Severity Breakdown

| Severity | Count | Status |
|----------|-------|--------|
| **CRITICAL** | 4 | Must fix before implementation |
| **HIGH** | 5 | Should fix soon |
| **MEDIUM** | 3 | Review and test |

---

### CRITICAL FIXES (DO BEFORE IMPLEMENTATION)

#### 1. Error Dialog - Missing ScrollView ⚠️

**File:** `lib/presentation/widgets/error_dialog.dart`
**Line:** 89-112

**Current Code (BROKEN):**
```dart
return AlertDialog(
  title: Row(...),
  content: Column(  // ⚠️ NO SCROLL WRAPPER
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message, ...),
      if (rawError != null) ...[
        // Technical details can be VERY LONG
        Container(
          width: double.infinity,
          // This WILL overflow on small screens
```

**FIXED CODE:**
```dart
return AlertDialog(
  title: Row(...),
  content: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
      maxWidth: 400.w,
    ),
    child: SingleChildScrollView(  // ✅ ADDED
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, ...),
          if (rawError != null) ...[
            Container(
              width: double.infinity,
              // Now scrollable
```

**Why:** Error messages with technical details can be very long and will overflow screen on phones < 5 inches.

---

#### 2. Item Selector Dialog - Missing ScrollView ⚠️

**File:** `lib/presentation/widgets/selectors/item_selector_dialog.dart`
**Line:** 122-189

**Current Code (BROKEN):**
```dart
Dialog(
  shape: RoundedRectangleBorder(...),
  child: Container(
    width: MediaQuery.of(context).size.width * 0.9,
    padding: EdgeInsets.all(16.w),
    child: Column(  // ⚠️ NO SCROLL WRAPPER
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Select Item', ...),  // Title
        SizedBox(height: 16.h),
        TextField(...),  // Search
        SizedBox(height: 16.h),
        Container(
          constraints: BoxConstraints(maxHeight: 400.h),  // Fixed height
          child: Flexible(  // This doesn't help without outer scroll
```

**FIXED CODE:**
```dart
Dialog(
  shape: RoundedRectangleBorder(...),
  child: Container(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.9,
      maxHeight: MediaQuery.of(context).size.height * 0.85,  // ✅ ADDED
    ),
    padding: EdgeInsets.all(16.w),
    child: SingleChildScrollView(  // ✅ ADDED
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Item', ...),
          SizedBox(height: 16.h),
          TextField(...),
          SizedBox(height: 16.h),
          Container(
            constraints: BoxConstraints(
              maxHeight: min(400.h, MediaQuery.of(context).size.height * 0.5),  // ✅ FIXED
            ),
```

**Why:** On landscape mode or tablets, the title + search bar + list can exceed screen height.

---

#### 3. Cash Receipt Printer Dialog - Fixed Height ⚠️

**File:** `lib/utils/cash_receipt_dialog.dart`
**Line:** 247-327

**Current Code (BROKEN):**
```dart
AlertDialog(
  title: Text('Select Printer'),
  content: SizedBox(
    height: 300.h,  // ⚠️ FIXED HEIGHT - Will overflow on small screens
    width: double.maxFinite,
    child: _availableDevices.isEmpty
```

**FIXED CODE:**
```dart
AlertDialog(
  title: Text('Select Printer'),
  content: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: min(300.h, MediaQuery.of(context).size.height * 0.6),  // ✅ FIXED
      maxWidth: double.maxFinite,
    ),
    child: SingleChildScrollView(  // ✅ ADDED (in case of many printers)
      child: _availableDevices.isEmpty
```

**Why:** Phones with 4.5" screen will cut off the bottom of the dialog.

---

#### 4. Gatepass Printer Dialog - Same Issue ⚠️

**File:** `lib/utils/gatepass_dialog.dart`
**Line:** 239-327

**Same fix as Cash Receipt Dialog above.**

---

### HIGH PRIORITY FIXES

#### 5. Driver Selector Dialog

**File:** `lib/presentation/widgets/selectors/driver_selector_dialog.dart`
**Line:** 45

**Fix:** Wrap content in `SingleChildScrollView` at top level

**Current:**
```dart
Dialog(
  child: Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    child: Column(  // ⚠️ Should be scrollable
```

**Fixed:**
```dart
Dialog(
  child: Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    child: SingleChildScrollView(  // ✅ ADDED
      child: Column(
```

---

#### 6. Profile Action Bottom Sheet

**File:** `lib/presentation/widgets/profile/profile_aciton_dialog.dart`
**Line:** 30-37

**Current:**
```dart
showModalBottomSheet(
  context: context,
  shape: RoundedRectangleBorder(...),
  builder: (context) => ProfileActionDialog(actions: actions),
);
```

**Fixed:**
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // ✅ ADDED
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,  // ✅ ADDED
  ),
  shape: RoundedRectangleBorder(...),
  builder: (context) => ProfileActionDialog(actions: actions),
);
```

---

### STANDARD RESPONSIVE PATTERNS

Use these patterns for all future dialogs:

#### Pattern 1: Standard Dialog (Most Common)
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: min(400.w, MediaQuery.of(context).size.width * 0.95),
      ),
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(  // ✅ ALWAYS ADD THIS
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your content here
          ],
        ),
      ),
    ),
  ),
);
```

#### Pattern 2: AlertDialog with Content
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(  // ✅ ALWAYS ADD THIS
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your content here
          ],
        ),
      ),
    ),
    actions: [...],
  ),
);
```

#### Pattern 3: Modal Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,  // ✅ IMPORTANT
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.9,
  ),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
  ),
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.9,
    builder: (context, scrollController) => ListView(
      controller: scrollController,
      // Your content here
    ),
  ),
);
```

---

## 🌍 COMPLETE TRANSLATION KEYS

### Summary
- **200+ hardcoded strings** found
- **25 files** need localization
- **8 categories** of strings

### Translation File Structure

All keys organized by:
1. **Common** - Shared across app (buttons, actions)
2. **Auth** - Login, signup, password
3. **Cash** - Cash management
4. **Inventory** - Inventory screens
5. **Orders** - Orders screens
6. **Profile** - User profile
7. **SDMS** - SDMS module
8. **Purchase** - Purchase invoice

---

### 1. COMMON TRANSLATIONS (Shared)

#### English (`app_en.arb`)
```json
{
  "@@locale": "en",

  "buttonRetry": "Retry",
  "buttonCancel": "Cancel",
  "buttonClose": "Close",
  "buttonApprove": "Approve",
  "buttonReject": "Reject",
  "buttonSave": "Save",
  "buttonSubmit": "Submit",
  "buttonDelete": "Delete",
  "buttonEdit": "Edit",
  "buttonAdd": "Add",
  "buttonRemove": "Remove",
  "buttonChange": "Change",
  "buttonRefresh": "REFRESH",
  "buttonCreateNew": "Create New",
  "buttonCreateAnother": "Create Another",
  "buttonBackToList": "Back to List",
  "buttonTryAgain": "Try Again",
  "buttonClearAll": "Clear All",
  "buttonClearFilters": "Clear Filters",
  "buttonUseOrderId": "Use This Order ID",
  "buttonScanAgain": "Scan Again",

  "dialogErrorTitle": "Error",
  "dialogSuccessTitle": "Success",
  "dialogConfirmTitle": "Confirm",
  "dialogWarningTitle": "Warning",
  "dialogInfoTitle": "Information",
  "dialogOptionAll": "All",

  "statusPending": "Pending",
  "statusApproved": "Approved",
  "statusRejected": "Rejected",
  "statusProcessing": "Processing",
  "statusCompleted": "Completed",
  "statusCancelled": "Cancelled",

  "tableHeaderAccount": "Account",
  "tableHeaderLedger": "Ledger",
  "tableHeaderOpen": "Open",
  "tableHeaderAvailable": "Available",

  "loadingPleaseWait": "Please wait...",
  "loadingSearching": "Searching...",
  "loadingSubmitting": "Submitting...",
  "loadingLoading": "Loading..."
}
```

#### Hindi (`app_hi.arb`)
```json
{
  "@@locale": "hi",

  "buttonRetry": "पुनः प्रयास करें",
  "buttonCancel": "रद्द करें",
  "buttonClose": "बंद करें",
  "buttonApprove": "स्वीकृत करें",
  "buttonReject": "अस्वीकार करें",
  "buttonSave": "सहेजें",
  "buttonSubmit": "जमा करें",
  "buttonDelete": "हटाएं",
  "buttonEdit": "संपादित करें",
  "buttonAdd": "जोड़ें",
  "buttonRemove": "हटाएं",
  "buttonChange": "बदलें",
  "buttonRefresh": "ताज़ा करें",
  "buttonCreateNew": "नया बनाएं",
  "buttonCreateAnother": "एक और बनाएं",
  "buttonBackToList": "सूची पर वापस जाएं",
  "buttonTryAgain": "फिर कोशिश करें",
  "buttonClearAll": "सभी साफ़ करें",
  "buttonClearFilters": "फ़िल्टर साफ़ करें",
  "buttonUseOrderId": "इस ऑर्डर आईडी का उपयोग करें",
  "buttonScanAgain": "फिर से स्कैन करें",

  "dialogErrorTitle": "त्रुटि",
  "dialogSuccessTitle": "सफलता",
  "dialogConfirmTitle": "पुष्टि करें",
  "dialogWarningTitle": "चेतावनी",
  "dialogInfoTitle": "जानकारी",
  "dialogOptionAll": "सभी",

  "statusPending": "लंबित",
  "statusApproved": "स्वीकृत",
  "statusRejected": "अस्वीकृत",
  "statusProcessing": "प्रक्रिया में",
  "statusCompleted": "पूर्ण",
  "statusCancelled": "रद्द",

  "tableHeaderAccount": "खाता",
  "tableHeaderLedger": "लेजर",
  "tableHeaderOpen": "खुला",
  "tableHeaderAvailable": "उपलब्ध",

  "loadingPleaseWait": "कृपया प्रतीक्षा करें...",
  "loadingSearching": "खोज रहे हैं...",
  "loadingSubmitting": "जमा कर रहे हैं...",
  "loadingLoading": "लोड हो रहा है..."
}
```

---

### 2. AUTHENTICATION TRANSLATIONS

#### English
```json
{
  "loginWelcomeTitle": "Welcome Back",
  "loginSubtitle": "Sign in to continue",
  "loginUsernameHint": "Enter Mobile Number / Username",
  "loginPasswordHint": "Enter Password",
  "loginButton": "LOGIN",
  "loginForgotPassword": "Forgot Password?",
  "loginNoAccount": "Don't have an account?",
  "loginSignUpButtonLabel": "Sign Up for New Account",

  "forgotPasswordScreenTitle": "Reset Password",
  "forgotPasswordAadharLabel": "Aadhar Number",
  "forgotPasswordOtpLabel": "6-Digit OTP",
  "forgotPasswordNewPasswordLabel": "New Password",
  "forgotPasswordConfirmPasswordLabel": "Confirm New Password",

  "signUpAadharLabel": "Aadhar Number",
  "signUpPhoneLabel": "Phone Number",
  "signUpAadharRequired": "Aadhar number is required",
  "signUpAadharInvalid": "Aadhar must be exactly 12 digits",
  "signUpAadharChecksum": "Invalid Aadhar number",
  "signUpPhoneRequired": "Phone number is required",
  "signUpPhoneInvalid": "Phone number must be exactly 10 digits",

  "passwordChangeScreenTitle": "Change Password",
  "passwordChangeSectionTitle": "Change Password",
  "passwordChangeSubtitle": "Update your account password to keep your account secure",
  "passwordChangeCurrentLabel": "Current Password",
  "passwordChangeCurrentHint": "Enter current password",
  "passwordChangeNewLabel": "New Password",
  "passwordChangeNewHint": "Enter new password",
  "passwordChangeConfirmLabel": "Confirm New Password",
  "passwordChangeConfirmHint": "Confirm new password",
  "buttonChangingPassword": "CHANGING...",
  "buttonChangePassword": "CHANGE PASSWORD",
  "passwordChangeCurrentRequired": "Current password is required",
  "passwordChangeNewRequired": "New password is required",
  "passwordChangeNewMinLength": "Password must be at least 6 characters",
  "passwordChangeNewDifferent": "New password must be different from current password",
  "passwordChangeConfirmRequired": "Please confirm your new password",
  "passwordChangeConfirmMismatch": "New Password does not match with Confirm Password",

  "panVerificationScreenTitle": "Become Partner",
  "panVerificationHeading": "Partner Registration",
  "panVerificationSubtitle": "Enter your PAN number to begin the partner verification process",
  "panNumberLabel": "PAN Number",
  "panNumberHint": "Enter PAN (e.g., AZJPG7110R)",
  "panNumberRequired": "PAN number is required",
  "panNumberInvalid": "Invalid PAN format. Use: AAAAA9999A"
}
```

#### Hindi
```json
{
  "loginWelcomeTitle": "वापस स्वागत है",
  "loginSubtitle": "जारी रखने के लिए साइन इन करें",
  "loginUsernameHint": "मोबाइल नंबर / यूजरनेम दर्ज करें",
  "loginPasswordHint": "पासवर्ड दर्ज करें",
  "loginButton": "लॉगिन",
  "loginForgotPassword": "पासवर्ड भूल गए?",
  "loginNoAccount": "खाता नहीं है?",
  "loginSignUpButtonLabel": "नया खाता पंजीकृत करें",

  "forgotPasswordScreenTitle": "पासवर्ड रीसेट करें",
  "forgotPasswordAadharLabel": "आधार नंबर",
  "forgotPasswordOtpLabel": "6-अंकीय OTP",
  "forgotPasswordNewPasswordLabel": "नया पासवर्ड",
  "forgotPasswordConfirmPasswordLabel": "नए पासवर्ड की पुष्टि करें",

  "signUpAadharLabel": "आधार नंबर",
  "signUpPhoneLabel": "फ़ोन नंबर",
  "signUpAadharRequired": "आधार नंबर आवश्यक है",
  "signUpAadharInvalid": "आधार ठीक 12 अंकों का होना चाहिए",
  "signUpAadharChecksum": "अमान्य आधार नंबर",
  "signUpPhoneRequired": "फ़ोन नंबर आवश्यक है",
  "signUpPhoneInvalid": "फ़ोन नंबर ठीक 10 अंकों का होना चाहिए",

  "passwordChangeScreenTitle": "पासवर्ड बदलें",
  "passwordChangeSectionTitle": "पासवर्ड बदलें",
  "passwordChangeSubtitle": "अपने खाते को सुरक्षित रखने के लिए अपना पासवर्ड अपडेट करें",
  "passwordChangeCurrentLabel": "वर्तमान पासवर्ड",
  "passwordChangeCurrentHint": "वर्तमान पासवर्ड दर्ज करें",
  "passwordChangeNewLabel": "नया पासवर्ड",
  "passwordChangeNewHint": "नया पासवर्ड दर्ज करें",
  "passwordChangeConfirmLabel": "नए पासवर्ड की पुष्टि करें",
  "passwordChangeConfirmHint": "नए पासवर्ड की पुष्टि करें",
  "buttonChangingPassword": "बदल रहे हैं...",
  "buttonChangePassword": "पासवर्ड बदलें",
  "passwordChangeCurrentRequired": "वर्तमान पासवर्ड आवश्यक है",
  "passwordChangeNewRequired": "नया पासवर्ड आवश्यक है",
  "passwordChangeNewMinLength": "पासवर्ड कम से कम 6 अक्षर का होना चाहिए",
  "passwordChangeNewDifferent": "नया पासवर्ड वर्तमान पासवर्ड से अलग होना चाहिए",
  "passwordChangeConfirmRequired": "कृपया अपने नए पासवर्ड की पुष्टि करें",
  "passwordChangeConfirmMismatch": "नया पासवर्ड पुष्टिकरण पासवर्ड से मेल नहीं खाता",

  "panVerificationScreenTitle": "साझेदार बनें",
  "panVerificationHeading": "साझेदार पंजीकरण",
  "panVerificationSubtitle": "साझेदार सत्यापन प्रक्रिया शुरू करने के लिए अपना PAN नंबर दर्ज करें",
  "panNumberLabel": "PAN नंबर",
  "panNumberHint": "PAN दर्ज करें (उदा., AZJPG7110R)",
  "panNumberRequired": "PAN नंबर आवश्यक है",
  "panNumberInvalid": "अमान्य PAN प्रारूप। उपयोग करें: AAAAA9999A"
}
```

---

### 3. CASH MANAGEMENT TRANSLATIONS

#### English
```json
{
  "cashPageTitle": "Cash Management",
  "cashSearchHint": "Search by ID, name, reference...",
  "cashLoadingError": "Error loading cash data:",
  "cashAccountBalancesTitle": "Account Balances",
  "cashDataNotAvailable": "Data not available",
  "cashPullToRefresh": "Pull down to refresh",
  "cashNoAccountData": "No account data available",
  "cashAccountDefault": "Cash Account",
  "cashViewTransactionHistory": "View Transaction History",
  "cashDepositActionTitle": "Cash Deposit",
  "cashDepositActionSubtitle": "Deposit cash to Manager",
  "cashHandoverActionTitle": "Handover Cash",
  "cashHandoverActionSubtitle": "Handover cash to Manager",
  "cashBankDepositActionTitle": "Bank Deposit",
  "cashBankDepositActionSubtitle": "Deposit cash directly to bank",

  "cashDepositAmountHint": "Enter amount",
  "cashDepositAccountSelectHint": "Select Account Paid To",
  "cashDepositRemarksHint": "Enter any remarks or notes",

  "handoverAccountSelectHint": "Select Account for Handover",
  "handoverAmountHint": "Enter amount",
  "handoverRemarksHint": "Enter any remarks or notes",

  "bankDepositAmountHint": "Enter amount",
  "bankDepositReferenceHint": "Enter receipt or reference number",
  "bankDepositRemarksHint": "Enter any remarks or notes",

  "transactionDetailsTitle": "Transaction Details",
  "transactionApproving": "Approving transaction...",
  "transactionRejecting": "Rejecting transaction...",
  "rejectionReasonIncorrectAmount": "Incorrect Amount",
  "rejectionReasonAmountMismatch": "Cash Amount Mismatch",
  "rejectionReasonMissingReceipt": "Missing Receipt",
  "rejectionReasonOther": "Other",
  "transactionCommentsHint": "Additional Comments (Optional)",
  "buttonVerifyCashReceived": "VERIFY CASH RECEIVED",
  "dialogReceiptImageTitle": "Receipt Image",
  "imageLoadError": "Failed to load image",
  "dialogBankDepositSlipTitle": "Bank Deposit Slip"
}
```

#### Hindi
```json
{
  "cashPageTitle": "नकद प्रबंधन",
  "cashSearchHint": "आईडी, नाम, संदर्भ से खोजें...",
  "cashLoadingError": "नकद डेटा लोड करने में त्रुटि:",
  "cashAccountBalancesTitle": "खाता शेष",
  "cashDataNotAvailable": "डेटा उपलब्ध नहीं",
  "cashPullToRefresh": "ताज़ा करने के लिए नीचे खींचें",
  "cashNoAccountData": "कोई खाता डेटा उपलब्ध नहीं",
  "cashAccountDefault": "नकद खाता",
  "cashViewTransactionHistory": "लेनदेन इतिहास देखें",
  "cashDepositActionTitle": "कैश जमा",
  "cashDepositActionSubtitle": "प्रबंधक को नकद जमा करें",
  "cashHandoverActionTitle": "नकद सौंपना",
  "cashHandoverActionSubtitle": "प्रबंधक को नकद सौंपें",
  "cashBankDepositActionTitle": "बैंक जमा",
  "cashBankDepositActionSubtitle": "बैंक में सीधे नकद जमा करें",

  "cashDepositAmountHint": "राशि दर्ज करें",
  "cashDepositAccountSelectHint": "भुगतान खाता चुनें",
  "cashDepositRemarksHint": "कोई टिप्पणी या नोट दर्ज करें",

  "handoverAccountSelectHint": "सौंपने के लिए खाता चुनें",
  "handoverAmountHint": "राशि दर्ज करें",
  "handoverRemarksHint": "कोई टिप्पणी या नोट दर्ज करें",

  "bankDepositAmountHint": "राशि दर्ज करें",
  "bankDepositReferenceHint": "रसीद या संदर्भ नंबर दर्ज करें",
  "bankDepositRemarksHint": "कोई टिप्पणी या नोट दर्ज करें",

  "transactionDetailsTitle": "लेनदेन विवरण",
  "transactionApproving": "लेनदेन स्वीकृत कर रहे हैं...",
  "transactionRejecting": "लेनदेन अस्वीकार कर रहे हैं...",
  "rejectionReasonIncorrectAmount": "गलत राशि",
  "rejectionReasonAmountMismatch": "नकद राशि बेमेल",
  "rejectionReasonMissingReceipt": "रसीद गायब",
  "rejectionReasonOther": "अन्य",
  "transactionCommentsHint": "अतिरिक्त टिप्पणियाँ (वैकल्पिक)",
  "buttonVerifyCashReceived": "नकद प्राप्त की पुष्टि करें",
  "dialogReceiptImageTitle": "रसीद छवि",
  "imageLoadError": "छवि लोड करने में विफल",
  "dialogBankDepositSlipTitle": "बैंक जमा पर्ची"
}
```

---

### 4. INVENTORY TRANSLATIONS

#### English
```json
{
  "inventoryPageTitle": "Inventory",
  "inventorySearchHint": "Search Requests...",
  "inventoryDepositUnlinkedTitle": "Deposit Inventory (Unlinked)",
  "inventoryDepositUnlinkedSubtitle": "Deposit items for warehouse",
  "inventoryDepositSaleOrderTitle": "Deposit Inventory (Sale Order)",
  "inventoryDepositSaleOrderSubtitle": "Deposit items against sale orders",
  "inventoryDepositMaterialRequestTitle": "Deposit Inventory (Material Request)",
  "inventoryDepositMaterialRequestSubtitle": "Deposit items against material requests",
  "inventoryCreateChallanTitle": "Create Challan",
  "inventoryCreateChallanSubtitle": "Create a inventory challan",
  "inventoryTransferTitle": "Inventory Transfer",
  "inventoryTransferSubtitle": "Transfer items to another warehouse",

  "dialogRequestDetailsTitle": "Request Details",
  "inventoryApproveButton": "Approve {type}",
  "inventoryApproveConfirmation": "Are you sure you want to approve this {type} request?",
  "inventoryRejectButton": "Reject {type}",
  "inventorySelectRejectionReason": "Please select a rejection reason:",
  "buttonRejectAction": "Reject",

  "dialogFailedToLoadDataTitle": "Failed to Load Data",
  "dialogSelectVehicleTitle": "Select vehicle",
  "dialogSelectWarehouseTitle": "Select Warehouse",
  "dialogSubmissionFailedTitle": "Submission Failed",
  "dialogFailedToLoadItemsTitle": "Failed to Load Pending Delivery Items",

  "transferOriginWarehouseHint": "Select origin warehouse",
  "transferDestinationWarehouseHint": "Select destination warehouse"
}
```

#### Hindi
```json
{
  "inventoryPageTitle": "इन्वेंटरी",
  "inventorySearchHint": "अनुरोध खोजें...",
  "inventoryDepositUnlinkedTitle": "इन्वेंटरी जमा करें (बिना लिंक)",
  "inventoryDepositUnlinkedSubtitle": "वेयरहाउस के लिए आइटम जमा करें",
  "inventoryDepositSaleOrderTitle": "इन्वेंटरी जमा करें (बिक्री ऑर्डर)",
  "inventoryDepositSaleOrderSubtitle": "बिक्री ऑर्डर के विरुद्ध आइटम जमा करें",
  "inventoryDepositMaterialRequestTitle": "इन्वेंटरी जमा करें (सामग्री अनुरोध)",
  "inventoryDepositMaterialRequestSubtitle": "सामग्री अनुरोध के विरुद्ध आइटम जमा करें",
  "inventoryCreateChallanTitle": "चालान बनाएं",
  "inventoryCreateChallanSubtitle": "इन्वेंटरी चालान बनाएं",
  "inventoryTransferTitle": "इन्वेंटरी ट्रांसफर",
  "inventoryTransferSubtitle": "दूसरे वेयरहाउस में आइटम ट्रांसफर करें",

  "dialogRequestDetailsTitle": "अनुरोध विवरण",
  "inventoryApproveButton": "{type} स्वीकृत करें",
  "inventoryApproveConfirmation": "क्या आप वास्तव में इस {type} अनुरोध को स्वीकृत करना चाहते हैं?",
  "inventoryRejectButton": "{type} अस्वीकार करें",
  "inventorySelectRejectionReason": "कृपया अस्वीकृति कारण चुनें:",
  "buttonRejectAction": "अस्वीकार करें",

  "dialogFailedToLoadDataTitle": "डेटा लोड करने में विफल",
  "dialogSelectVehicleTitle": "वाहन चुनें",
  "dialogSelectWarehouseTitle": "वेयरहाउस चुनें",
  "dialogSubmissionFailedTitle": "सबमिशन विफल",
  "dialogFailedToLoadItemsTitle": "लंबित डिलीवरी आइटम लोड करने में विफल",

  "transferOriginWarehouseHint": "मूल वेयरहाउस चुनें",
  "transferDestinationWarehouseHint": "गंतव्य वेयरहाउस चुनें"
}
```

---

### 5. ORDERS TRANSLATIONS

#### English
```json
{
  "ordersPageTitle": "Orders",
  "ordersSearchHint": "Search orders...",
  "ordersFilterDeliveryStatus": "Delivery Status",
  "ordersFilterVehicle": "Vehicle",
  "ordersFilterWarehouse": "Warehouse",
  "ordersFilterStatus": "Status",

  "dialogFailedToLoadWarehousesTitle": "Failed to Load Warehouses",
  "dialogFailedToLoadItemsTitle": "Failed to Load Items",
  "dialogFailedToLoadPartnersTitle": "Failed to Load Partners",
  "dialogOrderCreationFailedTitle": "Order Creation Failed",

  "orderTypeRefill": "Refill",
  "orderTypeNFR": "NFR"
}
```

#### Hindi
```json
{
  "ordersPageTitle": "ऑर्डर",
  "ordersSearchHint": "ऑर्डर खोजें...",
  "ordersFilterDeliveryStatus": "डिलीवरी स्थिति",
  "ordersFilterVehicle": "वाहन",
  "ordersFilterWarehouse": "वेयरहाउस",
  "ordersFilterStatus": "स्थिति",

  "dialogFailedToLoadWarehousesTitle": "वेयरहाउस लोड करने में विफल",
  "dialogFailedToLoadItemsTitle": "आइटम लोड करने में विफल",
  "dialogFailedToLoadPartnersTitle": "साझेदार लोड करने में विफल",
  "dialogOrderCreationFailedTitle": "ऑर्डर निर्माण विफल",

  "orderTypeRefill": "रीफिल",
  "orderTypeNFR": "NFR"
}
```

---

### 6. PURCHASE INVOICE TRANSLATIONS

#### English
```json
{
  "seedCodeLabel": "Enter Seed Code *",
  "driverPhoneLabel": "Driver Phone Number",
  "driverNameLabel": "Driver Name *",
  "driverSearching": "Searching drivers...",
  "buttonCreateNewDriver": "Create New Driver",
  "dialogSelectDriverTitle": "Select Driver",

  "dialogSelectItemsToDispatchTitle": "Select Items to Dispatch",
  "noItemsAvailable": "No items available"
}
```

#### Hindi
```json
{
  "seedCodeLabel": "सीड कोड दर्ज करें *",
  "driverPhoneLabel": "ड्राइवर फ़ोन नंबर",
  "driverNameLabel": "ड्राइवर का नाम *",
  "driverSearching": "ड्राइवर खोज रहे हैं...",
  "buttonCreateNewDriver": "नया ड्राइवर बनाएं",
  "dialogSelectDriverTitle": "ड्राइवर चुनें",

  "dialogSelectItemsToDispatchTitle": "भेजने के लिए आइटम चुनें",
  "noItemsAvailable": "कोई आइटम उपलब्ध नहीं"
}
```

---

### 7. SDMS TRANSLATIONS

#### English
```json
{
  "sdmsCreateTransactionTitle": "Create SDMS Transaction",
  "sdmsNoUserCode": "No SDMS User Code",
  "sdmsOnlyPaymentAvailable": "Only Credit Payment transactions are available",
  "sdmsOrderIdHint": "Enter sales order ID",
  "sdmsOrderIdLabel": "Sales Order ID *",
  "sdmsCreateTransactionLabel": "Create Transaction",
  "sdmsSearchHint": "Search by Order ID"
}
```

#### Hindi
```json
{
  "sdmsCreateTransactionTitle": "SDMS लेनदेन बनाएं",
  "sdmsNoUserCode": "कोई SDMS उपयोगकर्ता कोड नहीं",
  "sdmsOnlyPaymentAvailable": "केवल क्रेडिट भुगतान लेनदेन उपलब्ध हैं",
  "sdmsOrderIdHint": "बिक्री ऑर्डर आईडी दर्ज करें",
  "sdmsOrderIdLabel": "बिक्री ऑर्डर आईडी *",
  "sdmsCreateTransactionLabel": "लेनदेन बनाएं",
  "sdmsSearchHint": "ऑर्डर आईडी से खोजें"
}
```

---

### 8. REPORTS TRANSLATIONS

#### English
```json
{
  "reportsPageTitle": "Reports"
}
```

#### Hindi
```json
{
  "reportsPageTitle": "रिपोर्ट"
}
```

---

## 🔄 DUPLICATE WIDGET ANALYSIS

### Widgets That Can Be Consolidated

#### 1. **Selector Dialogs (4 Similar Widgets)**

**Files:**
- `lib/presentation/widgets/selectors/driver_selector_dialog.dart`
- `lib/presentation/widgets/selectors/vehicle_selector_dialog.dart`
- `lib/presentation/widgets/selectors/warehouse_selector_dialog.dart`
- `lib/presentation/widgets/selectors/item_selector_dialog.dart`

**Similarity:** All follow same pattern:
- Search bar at top
- List of items with selection
- Single selection vs multi-selection

**Consolidation Opportunity:**
Create ONE generic `ProfessionalSelectorDialog<T>` widget:

```dart
// lib/presentation/widgets/professional_selector_dialog.dart

class ProfessionalSelectorDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getDisplayText;
  final String Function(T) getSearchText;
  final bool multiSelect;
  final void Function(T) onSingleSelect;
  final void Function(List<T>) onMultiSelect;

  // Use like:
  // ProfessionalSelectorDialog<Driver>(
  //   title: 'Select Driver',
  //   items: drivers,
  //   getDisplayText: (d) => d.name,
  //   getSearchText: (d) => '${d.name} ${d.phone}',
  //   ...
  // )
}
```

**Action:** Comment out 3 duplicate files, keep one as template

---

#### 2. **Error Dialogs (3 Similar)**

**Files:**
- `lib/presentation/widgets/error_dialog.dart`
- `lib/presentation/widgets/sdms/sdms_error_dialog.dart`
- `lib/core/services/validation_error_dialog.dart`

**Consolidation:**
Create ONE `ProfessionalErrorDialog` widget with customization options

**Action:** Keep `validation_error_dialog.dart` (it's best implemented), comment others, add note to use it

---

#### 3. **Loading Indicators (Scattered)**

**Found in:**
- Multiple files use `CircularProgressIndicator` directly
- Some use custom sized boxes

**Consolidation:**
Create ONE `ProfessionalLoadingIndicator` widget:

```dart
// lib/presentation/widgets/professional_loading_indicator.dart

class ProfessionalLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final widget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primaryBlue),
        if (message != null) ...[
          SizedBox(height: 16.h),
          Text(message!, style: AppTextStyles.bodyMedium),
        ],
      ],
    );

    return fullScreen
      ? Center(child: widget)
      : widget;
  }
}
```

---

#### 4. **Printer Dialogs (2 Identical)**

**Files:**
- `lib/utils/cash_receipt_dialog.dart`
- `lib/utils/gatepass_dialog.dart`

**Similarity:** 90% same code (bluetooth connection, printer selection, printing logic)

**Consolidation:**
Create ONE `ProfessionalPrinterDialog` widget with content builder:

```dart
class ProfessionalPrinterDialog extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext) contentBuilder;
  final Future<List<int>> Function() getPrintData;

  // Usage:
  // ProfessionalPrinterDialog(
  //   title: 'Cash Receipt',
  //   contentBuilder: (context) => CashReceiptContent(transaction),
  //   getPrintData: () => _buildCashReceiptBytes(),
  // )
}
```

**Action:** Extract common bluetooth/printer logic, create base class

---

### Summary of Duplicate Code

| Widget Type | Instances | Consolidation Priority |
|-------------|-----------|------------------------|
| Selector Dialogs | 4 | HIGH |
| Error Dialogs | 3 | MEDIUM |
| Printer Dialogs | 2 | HIGH |
| Loading Indicators | 10+ | LOW |
| Empty State Messages | 8+ | MEDIUM |

**Estimated Code Reduction:** 30-40% in widgets folder

---

## 🔧 CODE OPTIMIZATION GUIDELINES

### 1. Remove Commented Code

**Search for:** `//`, `/* */` blocks that are not documentation

**Files with most comments:**
- `lib/presentation/pages/cash/cash_page.dart` (Lines 351-380)
- `lib/presentation/pages/dashboard/dashboard_screen.dart` (Line 232)

**Action:** Delete all commented-out code blocks

---

### 2. Unused Imports

**Common culprits:**
```dart
import 'package:flutter/foundation.dart'; // Often unused
import 'package:flutter/cupertino.dart'; // Often unused if only Material is used
```

**Action:** Run `flutter pub run dependency_validator` or use IDE "Optimize Imports"

---

### 3. Hardcoded Values to Constants

**Examples found:**
```dart
// Instead of:
Color(0xFF0E5CA8)  // Used 50+ times

// Use:
AppColors.primaryBlue  // From constants file
```

**Action:** Replace all hardcoded colors/sizes with constant references

---

### 4. Repeated Padding/Spacing

**Instead of:**
```dart
Padding(padding: EdgeInsets.all(16.w))  // Used 100+ times
```

**Use:**
```dart
Padding(padding: AppSpacing.pagePadding)  // Defined once
```

---

### 5. Extraction of Large Build Methods

**Files with 500+ line build methods:**
- `lib/presentation/pages/profile/profile_screen.dart` (1362 lines total)
- `lib/presentation/pages/cash/cash_page.dart` (1092 lines total)

**Action:** Extract into smaller widget methods:
```dart
// Instead of:
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // 200 lines of code here
      ],
    ),
  );
}

// Use:
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        _buildHeader(),
        _buildContent(),
        _buildFooter(),
      ],
    ),
  );
}

Widget _buildHeader() { ... }
Widget _buildContent() { ... }
Widget _buildFooter() { ... }
```

---

## ✅ IMPLEMENTATION CHECKLIST

Before implementing new professional UI:

### Phase 1: Fix Critical Issues ⚠️
- [ ] Fix Error Dialog scroll wrapper (error_dialog.dart)
- [ ] Fix Item Selector scroll wrapper (item_selector_dialog.dart)
- [ ] Fix Cash Receipt printer dialog height (cash_receipt_dialog.dart)
- [ ] Fix Gatepass printer dialog height (gatepass_dialog.dart)

### Phase 2: Add All Translations 🌍
- [ ] Add common translations to app_en.arb
- [ ] Add auth translations to app_en.arb
- [ ] Add cash translations to app_en.arb
- [ ] Add inventory translations to app_en.arb
- [ ] Add orders translations to app_en.arb
- [ ] Add purchase translations to app_en.arb
- [ ] Add SDMS translations to app_en.arb
- [ ] Add all Hindi translations to app_hi.arb

### Phase 3: Code Cleanup 🧹
- [ ] Comment out duplicate selector dialogs (keep 1 as template)
- [ ] Comment out duplicate error dialogs (keep validation_error_dialog.dart)
- [ ] Remove all commented-out code blocks
- [ ] Optimize imports in all files
- [ ] Replace hardcoded values with constants

### Phase 4: Test Responsiveness ✅
- [ ] Test all dialogs on 4" screen
- [ ] Test all dialogs on 6" screen
- [ ] Test all dialogs on tablet (landscape)
- [ ] Test with large system font
- [ ] Test with Hindi language (longer text)

### Phase 5: Ready for UI Implementation 🎨
- [ ] All responsive issues fixed
- [ ] All translations added
- [ ] Duplicate code marked/commented
- [ ] Code optimized
- [ ] Tests passing

---

## 📝 NOTES

### DO NOT CHANGE (KEEP AS-IS):
- Business logic in BLoC files
- API service implementations
- Data models and entities
- Navigation structure
- State management patterns
- Existing functionality

### ONLY CHANGE:
- Visual styling (colors, fonts, spacing)
- Widget layouts and arrangements
- Dialog/popup sizing and scrolling
- Translation keys and text
- Remove duplicate/unused code
- Comment out redundant widgets

### MAINTAIN:
- All existing features
- User roles and permissions
- Data flow and state
- Error handling
- Loading states
- Language toggle functionality

---

**End of Pre-Implementation Fixes Document**

*Complete these fixes before implementing the Professional UI Design Proposal*
