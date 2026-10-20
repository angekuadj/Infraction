import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/plate/cote_ivoire_plate.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

/// Saisie de la plaque d'immatriculation (obligatoire pour les usagers).
class PlaqueSaisieScreen extends StatefulWidget {
  const PlaqueSaisieScreen({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<PlaqueSaisieScreen> createState() => _PlaqueSaisieScreenState();
}

class _PlaqueSaisieScreenState extends State<PlaqueSaisieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plaqueCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _plaqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final plaque = CoteIvoirePlate.normalize(_plaqueCtrl.text);
    final ok = await auth.submitPlaque(plaque);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onSaved?.call();
      context.go(AppRoutes.client);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur lors de l\'enregistrement'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Saisir votre plaque'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Container
                  Container(
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
                      Icons.directions_car,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Enregistrez votre plaque',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Consultez les infractions liées à votre véhicule',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Plate Input Card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                        TextFormField(
                          controller: _plaqueCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'Numéro d\'immatriculation',
                            hintText: 'Ex : AB1234',
                            prefixIcon: const Icon(
                              Icons.confirmation_number_outlined,
                            ),
                          ),
                          validator: (v) => CoteIvoirePlate.validate(v ?? ''),
                          onChanged: (v) {
                            final formatted = CoteIvoirePlate.format(v);
                            if (formatted != v) {
                              _plaqueCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Format ivoirien : 2-3 lettres + 3-4 chiffres',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enregistrer et continuer',
                            style: TextStyle(fontSize: 16),
                          ),
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
