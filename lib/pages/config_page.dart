/// File Overview:
/// - Purpose: Device configuration checklist that inspects Termux installation
///   and hardware stats locally.
/// - Backend Migration: Reevaluate necessity; backend onboarding may make this
///   redundant or require sanitized telemetry reporting instead of direct checks.
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_info2/system_info2.dart';
import 'package:pocketllm/services/termux_service.dart';
import 'docs_page.dart';

class ConfigPage extends StatefulWidget {
  final String appName;

  const ConfigPage({Key? key, required this.appName}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  Map<String, String> deviceInfo = {};
  Map<String, String> storageInfo = {};
  bool isTermuxInstalled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadDeviceInfo();
    _loadStorageInfo();
    _checkTermux();
  }

  Future<void> _loadStorageInfo() async {
    try {
      // Get RAM information
      final totalRam = SysInfo.getTotalPhysicalMemory();
      final freeRam = SysInfo.getFreePhysicalMemory();
      final usedRam = totalRam - freeRam;
      final ramPercentage = ((usedRam / totalRam) * 100).toStringAsFixed(0);
      
      // Get storage information
      final directory = Directory('/storage/emulated/0');
      final df = await Process.run('df', [directory.path]);
      final lines = df.stdout.toString().split('\n');
      
      if (lines.length > 1) {
        final values = lines[1].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
        final totalBytes = int.parse(values[1]) * 1024;
        final freeBytes = int.parse(values[3]) * 1024;
        final usedBytes = totalBytes - freeBytes;
        final storagePercentage = ((usedBytes / totalBytes) * 100).toStringAsFixed(0);

        setState(() {
          storageInfo = {
            'System Memory': '${(usedRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB of ${(totalRam / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB ($ramPercentage%)',
            'Internal Storage': '${(usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB of ${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB ($storagePercentage%)',
          };
        });
      }
    } catch (e) {
      print("Error loading storage info: $e");
      setState(() {
        storageInfo = {
          'System Memory': 'Error loading memory information',
          'Internal Storage': 'Error loading storage information',
        };
      });
    }
  }

  Future<void> _checkTermux() async {
    try {
      // Define possible Termux installation paths
      final List<String> possiblePaths = [
        '/data/data/com.termux',
        '/storage/emulated/0/Android/data/com.termux',
        '/storage/emulated/0/Android/obb/com.termux',
      ];
      
      bool found = false;
      
      // Check if any of the directories exist
      for (final path in possiblePaths) {
        final directory = Directory(path);
        if (await directory.exists()) {
          found = true;
          break;
        }
      }
      
      // Try to check if the package is installed using canLaunchUrl
      try {
        final termuxPackageUrl = Uri.parse('package:com.termux');
        final canLaunch = await canLaunchUrl(termuxPackageUrl);
        found = found || canLaunch;
      } catch (e) {
        print("Error checking package URL: $e");
      }

      setState(() {
        isTermuxInstalled = found;
        isLoading = false;
      });
    } catch (e) {
      print("Error checking Termux: $e");
      setState(() {
        isTermuxInstalled = false;
        isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.storage,
    ].request();

    if (statuses[Permission.phone]!.isGranted) {
      _loadDeviceInfo();
    } else {
      setState(() {
        deviceInfo = {
          'Error': 'Permissions required to show device information',
        };
        isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;

      if (!mounted) return;

      setState(() {
        deviceInfo = {
          'Device Name': androidInfo.model,
          'Manufacturer': androidInfo.manufacturer,
          'Android Version': '${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
          'Security Patch': androidInfo.version.securityPatch ?? 'Unknown',
          'Build Number': androidInfo.id,
          'Brand': androidInfo.brand,
          'Board': androidInfo.board,
          'Processor': androidInfo.hardware,
        };
      });
    } catch (e) {
      print("Error loading device info: $e");
      if (!mounted) return;

      setState(() {
        deviceInfo = {
          'Error': 'Failed to load device information',
        };
      });
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.7) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadDeviceInfo();
              _loadStorageInfo();
              _checkTermux();
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceSection(),
                  _buildStorageSection(),
                  _buildMemorySection(),
                  _buildTermuxSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceSection() {
    return _buildSection(
      'Device Information',
      deviceInfo.entries.map((e) => _buildInfoRow(e.key, e.value)).toList(),
    );
  }

  Widget _buildStorageSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.storage, color: Color(0xFF8B5CF6)),
                SizedBox(width: 12),
                Text(
                  'Storage Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...storageInfo.entries.map((entry) => _buildStorageItem(
            entry.key,
            entry.value,
            _getStoragePercentage(entry.value),
          )).toList(),
        ],
      ),
    );
  }

  double _getStoragePercentage(String value) {
    try {
      final percentageMatch = RegExp(r'\((\d+)%\)').firstMatch(value);
      if (percentageMatch != null) {
        return int.parse(percentageMatch.group(1)!) / 100;
      }
    } catch (e) {
      print("Error parsing storage percentage: $e");
    }
    return 0.0;
  }

  Widget _buildStorageItem(String label, String value, double percentage) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: _getProgressColor(percentage).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(percentage)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorySection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Memory Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildMemoryRow('Total RAM', '12 GB'),
                      const SizedBox(height: 16),
                      _buildMemoryRow('Available RAM', '4.8 GB'),
                      const SizedBox(height: 16),
                      _buildMemoryRow('Running Processes', '142'),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CustomPaint(
                    painter: MemoryPainter(0.6, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermuxSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: Colors.purple[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Termux',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTermuxInstalled ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTermuxInstalled ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTermuxInstalled ? Icons.check_circle : Icons.error,
                        color: isTermuxInstalled ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTermuxInstalled ? 'Installed' : 'Not Installed',
                        style: TextStyle(
                          color: isTermuxInstalled ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Termux Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isTermuxInstalled
                      ? 'Termux is installed on your device. You can use it to run Linux commands and tools.'
                      : 'Termux is not installed on your device. Install it to access powerful command-line tools and Linux utilities.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isTermuxInstalled
                            ? _launchTermux
                            : _launchTermuxDownload,
                        icon: Icon(
                          isTermuxInstalled ? Icons.launch : Icons.download,
                          color: Colors.white,
                        ),
                        label: Text(
                          isTermuxInstalled ? 'Open Termux' : 'Install Termux',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (isTermuxInstalled) ...[  
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to the docs page instead of showing a simple dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DocsPage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.help_outline,
                          color: Colors.purple[600],
                        ),
                        label: Text(
                          'Setup Guide',
                          style: TextStyle(color: Colors.purple[600]),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          side: BorderSide(color: Colors.purple[600]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTermuxDownload() async {
    final Uri url = Uri.parse('https://f-droid.org/en/packages/com.termux/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchTermux() async {
    try {
      await TermuxService.launchTermux();
    } catch (e) {
      print("Error launching Termux: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to launch Termux')),
      );
    }
  }
}

class MemoryPainter extends CustomPainter {
  final double percentage;
  final Color color;

  MemoryPainter(this.percentage, {this.color = Colors.purple});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius - 4, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -1.5708,
      percentage * 2 * 3.14159,
      false,
      progressPaint,
    );

    // Add percentage text in center
    final textSpan = TextSpan(
      text: '${(percentage * 100).toInt()}%',
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}