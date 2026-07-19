// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get lammaPlatform => 'Lamma Platform';

  @override
  String get loginSubtitle => 'All your services in one place, please login';

  @override
  String get loginTitle => 'Login';

  @override
  String get identifierLabel => 'Email, Phone, or Username';

  @override
  String get emptyIdentifierError => 'Please enter your details';

  @override
  String get passwordLabel => 'Password';

  @override
  String get emptyPasswordError => 'Please enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginButton => 'Login';

  @override
  String get or => 'OR';

  @override
  String get loginWithGoogle => 'Login with Google';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register Now';

  @override
  String get fullNameRequiredError => 'Please enter your full name';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get invalidPhoneError => 'Please enter a valid phone number';

  @override
  String get otpSentSuccess => 'Verification code sent successfully! 💬';

  @override
  String get createNewAccount => 'Create a new account';

  @override
  String get joinLammaFamily => 'Join the Lamma family and enjoy all services';

  @override
  String get passengerRole => 'Passenger';

  @override
  String get captainRole => 'Captain';

  @override
  String get fullNameHint => 'Full Name';

  @override
  String get emailHint => 'Email Address';

  @override
  String get registerNewAccount => 'Register new account';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get signUpWithEmailOnly => 'Sign up with email only';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loginNow => 'Login now';

  @override
  String get fillAllFieldsError => 'Please fill in all fields';

  @override
  String get passwordLengthError => 'Password must be at least 6 characters';

  @override
  String get registrationSuccess => 'Registered successfully';

  @override
  String get completeDataTitle => 'Complete Data';

  @override
  String get completeDataSubtitle =>
      'Enter your email and password to create your account';

  @override
  String get saveAndActivate => 'Save data and activate';

  @override
  String get forgotPasswordAppBar => 'Restore Password';

  @override
  String get activationCodeSentMsg => 'Activation code sent successfully 💬';

  @override
  String get sendSuccess => 'Sent successfully';

  @override
  String get forgotPasswordHeader => 'Forgot your password?';

  @override
  String get forgotPasswordDescription =>
      'Choose your preferred recovery method to easily reset your password.';

  @override
  String get emailMethod => 'Email';

  @override
  String get phoneMethod => 'Phone Number';

  @override
  String get emailExampleHint => 'example@mail.com';

  @override
  String get phoneExampleHint => '10xxxxxxxxx';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get otpLengthError =>
      'Please enter the full 6-digit verification code';

  @override
  String get loginSuccess => 'Logged in successfully';

  @override
  String get otpVerifiedNeedPassword =>
      'Phone verified successfully, please enter a password';

  @override
  String get verifyPhoneTitle => 'Verify Phone Number';

  @override
  String verifyPhoneSubtitle(String phone) {
    return 'Enter the 6-digit verification code\nsent to $phone';
  }

  @override
  String get verifyAndActivate => 'Verify and Activate';

  @override
  String get didntReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resendingCode => 'Resending...';

  @override
  String get resendCode => 'Resend';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordResetSuccess =>
      'Password changed successfully! 🎉 Please login.';

  @override
  String get setNewPasswordTitle => 'Set New Password';

  @override
  String setNewPasswordSubtitle(String phone) {
    return 'Enter the verification code sent to $phone\nthen set your new password';
  }

  @override
  String get newPasswordHint => 'New Password';

  @override
  String get confirmPasswordHint => 'Confirm Password';

  @override
  String get saveAndLogin => 'Save and Login';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications currently 🔕';

  @override
  String get loading => 'Loading...';

  @override
  String get navHome => 'Home';

  @override
  String get navRadar => 'Radar';

  @override
  String get navActive => 'Active';

  @override
  String get navHistory => 'History';

  @override
  String get navSearch => 'Search';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get chooseRecoveryMethod =>
      'Choose recovery method to reset your password:';

  @override
  String get sendEmailLink => 'Send Email Link';

  @override
  String get emailNotAvailable =>
      'Email is not available, please complete your profile.';

  @override
  String get sendPhoneCode => 'Send Phone Code';

  @override
  String get phoneNotAvailable =>
      'Phone number is not available, please complete your profile.';

  @override
  String get cancel => 'Cancel';

  @override
  String get supportTitle => 'Technical Support & Complaints';

  @override
  String get supportHint =>
      'Write your complaint, problem, or suggestion here...';

  @override
  String get sendSupport => 'Send Support';

  @override
  String get operationSuccess => 'Operation completed successfully';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get analyzingDocumentMsg => '🤖 Analyzing document in cloud...';

  @override
  String get docValidationAlertTitle => 'Document Validation Alert ⚠️';

  @override
  String get docValidationAlertBody =>
      'AI could not recognize the document. Do you want to proceed with manual review?';

  @override
  String get yesContinue => 'Yes, Continue';

  @override
  String get docAttachedSuccessfully => '✅ Document attached successfully.';

  @override
  String get errorFetchingDoc => 'Error fetching document';

  @override
  String get fillAllFieldsWarning => 'Please complete all fields';

  @override
  String get fillAllFieldsAndImagesWarning =>
      'Please complete all fields and images';

  @override
  String errorOccurredWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get activateAccountAndStart => 'Activate Account & Start';

  @override
  String get personalIdFront => 'Personal ID (Front)';

  @override
  String get personalIdBack => 'Personal ID (Back)';

  @override
  String get edit => 'Edit';

  @override
  String get attachedSuccessfully => 'Attached';

  @override
  String get activateCaptainAccount => 'Activate Captain Account 🚖';

  @override
  String get carType => 'Vehicle Type';

  @override
  String get plateNumber => 'Plate Number';

  @override
  String get carLicenseFront => 'Vehicle License (Front)';

  @override
  String get carLicenseBack => 'Vehicle License (Back)';

  @override
  String captainPrefix(String name) {
    return 'Captain $name';
  }

  @override
  String get activateLawyerAccount => 'Activate Lawyer Account ⚖️';

  @override
  String get barDegree => 'Bar Degree';

  @override
  String get barRegistrationNumber => 'Bar Registration Number';

  @override
  String get attachSyndicateId => 'Attach Syndicate ID';

  @override
  String lawyerPrefix(String name) {
    return 'Mr./Ms. $name';
  }

  @override
  String get activateDoctorAccount => 'Activate Doctor Account 👨‍⚕️';

  @override
  String get specialty => 'Specialty';

  @override
  String get medicalLicenseNumber => 'Medical License Number';

  @override
  String doctorPrefix(String name) {
    return 'Dr. $name';
  }

  @override
  String get activateNurseAccount => 'Activate Nurse Account 🩺';

  @override
  String get nurseQualification => 'Qualification (Specialist / Technician)';

  @override
  String get nurseLicenseNumber => 'Syndicate License Number';

  @override
  String nursePrefix(String name) {
    return 'Nurse $name';
  }

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get clientRoleName => 'Client';

  @override
  String get captainRoleName => 'Captain';

  @override
  String get lawyerRoleName => 'Lawyer';

  @override
  String get doctorRoleName => 'Doctor';

  @override
  String get nurseRoleName => 'Nurse';

  @override
  String get serviceProviderRoleName => 'Service Provider';

  @override
  String get currentAccountMode => 'Current Account Mode';

  @override
  String get switchBtn => 'Switch';

  @override
  String get deliveryAndTrips => 'Delivery & Trips';

  @override
  String get requestCaptainNow => 'Request a captain immediately';

  @override
  String get medicalServices => 'Medical Services';

  @override
  String get doctorsAndClinics => 'Doctors & Clinics';

  @override
  String get medicalSectionComingSoon =>
      'Medical section will be activated soon';

  @override
  String get legalServices => 'Legal Services';

  @override
  String get consultationsAndPowerOfAttorney =>
      'Consultations & Power of Attorney';

  @override
  String get legalSectionComingSoon =>
      'Legal services section will be activated soon';

  @override
  String get shopAndStores => 'Shop & Stores';

  @override
  String get shopBestProductsEasily => 'Shop the best products easily';

  @override
  String get storesSectionUnderConstruction =>
      'Stores section is under construction';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get consultationsAndAgencies => 'Consultations & Agencies';

  @override
  String get accountSwitchTitle => 'Switch Account';

  @override
  String get currentRoleLabel => 'Current Role';

  @override
  String get switchToOtherRole => 'Switch to another role';

  @override
  String get activeNow => 'Active Now';

  @override
  String get lammaDefaultUserName => 'Lamma User';

  @override
  String get loadingDataPleaseWait => 'Loading your data, please wait...';

  @override
  String get passwordResetConfirmation =>
      'Do you want to send a password reset link to your email?';

  @override
  String get sendLink => 'Send Link';

  @override
  String get supportSentSuccess =>
      'Your support message has been sent successfully ✅';

  @override
  String get supportSendError => 'An error occurred while sending ❌';

  @override
  String get activeOrdersTitle => 'Track Active Orders';

  @override
  String get errorLoadingOrders => 'Error loading orders';

  @override
  String get noActiveOrdersCurrent => 'You have no active orders currently';

  @override
  String get requestCaptainNowSub =>
      'Request a captain now and your trip will appear here';

  @override
  String get tripWord => 'Trip';

  @override
  String get determinedLater => 'Determined later';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusNegotiating => 'Negotiating';

  @override
  String get statusArrived => 'Driver Arrived';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get pickupLocationPlaceholder => 'Pickup Location';

  @override
  String get dropoffLocationPlaceholder => 'Dropoff Location';

  @override
  String priceWithCurrency(String price) {
    return '$price EGP';
  }

  @override
  String get welcomeGreeting => 'Welcome 👋';

  @override
  String get loadingDataPlaceholder => 'Loading data...';

  @override
  String get editPersonalData => 'Edit Personal Profile';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get familySubscription => 'Family Subscription (Child Tracking)';

  @override
  String get logoutFromPlatform => 'Logout from Platform';

  @override
  String get bookingLoadingMsg => 'Sending booking request...';

  @override
  String get searchForTripTitle => 'Search for a Trip';

  @override
  String get fromCity => 'From City';

  @override
  String get toCity => 'To City';

  @override
  String get enterCitiesWarning => 'Please enter departure and arrival cities';

  @override
  String get searchTripsButton => 'Search Trips';

  @override
  String get noTripsAvailable => 'No trips available for this route currently.';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get bookAction => 'Book';

  @override
  String get searchPrompt => 'Set your route and press search to start';

  @override
  String tripRoute(String from, String to) {
    return '$from ➔ $to';
  }

  @override
  String tripDetailsSubtitle(String driver, String price) {
    return 'Driver: $driver | Price: $price EGP';
  }

  @override
  String get loginSuccessMsg => 'Logged in successfully! 🚀';

  @override
  String get welcomeToLamma => 'Welcome to Lamma';

  @override
  String get loginToContinue => 'Login to continue';

  @override
  String get passwordHint => 'Password';

  @override
  String get myLocationMarker => 'My Location';

  @override
  String get driverMarker => 'Driver';

  @override
  String get addNewAddress => 'Add New Address';

  @override
  String get editAddressTitle => 'Edit Address';

  @override
  String get addressNameHint => 'Address Name (e.g., Home, Work)';

  @override
  String get addressDetailsHint => 'Address Details';

  @override
  String get setAsDefaultAddress => 'Set as Default Address';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get deleteAddressTitle => 'Delete Address';

  @override
  String get deleteAddressConfirmation =>
      'Are you sure you want to permanently delete this address?';

  @override
  String get delete => 'Delete';

  @override
  String get noSavedAddresses => 'No saved addresses';

  @override
  String get defaultAddressLabel => 'Default';

  @override
  String get allCategory => 'All';

  @override
  String get tripsAndDeliveryCategory => 'Trips & Delivery';

  @override
  String get legalConsultationsCategory => 'Legal Consultations';

  @override
  String get storesCategory => 'Stores';

  @override
  String get medicalServicesCategory => 'Medical Services';

  @override
  String get requestDriverService => 'Request Driver Now';

  @override
  String get deliveryService => 'Delivery';

  @override
  String get lawyerConsultationService => 'Lawyer Consultation';

  @override
  String get officialPowerOfAttorneyService => 'Official Power of Attorney';

  @override
  String get marketShoppingService => 'Market Shopping';

  @override
  String get pharmaciesService => 'Pharmacies';

  @override
  String get bookMedicalAppointmentService => 'Book Medical Appointment';

  @override
  String get comprehensiveSearch => 'Comprehensive Search';

  @override
  String get searchHint => 'What are you looking for? (Driver, Lawyer...)';

  @override
  String get typeToStartSearching => 'Type what you are looking for to start';

  @override
  String get noMatchingResults => 'No results match your search';

  @override
  String get serviceUnderPreparation => 'This service is under preparation';

  @override
  String get deliveryDisplay => 'Delivery';

  @override
  String get buyOrdersDisplay => 'Buy Orders';

  @override
  String get carVehicle => 'Car';

  @override
  String get motorcycleVehicle => 'Motorcycle';

  @override
  String get tuktukVehicle => 'TukTuk';

  @override
  String get pickupLocationLabel => 'Current location / Pickup';

  @override
  String get destinationLocationLabel => 'Destination / Drop-off';

  @override
  String get estimatedOrderPriceLabel => 'Estimated order cost (to buy)';

  @override
  String get deliveryFareLabel => 'Delivery fare for driver';

  @override
  String get sendPurchaseRequestBtn => 'Send Purchase Request';

  @override
  String get sendRequestBtn => 'Send Request';

  @override
  String get deleteTripTitle => 'Delete Order';

  @override
  String get deleteTripConfirmation =>
      'Are you sure you want to remove this order from your list?';

  @override
  String get goBack => 'Back';

  @override
  String get yesDelete => 'Yes, Delete';

  @override
  String get cancelTripTitle => 'Cancel Trip';

  @override
  String get cancelTripConfirmation =>
      'Are you sure you want to cancel this trip? The other party will be notified.';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get tripCancelledSuccessfully => 'Trip cancelled successfully';

  @override
  String get errorDuringCancellation => 'An error occurred during cancellation';

  @override
  String get negotiateFareTitle => 'Negotiate Fare';

  @override
  String get suggestedPriceHint => 'Enter your suggested price';

  @override
  String get currencyEGP => 'EGP';

  @override
  String get sendBtn => 'Send';

  @override
  String get tripEndedTitle => 'Trip Ended!';

  @override
  String get submitRatingBtn => 'Submit Rating';

  @override
  String get travel_preBooking => 'Pre-booking';

  @override
  String get travel_travelingSoon => 'Traveling to another governorate soon?';

  @override
  String get travel_travelDescription =>
      'Set your route and date, let clients book with you in advance and share the cost.';

  @override
  String get travel_addTravelTrip => 'Add Travel Trip';

  @override
  String get travel_publishNewTrip => 'Publish New Travel Trip';

  @override
  String get travel_individualSeats => 'Individual Seats';

  @override
  String get travel_fullCar => 'Full Car';

  @override
  String get travel_availableSeatsCount => 'Available Seats:';

  @override
  String get travel_departurePoint => 'Departure Point (From)';

  @override
  String get travel_destinationPoint => 'Destination (To)';

  @override
  String get travel_dateAndTime => 'Date and Time of Departure';

  @override
  String get travel_fullTripPrice => 'Full Trip Price (EGP)';

  @override
  String get travel_singleSeatPrice => 'Single Seat Price (EGP)';

  @override
  String get travel_publishBtn => 'Publish Trip';

  @override
  String get travel_selectDateError =>
      'Please select the date and time of the trip';

  @override
  String get travel_activeTripExistError =>
      'Sorry, you cannot publish a new trip because you already have an active one.';

  @override
  String get travel_enterDepartureError => 'Please enter departure point';

  @override
  String get travel_enterDestinationError => 'Please enter destination';

  @override
  String get travel_enterPriceError => 'Please enter the price';

  @override
  String get tripForm_deliveryName => 'Delivery';

  @override
  String get tripForm_buyOrdersName => 'Buy Orders';

  @override
  String get tripForm_travelName => 'Travel';

  @override
  String get tripForm_travelServicesSoon => 'Travel services coming soon...';

  @override
  String get tripMap_locating => 'Locating...';

  @override
  String get tripMap_pickupPoint => 'Pickup Point';

  @override
  String get tripMap_dropoffPoint => 'Dropoff Point';

  @override
  String get tripMap_gpsDisabled =>
      'Location services (GPS) are disabled, please enable them.';

  @override
  String get tripMap_permissionDenied => 'Location permissions are denied.';

  @override
  String get tripMap_permissionDeniedForever =>
      'Location permissions are permanently denied, please enable them in settings.';

  @override
  String get tripMap_errorFetchingLocation => 'Error fetching location';

  @override
  String get tripMap_unknownLocation => 'Unknown location';

  @override
  String get tripMap_regularTrip => 'Regular Trip';

  @override
  String get tripMap_governoratesTravel => 'Governorates Travel';

  @override
  String get tripMap_confirmThisAddress => 'Confirm this address';

  @override
  String get tripMap_confirmPickupHere => 'Confirm pickup here';

  @override
  String get tripMap_home => 'Home';

  @override
  String get tripMap_addHomeAddress => 'Add home address';

  @override
  String get tripMap_work => 'Work';

  @override
  String get tripMap_addWorkAddress => 'Add work address';

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get locationPermissionMessage =>
      'Location permission is permanently denied. Please enable it in the app settings to continue.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get sendingRequest => 'Sending your request...';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get destinationLocation => 'Destination';

  @override
  String get locatingMap => 'Locating on map...';

  @override
  String get fetchingAddress => 'Fetching address...';

  @override
  String get confirmLocation => 'Confirm Location 🚖';

  @override
  String get errorSelectPickup => 'Please select a pickup location first';

  @override
  String get errorSelectDestination => 'Please select a destination';

  @override
  String get errorProvideOrderDetails =>
      'Please write or record the order details';

  @override
  String get errorEnterPrice => 'Please enter a suggested price';

  @override
  String get errorInvalidPrice => 'Please enter a valid price (numbers only)';

  @override
  String get requestSentSuccess =>
      'Your request has been sent successfully! 🚀';

  @override
  String get activeTripsTabTitle => 'Active Trips';

  @override
  String get travelBookingRequests => 'Travel Booking Requests';

  @override
  String get yourCurrentTrips => 'Your Current Trips';

  @override
  String get noActiveTripsCurrently => 'No active trips currently';

  @override
  String get cancelBookingTitle => 'Cancel Booking';

  @override
  String get cancelBookingConfirmation =>
      'Are you sure you want to cancel this booking and remove the passenger?';

  @override
  String get backBtn => 'Back';

  @override
  String get unspecified => 'Unspecified';

  @override
  String get fullCarBookingRequest => 'Full Car Booking Request';

  @override
  String get seatsBookingRequest => 'Seats Booking Request';

  @override
  String pendingSeatsRequest(String seats) {
    return '⏳ Pending - Client requesting $seats seats';
  }

  @override
  String acceptedSeatsRequest(String seats) {
    return '✅ Accepted - Client booked $seats seats';
  }

  @override
  String requestTime(String time) {
    return 'Request Time: $time';
  }

  @override
  String get acceptBtn => 'Accept';

  @override
  String get rejectBtn => 'Reject';

  @override
  String get messageClient => 'Message Client';

  @override
  String get pickupLocationDefault => 'Pickup Location';

  @override
  String get dropoffLocationDefault => 'Dropoff Location';

  @override
  String get fullSeats => 'Full 🔴';

  @override
  String availableSeats(String seats) {
    return '$seats seats available';
  }

  @override
  String get searchingForPassengers => 'Searching for passengers';

  @override
  String get clientProposesNewPrice => 'Client proposed a new price';

  @override
  String get waitingForClientResponse => 'Waiting for client response';

  @override
  String proposedPrice(String price) {
    return 'Proposed Price: $price EGP';
  }

  @override
  String finalPrice(String price) {
    return 'Final Price: $price EGP';
  }

  @override
  String get agreeWithPrice => 'Agree to Price';

  @override
  String get negotiateBtn => 'Negotiate';

  @override
  String get activateActiveTrip => 'Activate Trip';

  @override
  String get detailsAndMap => 'Details & Map';

  @override
  String get clientLocationNotAvailable =>
      'Client location is not available currently';

  @override
  String get cannotOpenGoogleMaps => 'Cannot open Google Maps';

  @override
  String get tripDataNotAvailable =>
      'Sorry, trip data is not available or has been cancelled.';

  @override
  String get trackTripTitle => 'Track Trip';

  @override
  String get unspecifiedDestination => 'Unspecified destination';

  @override
  String agreedPrice(String price) {
    return 'Agreed price: $price EGP';
  }

  @override
  String get iArrivedToClient => 'I arrived at the client';

  @override
  String get startTripBtn => 'Start Trip';

  @override
  String get tripEndedBtn => 'Trip Ended';

  @override
  String get endTripBtn => 'End Trip';

  @override
  String get driverMarkerTitle => 'Driver';

  @override
  String get statusPendingSearching => 'Searching for a captain...';

  @override
  String get statusNegotiatingPrice => 'Negotiating the price...';

  @override
  String get statusAcceptedGettingReady =>
      'Request accepted, captain is getting ready...';

  @override
  String get statusOnTheWay => 'Captain is on the way...';

  @override
  String get statusCaptainArrived => 'Captain is outside!';

  @override
  String get statusTripInProgress => 'Trip is currently in progress...';

  @override
  String get statusArrivedSafely => 'Arrived safely!';

  @override
  String get statusTripCancelled => 'Trip cancelled';

  @override
  String get tripEndedSuccessfully => 'Trip ended successfully!';

  @override
  String rateCaptain(String name) {
    return 'How do you rate Captain $name?';
  }

  @override
  String get addCommentOptional => 'Add a comment (optional)...';

  @override
  String get skipBtn => 'Skip';

  @override
  String get lammaCaptain => 'Lamma Captain';

  @override
  String get noPlateBoard => 'No plate';

  @override
  String get toDestination => 'To:';

  @override
  String get destinationPlaceholder => 'Destination';

  @override
  String get priceLabel => 'Price:';

  @override
  String get cancelTripBtn => 'Cancel Trip';
}
