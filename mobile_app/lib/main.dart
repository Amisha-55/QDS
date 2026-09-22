import 'package:flutter/material.dart';
import 'package:qds/app/app.dart';
import 'package:qds/core/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance.init();
  runApp(const QdsApp());
}
