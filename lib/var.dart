import 'package:flutter/material.dart';

bool isDarkMode = false;
Color darkPurple = Color(0xff290119);
Color lightPurple = Colors.purple.shade50;
bool isIOS = false;
bool loading = true;
bool noInternet = false;
PageController startScreenPageController = PageController(initialPage: 0);