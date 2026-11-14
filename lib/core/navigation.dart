import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum Transition { fadeIn }

class AppNavigator extends NavigatorObserver {
  static final key = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
  static final observer = AppNavigator();
  static final _routes = <Route<dynamic>>[];
  static BuildContext? get context => key.currentState?.overlay?.context;
  static ThemeData get theme =>
      context == null ? ThemeData.light() : Theme.of(context!);
  static double get height =>
      context == null ? 0 : MediaQuery.sizeOf(context!).height;
  static String get currentRoute =>
      _routes.reversed.whereType<PageRoute>().firstOrNull?.settings.name ?? '';
  static bool get isDialogOpen => _routes.lastOrNull is DialogRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) _routes[index] = newRoute;
  }

  static Future<T?>? toNamed<T>(String route, {Object? arguments}) =>
      key.currentState?.pushNamed<T>(route, arguments: arguments);
  static Future<T?>? offAllNamed<T>(String route, {Object? arguments}) => key
      .currentState
      ?.pushNamedAndRemoveUntil<T>(route, (_) => false, arguments: arguments);
  static Future<T?>? to<T>(Widget Function() page) =>
      key.currentState?.push<T>(CupertinoPageRoute(builder: (_) => page()));
  static Future<T?>? offAll<T>(
    Widget Function() page, {
    Transition? transition,
    Duration? duration,
  }) {
    final Route<T> route = transition == Transition.fadeIn
        ? PageRouteBuilder(
            transitionDuration: duration ?? const Duration(milliseconds: 300),
            pageBuilder: (_, _, _) => page(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          )
        : CupertinoPageRoute(builder: (_) => page());
    return key.currentState?.pushAndRemoveUntil<T>(route, (_) => false);
  }

  static void back<T>({T? result}) {
    if (key.currentState?.canPop() == true) key.currentState!.pop<T>(result);
  }

  static void until(RoutePredicate predicate) =>
      key.currentState?.popUntil(predicate);
  static Future<T?>? dialog<T>(
    Widget widget, {
    bool barrierDismissible = true,
  }) => context == null
      ? null
      : showDialog<T>(
          context: context!,
          barrierDismissible: barrierDismissible,
          builder: (_) => widget,
        );
  static Future<T?>? bottomSheet<T>(
    Widget widget, {
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) => context == null
      ? null
      : showModalBottomSheet<T>(
          context: context!,
          isScrollControlled: isScrollControlled,
          backgroundColor: backgroundColor,
          builder: (_) => widget,
        );

  static void defaultDialog({
    required String title,
    required String middleText,
    required String textConfirm,
    required String textCancel,
    required VoidCallback onConfirm,
    TextStyle? titleStyle,
    Color? buttonColor,
    Color? confirmTextColor,
  }) {
    dialog(
      AlertDialog(
        title: Text(title, style: titleStyle),
        content: Text(middleText),
        actions: [
          TextButton(onPressed: back, child: Text(textCancel)),
          FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: confirmTextColor,
            ),
            child: Text(textConfirm),
          ),
        ],
      ),
    );
  }
}
