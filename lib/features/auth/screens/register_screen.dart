import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_roles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _cniCtrl = TextEditingController();
  final _plaqueCtrl = TextEditingController();
  AppRole _role = AppRole.client;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  File? _cniPhoto;
  String? _cniPhotoName;

  bool get _isProprietaire => _role == AppRole.usager;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _cniCtrl.dispose();
    _plaqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCniPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    final path = file?.path;
    if (file == null || path == null) return;
    setState(() {
      _cniPhoto = File(path);
      _cniPhotoName = file.name;
      _cniCtrl.clear();
    });
  }

  void _clearCniPhoto() {
    setState(() {
      _cniPhoto = null;
      _cniPhotoName = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cni = _cniCtrl.text.trim();
    if (!_isProprietaire && cni.isEmpty && _cniPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro ou photo de CNI obligatoire'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _isProprietaire ? _emailCtrl.text.trim() : null,
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role.apiValue,
      cni: cni.isEmpty ? null : cni,
      plaque: _isProprietaire ? _plaqueCtrl.text.trim() : null,
      cniPhotoPath: _cniPhoto?.path,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.go(AppRoutes.client);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Selection Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
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
                        'Vous êtes ?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Usager : téléphone et CNI\nPropriétaire : plaque d\'immatriculation obligatoire',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<AppRole>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: AppTheme.background,
                          selectedBackgroundColor: AppTheme.primary,
                          selectedForegroundColor: Colors.white,
                        ),
                        segments: [
                          ButtonSegment(
                            value: AppRole.client,
                            label: const Text('Usager'),
                            icon: const Icon(Icons.person),
                          ),
                          ButtonSegment(
                            value: AppRole.usager,
                            label: const Text('Propriétaire'),
                            icon: const Icon(Icons.directions_car),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) =>
                            setState(() => _role = s.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Entrez votre nom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prenomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    hintText: 'Entrez votre prénom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Prénom requis'
                      : null,
                ),
                if (_isProprietaire) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'exemple@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: 01 02 03 04 05',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
                ),
                if (_isProprietaire) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _plaqueCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Numéro d\'immatriculation',
                      hintText: 'Ex: AB123CD',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) {
                        return 'Plaque trop courte';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),

                // CNI Section
                const Text(
                  'Carte d\'identité',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cniCtrl,
                  enabled: _cniPhoto == null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isProprietaire
                        ? 'Numéro de CNI (facultatif)'
                        : 'Numéro de CNI',
                    hintText: 'Ex: 1234567890123',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: _cniPhoto == null
                        ? IconButton(
                            icon: const Icon(Icons.photo_camera_outlined),
                            tooltip: 'Photo de la CNI',
                            onPressed: _pickCniPhoto,
                          )
                        : IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: AppTheme.success),
                            tooltip: _cniPhotoName ?? 'Photo sélectionnée',
                            onPressed: _clearCniPhoto,
                          ),
                  ),
                  validator: (v) {
                    if (!_isProprietaire &&
                        (v == null || v.trim().isEmpty) &&
                        _cniPhoto == null) {
                      return 'CNI requise (numéro ou photo)';
                    }
                    return null;
                  },
                ),
                if (_cniPhoto != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Photo de CNI sélectionnée',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.success,
                                ),
                              ),
                              Text(
                                _cniPhotoName ?? 'Photo',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _clearCniPhoto,
                          child: const Text('Retirer'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Password Section
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Min 6 caractères',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mot de passe trop court (min 6)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Répétez le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Confirmation requise';
                    }
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
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
                          'S\'inscrire',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour à la connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
