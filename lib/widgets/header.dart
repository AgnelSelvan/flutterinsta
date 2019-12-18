import 'package:flutter/material.dart';

AppBar header(context, { bool isAppTitle = false, String titleText, removeBackButton = false }) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(isAppTitle ? "Flutter Insta" : titleText,
    style: TextStyle(
      color: Colors.white,
      fontFamily: 'Ubuntu',
      fontSize:isAppTitle ? 40.0 : 25,
    ),overflow: TextOverflow.ellipsis,),
    
    centerTitle: true,
    backgroundColor: Theme.of(context).primaryColor,
    
  );
}
