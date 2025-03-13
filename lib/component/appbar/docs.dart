import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class Docs extends StatelessWidget {
  const Docs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DocsPage();
  }
}

class DocsPage extends StatefulWidget {
  const DocsPage({Key? key}) : super(key: key);

  @override
  _DocsPageState createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final String termuxDocs = '''
# Termux Setup Guide

## What is Termux?
Termux is an Android terminal emulator and Linux environment app that works directly with no rooting required. It provides a powerful command-line experience and allows you to run Linux tools on your Android device.

## Installation Methods

### Method 1: F-Droid (Recommended)
1. Visit [F-Droid website](https://f-droid.org)
2. Download and install F-Droid
3. Search for "Termux" in F-Droid
4. Install the latest version

### Method 2: GitHub Release
If F-Droid is not accessible:
1. Go to [Termux GitHub releases](https://github.com/termux/termux-app/releases)
2. Download `termux-app_v0.119.0-beta.1+apt-android-7-github-debug_arm64-v8a.apk`
3. Install the downloaded APK

## Initial Setup

1. **Grant Storage Permission**
   ```bash
   termux-setup-storage
   ```
   - This will prompt for storage access permission
   - Required for accessing device storage

2. **Update Package Repository**
   ```bash
   pkg update
   pkg upgrade
   ```
   - Always run this after fresh installation
   - Type 'y' when prompted

3. **Install Essential Packages**
   ```bash
   pkg install git cmake golang
   ```
   These are required for building Ollama

## Basic Termux Usage

### Package Management
- Install package: `pkg install <package-name>`
- Update packages: `pkg upgrade`
- Search packages: `pkg search <query>`
- Remove package: `pkg remove <package-name>`

### File Navigation
- Current directory: `pwd`
- List files: `ls`
- Change directory: `cd <directory>`
- Create directory: `mkdir <name>`
- Remove directory: `rm -r <directory>`

### Tips & Best Practices

1. **Performance**
   - Keep packages updated
   - Remove unused packages
   - Clear package cache: `pkg clean`

2. **Storage**
   - Regular cleanup of downloaded files
   - Monitor storage usage: `df -h`
   - Use `termux-setup-storage` for external storage

## Troubleshooting

### Common Issues

1. **Package Installation Fails**
   ```bash
   pkg update
   pkg upgrade
   ```
   If still failing, try:
   ```bash
   termux-change-repo
   ```

2. **Storage Access Issues**
   - Check app permissions in Android settings
   - Run `termux-setup-storage`
   - Restart Termux
''';

  final String ollamaDocs = '''
# Ollama Setup Guide

## What is Ollama?
Ollama is an open-source tool that allows you to run large language models locally on your Android device through Termux, without requiring cloud services.

## Prerequisites
- Termux installed and configured
- Git, CMake, and Golang installed
- Sufficient storage space (varies by model)
- Android device with good processing power

## Installation Steps

### 1. Install Dependencies
```bash
pkg upgrade
pkg install git cmake golang
```

### 2. Build from Source
```bash
# Clone Ollama repository
git clone --depth 1 https://github.com/ollama/ollama.git

# Navigate to ollama directory
cd ollama

# Generate and build
go generate ./...
go build .
```

### 3. Start Ollama Server
```bash
# Run server in background
./ollama serve &
```

### 4. Run a Model
```bash
# Example with Phi model
./ollama run phi
```

## Basic Commands

### Model Management
- Start server: `./ollama serve &`
- Run model: `./ollama run <model-name>`
- List models: `./ollama list`
- Remove model: `./ollama rm <model-name>`
- Pull model: `./ollama pull <model-name>`

### Recommended Models for Mobile
1. **Small Models (Best Performance)**
   - phi-2
   - deepseek-r1:1.5b
   - neural-chat:3b
   - mistral:7b

2. **Model Size Guidelines**
   - 1.5B-3B: Good performance on phones
   - 7B-13B: May be slower but usable
   - >30B: Not recommended for mobile

## Cleanup and Maintenance

### Remove Build Files
```bash
# Clean up Go directory
chmod -R 700 ~/go
rm -r ~/go
```

### System-wide Installation
```bash
# Move to bin for system-wide access
cp ollama/ollama /data/data/com.termux/files/usr/bin/
```

## Performance Tips

1. **Device Preparation**
   - Close background apps
   - Ensure sufficient free RAM
   - Connect to power source
   - Use in a cool environment

2. **Best Practices**
   - Start with smaller models
   - Monitor device temperature
   - Keep sessions reasonable length
   - Regular cleanup of unused models

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Go installation
   - Update all packages
   - Ensure sufficient storage

2. **Performance Issues**
   - Try smaller models
   - Check RAM usage
   - Monitor CPU temperature
   - Close background apps
''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Documentation',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF8B5CF6),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Termux'),
            Tab(text: 'Ollama'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarkdownTab(termuxDocs),
          _buildMarkdownTab(ollamaDocs),
        ],
      ),
    );
  }

  Widget _buildMarkdownTab(String content) {
    return Markdown(
      data: content,
      selectable: true,
      padding: EdgeInsets.all(16),
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        h2: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey[100],
          color: Color(0xFF8B5CF6),
          fontSize: 14,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        blockquote: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
        listBullet: TextStyle(
          color: Color(0xFF8B5CF6),
          fontSize: 16,
        ),
      ),
      onTapLink: (text, url, title) {
        if (url != null) _launchUrl(url);
      },
    );
  }
}