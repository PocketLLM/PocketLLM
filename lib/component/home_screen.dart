import 'package:flutter/material.dart';
import 'custom_app_bar.dart';
import 'chat_interface.dart';
import 'sidebar.dart';
import '../pages/settings_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appName: 'PocketLLM',
        onSettingsPressed: () => _openSettings(context),
      ),
      drawer: Sidebar(),
      body: const ChatInterface(),
    );
  }
}
