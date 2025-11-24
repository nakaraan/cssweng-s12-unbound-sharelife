import 'package:flutter/material.dart';

class AppThemes{
  
  // COLORS
  static const Color lightorange = Color(0xFFFFC6A0);
  static const Color orange = Color(0xFFf78a43);
  static const Color lightgreen = Color(0xFFC8D26A);
  static const Color green = Color.fromRGBO(69, 133, 74, 1);
  static const Color darkgreen = Color(0xFF1e3f20);
  static const Color brown = Color(0xFF3c2412);
  static const Color creme = Color(0xFFf5f2ea);
  static const Color lightcreme = Color(0xFFfffbf0);

  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFD9D9D9);
  static const Color darkgrey = Color.fromARGB(255, 148, 148, 148);
  static const Color black = Color(0xFF1E1E1E);




  // COLOR ASSIGNMENTS

  // top nav bar
  static const Color topnavContainer = darkgreen;
  static const Color topnavName = orange;
  static const Color topnavRole = grey;
  static const Color topnavIcons = white;

  // side nav bar
  static const Color sidenavContainer = lightcreme;
  static const Color sidenavSelected = orange;  // accounts for both icons and text
  static const Color sidenavOptions = brown;   // accounts for both icons and text

  // authentication + reg
  static const Color authContainer = brown;
  static const Color authFieldName = orange;
  static const Color authOptions = grey;
  static const Color authInput = creme;
  static const Color authInputHint = grey;
  static const Color authRememberFilled = lightgreen;

  // per page
  static const Color pageTitle = brown;
  static const Color pageSubtitle = darkgrey;
  static const Color searchButton = black;
  static const Color searchText = white;

  // general
  static const Color lines = black;   // accounts for both icons and text
  static const Color outerformButton = orange;
  static const Color innerformButton = lightorange;
  static const Color confirmButton = lightgreen;
  static const Color rejectButton = Color.fromARGB(255, 210, 106, 106);
  static const Color buttonText = brown;
}