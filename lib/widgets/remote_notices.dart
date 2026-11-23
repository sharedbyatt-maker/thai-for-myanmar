import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/remote_controls.dart';

class RemoteNotices extends StatelessWidget {
  const RemoteNotices({super.key});

  @override
  Widget build(BuildContext context) {
    final controls = RemoteControls.instance;
    final buildNumber = controls.buildNumber;
    final announcement = controls.announcement;
    final expiry = DateTime.tryParse(
      controlText(announcement['expiresAt']) ?? '',
    );
    final title = controlText(announcement['title']);
    final body = controlText(announcement['body']);
    final showAnnouncement =
        announcement['enabled'] == true &&
        expiry != null &&
        expiry.isAfter(DateTime.now()) &&
        title != null &&
        body != null;
    final update = controls.update;
    final latest = update['latestCode'];
    final minimum = update['minimumCode'];
    final showUpdate =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        buildNumber > 0 &&
        latest is int &&
        latest > buildNumber;
    if (!showAnnouncement && !showUpdate) return const SizedBox.shrink();
    return Column(
      children: [
        if (showAnnouncement)
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: Text(title),
            subtitle: Text(body),
          ),
        if (showUpdate)
          ListTile(
            leading: const Icon(Icons.system_update_rounded),
            title: Text(
              minimum is int && minimum > buildNumber
                  ? 'App ကို Update လုပ်ပါ'
                  : 'App version အသစ် ရပါပြီ',
            ),
            subtitle: Text(
              controlText(update['message']) ??
                  'Google Play မှာ ကြည့်နိုင်ပါတယ်။',
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.https('play.google.com', '/store/apps/details', {
                'id': 'com.sharedbyatt.thaiformyanmar',
              }),
              mode: LaunchMode.externalApplication,
            ),
          ),
      ],
    );
  }
}
