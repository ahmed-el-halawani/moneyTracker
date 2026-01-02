import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});

class AudioRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording(String filePath) async {
    if (await hasPermission()) {
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), 
        path: filePath
      );
    }
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }
  
  Future<String> getTemporaryFilePath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/voice_command_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }
  
  Future<void> dispose() async {
    _audioRecorder.dispose();
  }
}
