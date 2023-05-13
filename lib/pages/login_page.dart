import 'package:flutter/material.dart';
import 'package:fyp_controller/data/location_manager.dart';

import '../data/firestore_manager.dart';
import '../data/resources.dart';
import '../models/route_info.dart';
import '../widgets/form_text_field.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  List<String> stationIDs = [];

  void _getAllStationIDs() async {
    stationIDs = await firestoreManager.getAllStationIDs();
  }

  @override
  void initState() {
    routeInfo = <RouteInfo>[];
    firestoreManager = FirestoreManager();
    locationManager = LocationManager();
    _getAllStationIDs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return SizedBox(
              width: width,
              height: height,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.35),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 30.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              radius: 30.0,
                              child: Text(
                                'PMS',
                                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'Enter Station ID',
                              style: TextStyle(fontSize: 18.0, color: Colors.grey),
                            ),
                          ),
                          FormTextField(
                            hintText: 'Station ID',
                            controller: _controller,
                            validator: (value) {
                              if (value == null) return null;
                              bool doesIDExist = _doesExist(value);
                              if (!doesIDExist) {
                                return 'ID does not exist';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                HomePage(stationID: _controller.text)));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Successfully logged in!'),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Incorrect logins info'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(Colors.blue)),
                                child: const Text('Login'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _doesExist(String value) {
    for (var id in stationIDs) {
      if (id.trim().toLowerCase() == value.trim().toLowerCase()) {
        return true;
      }
    }
    return false;
  }
}
