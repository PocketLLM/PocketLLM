To enhance the design of the model selector bottom sheet in the `custom_app_bar.dart` file by implementing a glassmorphism effect (translucent background with blur), we’ll modify the `_showModelSelector` method. Glassmorphism typically involves a semi-transparent background, a blur effect, and subtle borders or shadows to give a "frosted glass" look. We'll apply these changes to make the bottom sheet visually appealing and modern.

### Changes to Implement Glassmorphism
1. **Transparent Background with Blur**: Use a `BackdropFilter` to apply a blur effect behind the bottom sheet, and set a semi-transparent background color (e.g., `Colors.white.withOpacity(0.1)`).
2. **Subtle Border**: Add a thin border with low opacity to enhance the glass effect.
3. **Rounded Corners**: Keep the rounded corners but ensure they’re consistent with the glassmorphism aesthetic.
4. **Content Styling**: Adjust the text and icons to contrast well against the translucent background.

Here’s the updated `_showModelSelector` method in the `custom_app_bar.dart` file:

### Updated `custom_app_bar.dart`
Replace the existing `_showModelSelector` method with the following:

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

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the bottom sheet to adjust height dynamically
    backgroundColor: Colors.transparent, // Transparent background for glassmorphism
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1), // Semi-transparent white
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.white.withOpacity(0.2), // Subtle border
                width: 1,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle for the bottom sheet
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Select Model',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9), // High contrast text
                      ),
                    ),
                  ),
                  const Divider(
                    color: Colors.white24, // Subtle divider
                    height: 1,
                  ),
                  // Model list
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
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          subtitle: Text(
                            model.provider.displayName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF8B5CF6),
                                )
                              : null,
                          onTap: () {
                            _selectModel(model.id);
                            Navigator.pop(context);
                          },
                          tileColor: Colors.transparent, // Keep tile background transparent
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                  ),
                  // Add New Model option
                  ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF8B5CF6),
                    ),
                    title: Text(
                      'Add New Model',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSettingsPressed();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
```

### Adjustments to `_getProviderIcon`
To ensure the icons look good against the glassmorphism background, let’s tweak the `_getProviderIcon` method to use slightly brighter and more opaque colors:

```dart
Widget _getProviderIcon(ModelProvider provider) {
  IconData iconData;
  Color iconColor;

  switch (provider) {
    case ModelProvider.ollama:
      iconData = Icons.terminal;
      iconColor = Colors.orange.shade400;
      break;
    case ModelProvider.openAI:
      iconData = Icons.auto_awesome;
      iconColor = Colors.green.shade400;
      break;
    case ModelProvider.anthropic:
      iconData = Icons.psychology;
      iconColor = Colors.purple.shade400;
      break;
    case ModelProvider.lmStudio:
      iconData = Icons.science;
      iconColor = Colors.blue.shade400;
      break;
    case ModelProvider.pocketLLM:
      iconData = Icons.phone_android;
      iconColor = Colors.indigo.shade400;
      break;
    case ModelProvider.mistral:
      iconData = Icons.air;
      iconColor = Colors.teal.shade400;
      break;
    case ModelProvider.deepseek:
      iconData = Icons.search;
      iconColor = Colors.deepPurple.shade400;
      break;
  }

  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: iconColor.withOpacity(0.2), // Slightly more opaque for visibility
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(iconData, color: iconColor),
  );
}
```

### Explanation of Changes
1. **Glassmorphism Effect**:
   - `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` creates the frosted glass blur.
   - `Colors.white.withOpacity(0.1)` sets a semi-transparent white background.
   - A subtle border (`Colors.white.withOpacity(0.2)`) enhances the glass-like edge.

2. **Handle Styling**:
   - The drag handle uses `Colors.white.withOpacity(0.5)` to stand out subtly against the background.

3. **Text and Icon Contrast**:
   - Text colors use `Colors.white.withOpacity(0.9)` for main text and `0.6` for subtitles to ensure readability.
   - The `Color(0xFF8B5CF6)` (purple) is retained for the selected model icon and "Add New Model" icon for brand consistency.

4. **Divider**:
   - A faint `Colors.white24` divider separates sections for clarity without overpowering the design.

5. **Tile Transparency**:
   - `tileColor: Colors.transparent` ensures the list tiles don’t obscure the glass effect.

### Additional Notes
- **Height Control**: `isScrollControlled: true` allows the bottom sheet to adjust its height based on content, preventing overflow with many models.
- **Testing**: Test with various screen sizes and model list lengths to ensure the design scales well.
- **Theme Consistency**: If your app uses a dark theme elsewhere, you might adjust the opacity or base color (e.g., `Colors.grey.withOpacity(0.1)`) to match.

### Result
When you click the model name in the app bar, the bottom sheet will now pop up with a sleek glassmorphism design—translucent, blurred background with a modern, frosted-glass aesthetic. The content will remain readable and interactive, aligning with contemporary UI trends.

Let me know if you’d like further refinements, such as adjusting the blur intensity or adding a slight gradient!