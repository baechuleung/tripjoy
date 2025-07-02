import 'package:flutter/material.dart';
import '../../setting/setting.dart';

class DrawerHeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 10.0, right: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close, size: 23, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: Image.asset(
              'assets/side/setting.png',
              width: 20,
              height: 20,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}