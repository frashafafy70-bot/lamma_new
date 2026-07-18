import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @noInternetConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get noInternetConnection;

  /// No description provided for @lammaPlatform.
  ///
  /// In ar, this message translates to:
  /// **'منصة لَمَّة الشاملة'**
  String get lammaPlatform;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل خدماتك في مكان واحد، يرجى تسجيل الدخول'**
  String get loginSubtitle;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @identifierLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد أو الهاتف أو اسم المستخدم'**
  String get identifierLabel;

  /// No description provided for @emptyIdentifierError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال البيانات'**
  String get emptyIdentifierError;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @emptyPasswordError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال كلمة المرور'**
  String get emptyPasswordError;

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get loginButton;

  /// No description provided for @or.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get or;

  /// No description provided for @loginWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'الدخول باستخدام Google'**
  String get loginWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In ar, this message translates to:
  /// **'سجل الآن'**
  String get registerNow;

  /// No description provided for @fullNameRequiredError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء كتابة الاسم بالكامل'**
  String get fullNameRequiredError;

  /// No description provided for @invalidEmailError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال بريد إلكتروني صحيح'**
  String get invalidEmailError;

  /// No description provided for @invalidPhoneError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال رقم هاتف صحيح'**
  String get invalidPhoneError;

  /// No description provided for @otpSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال كود التحقق بنجاح! 💬'**
  String get otpSentSuccess;

  /// No description provided for @createNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get createNewAccount;

  /// No description provided for @joinLammaFamily.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى عائلة لَمَّة واستمتع بكافة الخدمات'**
  String get joinLammaFamily;

  /// No description provided for @passengerRole.
  ///
  /// In ar, this message translates to:
  /// **'راكب'**
  String get passengerRole;

  /// No description provided for @captainRole.
  ///
  /// In ar, this message translates to:
  /// **'كابتن'**
  String get captainRole;

  /// No description provided for @fullNameHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالكامل'**
  String get fullNameHint;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailHint;

  /// No description provided for @registerNewAccount.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حساب جديد'**
  String get registerNewAccount;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل باستخدام Google'**
  String get signUpWithGoogle;

  /// No description provided for @signUpWithEmailOnly.
  ///
  /// In ar, this message translates to:
  /// **'التسجيل باستخدام البريد الإلكتروني فقط'**
  String get signUpWithEmailOnly;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get alreadyHaveAccount;

  /// No description provided for @loginNow.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginNow;

  /// No description provided for @fillAllFieldsError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إكمال جميع البيانات'**
  String get fillAllFieldsError;

  /// No description provided for @passwordLengthError.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب ألا تقل عن 6 أحرف'**
  String get passwordLengthError;

  /// No description provided for @registrationSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم التسجيل بنجاح'**
  String get registrationSuccess;

  /// No description provided for @completeDataTitle.
  ///
  /// In ar, this message translates to:
  /// **'استكمال البيانات'**
  String get completeDataTitle;

  /// No description provided for @completeDataSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني وكلمة المرور لإنشاء حسابك'**
  String get completeDataSubtitle;

  /// No description provided for @saveAndActivate.
  ///
  /// In ar, this message translates to:
  /// **'حفظ البيانات والتفعيل'**
  String get saveAndActivate;

  /// No description provided for @forgotPasswordAppBar.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordAppBar;

  /// No description provided for @activationCodeSentMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال كود التفعيل بنجاح 💬'**
  String get activationCodeSentMsg;

  /// No description provided for @sendSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال بنجاح'**
  String get sendSuccess;

  /// No description provided for @forgotPasswordHeader.
  ///
  /// In ar, this message translates to:
  /// **'هل نسيت كلمة المرور؟'**
  String get forgotPasswordHeader;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الاستعادة المناسبة لك لإعادة تعيين كلمة المرور بكل سهولة.'**
  String get forgotPasswordDescription;

  /// No description provided for @emailMethod.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني'**
  String get emailMethod;

  /// No description provided for @phoneMethod.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneMethod;

  /// No description provided for @emailExampleHint.
  ///
  /// In ar, this message translates to:
  /// **'example@mail.com'**
  String get emailExampleHint;

  /// No description provided for @phoneExampleHint.
  ///
  /// In ar, this message translates to:
  /// **'10xxxxxxxxx'**
  String get phoneExampleHint;

  /// No description provided for @sendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط الاستعادة'**
  String get sendResetLink;

  /// No description provided for @sendVerificationCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال كود التحقق'**
  String get sendVerificationCode;

  /// No description provided for @otpLengthError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال كود التحقق كاملاً المكون من 6 أرقام'**
  String get otpLengthError;

  /// No description provided for @loginSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح'**
  String get loginSuccess;

  /// No description provided for @otpVerifiedNeedPassword.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد الرقم بنجاح، يرجى كتابة كلمة المرور'**
  String get otpVerifiedNeedPassword;

  /// No description provided for @verifyPhoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد رقم الهاتف'**
  String get verifyPhoneTitle;

  /// No description provided for @verifyPhoneSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التحقق المكون من 6 أرقام\nالذي تم إرساله إلى الرقم {phone}'**
  String verifyPhoneSubtitle(String phone);

  /// No description provided for @verifyAndActivate.
  ///
  /// In ar, this message translates to:
  /// **'تحقق وتفعيل الحساب'**
  String get verifyAndActivate;

  /// No description provided for @didntReceiveCode.
  ///
  /// In ar, this message translates to:
  /// **'لم يصلك الكود؟'**
  String get didntReceiveCode;

  /// No description provided for @resendingCode.
  ///
  /// In ar, this message translates to:
  /// **'جاري إعادة الإرسال...'**
  String get resendingCode;

  /// No description provided for @resendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال'**
  String get resendCode;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمات المرور غير متطابقة'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور بنجاح! 🎉 يرجى تسجيل الدخول.'**
  String get passwordResetSuccess;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كود التحقق المرسل إلى {phone}\nثم قم بتعيين كلمة المرور الجديدة'**
  String setNewPasswordSubtitle(String phone);

  /// No description provided for @newPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPasswordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPasswordHint;

  /// No description provided for @saveAndLogin.
  ///
  /// In ar, this message translates to:
  /// **'حفظ وتسجيل الدخول'**
  String get saveAndLogin;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات حالياً 🔕'**
  String get noNotifications;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navRadar.
  ///
  /// In ar, this message translates to:
  /// **'الرادار'**
  String get navRadar;

  /// No description provided for @navActive.
  ///
  /// In ar, this message translates to:
  /// **'النشطة'**
  String get navActive;

  /// No description provided for @navHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get navHistory;

  /// No description provided for @navSearch.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get navSearch;

  /// No description provided for @navOrders.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get navAccount;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordTitle;

  /// No description provided for @chooseRecoveryMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الاستعادة لإعادة تعيين كلمة المرور:'**
  String get chooseRecoveryMethod;

  /// No description provided for @sendEmailLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط للبريد'**
  String get sendEmailLink;

  /// No description provided for @emailNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير متوفر، يرجى استكمال بياناتك.'**
  String get emailNotAvailable;

  /// No description provided for @sendPhoneCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال كود للهاتف'**
  String get sendPhoneCode;

  /// No description provided for @phoneNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير متوفر، يرجى استكمال بياناتك.'**
  String get phoneNotAvailable;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @supportTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدعم الفني والشكاوى'**
  String get supportTitle;

  /// No description provided for @supportHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب شكوتك، مشكلتك، أو مقترحك هنا...'**
  String get supportHint;

  /// No description provided for @sendSupport.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الدعم'**
  String get sendSupport;

  /// No description provided for @operationSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت العملية بنجاح'**
  String get operationSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get errorOccurred;

  /// No description provided for @analyzingDocumentMsg.
  ///
  /// In ar, this message translates to:
  /// **'🤖 جاري فحص المستند سحابياً...'**
  String get analyzingDocumentMsg;

  /// No description provided for @docValidationAlertTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه فحص المستند ⚠️'**
  String get docValidationAlertTitle;

  /// No description provided for @docValidationAlertBody.
  ///
  /// In ar, this message translates to:
  /// **'الذكاء الاصطناعي لم يتعرف على الكارنيه. هل تريد إكمال الرفع للمراجعة اليدوية؟'**
  String get docValidationAlertBody;

  /// No description provided for @yesContinue.
  ///
  /// In ar, this message translates to:
  /// **'نعم، المتابعة'**
  String get yesContinue;

  /// No description provided for @docAttachedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إرفاق المستند بنجاح.'**
  String get docAttachedSuccessfully;

  /// No description provided for @errorFetchingDoc.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في جلب المستند'**
  String get errorFetchingDoc;

  /// No description provided for @fillAllFieldsWarning.
  ///
  /// In ar, this message translates to:
  /// **'برجاء استكمال جميع البيانات'**
  String get fillAllFieldsWarning;

  /// No description provided for @fillAllFieldsAndImagesWarning.
  ///
  /// In ar, this message translates to:
  /// **'برجاء استكمال جميع البيانات والصور'**
  String get fillAllFieldsAndImagesWarning;

  /// No description provided for @errorOccurredWithDetails.
  ///
  /// In ar, this message translates to:
  /// **'خطأ: {error}'**
  String errorOccurredWithDetails(String error);

  /// No description provided for @activateAccountAndStart.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الحساب والبدء'**
  String get activateAccountAndStart;

  /// No description provided for @personalIdFront.
  ///
  /// In ar, this message translates to:
  /// **'البطاقة الشخصية (أمامي)'**
  String get personalIdFront;

  /// No description provided for @personalIdBack.
  ///
  /// In ar, this message translates to:
  /// **'البطاقة الشخصية (خلفي)'**
  String get personalIdBack;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @attachedSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرفاق'**
  String get attachedSuccessfully;

  /// No description provided for @activateCaptainAccount.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل حساب كابتن 🚖'**
  String get activateCaptainAccount;

  /// No description provided for @carType.
  ///
  /// In ar, this message translates to:
  /// **'نوع السيارة'**
  String get carType;

  /// No description provided for @plateNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم اللوحة'**
  String get plateNumber;

  /// No description provided for @carLicenseFront.
  ///
  /// In ar, this message translates to:
  /// **'رخصة المركبة (أمامي)'**
  String get carLicenseFront;

  /// No description provided for @carLicenseBack.
  ///
  /// In ar, this message translates to:
  /// **'رخصة المركبة (خلفي)'**
  String get carLicenseBack;

  /// No description provided for @captainPrefix.
  ///
  /// In ar, this message translates to:
  /// **'كابتن {name}'**
  String captainPrefix(String name);

  /// No description provided for @activateLawyerAccount.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد حساب المحامي ⚖️'**
  String get activateLawyerAccount;

  /// No description provided for @barDegree.
  ///
  /// In ar, this message translates to:
  /// **'درجة القيد'**
  String get barDegree;

  /// No description provided for @barRegistrationNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم القيد بالنقابة'**
  String get barRegistrationNumber;

  /// No description provided for @attachSyndicateId.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة الكارنيه'**
  String get attachSyndicateId;

  /// No description provided for @lawyerPrefix.
  ///
  /// In ar, this message translates to:
  /// **'الأستاذ / {name}'**
  String lawyerPrefix(String name);

  /// No description provided for @activateDoctorAccount.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد حساب الطبيب 👨‍⚕️'**
  String get activateDoctorAccount;

  /// No description provided for @specialty.
  ///
  /// In ar, this message translates to:
  /// **'التخصص'**
  String get specialty;

  /// No description provided for @medicalLicenseNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم ترخيص مزاولة المهنة'**
  String get medicalLicenseNumber;

  /// No description provided for @doctorPrefix.
  ///
  /// In ar, this message translates to:
  /// **'دكتور / {name}'**
  String doctorPrefix(String name);

  /// No description provided for @activateNurseAccount.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد حساب التمريض 🩺'**
  String get activateNurseAccount;

  /// No description provided for @nurseQualification.
  ///
  /// In ar, this message translates to:
  /// **'المؤهل (أخصائي / فني)'**
  String get nurseQualification;

  /// No description provided for @nurseLicenseNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم ترخيص النقابة'**
  String get nurseLicenseNumber;

  /// No description provided for @nursePrefix.
  ///
  /// In ar, this message translates to:
  /// **'ممرض(ة) / {name}'**
  String nursePrefix(String name);

  /// No description provided for @welcomeUser.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، {name}'**
  String welcomeUser(String name);

  /// No description provided for @clientRoleName.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get clientRoleName;

  /// No description provided for @captainRoleName.
  ///
  /// In ar, this message translates to:
  /// **'كابتن'**
  String get captainRoleName;

  /// No description provided for @lawyerRoleName.
  ///
  /// In ar, this message translates to:
  /// **'محامي'**
  String get lawyerRoleName;

  /// No description provided for @doctorRoleName.
  ///
  /// In ar, this message translates to:
  /// **'طبيب'**
  String get doctorRoleName;

  /// No description provided for @nurseRoleName.
  ///
  /// In ar, this message translates to:
  /// **'تمريض'**
  String get nurseRoleName;

  /// No description provided for @serviceProviderRoleName.
  ///
  /// In ar, this message translates to:
  /// **'مقدم خدمة'**
  String get serviceProviderRoleName;

  /// No description provided for @currentAccountMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع الحساب الحالي'**
  String get currentAccountMode;

  /// No description provided for @switchBtn.
  ///
  /// In ar, this message translates to:
  /// **'تبديل'**
  String get switchBtn;

  /// No description provided for @deliveryAndTrips.
  ///
  /// In ar, this message translates to:
  /// **'توصيل ورحلات'**
  String get deliveryAndTrips;

  /// No description provided for @requestCaptainNow.
  ///
  /// In ar, this message translates to:
  /// **'اطلب كابتن فوراً لرحلتك'**
  String get requestCaptainNow;

  /// No description provided for @medicalServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات طبية'**
  String get medicalServices;

  /// No description provided for @doctorsAndClinics.
  ///
  /// In ar, this message translates to:
  /// **'أطباء وعيادات'**
  String get doctorsAndClinics;

  /// No description provided for @medicalSectionComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تفعيل القسم الطبي قريباً'**
  String get medicalSectionComingSoon;

  /// No description provided for @legalServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات قانونية'**
  String get legalServices;

  /// No description provided for @consultationsAndPowerOfAttorney.
  ///
  /// In ar, this message translates to:
  /// **'استشارات وتوكيلات'**
  String get consultationsAndPowerOfAttorney;

  /// No description provided for @legalSectionComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تفعيل قسم الخدمات القانونية قريباً'**
  String get legalSectionComingSoon;

  /// No description provided for @shopAndStores.
  ///
  /// In ar, this message translates to:
  /// **'شوب ومتاجر'**
  String get shopAndStores;

  /// No description provided for @shopBestProductsEasily.
  ///
  /// In ar, this message translates to:
  /// **'تسوق أفضل المنتجات بسهولة'**
  String get shopBestProductsEasily;

  /// No description provided for @storesSectionUnderConstruction.
  ///
  /// In ar, this message translates to:
  /// **'قسم المتاجر تحت الإنشاء'**
  String get storesSectionUnderConstruction;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboardTitle;

  /// No description provided for @consultationsAndAgencies.
  ///
  /// In ar, this message translates to:
  /// **'الاستشارات والتوكيلات'**
  String get consultationsAndAgencies;

  /// No description provided for @accountSwitchTitle.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب'**
  String get accountSwitchTitle;

  /// No description provided for @currentRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور الحالي'**
  String get currentRoleLabel;

  /// No description provided for @switchToOtherRole.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى دور آخر'**
  String get switchToOtherRole;

  /// No description provided for @activeNow.
  ///
  /// In ar, this message translates to:
  /// **'نشط الآن'**
  String get activeNow;

  /// No description provided for @lammaDefaultUserName.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم لَمَّة'**
  String get lammaDefaultUserName;

  /// No description provided for @loadingDataPleaseWait.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل بياناتك، يرجى المحاولة بعد قليل...'**
  String get loadingDataPleaseWait;

  /// No description provided for @passwordResetConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟'**
  String get passwordResetConfirmation;

  /// No description provided for @sendLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get sendLink;

  /// No description provided for @supportSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رسالتك للدعم الفني بنجاح ✅'**
  String get supportSentSuccess;

  /// No description provided for @supportSendError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإرسال ❌'**
  String get supportSendError;

  /// No description provided for @activeOrdersTitle.
  ///
  /// In ar, this message translates to:
  /// **'متابعة طلباتي النشطة'**
  String get activeOrdersTitle;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ في تحميل الطلبات'**
  String get errorLoadingOrders;

  /// No description provided for @noActiveOrdersCurrent.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك أي طلبات نشطة حالية'**
  String get noActiveOrdersCurrent;

  /// No description provided for @requestCaptainNowSub.
  ///
  /// In ar, this message translates to:
  /// **'اطلب كابتن الآن وستظهر رحلتك هنا'**
  String get requestCaptainNowSub;

  /// No description provided for @tripWord.
  ///
  /// In ar, this message translates to:
  /// **'رحلة'**
  String get tripWord;

  /// No description provided for @determinedLater.
  ///
  /// In ar, this message translates to:
  /// **'يحدد لاحقاً'**
  String get determinedLater;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'تم القبول'**
  String get statusAccepted;

  /// No description provided for @statusNegotiating.
  ///
  /// In ar, this message translates to:
  /// **'جاري التفاوض'**
  String get statusNegotiating;

  /// No description provided for @statusArrived.
  ///
  /// In ar, this message translates to:
  /// **'السائق بالخارج'**
  String get statusArrived;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'الرحلة مستمرة'**
  String get statusInProgress;

  /// No description provided for @pickupLocationPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'موقع الانطلاق'**
  String get pickupLocationPlaceholder;

  /// No description provided for @dropoffLocationPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'وجهة الوصول'**
  String get dropoffLocationPlaceholder;

  /// No description provided for @priceWithCurrency.
  ///
  /// In ar, this message translates to:
  /// **'{price} ج.م'**
  String priceWithCurrency(String price);

  /// No description provided for @welcomeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك 👋'**
  String get welcomeGreeting;

  /// No description provided for @loadingDataPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل البيانات...'**
  String get loadingDataPlaceholder;

  /// No description provided for @editPersonalData.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات الشخصية'**
  String get editPersonalData;

  /// No description provided for @savedAddresses.
  ///
  /// In ar, this message translates to:
  /// **'العناوين المحفوظة'**
  String get savedAddresses;

  /// No description provided for @familySubscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك العائلي (تتبع الأبناء)'**
  String get familySubscription;

  /// No description provided for @logoutFromPlatform.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج من المنصة'**
  String get logoutFromPlatform;

  /// No description provided for @bookingLoadingMsg.
  ///
  /// In ar, this message translates to:
  /// **'جاري إرسال طلب الحجز...'**
  String get bookingLoadingMsg;

  /// No description provided for @searchForTripTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن رحلة سفر'**
  String get searchForTripTitle;

  /// No description provided for @fromCity.
  ///
  /// In ar, this message translates to:
  /// **'من مدينة'**
  String get fromCity;

  /// No description provided for @toCity.
  ///
  /// In ar, this message translates to:
  /// **'إلى مدينة'**
  String get toCity;

  /// No description provided for @enterCitiesWarning.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال مدينة الانطلاق والوصول'**
  String get enterCitiesWarning;

  /// No description provided for @searchTripsButton.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن الرحلات'**
  String get searchTripsButton;

  /// No description provided for @noTripsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رحلات متاحة لهذا المسار حالياً.'**
  String get noTripsAvailable;

  /// No description provided for @notSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSpecified;

  /// No description provided for @bookAction.
  ///
  /// In ar, this message translates to:
  /// **'حجز'**
  String get bookAction;

  /// No description provided for @searchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'حدد مسار رحلتك واضغط بحث للبدء'**
  String get searchPrompt;

  /// No description provided for @tripRoute.
  ///
  /// In ar, this message translates to:
  /// **'{from} ➔ {to}'**
  String tripRoute(String from, Object to);

  /// No description provided for @tripDetailsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'السائق: {driver} | السعر: {price} ج.م'**
  String tripDetailsSubtitle(String driver, String price);

  /// No description provided for @loginSuccessMsg.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول بنجاح! 🚀'**
  String get loginSuccessMsg;

  /// No description provided for @welcomeToLamma.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في لَمَّة'**
  String get welcomeToLamma;

  /// No description provided for @loginToContinue.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك للمتابعة'**
  String get loginToContinue;

  /// No description provided for @passwordHint.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordHint;

  /// No description provided for @myLocationMarker.
  ///
  /// In ar, this message translates to:
  /// **'موقعي'**
  String get myLocationMarker;

  /// No description provided for @driverMarker.
  ///
  /// In ar, this message translates to:
  /// **'السائق'**
  String get driverMarker;

  /// No description provided for @addNewAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان جديد'**
  String get addNewAddress;

  /// No description provided for @editAddressTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العنوان'**
  String get editAddressTitle;

  /// No description provided for @addressNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان (مثال: المنزل، العمل)'**
  String get addressNameHint;

  /// No description provided for @addressDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العنوان'**
  String get addressDetailsHint;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كعنوان أساسي'**
  String get setAsDefaultAddress;

  /// No description provided for @saveAddress.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العنوان'**
  String get saveAddress;

  /// No description provided for @deleteAddressTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العنوان'**
  String get deleteAddressTitle;

  /// No description provided for @deleteAddressConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا العنوان بشكل نهائي؟'**
  String get deleteAddressConfirmation;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @noSavedAddresses.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عناوين محفوظة'**
  String get noSavedAddresses;

  /// No description provided for @defaultAddressLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأساسي'**
  String get defaultAddressLabel;

  /// No description provided for @allCategory.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategory;

  /// No description provided for @tripsAndDeliveryCategory.
  ///
  /// In ar, this message translates to:
  /// **'رحلات وتوصيل'**
  String get tripsAndDeliveryCategory;

  /// No description provided for @legalConsultationsCategory.
  ///
  /// In ar, this message translates to:
  /// **'استشارات قانونية'**
  String get legalConsultationsCategory;

  /// No description provided for @storesCategory.
  ///
  /// In ar, this message translates to:
  /// **'متاجر'**
  String get storesCategory;

  /// No description provided for @medicalServicesCategory.
  ///
  /// In ar, this message translates to:
  /// **'خدمات طبية'**
  String get medicalServicesCategory;

  /// No description provided for @requestDriverService.
  ///
  /// In ar, this message translates to:
  /// **'طلب سائق فوراً'**
  String get requestDriverService;

  /// No description provided for @deliveryService.
  ///
  /// In ar, this message translates to:
  /// **'توصيل طلبات (دليفري)'**
  String get deliveryService;

  /// No description provided for @lawyerConsultationService.
  ///
  /// In ar, this message translates to:
  /// **'استشارة محامي'**
  String get lawyerConsultationService;

  /// No description provided for @officialPowerOfAttorneyService.
  ///
  /// In ar, this message translates to:
  /// **'توكيل رسمي'**
  String get officialPowerOfAttorneyService;

  /// No description provided for @marketShoppingService.
  ///
  /// In ar, this message translates to:
  /// **'تسوق من الماركت'**
  String get marketShoppingService;

  /// No description provided for @pharmaciesService.
  ///
  /// In ar, this message translates to:
  /// **'صيدليات'**
  String get pharmaciesService;

  /// No description provided for @bookMedicalAppointmentService.
  ///
  /// In ar, this message translates to:
  /// **'حجز كشف طبي'**
  String get bookMedicalAppointmentService;

  /// No description provided for @comprehensiveSearch.
  ///
  /// In ar, this message translates to:
  /// **'البحث الشامل'**
  String get comprehensiveSearch;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'عن ماذا تبحث؟ (سائق، محامي، توصيل...)'**
  String get searchHint;

  /// No description provided for @typeToStartSearching.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ما تبحث عنه للبدء'**
  String get typeToStartSearching;

  /// No description provided for @noMatchingResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة لبحثك'**
  String get noMatchingResults;

  /// No description provided for @serviceUnderPreparation.
  ///
  /// In ar, this message translates to:
  /// **'هذه الخدمة قيد التجهيز'**
  String get serviceUnderPreparation;

  /// No description provided for @deliveryDisplay.
  ///
  /// In ar, this message translates to:
  /// **'توصيل'**
  String get deliveryDisplay;

  /// No description provided for @buyOrdersDisplay.
  ///
  /// In ar, this message translates to:
  /// **'شراء طلبات'**
  String get buyOrdersDisplay;

  /// No description provided for @carVehicle.
  ///
  /// In ar, this message translates to:
  /// **'سيارة'**
  String get carVehicle;

  /// No description provided for @motorcycleVehicle.
  ///
  /// In ar, this message translates to:
  /// **'موتوسيكل'**
  String get motorcycleVehicle;

  /// No description provided for @tuktukVehicle.
  ///
  /// In ar, this message translates to:
  /// **'توكتوك'**
  String get tuktukVehicle;

  /// No description provided for @pickupLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'موقعك الحالي / مكان الاستلام'**
  String get pickupLocationLabel;

  /// No description provided for @destinationLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكان الوصول / تسليم الطلب'**
  String get destinationLocationLabel;

  /// No description provided for @estimatedOrderPriceLabel.
  ///
  /// In ar, this message translates to:
  /// **'سعر الطلبات التقريبي (للشراء)'**
  String get estimatedOrderPriceLabel;

  /// No description provided for @deliveryFareLabel.
  ///
  /// In ar, this message translates to:
  /// **'أجرة التوصيل للسائق'**
  String get deliveryFareLabel;

  /// No description provided for @sendPurchaseRequestBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب المشتروات للسائق'**
  String get sendPurchaseRequestBtn;

  /// No description provided for @sendRequestBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب للسائق'**
  String get sendRequestBtn;

  /// No description provided for @deleteTripTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح الطلب'**
  String get deleteTripTitle;

  /// No description provided for @deleteTripConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إزالة هذا الطلب من القائمة عندك؟'**
  String get deleteTripConfirmation;

  /// No description provided for @goBack.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get goBack;

  /// No description provided for @yesDelete.
  ///
  /// In ar, this message translates to:
  /// **'نعم، امسح'**
  String get yesDelete;

  /// No description provided for @cancelTripTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الرحلة'**
  String get cancelTripTitle;

  /// No description provided for @cancelTripConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.'**
  String get cancelTripConfirmation;

  /// No description provided for @yesCancel.
  ///
  /// In ar, this message translates to:
  /// **'نعم، إلغاء'**
  String get yesCancel;

  /// No description provided for @tripCancelledSuccessfully.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الرحلة بنجاح'**
  String get tripCancelledSuccessfully;

  /// No description provided for @errorDuringCancellation.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإلغاء'**
  String get errorDuringCancellation;

  /// No description provided for @negotiateFareTitle.
  ///
  /// In ar, this message translates to:
  /// **'التفاوض على الأجرة'**
  String get negotiateFareTitle;

  /// No description provided for @suggestedPriceHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعرك المقترح'**
  String get suggestedPriceHint;

  /// No description provided for @currencyEGP.
  ///
  /// In ar, this message translates to:
  /// **'جنيه'**
  String get currencyEGP;

  /// No description provided for @sendBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get sendBtn;

  /// No description provided for @tripEndedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إنهاء الرحلة!'**
  String get tripEndedTitle;

  /// No description provided for @submitRatingBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقييم'**
  String get submitRatingBtn;

  /// No description provided for @travel_preBooking.
  ///
  /// In ar, this message translates to:
  /// **'حجز مسبق'**
  String get travel_preBooking;

  /// No description provided for @travel_travelingSoon.
  ///
  /// In ar, this message translates to:
  /// **'مسافر لمحافظة تانية قريباً؟'**
  String get travel_travelingSoon;

  /// No description provided for @travel_travelDescription.
  ///
  /// In ar, this message translates to:
  /// **'حدد مسارك وتاريخ رحلتك، وخلي العملاء تحجز معاك مقدماً وتشاركك التكلفة.'**
  String get travel_travelDescription;

  /// No description provided for @travel_addTravelTrip.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رحلة سفر'**
  String get travel_addTravelTrip;

  /// No description provided for @travel_publishNewTrip.
  ///
  /// In ar, this message translates to:
  /// **'نشر رحلة سفر جديدة'**
  String get travel_publishNewTrip;

  /// No description provided for @travel_individualSeats.
  ///
  /// In ar, this message translates to:
  /// **'مقاعد فردية'**
  String get travel_individualSeats;

  /// No description provided for @travel_fullCar.
  ///
  /// In ar, this message translates to:
  /// **'سيارة كاملة'**
  String get travel_fullCar;

  /// No description provided for @travel_availableSeatsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد المقاعد المتاحة:'**
  String get travel_availableSeatsCount;

  /// No description provided for @travel_departurePoint.
  ///
  /// In ar, this message translates to:
  /// **'نقطة التحرك (من)'**
  String get travel_departurePoint;

  /// No description provided for @travel_destinationPoint.
  ///
  /// In ar, this message translates to:
  /// **'وجهة السفر (إلى)'**
  String get travel_destinationPoint;

  /// No description provided for @travel_dateAndTime.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ ووقت التحرك'**
  String get travel_dateAndTime;

  /// No description provided for @travel_fullTripPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الرحلة بالكامل (ج.م)'**
  String get travel_fullTripPrice;

  /// No description provided for @travel_singleSeatPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر المقعد الواحد (ج.م)'**
  String get travel_singleSeatPrice;

  /// No description provided for @travel_publishBtn.
  ///
  /// In ar, this message translates to:
  /// **'نشر الرحلة'**
  String get travel_publishBtn;

  /// No description provided for @travel_selectDateError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء تحديد تاريخ ووقت الرحلة'**
  String get travel_selectDateError;

  /// No description provided for @travel_activeTripExistError.
  ///
  /// In ar, this message translates to:
  /// **'عفواً، لا يمكنك نشر رحلة جديدة لوجود رحلة نشطة بالفعل.'**
  String get travel_activeTripExistError;

  /// No description provided for @travel_enterDepartureError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال نقطة التحرك'**
  String get travel_enterDepartureError;

  /// No description provided for @travel_enterDestinationError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال وجهة السفر'**
  String get travel_enterDestinationError;

  /// No description provided for @travel_enterPriceError.
  ///
  /// In ar, this message translates to:
  /// **'برجاء إدخال السعر'**
  String get travel_enterPriceError;

  /// No description provided for @tripForm_deliveryName.
  ///
  /// In ar, this message translates to:
  /// **'توصيل'**
  String get tripForm_deliveryName;

  /// No description provided for @tripForm_buyOrdersName.
  ///
  /// In ar, this message translates to:
  /// **'شراء طلبات'**
  String get tripForm_buyOrdersName;

  /// No description provided for @tripForm_travelName.
  ///
  /// In ar, this message translates to:
  /// **'سفر'**
  String get tripForm_travelName;

  /// No description provided for @tripForm_travelServicesSoon.
  ///
  /// In ar, this message translates to:
  /// **'خدمات السفر قريباً...'**
  String get tripForm_travelServicesSoon;

  /// No description provided for @tripMap_locating.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحديد الموقع...'**
  String get tripMap_locating;

  /// No description provided for @tripMap_pickupPoint.
  ///
  /// In ar, this message translates to:
  /// **'نقطة الانطلاق'**
  String get tripMap_pickupPoint;

  /// No description provided for @tripMap_dropoffPoint.
  ///
  /// In ar, this message translates to:
  /// **'وجهة الوصول'**
  String get tripMap_dropoffPoint;

  /// No description provided for @tripMap_gpsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع (GPS) مغلقة، يرجى تفعيلها.'**
  String get tripMap_gpsDisabled;

  /// No description provided for @tripMap_permissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض صلاحية الوصول للموقع.'**
  String get tripMap_permissionDenied;

  /// No description provided for @tripMap_permissionDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات الموقع مرفوضة نهائياً، يرجى تعديلها من الإعدادات.'**
  String get tripMap_permissionDeniedForever;

  /// No description provided for @tripMap_errorFetchingLocation.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء جلب الموقع'**
  String get tripMap_errorFetchingLocation;

  /// No description provided for @tripMap_unknownLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع غير معروف'**
  String get tripMap_unknownLocation;

  /// No description provided for @tripMap_regularTrip.
  ///
  /// In ar, this message translates to:
  /// **'رحلة عادية'**
  String get tripMap_regularTrip;

  /// No description provided for @tripMap_governoratesTravel.
  ///
  /// In ar, this message translates to:
  /// **'سفر للمحافظات'**
  String get tripMap_governoratesTravel;

  /// No description provided for @tripMap_confirmThisAddress.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد هذا العنوان'**
  String get tripMap_confirmThisAddress;

  /// No description provided for @tripMap_confirmPickupHere.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الانطلاق من هنا'**
  String get tripMap_confirmPickupHere;

  /// No description provided for @tripMap_home.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get tripMap_home;

  /// No description provided for @tripMap_addHomeAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان المنزل'**
  String get tripMap_addHomeAddress;

  /// No description provided for @tripMap_work.
  ///
  /// In ar, this message translates to:
  /// **'العمل'**
  String get tripMap_work;

  /// No description provided for @tripMap_addWorkAddress.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عنوان العمل'**
  String get tripMap_addWorkAddress;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In ar, this message translates to:
  /// **'صلاحية الموقع'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In ar, this message translates to:
  /// **'لقد قمت برفض صلاحية الموقع بشكل دائم. لكي تتمكن من استخدام التطبيق، يرجى التفعيل من الإعدادات.'**
  String get locationPermissionMessage;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح الإعدادات'**
  String get openSettings;

  /// No description provided for @sendingRequest.
  ///
  /// In ar, this message translates to:
  /// **'جاري إرسال طلبك...'**
  String get sendingRequest;

  /// No description provided for @pickupLocation.
  ///
  /// In ar, this message translates to:
  /// **'نقطة الانطلاق'**
  String get pickupLocation;

  /// No description provided for @destinationLocation.
  ///
  /// In ar, this message translates to:
  /// **'وجهة الوصول'**
  String get destinationLocation;

  /// No description provided for @locatingMap.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحديد الموقع...'**
  String get locatingMap;

  /// No description provided for @fetchingAddress.
  ///
  /// In ar, this message translates to:
  /// **'جاري جلب العنوان...'**
  String get fetchingAddress;

  /// No description provided for @confirmLocation.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الموقع 🚖'**
  String get confirmLocation;

  /// No description provided for @errorSelectPickup.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تحديد نقطة الانطلاق أولاً'**
  String get errorSelectPickup;

  /// No description provided for @errorSelectDestination.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء تحديد مكان الوصول'**
  String get errorSelectDestination;

  /// No description provided for @errorProvideOrderDetails.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء كتابة أو تسجيل تفاصيل الطلبات'**
  String get errorProvideOrderDetails;

  /// No description provided for @errorEnterPrice.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال السعر المقترح'**
  String get errorEnterPrice;

  /// No description provided for @errorInvalidPrice.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال سعر صحيح (أرقام فقط)'**
  String get errorInvalidPrice;

  /// No description provided for @requestSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك بنجاح! 🚀'**
  String get requestSentSuccess;

  /// No description provided for @activeTripsTabTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرحلات النشطة'**
  String get activeTripsTabTitle;

  /// No description provided for @travelBookingRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات حجز السفر'**
  String get travelBookingRequests;

  /// No description provided for @yourCurrentTrips.
  ///
  /// In ar, this message translates to:
  /// **'رحلاتك الحالية'**
  String get yourCurrentTrips;

  /// No description provided for @noActiveTripsCurrently.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رحلات نشطة حالياً'**
  String get noActiveTripsCurrently;

  /// No description provided for @cancelBookingTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحجز'**
  String get cancelBookingTitle;

  /// No description provided for @cancelBookingConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من إلغاء هذا الحجز وإزالة الراكب؟'**
  String get cancelBookingConfirmation;

  /// No description provided for @backBtn.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get backBtn;

  /// No description provided for @unspecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get unspecified;

  /// No description provided for @fullCarBookingRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب حجز رحلة كاملة'**
  String get fullCarBookingRequest;

  /// No description provided for @seatsBookingRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب حجز مقاعد'**
  String get seatsBookingRequest;

  /// No description provided for @pendingSeatsRequest.
  ///
  /// In ar, this message translates to:
  /// **'⏳ قيد الانتظار - العميل يطلب {seats} مقاعد'**
  String pendingSeatsRequest(String seats);

  /// No description provided for @acceptedSeatsRequest.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم القبول - العميل حاجز {seats} مقاعد'**
  String acceptedSeatsRequest(String seats);

  /// No description provided for @requestTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الطلب: {time}'**
  String requestTime(String time);

  /// No description provided for @acceptBtn.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get acceptBtn;

  /// No description provided for @rejectBtn.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get rejectBtn;

  /// No description provided for @messageClient.
  ///
  /// In ar, this message translates to:
  /// **'مراسلة العميل'**
  String get messageClient;

  /// No description provided for @pickupLocationDefault.
  ///
  /// In ar, this message translates to:
  /// **'موقع الانطلاق'**
  String get pickupLocationDefault;

  /// No description provided for @dropoffLocationDefault.
  ///
  /// In ar, this message translates to:
  /// **'وجهة الوصول'**
  String get dropoffLocationDefault;

  /// No description provided for @fullSeats.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل 🔴'**
  String get fullSeats;

  /// No description provided for @availableSeats.
  ///
  /// In ar, this message translates to:
  /// **'متاح {seats} مقاعد'**
  String availableSeats(String seats);

  /// No description provided for @searchingForPassengers.
  ///
  /// In ar, this message translates to:
  /// **'جاري البحث عن ركاب'**
  String get searchingForPassengers;

  /// No description provided for @clientProposesNewPrice.
  ///
  /// In ar, this message translates to:
  /// **'العميل يقترح سعراً جديداً'**
  String get clientProposesNewPrice;

  /// No description provided for @waitingForClientResponse.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار رد العميل'**
  String get waitingForClientResponse;

  /// No description provided for @proposedPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر المقترح: {price} ج.م'**
  String proposedPrice(String price);

  /// No description provided for @finalPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر النهائي: {price} ج.م'**
  String finalPrice(String price);

  /// No description provided for @agreeWithPrice.
  ///
  /// In ar, this message translates to:
  /// **'موافق بالسعر'**
  String get agreeWithPrice;

  /// No description provided for @negotiateBtn.
  ///
  /// In ar, this message translates to:
  /// **'تفاوض'**
  String get negotiateBtn;

  /// No description provided for @activateActiveTrip.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الرحلة النشطة'**
  String get activateActiveTrip;

  /// No description provided for @detailsAndMap.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل والخريطة'**
  String get detailsAndMap;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
