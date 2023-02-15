import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';
import '../utils/data.dart';
import 'copyrights_page.dart';

Color? _onHover(bool isFocused) {
  return isFocused ? Colors.grey[400] : Colors.grey;
}

Future<http.Response> getCopyRightsData() async {
  var url = Uri.parse('$tomtomUrl/2/copyrights?key=$apiKey');
  return await http.get(url);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    final officeLocation = LatLng(-6.7789659, 39.2525232);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xfff4f3ee),
              leading: const ControllerLogo(),
              leadingWidth: 130,
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Icon(
                    Icons.menu,
                    color: Color(0xffbcb8b1),
                    size: 32,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const CircleAvatar(
                    backgroundColor: Color(0xffbcb8b1),
                    radius: 16,
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Color(0xfff4f3ee),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: ListView.builder(
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: const Color(0xffedede9),
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 9,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routes[index].firstTerminal,
                                          style: kTerminalStyle,
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Earliest request: ${requests[index].earliestRequestAt}',
                                          style: kRequestTimeStyle,
                                        ),
                                      ],
                                    ),
                                    const CircleAvatar(
                                      foregroundColor: Color(0xfff4f3ee),
                                      backgroundColor: Color(0xffbcb8b1),
                                      child: Icon(Icons.sync_alt),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routes[index].lastTerminal,
                                          style: kTerminalStyle,
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Latest request: ${requests[index].latestRequestAt}',
                                          style: kRequestTimeStyle,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            // flex: 2,
                            child: VerticalDivider(
                              width: 30,
                              thickness: 0.5,
                              // indent: 20,
                              color: Color(0xffcccccc),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              requests[index].totalRequest,
                              style: kCounterStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              shrinkWrap: true,
              itemCount: routes.length,
              // physics: ClampingScrollPhysics(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.grey,
                child: FlutterMap(
                  options: MapOptions(
                    center: officeLocation,
                    zoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          '$tomtomUrl/1/tile/basic/main/{z}/{x}/{y}.png?key=$apiKey',
                      additionalOptions: const {'apiKey': apiKey},
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80,
                          height: 80,
                          point: officeLocation,
                          builder: (context) {
                            return Icon(
                              Icons.location_on,
                              size: 60,
                              color: Colors.blue[900],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Image.asset(
                        'images/tomtom_logo.png',
                        width: 110,
                        height: 50,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      http.Response response = await getCopyRightsData();
                      if (response.statusCode == 200) {
                        String resp = response.body;
                        if (context.mounted) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CopyrightsPage(
                                        copyrights: resp,
                                      )));
                        }
                      }
                    },
                    onHover: (focus) {
                      setState(() {
                        focus ? isFocused = true : isFocused = false;
                      });
                    },
                    style: const ButtonStyle(
                      overlayColor:
                          MaterialStatePropertyAll(Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.copyright,
                          size: 14,
                          color: _onHover(isFocused),
                        ),
                        Text(
                          'tomtom',
                          style: kCopyrightStyle.copyWith(
                            color: _onHover(isFocused),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ControllerLogo extends StatelessWidget {
  const ControllerLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        'PMS',
        textScaleFactor: 1.3,
        style: GoogleFonts.sofadiOne(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: Colors.blue[900],
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
