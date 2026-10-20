import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/api_config_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class EndpointSetupScreen extends StatefulWidget {
  const EndpointSetupScreen({super.key});

  @override
  State<EndpointSetupScreen> createState() => _EndpointSetupScreenState();
}

class _EndpointSetupScreenState extends State<EndpointSetupScreen> {
  final _ctrl = TextEditingController();
  bool _discovering = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _ctrl.text = context.read<ApiConfigProvider>().baseUrl ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _discover() async {
    setState(() {
      _discovering = true;
      _message = null;
    });
    final found = await context.read<ApiConfigProvider>().discover();
    if (!mounted) return;
    setState(() {
      _discovering = false;
      _message = found != null
          ? 'Endpoint détecté automatiquement : $found'
          : 'Aucun serveur détecté sur le réseau (port 8080)';
      if (found != null) _ctrl.text = found;
    });
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) {
      setState(() => _message = 'Veuillez saisir une URL.');
      return;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      setState(() => _message = 'URL invalide. Ex : http://192.168.1.10:8080');
      return;
    }
    await context.read<ApiConfigProvider>().setBaseUrl(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endpoint enregistré.'),
        backgroundColor: AppTheme.success,
      ),
    );
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configuration serveur'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dns_outlined,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Adresse du serveur Circulation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saisissez l\'URL de l\'API (ex : http://192.168.1.10:8080) '
            'ou lancez la détection automatique.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _ctrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'URL de l\'API',
                hintText: 'http://192.168.1.10:8080',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _discovering ? null : _discover,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _discovering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(
              _discovering ? 'Recherche en cours…' : 'Détecter automatiquement',
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _message!.contains('détecté')
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
