import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';
import 'copyrights_page.dart';

Color? _onHover(bool isFocused) {
  return isFocused ? Colors.grey[400] : Colors.grey;
}

Future<http.Response> getCopyRightsData() async {
  var url = Uri.parse('$tomtomUrl/2/copyrights?key=$apiKey');
  return await http.get(url);
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    final officeLocation = LatLng(-6.7789659, 39.2525232);
    return Container(
      color: Colors.brown,
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
                        return const Icon(
                          Icons.location_on,
                          size: 60,
                          color: Colors.black,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 24, top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const CircleAvatar(
                        radius: 18,
                        child: Text('U'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: badges.Badge(
                        badgeContent: const Text(
                          '9',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        position: badges.BadgePosition.topEnd(),
                        badgeStyle: const badges.BadgeStyle(
                            badgeColor: Colors.blueAccent,
                            borderSide: BorderSide(color: Colors.white)),
                        child: const Icon(
                          Icons.menu,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(right: 24, top: 12),
                child: TextButton(
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
                ),
              ),
            ],
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
                  overlayColor: MaterialStatePropertyAll(Colors.transparent),
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
                      style: copyrightStyle.copyWith(
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
    );
  }
}
