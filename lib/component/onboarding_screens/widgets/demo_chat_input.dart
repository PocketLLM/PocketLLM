import 'package:flutter/material.dart';

class DemoChatInput extends StatelessWidget {
  const DemoChatInput({
    required this.controller,
    required this.onSuggestionSelected,
    this.onSend,
    Key? key,
  }) : super(key: key);

  final TextEditingController controller;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const suggestions = [
      'Summarize the last article I read',
      'Draft a friendly status update',
      'Explain transformers like I am five',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Try saying hello... ',
            suffixIcon: IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: 'Send demo message',
            ),
          ),
          minLines: 1,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Need inspiration?',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: suggestions
              .map(
                (suggestion) => ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestionSelected(suggestion),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
