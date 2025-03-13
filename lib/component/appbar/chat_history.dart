import 'package:flutter/material.dart';

class ChatHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with actual chat history count
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Chat ${index + 1}'),
            subtitle: Text('Last message...'),
            onTap: () {
              // Navigate to the selected chat
              Navigator.pop(context); // Close the chat history page
            },
          );
        },
      ),
    );
  }
}