import 'package:flutter/material.dart';

const double learnerStatusSlotHeight = 44;

final GlobalKey<NavigatorState> learnerNavigatorKey =
    GlobalKey<NavigatorState>();

RouteObserver<ModalRoute<dynamic>> learnerStatusRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

@visibleForTesting
void resetLearnerStatusRouteObserver() {
  learnerStatusRouteObserver = RouteObserver<ModalRoute<dynamic>>();
}
