// Path: lib/features/logo/logo_screen.dart
// Description: Simple UI to pick a logo from gallery and save locally.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import 'logo_storage_service.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  String? _logoPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _logoPath = await LogoStorageService.getLogoPath();
    setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;

    final saved = await LogoStorageService.saveLogoFromTempPath(file.path);
    setState(() => _logoPath = saved);
  }

  Future<void> _removeLogo() async {
    await LogoStorageService.removeLogo();
    setState(() => _logoPath = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.logo)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_logoPath != null && File(_logoPath!).existsSync())
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Image.file(File(_logoPath!), height: 140),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(child: Icon(Icons.image, size: 40)),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_logoPath == null ? t.addLogo : t.changeLogo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logoPath == null ? null : _removeLogo,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(t.removeLogo),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
