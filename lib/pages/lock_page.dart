import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class LockPage extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockPage({super.key, required this.onUnlock});
  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool isAuthenticating = false;
  String error = '';
  final TextEditingController pinController = TextEditingController();
  final String storedPin = '1234'; // TODO: Store securely

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() { isAuthenticating = true; error = ''; });
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock Spendwise',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (didAuthenticate) {
        widget.onUnlock();
      }
    } on PlatformException catch (e) {
      setState(() { error = e.message ?? 'Error'; });
    }
    setState(() { isAuthenticating = false; });
  }

  void _checkPin() {
    if (pinController.text == storedPin) {
      widget.onUnlock();
    } else {
      setState(() { error = 'Incorrect PIN'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Lock', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text('Unlock Spendwise', style: Theme.of(context).textTheme.headlineMedium),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(error, style: TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.fingerprint),
                    label: Text('Use Biometrics'),
                    onPressed: isAuthenticating ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Or enter PIN', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        labelText: 'PIN',
                      ),
                      onSubmitted: (_) => _checkPin(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _checkPin,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: Text('Unlock'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
