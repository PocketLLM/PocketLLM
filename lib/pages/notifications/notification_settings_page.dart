import 'package:flutter/material.dart';
import 'package:pocketllm/models/notification_preferences_model.dart';
import 'package:pocketllm/services/notification_preferences_service.dart';
import 'package:pocketllm/theme/theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationPreferencesService _notificationPreferencesService =
      NotificationPreferencesService();
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final preferences =
          await _notificationPreferencesService.getNotificationPreferences();
      setState(() {
        _preferences = preferences;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePreference(
      {bool? notifyJobStatus,
      bool? notifyAccountAlerts,
      bool? notifyReferralRewards,
      bool? notifyProductUpdates}) async {
    try {
      final updatedPreferences = await _notificationPreferencesService
          .updateNotificationPreferences(NotificationPreferencesUpdate(
        notifyJobStatus: notifyJobStatus,
        notifyAccountAlerts: notifyAccountAlerts,
        notifyReferralRewards: notifyReferralRewards,
        notifyProductUpdates: notifyProductUpdates,
      ));
      setState(() {
        _preferences = updatedPreferences;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_preferences == null) {
      return const Center(child: Text('No preferences available.'));
    }

    return ListView(
      children: [
        _buildSectionTitle('App Notifications'),
        _buildSwitchTile(
          'Background Job Status',
          'Updates on model processing or background tasks.',
          _preferences!.notifyJobStatus,
          (value) => _updatePreference(notifyJobStatus: value),
        ),
        _buildSwitchTile(
          'Critical Account Warnings',
          'Important security alerts and account notices.',
          _preferences!.notifyAccountAlerts,
          (value) => _updatePreference(notifyAccountAlerts: value),
        ),
        _buildSwitchTile(
          'Referral Rewards & Invites',
          'Notifications about referral program updates and rewards.',
          _preferences!.notifyReferralRewards,
          (value) => _updatePreference(notifyReferralRewards: value),
        ),
        _buildSwitchTile(
          'New Model & Feature...',
          'Announcements for new app features and LLM updates.',
          _preferences!.notifyProductUpdates,
          (value) => _updatePreference(notifyProductUpdates: value),
        ),
        const Divider(),
        _buildSectionTitle('System Permissions'),
        ListTile(
          title: const Text('System Notification Permissions'),
          subtitle: const Text('Enabled'),
          trailing: ElevatedButton(
            onPressed: () {},
            child: const Text('Open System Notification Settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: HiVpnColors.primary,
    );
  }
}
