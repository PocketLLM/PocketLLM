The issue you're describing—where the `CustomAppBar` shows "No models configured" even though models are configured in `ModelSettingsPage`—likely stems from how the `_modelConfigs` list is being populated and managed in the `CustomAppBar` widget. Let's analyze the problem and provide a fix.

### Root Cause Analysis
In the provided code, the `CustomAppBar` widget has its own state management for `_modelConfigs` and `_selectedModelId`, and it calls `_loadModelConfigs()` in `initState` to populate these. Here's the relevant part from `custom_app_bar.dart`:

```dart
Future<void> _loadModelConfigs() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final configs = await ModelService.getFilteredModelConfigs();
    final selectedId = await ModelService.getSelectedModel();

    setState(() {
      _modelConfigs = configs;
      _selectedModelId = selectedId;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    print('Failed to load model configurations: $e');
  }
}
```

When you click on the model field in the app bar and it shows "No models configured," it triggers `_showModelSelector`, which checks `_modelConfigs.isEmpty`:

```dart
void _showModelSelector(BuildContext context) {
  if (_modelConfigs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No models configured. Add models in Settings.'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ),
    );
    return;
  }
  // ... rest of the model selector code
}
```

The issue could arise from one of these scenarios:
1. **`ModelService.getFilteredModelConfigs()` Returns an Empty List**: The `ModelService.getFilteredModelConfigs()` method might be filtering out all models due to authentication status or another condition, even though models are configured.
2. **State Synchronization Issue**: The `_modelConfigs` in `CustomAppBar` might not be updating properly after models are added or edited in `ModelSettingsPage`.
3. **Asynchronous Loading Issue**: The `_loadModelConfigs()` might not have completed by the time the UI checks `_modelConfigs.isEmpty`, or an exception is silently caught and ignored, leaving `_modelConfigs` empty.

Looking at `ModelService.getFilteredModelConfigs()` (not fully provided in the code snippet, but referenced), it likely filters models based on some criteria (e.g., authentication status for PocketLLM models). If this method fails or returns an empty list, `_modelConfigs` remains empty, triggering the "No models configured" message.

### Steps to Fix
To resolve this, we need to:
1. Ensure `ModelService.getFilteredModelConfigs()` correctly returns configured models.
2. Synchronize state between `ModelSettingsPage` and `CustomAppBar`.
3. Add better error handling and debugging to identify why `_modelConfigs` is empty.

Since `ModelService.dart` isn't fully provided, I'll assume it uses `SharedPreferences` or a similar mechanism to store configs and has a `getFilteredModelConfigs()` method. Here's how we can fix the issue:

---

