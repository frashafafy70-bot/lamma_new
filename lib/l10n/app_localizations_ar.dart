// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get noInternetConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get lammaPlatform => 'منصة لَمَّة الشاملة';

  @override
  String get loginSubtitle => 'كل خدماتك في مكان واحد، يرجى تسجيل الدخول';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get identifierLabel => 'البريد أو الهاتف أو اسم المستخدم';

  @override
  String get emptyIdentifierError => 'برجاء إدخال البيانات';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get emptyPasswordError => 'برجاء إدخال كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'دخول';

  @override
  String get or => 'أو';

  @override
  String get loginWithGoogle => 'الدخول باستخدام Google';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get registerNow => 'سجل الآن';

  @override
  String get fullNameRequiredError => 'برجاء كتابة الاسم بالكامل';

  @override
  String get invalidEmailError => 'برجاء إدخال بريد إلكتروني صحيح';

  @override
  String get invalidPhoneError => 'برجاء إدخال رقم هاتف صحيح';

  @override
  String get otpSentSuccess => 'تم إرسال كود التحقق بنجاح! 💬';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get joinLammaFamily => 'انضم إلى عائلة لَمَّة واستمتع بكافة الخدمات';

  @override
  String get passengerRole => 'راكب';

  @override
  String get captainRole => 'كابتن';

  @override
  String get fullNameHint => 'الاسم بالكامل';

  @override
  String get emailHint => 'البريد الإلكتروني';

  @override
  String get registerNewAccount => 'تسجيل حساب جديد';

  @override
  String get signUpWithGoogle => 'التسجيل باستخدام Google';

  @override
  String get signUpWithEmailOnly => 'التسجيل باستخدام البريد الإلكتروني فقط';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginNow => 'تسجيل الدخول';

  @override
  String get fillAllFieldsError => 'برجاء إكمال جميع البيانات';

  @override
  String get passwordLengthError => 'كلمة المرور يجب ألا تقل عن 6 أحرف';

  @override
  String get registrationSuccess => 'تم التسجيل بنجاح';

  @override
  String get completeDataTitle => 'استكمال البيانات';

  @override
  String get completeDataSubtitle =>
      'أدخل بريدك الإلكتروني وكلمة المرور لإنشاء حسابك';

  @override
  String get saveAndActivate => 'حفظ البيانات والتفعيل';

  @override
  String get forgotPasswordAppBar => 'استعادة كلمة المرور';

  @override
  String get activationCodeSentMsg => 'تم إرسال كود التفعيل بنجاح 💬';

  @override
  String get sendSuccess => 'تم الإرسال بنجاح';

  @override
  String get forgotPasswordHeader => 'هل نسيت كلمة المرور؟';

  @override
  String get forgotPasswordDescription =>
      'اختر طريقة الاستعادة المناسبة لك لإعادة تعيين كلمة المرور بكل سهولة.';

  @override
  String get emailMethod => 'بريد إلكتروني';

  @override
  String get phoneMethod => 'رقم الهاتف';

  @override
  String get emailExampleHint => 'example@mail.com';

  @override
  String get phoneExampleHint => '10xxxxxxxxx';

  @override
  String get sendResetLink => 'إرسال رابط الاستعادة';

  @override
  String get sendVerificationCode => 'إرسال كود التحقق';

  @override
  String get otpLengthError =>
      'برجاء إدخال كود التحقق كاملاً المكون من 6 أرقام';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get otpVerifiedNeedPassword =>
      'تم تأكيد الرقم بنجاح، يرجى كتابة كلمة المرور';

  @override
  String get verifyPhoneTitle => 'تأكيد رقم الهاتف';

  @override
  String verifyPhoneSubtitle(String phone) {
    return 'أدخل كود التحقق المكون من 6 أرقام\nالذي تم إرساله إلى الرقم $phone';
  }

  @override
  String get verifyAndActivate => 'تحقق وتفعيل الحساب';

  @override
  String get didntReceiveCode => 'لم يصلك الكود؟';

  @override
  String get resendingCode => 'جاري إعادة الإرسال...';

  @override
  String get resendCode => 'إعادة إرسال';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordResetSuccess =>
      'تم تغيير كلمة المرور بنجاح! 🎉 يرجى تسجيل الدخول.';

  @override
  String get setNewPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String setNewPasswordSubtitle(String phone) {
    return 'أدخل كود التحقق المرسل إلى $phone\nثم قم بتعيين كلمة المرور الجديدة';
  }

  @override
  String get newPasswordHint => 'كلمة المرور الجديدة';

  @override
  String get confirmPasswordHint => 'تأكيد كلمة المرور';

  @override
  String get saveAndLogin => 'حفظ وتسجيل الدخول';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get noNotifications => 'لا توجد إشعارات حالياً 🔕';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navRadar => 'الرادار';

  @override
  String get navActive => 'النشطة';

  @override
  String get navHistory => 'السجل';

  @override
  String get navSearch => 'البحث';

  @override
  String get navOrders => 'الطلبات';

  @override
  String get navAccount => 'الحساب';

  @override
  String get changePasswordTitle => 'تغيير كلمة المرور';

  @override
  String get chooseRecoveryMethod =>
      'اختر طريقة الاستعادة لإعادة تعيين كلمة المرور:';

  @override
  String get sendEmailLink => 'إرسال رابط للبريد';

  @override
  String get emailNotAvailable =>
      'البريد الإلكتروني غير متوفر، يرجى استكمال بياناتك.';

  @override
  String get sendPhoneCode => 'إرسال كود للهاتف';

  @override
  String get phoneNotAvailable => 'رقم الهاتف غير متوفر، يرجى استكمال بياناتك.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get supportTitle => 'الدعم الفني والشكاوى';

  @override
  String get supportHint => 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...';

  @override
  String get sendSupport => 'إرسال الدعم';

  @override
  String get operationSuccess => 'تمت العملية بنجاح';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get analyzingDocumentMsg => '🤖 جاري فحص المستند سحابياً...';

  @override
  String get docValidationAlertTitle => 'تنبيه فحص المستند ⚠️';

  @override
  String get docValidationAlertBody =>
      'الذكاء الاصطناعي لم يتعرف على الكارنيه. هل تريد إكمال الرفع للمراجعة اليدوية؟';

  @override
  String get yesContinue => 'نعم، المتابعة';

  @override
  String get docAttachedSuccessfully => '✅ تم إرفاق المستند بنجاح.';

  @override
  String get errorFetchingDoc => 'حدث خطأ في جلب المستند';

  @override
  String get fillAllFieldsWarning => 'برجاء استكمال جميع البيانات';

  @override
  String get fillAllFieldsAndImagesWarning =>
      'برجاء استكمال جميع البيانات والصور';

  @override
  String errorOccurredWithDetails(String error) {
    return 'خطأ: $error';
  }

  @override
  String get activateAccountAndStart => 'تفعيل الحساب والبدء';

  @override
  String get personalIdFront => 'البطاقة الشخصية (أمامي)';

  @override
  String get personalIdBack => 'البطاقة الشخصية (خلفي)';

  @override
  String get edit => 'تعديل';

  @override
  String get attachedSuccessfully => 'تم الإرفاق';

  @override
  String get activateCaptainAccount => 'تفعيل حساب كابتن 🚖';

  @override
  String get carType => 'نوع السيارة';

  @override
  String get plateNumber => 'رقم اللوحة';

  @override
  String get carLicenseFront => 'رخصة المركبة (أمامي)';

  @override
  String get carLicenseBack => 'رخصة المركبة (خلفي)';

  @override
  String captainPrefix(String name) {
    return 'كابتن $name';
  }

  @override
  String get activateLawyerAccount => 'اعتماد حساب المحامي ⚖️';

  @override
  String get barDegree => 'درجة القيد';

  @override
  String get barRegistrationNumber => 'رقم القيد بالنقابة';

  @override
  String get attachSyndicateId => 'إرفاق صورة الكارنيه';

  @override
  String lawyerPrefix(String name) {
    return 'الأستاذ / $name';
  }

  @override
  String get activateDoctorAccount => 'اعتماد حساب الطبيب 👨‍⚕️';

  @override
  String get specialty => 'التخصص';

  @override
  String get medicalLicenseNumber => 'رقم ترخيص مزاولة المهنة';

  @override
  String doctorPrefix(String name) {
    return 'دكتور / $name';
  }

  @override
  String get activateNurseAccount => 'اعتماد حساب التمريض 🩺';

  @override
  String get nurseQualification => 'المؤهل (أخصائي / فني)';

  @override
  String get nurseLicenseNumber => 'رقم ترخيص النقابة';

  @override
  String nursePrefix(String name) {
    return 'ممرض(ة) / $name';
  }

  @override
  String welcomeUser(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get clientRoleName => 'عميل';

  @override
  String get captainRoleName => 'كابتن';

  @override
  String get lawyerRoleName => 'محامي';

  @override
  String get doctorRoleName => 'طبيب';

  @override
  String get nurseRoleName => 'تمريض';

  @override
  String get serviceProviderRoleName => 'مقدم خدمة';

  @override
  String get currentAccountMode => 'وضع الحساب الحالي';

  @override
  String get switchBtn => 'تبديل';

  @override
  String get deliveryAndTrips => 'توصيل ورحلات';

  @override
  String get requestCaptainNow => 'اطلب كابتن فوراً لرحلتك';

  @override
  String get medicalServices => 'خدمات طبية';

  @override
  String get doctorsAndClinics => 'أطباء وعيادات';

  @override
  String get medicalSectionComingSoon => 'سيتم تفعيل القسم الطبي قريباً';

  @override
  String get legalServices => 'خدمات قانونية';

  @override
  String get consultationsAndPowerOfAttorney => 'استشارات وتوكيلات';

  @override
  String get legalSectionComingSoon =>
      'سيتم تفعيل قسم الخدمات القانونية قريباً';

  @override
  String get shopAndStores => 'شوب ومتاجر';

  @override
  String get shopBestProductsEasily => 'تسوق أفضل المنتجات بسهولة';

  @override
  String get storesSectionUnderConstruction => 'قسم المتاجر تحت الإنشاء';

  @override
  String get dashboardTitle => 'لوحة التحكم';

  @override
  String get consultationsAndAgencies => 'الاستشارات والتوكيلات';

  @override
  String get accountSwitchTitle => 'تبديل الحساب';

  @override
  String get currentRoleLabel => 'الدور الحالي';

  @override
  String get switchToOtherRole => 'التبديل إلى دور آخر';

  @override
  String get activeNow => 'نشط الآن';

  @override
  String get lammaDefaultUserName => 'مستخدم لَمَّة';

  @override
  String get loadingDataPleaseWait =>
      'جاري تحميل بياناتك، يرجى المحاولة بعد قليل...';

  @override
  String get passwordResetConfirmation =>
      'هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟';

  @override
  String get sendLink => 'إرسال الرابط';

  @override
  String get supportSentSuccess => 'تم إرسال رسالتك للدعم الفني بنجاح ✅';

  @override
  String get supportSendError => 'حدث خطأ أثناء الإرسال ❌';

  @override
  String get activeOrdersTitle => 'متابعة طلباتي النشطة';

  @override
  String get errorLoadingOrders => 'حدث خطأ في تحميل الطلبات';

  @override
  String get noActiveOrdersCurrent => 'ليس لديك أي طلبات نشطة حالية';

  @override
  String get requestCaptainNowSub => 'اطلب كابتن الآن وستظهر رحلتك هنا';

  @override
  String get tripWord => 'رحلة';

  @override
  String get determinedLater => 'يحدد لاحقاً';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusAccepted => 'تم القبول';

  @override
  String get statusNegotiating => 'جاري التفاوض';

  @override
  String get statusArrived => 'السائق بالخارج';

  @override
  String get statusInProgress => 'الرحلة مستمرة';

  @override
  String get pickupLocationPlaceholder => 'موقع الانطلاق';

  @override
  String get dropoffLocationPlaceholder => 'وجهة الوصول';

  @override
  String priceWithCurrency(String price) {
    return '$price ج.م';
  }

  @override
  String get welcomeGreeting => 'أهلاً بك 👋';

  @override
  String get loadingDataPlaceholder => 'جاري تحميل البيانات...';

  @override
  String get editPersonalData => 'تعديل البيانات الشخصية';

  @override
  String get savedAddresses => 'العناوين المحفوظة';

  @override
  String get familySubscription => 'الاشتراك العائلي (تتبع الأبناء)';

  @override
  String get logoutFromPlatform => 'تسجيل الخروج من المنصة';

  @override
  String get bookingLoadingMsg => 'جاري إرسال طلب الحجز...';

  @override
  String get searchForTripTitle => 'البحث عن رحلة سفر';

  @override
  String get fromCity => 'من مدينة';

  @override
  String get toCity => 'إلى مدينة';

  @override
  String get enterCitiesWarning => 'الرجاء إدخال مدينة الانطلاق والوصول';

  @override
  String get searchTripsButton => 'بحث عن الرحلات';

  @override
  String get noTripsAvailable => 'لا توجد رحلات متاحة لهذا المسار حالياً.';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get bookAction => 'حجز';

  @override
  String get searchPrompt => 'حدد مسار رحلتك واضغط بحث للبدء';

  @override
  String tripRoute(String from, Object to) {
    return '$from ➔ $to';
  }

  @override
  String tripDetailsSubtitle(String driver, String price) {
    return 'السائق: $driver | السعر: $price ج.م';
  }

  @override
  String get loginSuccessMsg => 'تم تسجيل الدخول بنجاح! 🚀';

  @override
  String get welcomeToLamma => 'مرحباً بك في لَمَّة';

  @override
  String get loginToContinue => 'سجل دخولك للمتابعة';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get myLocationMarker => 'موقعي';

  @override
  String get driverMarker => 'السائق';

  @override
  String get addNewAddress => 'إضافة عنوان جديد';

  @override
  String get editAddressTitle => 'تعديل العنوان';

  @override
  String get addressNameHint => 'اسم العنوان (مثال: المنزل، العمل)';

  @override
  String get addressDetailsHint => 'تفاصيل العنوان';

  @override
  String get setAsDefaultAddress => 'تعيين كعنوان أساسي';

  @override
  String get saveAddress => 'حفظ العنوان';

  @override
  String get deleteAddressTitle => 'حذف العنوان';

  @override
  String get deleteAddressConfirmation =>
      'هل أنت متأكد من حذف هذا العنوان بشكل نهائي؟';

  @override
  String get delete => 'حذف';

  @override
  String get noSavedAddresses => 'لا توجد عناوين محفوظة';

  @override
  String get defaultAddressLabel => 'الأساسي';

  @override
  String get allCategory => 'الكل';

  @override
  String get tripsAndDeliveryCategory => 'رحلات وتوصيل';

  @override
  String get legalConsultationsCategory => 'استشارات قانونية';

  @override
  String get storesCategory => 'متاجر';

  @override
  String get medicalServicesCategory => 'خدمات طبية';

  @override
  String get requestDriverService => 'طلب سائق فوراً';

  @override
  String get deliveryService => 'توصيل طلبات (دليفري)';

  @override
  String get lawyerConsultationService => 'استشارة محامي';

  @override
  String get officialPowerOfAttorneyService => 'توكيل رسمي';

  @override
  String get marketShoppingService => 'تسوق من الماركت';

  @override
  String get pharmaciesService => 'صيدليات';

  @override
  String get bookMedicalAppointmentService => 'حجز كشف طبي';

  @override
  String get comprehensiveSearch => 'البحث الشامل';

  @override
  String get searchHint => 'عن ماذا تبحث؟ (سائق، محامي، توصيل...)';

  @override
  String get typeToStartSearching => 'اكتب ما تبحث عنه للبدء';

  @override
  String get noMatchingResults => 'لا توجد نتائج مطابقة لبحثك';

  @override
  String get serviceUnderPreparation => 'هذه الخدمة قيد التجهيز';

  @override
  String get deliveryDisplay => 'توصيل';

  @override
  String get buyOrdersDisplay => 'شراء طلبات';

  @override
  String get carVehicle => 'سيارة';

  @override
  String get motorcycleVehicle => 'موتوسيكل';

  @override
  String get tuktukVehicle => 'توكتوك';

  @override
  String get pickupLocationLabel => 'موقعك الحالي / مكان الاستلام';

  @override
  String get destinationLocationLabel => 'مكان الوصول / تسليم الطلب';

  @override
  String get estimatedOrderPriceLabel => 'سعر الطلبات التقريبي (للشراء)';

  @override
  String get deliveryFareLabel => 'أجرة التوصيل للسائق';

  @override
  String get sendPurchaseRequestBtn => 'إرسال طلب المشتروات للسائق';

  @override
  String get sendRequestBtn => 'إرسال الطلب للسائق';

  @override
  String get deleteTripTitle => 'مسح الطلب';

  @override
  String get deleteTripConfirmation =>
      'هل أنت متأكد من إزالة هذا الطلب من القائمة عندك؟';

  @override
  String get goBack => 'تراجع';

  @override
  String get yesDelete => 'نعم، امسح';

  @override
  String get cancelTripTitle => 'إلغاء الرحلة';

  @override
  String get cancelTripConfirmation =>
      'هل أنت متأكد من إلغاء هذه الرحلة؟ سيتم إبلاغ الطرف الآخر.';

  @override
  String get yesCancel => 'نعم، إلغاء';

  @override
  String get tripCancelledSuccessfully => 'تم إلغاء الرحلة بنجاح';

  @override
  String get errorDuringCancellation => 'حدث خطأ أثناء الإلغاء';

  @override
  String get negotiateFareTitle => 'التفاوض على الأجرة';

  @override
  String get suggestedPriceHint => 'اكتب سعرك المقترح';

  @override
  String get currencyEGP => 'جنيه';

  @override
  String get sendBtn => 'إرسال';

  @override
  String get tripEndedTitle => 'تم إنهاء الرحلة!';

  @override
  String get submitRatingBtn => 'إرسال التقييم';

  @override
  String get travel_preBooking => 'حجز مسبق';

  @override
  String get travel_travelingSoon => 'مسافر لمحافظة تانية قريباً؟';

  @override
  String get travel_travelDescription =>
      'حدد مسارك وتاريخ رحلتك، وخلي العملاء تحجز معاك مقدماً وتشاركك التكلفة.';

  @override
  String get travel_addTravelTrip => 'إضافة رحلة سفر';

  @override
  String get travel_publishNewTrip => 'نشر رحلة سفر جديدة';

  @override
  String get travel_individualSeats => 'مقاعد فردية';

  @override
  String get travel_fullCar => 'سيارة كاملة';

  @override
  String get travel_availableSeatsCount => 'عدد المقاعد المتاحة:';

  @override
  String get travel_departurePoint => 'نقطة التحرك (من)';

  @override
  String get travel_destinationPoint => 'وجهة السفر (إلى)';

  @override
  String get travel_dateAndTime => 'تاريخ ووقت التحرك';

  @override
  String get travel_fullTripPrice => 'سعر الرحلة بالكامل (ج.م)';

  @override
  String get travel_singleSeatPrice => 'سعر المقعد الواحد (ج.م)';

  @override
  String get travel_publishBtn => 'نشر الرحلة';

  @override
  String get travel_selectDateError => 'برجاء تحديد تاريخ ووقت الرحلة';

  @override
  String get travel_activeTripExistError =>
      'عفواً، لا يمكنك نشر رحلة جديدة لوجود رحلة نشطة بالفعل.';

  @override
  String get travel_enterDepartureError => 'برجاء إدخال نقطة التحرك';

  @override
  String get travel_enterDestinationError => 'برجاء إدخال وجهة السفر';

  @override
  String get travel_enterPriceError => 'برجاء إدخال السعر';

  @override
  String get tripForm_deliveryName => 'توصيل';

  @override
  String get tripForm_buyOrdersName => 'شراء طلبات';

  @override
  String get tripForm_travelName => 'سفر';

  @override
  String get tripForm_travelServicesSoon => 'خدمات السفر قريباً...';

  @override
  String get tripMap_locating => 'جاري تحديد الموقع...';

  @override
  String get tripMap_pickupPoint => 'نقطة الانطلاق';

  @override
  String get tripMap_dropoffPoint => 'وجهة الوصول';

  @override
  String get tripMap_gpsDisabled => 'خدمة الموقع (GPS) مغلقة، يرجى تفعيلها.';

  @override
  String get tripMap_permissionDenied => 'تم رفض صلاحية الوصول للموقع.';

  @override
  String get tripMap_permissionDeniedForever =>
      'صلاحيات الموقع مرفوضة نهائياً، يرجى تعديلها من الإعدادات.';

  @override
  String get tripMap_errorFetchingLocation => 'حدث خطأ أثناء جلب الموقع';

  @override
  String get tripMap_unknownLocation => 'موقع غير معروف';

  @override
  String get tripMap_regularTrip => 'رحلة عادية';

  @override
  String get tripMap_governoratesTravel => 'سفر للمحافظات';

  @override
  String get tripMap_confirmThisAddress => 'تأكيد هذا العنوان';

  @override
  String get tripMap_confirmPickupHere => 'تأكيد الانطلاق من هنا';

  @override
  String get tripMap_home => 'المنزل';

  @override
  String get tripMap_addHomeAddress => 'إضافة عنوان المنزل';

  @override
  String get tripMap_work => 'العمل';

  @override
  String get tripMap_addWorkAddress => 'إضافة عنوان العمل';

  @override
  String get locationPermissionTitle => 'صلاحية الموقع';

  @override
  String get locationPermissionMessage =>
      'لقد قمت برفض صلاحية الموقع بشكل دائم. لكي تتمكن من استخدام التطبيق، يرجى التفعيل من الإعدادات.';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get sendingRequest => 'جاري إرسال طلبك...';

  @override
  String get pickupLocation => 'نقطة الانطلاق';

  @override
  String get destinationLocation => 'وجهة الوصول';

  @override
  String get locatingMap => 'جاري تحديد الموقع...';

  @override
  String get fetchingAddress => 'جاري جلب العنوان...';

  @override
  String get confirmLocation => 'تأكيد الموقع 🚖';

  @override
  String get errorSelectPickup => 'الرجاء تحديد نقطة الانطلاق أولاً';

  @override
  String get errorSelectDestination => 'الرجاء تحديد مكان الوصول';

  @override
  String get errorProvideOrderDetails => 'الرجاء كتابة أو تسجيل تفاصيل الطلبات';

  @override
  String get errorEnterPrice => 'الرجاء إدخال السعر المقترح';

  @override
  String get errorInvalidPrice => 'الرجاء إدخال سعر صحيح (أرقام فقط)';

  @override
  String get requestSentSuccess => 'تم إرسال طلبك بنجاح! 🚀';

  @override
  String get activeTripsTabTitle => 'الرحلات النشطة';

  @override
  String get travelBookingRequests => 'طلبات حجز السفر';

  @override
  String get yourCurrentTrips => 'رحلاتك الحالية';

  @override
  String get noActiveTripsCurrently => 'لا توجد رحلات نشطة حالياً';

  @override
  String get cancelBookingTitle => 'إلغاء الحجز';

  @override
  String get cancelBookingConfirmation =>
      'هل أنت متأكد من إلغاء هذا الحجز وإزالة الراكب؟';

  @override
  String get backBtn => 'تراجع';

  @override
  String get unspecified => 'غير محدد';

  @override
  String get fullCarBookingRequest => 'طلب حجز رحلة كاملة';

  @override
  String get seatsBookingRequest => 'طلب حجز مقاعد';

  @override
  String pendingSeatsRequest(String seats) {
    return '⏳ قيد الانتظار - العميل يطلب $seats مقاعد';
  }

  @override
  String acceptedSeatsRequest(String seats) {
    return '✅ تم القبول - العميل حاجز $seats مقاعد';
  }

  @override
  String requestTime(String time) {
    return 'وقت الطلب: $time';
  }

  @override
  String get acceptBtn => 'قبول';

  @override
  String get rejectBtn => 'رفض';

  @override
  String get messageClient => 'مراسلة العميل';

  @override
  String get pickupLocationDefault => 'موقع الانطلاق';

  @override
  String get dropoffLocationDefault => 'وجهة الوصول';

  @override
  String get fullSeats => 'مكتمل 🔴';

  @override
  String availableSeats(String seats) {
    return 'متاح $seats مقاعد';
  }

  @override
  String get searchingForPassengers => 'جاري البحث عن ركاب';

  @override
  String get clientProposesNewPrice => 'العميل يقترح سعراً جديداً';

  @override
  String get waitingForClientResponse => 'في انتظار رد العميل';

  @override
  String proposedPrice(String price) {
    return 'السعر المقترح: $price ج.م';
  }

  @override
  String finalPrice(String price) {
    return 'السعر النهائي: $price ج.م';
  }

  @override
  String get agreeWithPrice => 'موافق بالسعر';

  @override
  String get negotiateBtn => 'تفاوض';

  @override
  String get activateActiveTrip => 'تفعيل الرحلة النشطة';

  @override
  String get detailsAndMap => 'التفاصيل والخريطة';
}
