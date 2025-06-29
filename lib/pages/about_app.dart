import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutAppPage extends StatelessWidget {
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrlString(emailLaunchUri.toString())) {
      await launchUrlString(emailLaunchUri.toString());
    }
  }
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About App', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.apps, size: 36, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Spendwise', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('v1.0.0', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('A modern expense and SMS analysis app for Android.', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Developer Info', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person)),
                    title: Text('Sagar Mallick'),
                    subtitle: Text('Lead Developer'),
                  ),
                  ListTile(
                    leading: CircleAvatar(child: Icon(Icons.email)),
                    title: Text('sam23k23@gmail.com'),
                    subtitle: Text('Contact Email'),
                    onTap: () => _launchEmail('mailto:sam23k23@gmail.com'),
                  ),
                  ListTile(
                    leading: CircleAvatar(child: Icon(Icons.code)),
                    title: Text('GitHub'),
                    subtitle: Text('github.com/samii83'),
                    onTap: () => _launchURL('https://github.com/samii83'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Info', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.verified, color: Theme.of(context).colorScheme.primary),
                    title: Text('Open Source'),
                    subtitle: Text('This app is open source and free to use.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
                    title: Text('Privacy Friendly'),
                    subtitle: Text('All data stays on your device.'),
                  ),
                  ListTile(
                    leading: Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
                    title: Text('Last Updated'),
                    subtitle: Text('June 2025'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
