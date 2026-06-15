import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_theme.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await NotificationService().init();
  runApp(const FileConverterApp());
}

class FileConverterApp extends StatelessWidget {
  const FileConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FileConvert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
