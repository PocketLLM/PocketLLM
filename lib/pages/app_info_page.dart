import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({Key? key}) : super(key: key);

  @override
  _AppInfoPageState createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showLicenseDialog() {
    showLicensePage(
      context: context,
      applicationName: 'PocketLLM',
      applicationVersion: 'Version $_version (Build $_buildNumber)',
      applicationIcon: const Padding(
        padding: EdgeInsets.all(16.0),
        child: FlutterLogo(size: 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About PocketLLM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header with Logo and Version
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/icons/logo2.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PocketLLM',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version $_version (Build $_buildNumber)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Pocket AI. One chat for every LLM.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            // Quick Links Section
            _buildSection(
              title: 'Quick Links',
              children: [
                _buildLinkItem(
                  context: context,
                  icon: Icons.public,
                  title: 'Visit Our Website',
                  subtitle: 'pocketllm-ai.vercel.app',
                  onTap: () => _launchURL('https://pocketllm-ai.vercel.app/'),
                ),
                _buildLinkItem(
                  context: context,
                  icon: Icons.code,
                  title: 'GitHub Repository',
                  subtitle: 'github.com/PocketLLM/PocketLLM',
                  onTap: () => _launchURL('https://github.com/PocketLLM/PocketLLM'),
                ),
                _buildLinkItem(
                  context: context,
                  icon: Icons.email,
                  title: 'Support Email',
                  subtitle: 'prashantc592114@gmail.com',
                  onTap: () => _launchURL('mailto:prashantc592114@gmail.com'),
                ),
              ],
            ),
            
            // App Information Section
            _buildSection(
              title: 'App Information',
              children: [
                _buildInfoItem(
                  icon: Icons.update,
                  title: 'Check for Updates',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checking for updates...')),
                    );
                  },
                ),
                _buildInfoItem(
                  icon: Icons.history,
                  title: 'Version History',
                  onTap: () {
                    // Show version history
                  },
                ),
                _buildInfoItem(
                  icon: Icons.description_outlined,
                  title: 'Open Source Licenses',
                  onTap: _showLicenseDialog,
                ),
              ],
            ),
            
            // Legal Section
            _buildSection(
              title: 'Legal',
              children: [
                _buildInfoItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchURL('https://pocketllm-ai.vercel.app/privacy'),
                ),
                _buildInfoItem(
                  icon: Icons.article_outlined,
                  title: 'Terms of Service',
                  onTap: () => _launchURL('https://pocketllm-ai.vercel.app/terms'),
                ),
              ],
            ),
            
            // Support Section
            _buildSection(
              title: 'Support & Feedback',
              children: [
                _buildInfoItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () => _launchURL('https://pocketllm-ai.vercel.app/help'),
                ),
                _buildInfoItem(
                  icon: Icons.bug_report_outlined,
                  title: 'Report a Bug',
                  onTap: () => _launchURL('mailto:prashantc592114@gmail.com?subject=Bug%20Report'),
                ),
                _buildInfoItem(
                  icon: Icons.lightbulb_outline,
                  title: 'Suggest a Feature',
                  onTap: () => _launchURL('mailto:prashantc592114@gmail.com?subject=Feature%20Suggestion'),
                ),
              ],
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    '  ${DateTime.now().year} PocketLLM. All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.code),
                        onPressed: () => _launchURL('https://github.com/PocketLLM/PocketLLM'),
                        iconSize: 20,
                        color: theme.hintColor,
                      ),
                      IconButton(
                        icon: const Icon(Icons.public),
                        onPressed: () => _launchURL('https://pocketllm-ai.vercel.app/'),
                        iconSize: 20,
                        color: theme.hintColor,
                      ),
                      IconButton(
                        icon: const Icon(Icons.email),
                        onPressed: () => _launchURL('mailto:prashantc592114@gmail.com'),
                        iconSize: 20,
                        color: theme.hintColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with  by the PocketLLM Team',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Column(children: children),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.hintColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLinkItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 20,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
