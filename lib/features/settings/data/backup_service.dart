import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/tracker/data/tracker_repository.dart';

/// Export / import of the JSON backup (compatible with the HTML prototype).
class BackupService {
  BackupService(this._repository);
  final TrackerRepository _repository;

  Future<void> exportAndShare(TrackerData data) async {
    final dir = await getTemporaryDirectory();
    final name = 'Ihsan_backup_${toDateKey(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(_repository.encode(data, pretty: true));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: name)],
        subject: 'Ihsan backup',
      ),
    );
  }

  /// Lets the user pick a backup. Returns `null` when cancelled and throws
  /// [FormatException] when the file isn't a valid backup.
  Future<TrackerData?> pickBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) return null;
    return _repository.parseBackup(utf8.decode(await file.readAsBytes()));
  }
}
