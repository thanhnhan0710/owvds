import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:owvds/core/app/my_app.dart';

void main() {
  usePathUrlStrategy();
  runApp(const MyApp());
}
