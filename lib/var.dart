import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

bool isDarkMode = false;
Color darkPurple = Color(0xff290119);
Color lightPurple = Colors.purple.shade50;
bool isIOS = false;
bool loading = true;
bool noInternet = false;

late DocumentSnapshot<Map<String, dynamic>> doc;

PageController startScreenPageController = PageController(initialPage: 0);