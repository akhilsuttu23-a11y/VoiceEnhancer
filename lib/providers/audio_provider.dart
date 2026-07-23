import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/audio_processor.dart';

class AudioProvider extends ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isProcessing = false;
  String _statusMessage = 'Initializing...';
  
  // Audio processing parameters
  double _noiseThreshold = 0.01;
  int _smoothFactor = 1;
  bool _enableSmoothing = false;
  bool _enableCompression = true;
  bool _enableHighPass = true;
  
  // Audio processing
  Timer? _processingTimer;
  String? _tempFilePath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  double get noiseThreshold => _noiseThreshold;
  int get smoothFactor => _smoothFactor;
  bool get enableSmoothing => _enableSmoothing;
  bool get enableCompression => _enableCompression;
  bool get enableHighPass => _enableHighPass;

  AudioProvider();

  Future<void> initAudio() async {
    if (kIsWeb) {
      _updateStatus('Web platform not supported for low-level audio streaming');
      return;
    }

    try {
      await _requestPermissions();
      
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.media,
        ),
      ));
      
      await _recorder.openRecorder();
      await _player.openPlayer();
      
      final tempDir = await getTemporaryDirectory();
      _tempFilePath = '${tempDir.path}/temp_audio.pcm';
      
      _updateStatus('Ready to enhance voice');
    } catch (e) {
      _updateStatus('Error: $e');
      debugPrint('Init error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    await [
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  void updateNoiseThreshold(double value) {
    _noiseThreshold = value;
    notifyListeners();
  }

  void updateSmoothFactor(int value) {
    _smoothFactor = value;
    notifyListeners();
  }

  void toggleSmoothing(bool value) {
    _enableSmoothing = value;
    notifyListeners();
  }

  void toggleCompression(bool value) {
    _enableCompression = value;
    notifyListeners();
  }

  void toggleHighPass(bool value) {
    _enableHighPass = value;
    notifyListeners();
  }

  Future<void> startEnhancement() async {
    if (_isRecording || kIsWeb) return;

    try {
      _updateStatus('Starting voice enhancement...');
      _isRecording = true;
      _isProcessing = true;
      notifyListeners();

      await _recorder.startRecorder(
        toFile: _tempFilePath,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100, // Updated to 44.1kHz for crystal clear sound
      );

      _processingTimer = Timer.periodic(
        const Duration(milliseconds: 100),
        (timer) async {
          if (_isRecording && _tempFilePath != null) {
            await _processRecordedAudio();
          }
        },
      );

      _updateStatus('🎤 Voice enhancement active');
    } catch (e) {
      _updateStatus('Error starting: $e');
      _isRecording = false;
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _processRecordedAudio() async {
    if (kIsWeb) return;
    try {
      final file = File(_tempFilePath!);
      if (!await file.exists()) return;
      
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      
      List<double> floatData = _bytesToFloat(bytes);
      if (floatData.isEmpty) return;
      
      List<double> processed = AudioProcessor.enhanceAudio(
        floatData,
        noiseThreshold: _noiseThreshold,
        smoothFactor: _smoothFactor,
        enableSmoothing: _enableSmoothing,
        enableCompression: _enableCompression,
        enableHighPass: _enableHighPass,
        sampleRate: 44100.0,
      );
      
      if (_isPlaying && processed.isNotEmpty) {
        Uint8List processedBytes = _floatToBytes(processed);
        await _player.feedFromStream(processedBytes);
      }
    } catch (e) {
      debugPrint('Processing error: $e');
    }
  }

  Future<void> stopEnhancement() async {
    if (!_isRecording || kIsWeb) return;

    try {
      _updateStatus('Stopping...');
      
      _isRecording = false;
      _isProcessing = false;
      _isPlaying = false;
      
      _processingTimer?.cancel();
      _processingTimer = null;
      
      await _recorder.stopRecorder();
      
      if (_tempFilePath != null) {
        final file = File(_tempFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _updateStatus('Stopped');
      notifyListeners();
    } catch (e) {
      _updateStatus('Error stopping: $e');
    }
  }

  void togglePlayback() {
    _isPlaying = !_isPlaying;
    _updateStatus(_isPlaying ? '🔊 Monitoring on' : '🎤 Enhancement active');
    notifyListeners();
  }

  List<double> _bytesToFloat(Uint8List bytes) {
    List<double> floats = [];
    for (int i = 0; i < bytes.length; i += 2) {
      if (i + 1 < bytes.length) {
        int sample = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
        double floatSample = sample / 32768.0;
        floats.add(floatSample);
      }
    }
    return floats;
  }

  Uint8List _floatToBytes(List<double> floats) {
    Uint8List bytes = Uint8List(floats.length * 2);
    for (int i = 0; i < floats.length; i++) {
      int sample = (floats[i] * 32768).toInt();
      sample = sample.clamp(-32768, 32767);
      bytes[i * 2] = sample & 0xFF;
      bytes[i * 2 + 1] = (sample >> 8) & 0xFF;
    }
    return bytes;
  }

  void _updateStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _processingTimer?.cancel();
    if (!kIsWeb) {
      _recorder.closeRecorder();
      _player.closePlayer();
    }
    super.dispose();
  }
}