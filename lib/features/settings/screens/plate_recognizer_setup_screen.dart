import 'package:flutter/material.dart';

import '../../../core/services/plate_recognizer_service.dart';
import '../../../core/theme/app_theme.dart';

class PlateRecognizerSetupScreen extends StatefulWidget {
  const PlateRecognizerSetupScreen({super.key});

  @override
  State<PlateRecognizerSetupScreen> createState() =>
      _PlateRecognizerSetupScreenState();
}

class _PlateRecognizerSetupScreenState
    extends State<PlateRecognizerSetupScreen> {
  final _tokenController = TextEditingController();
  final _regionController = TextEditingController(
    text: PlateRecognizerConfig.defaultRegion,
  );
  bool _loading = true;
  bool _saving = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await PlateRecognizerConfig.loadToken();
    final region = await PlateRecognizerConfig.loadRegion();
    if (!mounted) return;
    setState(() {
      _tokenController.text = token ?? '';
      _regionController.text = region;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final token = _tokenController.text.trim();
    final region = _regionController.text.trim().toLowerCase();
    try {
      if (token.isEmpty) {
        await PlateRecognizerConfig.clearToken();
      } else {
        await PlateRecognizerConfig.saveToken(token);
      }
      await PlateRecognizerConfig.saveRegion(
        region.isEmpty
            ? PlateRecognizerConfig.defaultRegion
            : region,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            token.isEmpty
                ? 'Clé PlateRecognizer supprimée.'
                : 'Configuration PlateRecognizer enregistrée.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Configuration PlateRecognizer'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                      Icons.camera_alt_outlined,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Configuration PlateRecognizer',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configurez votre clé API pour activer la reconnaissance '
                  'de plaques d\'immatriculation via le cloud.',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Fonctionnement',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'L\'application utilise d\'abord la détection locale '
                        '(TFLite + ML Kit). Si une clé PlateRecognizer est '
                        'configurée, les images sont aussi envoyées à l\'API '
                        'cloud pour améliorer la lecture des plaques.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'L\'envoi d\'images à un service externe peut '
                                'engendrer des coûts et transmettre des données '
                                'hors de l\'appareil.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                  child: Column(
                    children: [
                      TextField(
                        controller: _tokenController,
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Clé API',
                          hintText: 'Token PlateRecognizer',
                          prefixIcon: const Icon(Icons.key_outlined),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Afficher' : 'Masquer',
                            icon: Icon(
                              _obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _regionController,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Région',
                          hintText: 'ci',
                          helperText:
                              'Code de région PlateRecognizer (ci par défaut).',
                          prefixIcon: Icon(Icons.public),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}
