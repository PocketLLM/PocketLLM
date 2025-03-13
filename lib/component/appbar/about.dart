import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class About extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.2),
              elevation: 0,
              title: const Text('About'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'About PocketLLM',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4EFF),  // Updated to match theme color
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              'Our Mission',
              'Bringing powerful AI capabilities to everyone\'s pocket while ensuring complete privacy and control over your data.',
              Colors.pink.shade50,
            ),
            _buildCard(
              'Key Features',
              '• Custom Model Support\n• Web Search Integration\n• Document Chat\n• Image Understanding\n• Offline Operation\n• Zero Cost\n• No Data Collection',
              Colors.purple.shade50,
            ),
            _buildCard(
              'AI Expertise',
              'All processing is done locally on your device using state-of-the-art LLM models, ensuring fast and private interactions.',
              Colors.teal.shade50,
            ),
            _buildCard(
              'Privacy & Security',
              'Your data stays on your device. No cloud processing, no data collection, and complete control over your information.',
              Colors.orange.shade50,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  final url = Uri.parse('https://github.com/Mr-Dark-debug/PocketLLM');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                icon: const Icon(Icons.code),
                label: const Text('View Source Code'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B4EFF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String content, Color backgroundColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}