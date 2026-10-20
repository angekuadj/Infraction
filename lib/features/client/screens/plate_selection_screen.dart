import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/plate/cote_ivoire_plate.dart';
import '../../../core/providers/recap_pending_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class PlateSelectionScreen extends StatefulWidget {
  const PlateSelectionScreen({super.key});

  @override
  State<PlateSelectionScreen> createState() => _PlateSelectionScreenState();
}

class _PlateSelectionScreenState extends State<PlateSelectionScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final recap = context.read<RecapPendingProvider>();
    _ctrl.text = recap.detectedPlate ?? '';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validateAndContinue() {
    final recap = context.read<RecapPendingProvider>();
    final detected = recap.detectedPlate;

    // Si l'IA a détecté une plaque, on la valide
    if (detected != null && detected.isNotEmpty) {
      final error = CoteIvoirePlate.validate(detected);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.error),
        );
        return;
      }
      context.read<RecapPendingProvider>().updatePlate(detected);
    } else {
      // Si l'IA n'a pas détecté, on soumet sans plaque
      context.read<RecapPendingProvider>().updatePlate('');
    }
    context.go(AppRoutes.infractionRecap);
  }

  @override
  Widget build(BuildContext context) {
    final recap = context.watch<RecapPendingProvider>();
    final detected = recap.detectedPlate;
    final hasDetection = detected != null && detected.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sélection de la plaque'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: hasDetection
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.success, Color(0xFF1B5E20)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.warning, Color(0xFFE65100)],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (hasDetection ? AppTheme.success : AppTheme.warning)
                        .withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                hasDetection ? Icons.verified : Icons.search_off,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            hasDetection
                ? 'Plaque détectée automatiquement'
                : 'Aucune plaque détectée',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasDetection
                ? 'L\'IA a reconnu la plaque avec succès'
                : 'L\'IA n\'a pas pu détecter la plaque',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Detection Card
          if (hasDetection)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppTheme.success,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        detected,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      recap.score == null
                          ? 'Détectée automatiquement'
                          : 'Confiance : ${(recap.score! * 100).toStringAsFixed(1)} %',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le champ est grisé car l\'IA n\'a pas détecté de plaque',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vous pouvez continuer sans plaque',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Plate Input Field
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
                const Text(
                  'Plaque d\'immatriculation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: hasDetection ? AppTheme.textPrimary : Colors.grey,
                  ),
                  decoration: InputDecoration(
                    hintText: hasDetection ? detected : 'Non détectée',
                    hintStyle: TextStyle(
                      color: hasDetection
                          ? AppTheme.textSecondary
                          : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: hasDetection
                        ? AppTheme.success.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                  ),
                  // Champ en lecture seule si l'IA a détecté
                  readOnly: hasDetection,
                  // Champ grisé (disabled) si l'IA n'a pas détecté
                  enabled: hasDetection,
                  onChanged: hasDetection
                      ? null
                      : (v) {
                          final formatted = CoteIvoirePlate.format(v);
                          if (formatted != v) {
                            _ctrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Continue Button
          ElevatedButton(
            onPressed: _validateAndContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: hasDetection ? AppTheme.primary : AppTheme.warning,
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
