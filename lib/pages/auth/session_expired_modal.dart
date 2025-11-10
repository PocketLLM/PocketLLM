import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';
import '../../widgets/auth/custom_button.dart';
import '../../widgets/auth/custom_snackbar.dart';

class SessionExpiredModal extends StatefulWidget {
  final VoidCallback onSessionRestored;
  final VoidCallback onSignOut;
  
  const SessionExpiredModal({
    super.key,
    required this.onSessionRestored,
    required this.onSignOut,
  });

  @override
  State<SessionExpiredModal> createState() => _SessionExpiredModalState();
}

class _SessionExpiredModalState extends State<SessionExpiredModal> {
  bool _isRefreshing = false;

  Future<void> _handleRefreshSession() async {
    setState(() => _isRefreshing = true);

    try {
      final authState = context.read<AuthState>();
      
      // Attempt to refresh the session
      // This will use the existing refresh token logic in auth_state.dart
      final hasValidSession = await authState.refreshSession();
      
      if (mounted) {
        setState(() => _isRefreshing = false);
        
        if (hasValidSession) {
          // Show success message
          CustomSnackbar.show(
            context,
            CustomSnackbar(
              message: 'Session restored successfully',
              type: SnackbarType.success,
            ),
          );
          
          // Notify that session has been restored
          widget.onSessionRestored();
        } else {
          // If refresh failed, show error and sign out
          CustomSnackbar.show(
            context,
            CustomSnackbar(
              message: 'Unable to restore session. Please sign in again.',
              type: SnackbarType.error,
            ),
          );
          
          // Sign out the user
          await authState.signOut();
          if (mounted) {
            widget.onSignOut();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        
        // Show error message
        CustomSnackbar.show(
          context,
          CustomSnackbar(
            message: 'Failed to restore session. Please sign in again.',
            type: SnackbarType.error,
          ),
        );
        
        // Sign out the user
        final authState = context.read<AuthState>();
        await authState.signOut();
        if (mounted) {
          widget.onSignOut();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Session Expired',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Your session has expired. Please refresh your session or sign in again.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onSignOut,
          child: Text(
            'Sign Out',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        CustomButton(
          text: _isRefreshing ? 'Refreshing...' : 'Refresh Session',
          onPressed: _isRefreshing ? () {} : _handleRefreshSession,
          variant: ButtonVariant.filled,
          size: ButtonSize.medium,
        ),
      ],
    );
  }
}