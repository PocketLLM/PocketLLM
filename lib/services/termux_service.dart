import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class TermuxService {
  static Future<void> launchTermux() async {
    try {
      const String termuxPackageName = 'com.termux';
      if (Platform.isAndroid) {
        final Uri uri = Uri.parse('termux://');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // If can't launch directly, try to open in Play Store
          final Uri playStoreUri = Uri.parse(
            'market://details?id=$termuxPackageName',
          );
          if (await canLaunchUrl(playStoreUri)) {
            await launchUrl(playStoreUri);
          } else {
            throw Exception('Could not launch Termux or Play Store');
          }
        }
      } else {
        throw Exception('Termux is only available on Android');
      }
    } catch (e) {
      debugPrint('Error launching Termux: $e');
      rethrow;
    }
  }

  static Future<void> runCommand(
    BuildContext context, 
    String command, 
    {Function(String)? onOutput}
  ) async {
    try {
      print('Attempting to run command: $command');
      
      // First, try to launch Termux using package name
      final termuxPackageUrl = Uri.parse('package:com.termux');
      
      if (await canLaunchUrl(termuxPackageUrl)) {
        await launchUrl(
          termuxPackageUrl,
          mode: LaunchMode.externalApplication,
        );
        
        // Wait for Termux to open
        await Future.delayed(const Duration(seconds: 2));
        
        // Use the Android shell to send the command
        final shellCommand = 'input text "$command" && input keyevent 66';
        
        try {
          final result = await Process.run('su', ['-c', shellCommand]);
          print('Shell command result: ${result.stdout}');
          print('Shell command error: ${result.stderr}');
          
          if (result.exitCode == 0) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Command executed in Termux: $command'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            throw Exception('Failed to execute shell command');
          }
        } catch (e) {
          print('Shell command error: $e');
          // Try alternative method using am broadcast
          final amCommand = 'am start -n com.termux/.app.TermuxActivity && '
              'am broadcast --user 0 -a com.termux.app.RUN_COMMAND '
              '--es com.termux.app.RUN_COMMAND_PATH "/data/data/com.termux/files/usr/bin/bash" '
              '--es com.termux.app.RUN_COMMAND_ARGUMENTS "-c \'$command\'"';

          final broadcastResult = await Process.run('sh', ['-c', amCommand]);
          print('Broadcast result: ${broadcastResult.stdout}');
          print('Broadcast error: ${broadcastResult.stderr}');
          
          if (broadcastResult.exitCode != 0) {
            throw Exception('Failed to send broadcast command');
          }
        }
      } else {
        throw Exception('Termux is not installed or accessible');
      }
    } catch (e, stackTrace) {
      print('Error in runCommand: $e');
      print('Stack trace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to execute command: $command\nPlease make sure Termux is installed and accessible.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Install',
              textColor: Colors.white,
              onPressed: () async {
                final url = Uri.parse('https://f-droid.org/en/packages/com.termux/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      }
    }
  }
}