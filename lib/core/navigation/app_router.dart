import 'package:flutter/material.dart';

class AppRouter {
  static Future<T?> pushWithScaleTransition<T extends Object?>(
    BuildContext context,
    Widget newScreen, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => newScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: curve,
              ),
            ),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  static Future<T?> pushWithFadeTransition<T extends Object?>(
    BuildContext context,
    Widget newScreen, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeIn,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => newScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  static Future<T?> pushWithSlideTransition<T extends Object?>(
    BuildContext context,
    Widget newScreen, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    Offset beginOffset = const Offset(1.0, 0.0),
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => newScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var tween = Tween(begin: beginOffset, end: Offset.zero)
              .chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget newScreen,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => newScreen,
      ),
    );
  }

  static Future<void> pushAndRemoveUntil(
    BuildContext context,
    Widget newScreen, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeIn,
  }) {
    return Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => newScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
      (Route<dynamic> route) => false,
    );
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget newScreen, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeIn,
  }) {
    return Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => newScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }
}

class UnapprovedUserException implements Exception {
  final String message;

  UnapprovedUserException(this.message);

  @override
  String toString() => 'UnapprovedUserException: $message';
}
