import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';

import '../models/route_info.dart';
import 'map_manager.dart';

/// Initializes the firestore databases and its associated methods
late FirestoreManager firestoreManager;
late MapManager mapManager;

/// Value notifier used to notify whether the [AutoreleaseButton] is pressed or not
final autoreleaseButtonNotifier = AutoreleaseButtonNotifier();

/// This should retrieve all routeInfo from the database
late List<RouteInfo> routeInfo;

bool driverIsMoving = false;
String driverPhone = '';
