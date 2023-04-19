import 'package:fyp_controller/data/firestore_manager.dart';
import 'package:fyp_controller/notifiers/autorelease_button_notifier.dart';

/// Initializes the firestore databases and its associated methods
late FirestoreManager firestoreManager;

/// Value notifier used to notify whether the [AutoreleaseButton] is pressed or not
final autoreleaseButtonNotifier = AutoreleaseButtonNotifier();
