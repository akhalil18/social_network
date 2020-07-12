import 'package:flutter/material.dart';

AppBar header(BuildContext context,
    {bool isAppTitle = false, String title, bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? 'FlutterShare' : title,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? 'signatra' : '',
        fontSize: isAppTitle ? 50.0 : 22.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
