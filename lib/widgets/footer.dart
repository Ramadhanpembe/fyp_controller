import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../pages/copyrights_page.dart';
import '../utils/constants.dart';

class Footer extends StatelessWidget {
  const Footer({super.key, required this.isFocused, required this.onHover});

  final bool isFocused;
  final Function(bool) onHover;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            http.Response response = await _getCopyRightsData();
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
          onHover: (focus) => onHover(focus),
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
                style: kCopyrightStyle.copyWith(
                  color: _onHover(isFocused),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color? _onHover(bool isFocused) {
    return isFocused ? Colors.grey[400] : Colors.grey;
  }

  Future<http.Response> _getCopyRightsData() async {
    var url = Uri.parse('$tomtomUrl/2/copyrights?key=$apiKey');
    return await http.get(url);
  }
}