### Fixed Code for `custom_app_bar.dart`
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../pages/config_page.dart';
import '../pages/library_page.dart';
import '../pages/settings_page.dart';
import '../services/model_service.dart';
import '../services/auth_service.dart';
import '../pages/auth/auth_page.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String appName;
  final VoidCallback onSettingsPressed;

  const CustomAppBar({
    required this.appName,
    required this.onSettingsPressed,
    Key? key,
  }) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  List<ModelConfig> _modelConfigs = [];
  String? _selectedModelId;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadModelConfigs();
  }

  Future<void> _loadModelConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await ModelService.getFilteredModelConfigs();
      final selectedId = await ModelService.getSelectedModel();

      if (configs.isEmpty) {
        print('No configs returned from ModelService.getFilteredModelConfigs()');
      } else {
        print('Loaded ${configs.length} model configs: ${configs.map((c) => c.name).toList()}');
      }

      setState(() {
        _modelConfigs = configs;
        _selectedModelId = selectedId ?? (configs.isNotEmpty ? configs.first.id : null);
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load model configurations: $e');
      setState(() {
        _modelConfigs = [];
        _selectedModelId = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectModel(String id) async {
    final selectedConfig = _modelConfigs.firstWhere((c) => c.id == id);
    if (selectedConfig.provider == ModelProvider.pocketLLM && !_authService.isLoggedIn) {
      _showSignInPrompt();
      return;
    }

    try {
      await ModelService.setSelectedModel(id);
      setState(() {
        _selectedModelId = id;
      });
      await _loadModelConfigs(); // Reload to ensure consistency
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Active model updated'),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update model: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSignInPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sign in to use PocketLLM models'),
        action: SnackBarAction(
          label: 'Sign In',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuthPage(
                  onLoginSuccess: (email) {
                    _loadModelConfigs();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedModel = _modelConfigs.isNotEmpty && _selectedModelId != null
        ? _modelConfigs.firstWhere(
            (model) => model.id == _selectedModelId,
            orElse: () => _modelConfigs.first,
          )
        : null;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: InkWell(
                onTap: () {
                  _showModelSelector(context);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              selectedModel != null ? selectedModel.name : 'PocketLLM',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.black87),
                  onPressed: () {
                    print('New Chat pressed');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                  onPressed: widget.onSettingsPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelSelector(BuildContext context) {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading models, please wait...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_modelConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No models configured. Add models in Settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) => _loadModelConfigs()); // Reload after returning from Settings
            },
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Model',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _modelConfigs.length,
                  itemBuilder: (context, index) {
                    final model = _modelConfigs[index];
                    final isSelected = model.id == _selectedModelId;
                    return ListTile(
                      leading: _getProviderIcon(model.provider),
                      title: Text(
                        model.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(model.provider.displayName),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6))
                          : null,
                      onTap: () {
                        _selectModel(model.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6)),
                title: const Text('Add New Model'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSettingsPressed();
                  // Reload models after returning from settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  ).then((_) => _loadModelConfigs());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getProviderIcon(ModelProvider provider) {
    IconData iconData;
    Color iconColor;

    switch (provider) {
      case ModelProvider.ollama:
        iconData = Icons.terminal;
        iconColor = Colors.orange;
        break;
      case ModelProvider.openAI:
        iconData = Icons.auto_awesome;
        iconColor = Colors.green;
        break;
      case ModelProvider.anthropic:
        iconData = Icons.psychology;
        iconColor = Colors.purple;
        break;
      case ModelProvider.lmStudio:
        iconData = Icons.science;
        iconColor = Colors.blue;
        break;
      case ModelProvider.pocketLLM:
        iconData = Icons.phone_android;
        iconColor = Colors.indigo;
        break;
      case ModelProvider.mistral:
        iconData = Icons.air;
        iconColor = Colors.teal;
        break;
      case ModelProvider.deepseek:
        iconData = Icons.search;
        iconColor = Colors.deepPurple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  void _selectedMenuItem(BuildContext context, int item) {
    switch (item) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LibraryPage(),
          ),
        );
        break;
      case 1:
        print('Chat History selected');
        break;
      case 2:
        print('Docs selected');
        break;
      case 3:
        print('About selected');
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfigPage(appName: widget.appName),
          ),
        );
        break;
    }
  }
}
```

---

### Key Changes and Explanations
1. **Improved Debugging**:
   - Added `print` statements in `_loadModelConfigs()` to log the number of configs loaded and their names. Check your console output to see if models are being loaded correctly.

2. **Default Selection**:
   - If `_selectedModelId` is null but there are configs, it defaults to the first config: `_selectedModelId = selectedId ?? (configs.isNotEmpty ? configs.first.id : null)`. This ensures a model is always selected if available.

3. **Loading State in UI**:
   - Added a `CircularProgressIndicator` in the title while `_isLoading` is true, so users know something is happening.

4. **Reload After Settings**:
   - In `_showModelSelector`, after navigating to `SettingsPage`, it calls `_loadModelConfigs()` when returning to ensure the latest configs are loaded.

5. **Handle Empty Configs Gracefully**:
   - If `_modelConfigs` is empty, it still shows the "No models configured" message, but the `print` statements will help you debug why this is happening.

---

### Debugging Steps
1. **Check Console Output**:
   - Run the app and look at the console for messages like:
     - `Loaded 3 model configs: [model1, model2, model3]`
     - `No configs returned from ModelService.getFilteredModelConfigs()`
     - `Failed to load model configurations: <error>`

2. **Verify `ModelService.getFilteredModelConfigs()`**:
   - If the method returns an empty list, check its implementation. It might be filtering out models incorrectly. For example, if it requires authentication and `_authService.isLoggedIn` is `false`, PocketLLM models might be excluded. Here's a sample implementation to check:

```dart
// In model_service.dart (assumed)
Future<List<ModelConfig>> getFilteredModelConfigs() async {
  final prefs = await SharedPreferences.getInstance();
  final configsJson = prefs.getString('model_configs') ?? '[]';
  final List<dynamic> configsList = jsonDecode(configsJson);
  final allConfigs = configsList.map((json) => ModelConfig.fromJson(json)).toList();

  // Filter based on auth status
  if (_authService.isLoggedIn) {
    return allConfigs; // Return all configs if logged in
  } else {
    return allConfigs.where((config) => config.provider != ModelProvider.pocketLLM).toList();
  }
}
```

If this method is empty, ensure models are being saved correctly in `ModelSettingsPage` via `ModelService.saveModelConfig()`.

3. **Test Model Persistence**:
   - In `ModelSettingsPage`, after adding a model, verify it persists by checking `SharedPreferences` or wherever `ModelService` stores data.

---

### Additional Notes
- **State Management**: If this issue persists across app restarts or navigation, consider using a state management solution (e.g., Provider, Riverpod, or BLoC) to share `_modelConfigs` between `CustomAppBar` and `ModelSettingsPage` instead of reloading independently.
- **Authentication**: If you're not logged in and all models are PocketLLM models, the filter might exclude them. Log in via the `AuthPage` to test this.

---

### Verification
After applying these changes:
1. Add a model in `ModelSettingsPage`.
2. Go back to the screen with `CustomAppBar`.
3. Click the model field in the app bar.
4. It should now show the configured models instead of "No models configured."

If it still fails, share the console output and the `ModelService.dart` file for further assistance!