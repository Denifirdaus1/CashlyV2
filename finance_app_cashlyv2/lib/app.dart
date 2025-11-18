import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/home/home_screen.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashly V2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const HomeScreen(),
    );
  }
}
