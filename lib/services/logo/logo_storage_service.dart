// Path: lib/features/logo/logo_storage_service.dart
// Description: Stores logo file locally and keeps path in SharedPreferences.
// Includes BOTH methods:
// - saveLogoFromTempPath (old name for compatibility)
// - saveLogoFromPickedPath (recommended robust method)

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogoStorageService {
  static const _kLogoPath = 'logo_path';
  static const _kLogoPaths = 'logo_paths_v1';

  static Future<String?> getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLogoPath);
  }

  static Future<List<String>> getLogoPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final paths = prefs.getStringList(_kLogoPaths) ?? const <String>[];
    if (paths.isNotEmpty) return paths;

    final single = prefs.getString(_kLogoPath);
    if (single == null || single.isEmpty) return const <String>[];
    return [single];
  }

  static Future<void> removeLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getString(_kLogoPath);
    final allPaths = prefs.getStringList(_kLogoPaths) ?? const <String>[];

    for (final path in <String>{if (current != null) current, ...allPaths}) {
      if (path.isEmpty) continue;
      final file = File(path);
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // ignore
      }
    }

    await prefs.remove(_kLogoPath);
    await prefs.remove(_kLogoPaths);
  }

  /// ✅ NEW: Robust save from a picked (often temp) path.
  /// Reads bytes and writes into Documents to avoid iOS temp path issues.
  static Future<String> saveLogoFromPickedPath(String pickedPath) async {
    final source = File(pickedPath);
    if (!await source.exists()) {
      throw Exception('Picked logo file does not exist: $pickedPath');
    }

    final Uint8List bytes = await source.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();

    final ext = p.extension(pickedPath);
    final safeExt = ext.isEmpty ? '.png' : ext;

    final destPath = p.join(dir.path, 'showmyname_logo$safeExt');
    final dest = File(destPath);

    // Overwrite previous safely
    try {
      if (await dest.exists()) await dest.delete();
    } catch (_) {}

    await dest.writeAsBytes(bytes, flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLogoPath, dest.path);
    await prefs.setStringList(_kLogoPaths, [dest.path]);

    return dest.path;
  }

  static Future<List<String>> saveLogosFromPickedPaths(
    List<String> pickedPaths,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final savedPaths = <String>[];

    for (var i = 0; i < pickedPaths.length; i++) {
      final pickedPath = pickedPaths[i];
      final source = File(pickedPath);
      if (!await source.exists()) continue;

      final bytes = await source.readAsBytes();
      final ext = p.extension(pickedPath);
      final safeExt = ext.isEmpty ? '.png' : ext;
      final destPath = p.join(
        dir.path,
        'showmyname_logo_${DateTime.now().millisecondsSinceEpoch}_$i$safeExt',
      );
      final dest = File(destPath);
      await dest.writeAsBytes(bytes, flush: true);
      savedPaths.add(dest.path);
    }

    if (savedPaths.isEmpty) {
      throw Exception('No logo files were saved.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLogoPath, savedPaths.first);
    await prefs.setStringList(_kLogoPaths, savedPaths);

    return savedPaths;
  }

  /// ✅ OLD (compat): Keep this so other screens compile.
  /// Internally calls saveLogoFromPickedPath.
  static Future<String> saveLogoFromTempPath(String tempPath) async {
    return saveLogoFromPickedPath(tempPath);
  }
}
