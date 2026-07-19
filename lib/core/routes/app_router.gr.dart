// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DriverRadarPage]
class DriverRadarRoute extends PageRouteInfo<void> {
  const DriverRadarRoute({List<PageRouteInfo>? children})
      : super(
          DriverRadarRoute.name,
          initialChildren: children,
        );

  static const String name = 'DriverRadarRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DriverRadarPage();
    },
  );
}

/// generated route for
/// [DriverTripTrackingPage]
class DriverTripTrackingRoute
    extends PageRouteInfo<DriverTripTrackingRouteArgs> {
  DriverTripTrackingRoute({
    Key? key,
    required String tripId,
    List<PageRouteInfo>? children,
  }) : super(
          DriverTripTrackingRoute.name,
          args: DriverTripTrackingRouteArgs(
            key: key,
            tripId: tripId,
          ),
          initialChildren: children,
        );

  static const String name = 'DriverTripTrackingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DriverTripTrackingRouteArgs>();
      return DriverTripTrackingPage(
        key: args.key,
        tripId: args.tripId,
      );
    },
  );
}

class DriverTripTrackingRouteArgs {
  const DriverTripTrackingRouteArgs({
    this.key,
    required this.tripId,
  });

  final Key? key;

  final String tripId;

  @override
  String toString() {
    return 'DriverTripTrackingRouteArgs{key: $key, tripId: $tripId}';
  }
}

/// generated route for
/// [EmailSignUpPage]
class EmailSignUpRoute extends PageRouteInfo<EmailSignUpRouteArgs> {
  EmailSignUpRoute({
    Key? key,
    String? name,
    String? phone,
    String? email,
    String? role,
    List<PageRouteInfo>? children,
  }) : super(
          EmailSignUpRoute.name,
          args: EmailSignUpRouteArgs(
            key: key,
            name: name,
            phone: phone,
            email: email,
            role: role,
          ),
          initialChildren: children,
        );

  static const String name = 'EmailSignUpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EmailSignUpRouteArgs>(
          orElse: () => const EmailSignUpRouteArgs());
      return EmailSignUpPage(
        key: args.key,
        name: args.name,
        phone: args.phone,
        email: args.email,
        role: args.role,
      );
    },
  );
}

class EmailSignUpRouteArgs {
  const EmailSignUpRouteArgs({
    this.key,
    this.name,
    this.phone,
    this.email,
    this.role,
  });

  final Key? key;

  final String? name;

  final String? phone;

  final String? email;

  final String? role;

  @override
  String toString() {
    return 'EmailSignUpRouteArgs{key: $key, name: $name, phone: $phone, email: $email, role: $role}';
  }
}

/// generated route for
/// [ForgotPasswordPage]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
      : super(
          ForgotPasswordRoute.name,
          initialChildren: children,
        );

  static const String name = 'ForgotPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ForgotPasswordPage();
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [NotificationsPage]
class NotificationsRoute extends PageRouteInfo<void> {
  const NotificationsRoute({List<PageRouteInfo>? children})
      : super(
          NotificationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotificationsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotificationsPage();
    },
  );
}

/// generated route for
/// [OtpPage]
class OtpRoute extends PageRouteInfo<OtpRouteArgs> {
  OtpRoute({
    Key? key,
    required String verificationId,
    required String name,
    required String email,
    required String phone,
    required String role,
    List<PageRouteInfo>? children,
  }) : super(
          OtpRoute.name,
          args: OtpRouteArgs(
            key: key,
            verificationId: verificationId,
            name: name,
            email: email,
            phone: phone,
            role: role,
          ),
          initialChildren: children,
        );

  static const String name = 'OtpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OtpRouteArgs>();
      return OtpPage(
        key: args.key,
        verificationId: args.verificationId,
        name: args.name,
        email: args.email,
        phone: args.phone,
        role: args.role,
      );
    },
  );
}

class OtpRouteArgs {
  const OtpRouteArgs({
    this.key,
    required this.verificationId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final Key? key;

  final String verificationId;

  final String name;

  final String email;

  final String phone;

  final String role;

  @override
  String toString() {
    return 'OtpRouteArgs{key: $key, verificationId: $verificationId, name: $name, email: $email, phone: $phone, role: $role}';
  }
}

/// generated route for
/// [PassengerSearchPage]
class PassengerSearchRoute extends PageRouteInfo<void> {
  const PassengerSearchRoute({List<PageRouteInfo>? children})
      : super(
          PassengerSearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'PassengerSearchRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PassengerSearchPage();
    },
  );
}

/// generated route for
/// [PassengerTripTrackingPage]
class PassengerTripTrackingRoute
    extends PageRouteInfo<PassengerTripTrackingRouteArgs> {
  PassengerTripTrackingRoute({
    Key? key,
    required String tripId,
    required String passengerId,
    List<PageRouteInfo>? children,
  }) : super(
          PassengerTripTrackingRoute.name,
          args: PassengerTripTrackingRouteArgs(
            key: key,
            tripId: tripId,
            passengerId: passengerId,
          ),
          initialChildren: children,
        );

  static const String name = 'PassengerTripTrackingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PassengerTripTrackingRouteArgs>();
      return PassengerTripTrackingPage(
        key: args.key,
        tripId: args.tripId,
        passengerId: args.passengerId,
      );
    },
  );
}

class PassengerTripTrackingRouteArgs {
  const PassengerTripTrackingRouteArgs({
    this.key,
    required this.tripId,
    required this.passengerId,
  });

  final Key? key;

  final String tripId;

  final String passengerId;

  @override
  String toString() {
    return 'PassengerTripTrackingRouteArgs{key: $key, tripId: $tripId, passengerId: $passengerId}';
  }
}

/// generated route for
/// [SignUpPage]
class SignUpRoute extends PageRouteInfo<void> {
  const SignUpRoute({List<PageRouteInfo>? children})
      : super(
          SignUpRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignUpRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SignUpPage();
    },
  );
}

/// generated route for
/// [TripChatPage]
class TripChatRoute extends PageRouteInfo<TripChatRouteArgs> {
  TripChatRoute({
    Key? key,
    required String tripId,
    List<PageRouteInfo>? children,
  }) : super(
          TripChatRoute.name,
          args: TripChatRouteArgs(
            key: key,
            tripId: tripId,
          ),
          initialChildren: children,
        );

  static const String name = 'TripChatRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TripChatRouteArgs>();
      return TripChatPage(
        key: args.key,
        tripId: args.tripId,
      );
    },
  );
}

class TripChatRouteArgs {
  const TripChatRouteArgs({
    this.key,
    required this.tripId,
  });

  final Key? key;

  final String tripId;

  @override
  String toString() {
    return 'TripChatRouteArgs{key: $key, tripId: $tripId}';
  }
}
