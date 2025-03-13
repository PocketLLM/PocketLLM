import 'package:flutter/material.dart';
import '../pages/library_page.dart';
import '../pages/config_page.dart';
import '../pages/settings_page.dart';
// import '../component/appbar/docs.dart';
import '../pages/docs_page.dart';
import '../component/appbar/about.dart';
import '../component/appbar/chat_history.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool isDarkMode = false;
  bool isHistoryExpanded = false;
  final List<String> recentChats = ['Chat 1', 'Chat 2', 'Chat 3'];

  Widget _buildChatHistorySection() {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.chat_bubble_outline,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
            size: 22,
          ),
          title: Text(
            'Chat History',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey[800],
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Icon(
            isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24),
          dense: true,
          onTap: () {
            setState(() {
              isHistoryExpanded = !isHistoryExpanded;
            });
          },
        ),
        if (isHistoryExpanded)
          ...recentChats.map((chat) => ListTile(
                contentPadding: EdgeInsets.only(left: 56, right: 24),
                title: Text(
                  chat,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                dense: true,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ChatHistory()));
                },
              )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 50, bottom: 20, left: 20),
                  child: Text(
                    'PocketLLM',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B4EFF),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade100),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ),
                _buildChatHistorySection(),
                _buildMenuItem(Icons.store_outlined, 'Library',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LibraryPage()))),
                _buildMenuItem(Icons.settings_outlined, 'Settings',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SettingsPage()))),
                _buildMenuItem(Icons.description_outlined, 'Documentation',
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const DocsPage()))),
                _buildMenuItem(Icons.computer_outlined, 'System Config',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ConfigPage(appName: 'PocketLLM')))),
                _buildMenuItem(Icons.info_outline, 'Info',
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (context) => About()))),
              ],
            ),
          ),
          SizedBox(height: 8), // Add some space before dark mode button
          Padding(
            padding: EdgeInsets.only(bottom: 45),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              child: ListTile(
                leading: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined,
                  color: isDarkMode ? Colors.white : Colors.grey[700],
                  size: 20,
                ),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                dense: true,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () {
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDarkMode ? Colors.white70 : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.grey[800],
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 24),
      dense: true,
      onTap: onTap,
    );
  }
}

