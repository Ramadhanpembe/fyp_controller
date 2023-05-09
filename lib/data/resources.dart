import 'package:flutter/material.dart';
import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/data/location_manager.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';

import '../models/route_info.dart';
import 'map_manager.dart';

/// Initializes the firestore databases and its associated methods
late FirestoreManager firestoreManager;
late LocationManager locationManager;
late MapManager mapManager;

/// Value notifier used to notify whether the [AutoreleaseButton] is pressed or not
final autoreleaseButtonNotifier = AutoreleaseButtonNotifier();
final autoReleaseOnNotifier = ValueNotifier<bool>(false);

/// This should retrieve all routeInfo from the database
late List<RouteInfo> routeInfo;

bool driverIsMoving = false;
String driverPhone = '';

/// new
String notifiedDriverPhone = '';

/// //////////////////

late final List<ValueNotifier<int>> totalRequestsNotifiers;
late final List<ValueNotifier<String>> earliestRequestAtNotifiers;
late final List<ValueNotifier<String>> latestRequestAtNotifiers;

bool isPermissionGranted = false;
