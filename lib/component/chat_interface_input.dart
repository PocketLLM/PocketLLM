part of 'chat_interface.dart';

extension ChatInterfaceInput on ChatInterfaceState {
  Widget _buildInputArea() {
    final colorScheme = ThemeService().colorScheme;
    final composerEmpty = _messageController.text.trim().isEmpty;
    final quickActions = _quickActionItems();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.cardBorder.withOpacity(0.6),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 12,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _showAttachmentOptions
                    ? _buildAttachmentPanel(colorScheme)
                    : const SizedBox.shrink(),
              ),
              if (composerEmpty && quickActions.isNotEmpty) ...[
                _buildQuickActionSection(colorScheme, quickActions),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildAttachmentToggle(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(child: _buildComposerField(colorScheme)),
                  const SizedBox(width: 12),
                  _buildSendButton(colorScheme, composerEmpty || _isLoading),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentPanel(AppColorScheme colorScheme) {
    final shortcuts = _attachmentShortcuts();
    final options = _attachmentOptions();

    return Container(
      key: const ValueKey('composer-attachment-panel'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shortcuts.isNotEmpty) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: shortcuts
                  .map((shortcut) => _buildAttachmentShortcut(shortcut, colorScheme))
                  .toList(),
            ),
            if (options.isNotEmpty) const SizedBox(height: 16),
          ],
          if (options.isNotEmpty)
            ...List.generate(options.length * 2 - 1, (index) {
              if (index.isOdd) {
                return Divider(
                  height: 16,
                  thickness: 1,
                  color: colorScheme.cardBorder.withOpacity(0.4),
                );
              }
              final option = options[index ~/ 2];
              return _buildAttachmentOption(option, colorScheme);
            }),
        ],
      ),
    );
  }

  Widget _buildAttachmentShortcut(
    _ComposerAttachmentShortcut shortcut,
    AppColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: shortcut.onTap == null
          ? null
          : () async {
              setState(() {
                _showAttachmentOptions = false;
              });
              await shortcut.onTap!.call();
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              shortcut.icon,
              color: colorScheme.primary,
              size: 26,
            ),
            const SizedBox(height: 8),
            Text(
              shortcut.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    _ComposerAttachmentOption option,
    AppColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: option.onSelected == null
          ? null
          : () async {
              setState(() {
                _showAttachmentOptions = false;
              });
              await option.onSelected!.call();
            },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.inputBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                option.icon,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle!,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionSection(
    AppColorScheme colorScheme,
    List<_ComposerQuickAction> quickActions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What can I help with?',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: quickActions
              .map((action) => _buildQuickAction(colorScheme, action))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    AppColorScheme colorScheme,
    _ComposerQuickAction action,
  ) {
    return InkWell(
      onTap: () async {
        await action.onSelected();
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              action.label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentToggle(AppColorScheme colorScheme) {
    return InkWell(
      onTap: () {
        setState(() {
          _showAttachmentOptions = !_showAttachmentOptions;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _showAttachmentOptions
              ? colorScheme.primary.withOpacity(0.12)
              : colorScheme.inputBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _showAttachmentOptions
                ? colorScheme.primary
                : colorScheme.cardBorder,
          ),
        ),
        child: Icon(
          _showAttachmentOptions ? Icons.close_rounded : Icons.add_rounded,
          color: _showAttachmentOptions
              ? colorScheme.primary
              : colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildComposerField(AppColorScheme colorScheme) {
    return Container(
      constraints: BoxConstraints(maxHeight: _maxInputHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.inputBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.cardBorder),
      ),
      child: TextField(
        controller: _messageController,
        focusNode: _composerFocusNode,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: colorScheme.inputText),
        decoration: InputDecoration(
          hintText: 'Message PocketLLM',
          hintStyle: TextStyle(color: colorScheme.hint),
          border: InputBorder.none,
          isCollapsed: true,
          suffixIcon: IconButton(
            icon: Icon(
              Icons.mic_none_rounded,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
            onPressed: () {
              _showCustomSnackBar(
                context: context,
                message: 'Voice input coming soon',
                icon: Icons.mic_none_rounded,
              );
            },
          ),
        ),
        onTap: () {
          if (_showAttachmentOptions) {
            setState(() {
              _showAttachmentOptions = false;
            });
          }
        },
        onSubmitted: (_) => _sendMessage(),
      ),
    );
  }

  Widget _buildSendButton(AppColorScheme colorScheme, bool disable) {
    final bool canSend = !disable;
    return GestureDetector(
      onTap: canSend ? _sendMessage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canSend ? colorScheme.primary : colorScheme.inputBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: canSend ? colorScheme.primary : colorScheme.cardBorder,
          ),
          boxShadow: [
            if (canSend)
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: _isLoading && !canSend
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                Icons.send_rounded,
                color: canSend
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withOpacity(0.4),
              ),
      ),
    );
  }

  Future<void> _prefillComposer(String suggestion) async {
    setState(() {
      _messageController.text = suggestion;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: suggestion.length),
      );
    });
    await Future.delayed(Duration.zero);
    if (mounted) {
      _composerFocusNode.requestFocus();
    }
  }

  List<_ComposerQuickAction> _quickActionItems() {
    return [
      _ComposerQuickAction(
        icon: Icons.image_outlined,
        label: 'Create image',
        onSelected: () => _prefillComposer('Create an image of '),
      ),
      _ComposerQuickAction(
        icon: Icons.image_search_rounded,
        label: 'Analyze images',
        onSelected: () async {
          await _pickImage();
        },
      ),
      _ComposerQuickAction(
        icon: Icons.summarize_outlined,
        label: 'Summarize text',
        onSelected: () => _prefillComposer('Summarize the following text: '),
      ),
      _ComposerQuickAction(
        icon: Icons.more_horiz_rounded,
        label: 'More',
        onSelected: () async {
          setState(() {
            _showAttachmentOptions = true;
          });
        },
      ),
    ];
  }

  List<_ComposerAttachmentShortcut> _attachmentShortcuts() {
    return [
      _ComposerAttachmentShortcut(
        icon: Icons.photo_camera_outlined,
        label: 'Camera',
        onTap: _takePhoto,
      ),
      _ComposerAttachmentShortcut(
        icon: Icons.photo_library_outlined,
        label: 'Photos',
        onTap: _pickImage,
      ),
      _ComposerAttachmentShortcut(
        icon: Icons.insert_drive_file_outlined,
        label: 'Files',
        onTap: _pickFile,
      ),
      _ComposerAttachmentShortcut(
        icon: Icons.travel_explore_outlined,
        label: 'Search',
        onTap: _toggleWebSearch,
      ),
    ];
  }

  List<_ComposerAttachmentOption> _attachmentOptions() {
    return [
      _ComposerAttachmentOption(
        icon: Icons.auto_awesome,
        label: 'Model',
        subtitle: 'Switch between your configured models',
        onSelected: () async {
          await _showModelSelectionSheet();
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.brush_outlined,
        label: 'Create image',
        subtitle: 'Visualise anything with your configured image tools',
        onSelected: () async {
          await _prefillComposer('Create an image of ');
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.travel_explore,
        label: 'Deep research',
        subtitle: 'Launch multi-step research with tools and memory',
        onSelected: () async {
          _showCustomSnackBar(
            context: context,
            message: 'Deep research automations are coming soon.',
            icon: Icons.travel_explore,
          );
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.manage_search_rounded,
        label: 'Web search',
        subtitle: 'Search the web for current context',
        onSelected: _toggleWebSearch,
      ),
      _ComposerAttachmentOption(
        icon: Icons.school_outlined,
        label: 'Study and learn',
        subtitle: 'Generate lessons, flashcards, and study aids',
        onSelected: () async {
          await _prefillComposer('Help me study: ');
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.workspaces_outline,
        label: 'Agent mode',
        subtitle: 'Delegate a task to automations and workflows',
        onSelected: () async {
          _showCustomSnackBar(
            context: context,
            message: 'Agent mode is not yet available.',
            icon: Icons.workspaces_outline,
          );
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.palette_outlined,
        label: 'Canva',
        subtitle: 'Open Canva to design stunning visuals',
        onSelected: () async {
          _showCustomSnackBar(
            context: context,
            message: 'Connect Canva in Settings to get started.',
            icon: Icons.palette_outlined,
          );
        },
      ),
      _ComposerAttachmentOption(
        icon: Icons.music_note_outlined,
        label: 'Spotify',
        subtitle: 'Search for music and podcasts',
        onSelected: () async {
          _showCustomSnackBar(
            context: context,
            message: 'Link Spotify in Settings to enable playback.',
            icon: Icons.music_note_outlined,
          );
        },
      ),
    ];
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        File(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        File(photo.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }
}

class _ComposerQuickAction {
  const _ComposerQuickAction({
    required this.icon,
    required this.label,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onSelected;
}

class _ComposerAttachmentOption {
  const _ComposerAttachmentOption({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onSelected,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Future<void> Function()? onSelected;
}

class _ComposerAttachmentShortcut {
  const _ComposerAttachmentShortcut({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function()? onTap;
}
