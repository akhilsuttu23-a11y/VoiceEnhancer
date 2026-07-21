import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/control_button.dart';
import '../widgets/status_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().initAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const _Header(),
                const SizedBox(height: 20),
                const StatusDisplay(),
                const SizedBox(height: 30),
                const _ControlSection(),
                const SizedBox(height: 20),
                const Expanded(
                  child: SingleChildScrollView(
                    child: _SettingsSection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.mic_rounded,
          size: 60,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        const Text(
          'Voice Enhancer Pro',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Real-time Audio Processing',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _ControlSection extends StatelessWidget {
  const _ControlSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ControlButton(
              icon: provider.isRecording ? Icons.stop : Icons.play_arrow,
              label: provider.isRecording ? 'Stop' : 'Start',
              onPressed: provider.isRecording 
                  ? provider.stopEnhancement 
                  : provider.startEnhancement,
              isActive: provider.isRecording,
              color: provider.isRecording ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 20),
            ControlButton(
              icon: provider.isPlaying ? Icons.volume_up : Icons.volume_off,
              label: provider.isPlaying ? 'Mute' : 'Monitor',
              onPressed: provider.togglePlayback,
              isActive: provider.isPlaying,
              color: provider.isPlaying ? Colors.orange : Colors.grey,
            ),
          ],
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSlider(
                icon: Icons.noise_control_off,
                label: 'Noise Gate',
                value: provider.noiseThreshold,
                min: 0.001,
                max: 0.1,
                onChanged: provider.updateNoiseThreshold,
                displayValue: provider.noiseThreshold.toStringAsFixed(3),
              ),
              const SizedBox(height: 15),
              _buildSlider(
                icon: Icons.slow_motion_video,
                label: 'Smoothing',
                value: provider.smoothFactor.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => provider.updateSmoothFactor(value.toInt()),
                displayValue: provider.smoothFactor.toString(),
              ),
              const SizedBox(height: 15),
              _buildToggle(
                icon: Icons.filter_alt,
                label: 'High-Pass Filter',
                value: provider.enableHighPass,
                onChanged: provider.toggleHighPass,
              ),
              _buildToggle(
                icon: Icons.compress,
                label: 'Compression',
                value: provider.enableCompression,
                onChanged: provider.toggleCompression,
              ),
              _buildToggle(
                icon: Icons.slow_motion_video,
                label: 'Enable Smoothing',
                value: provider.enableSmoothing,
                onChanged: provider.toggleSmoothing,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String displayValue,
    int? divisions,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Container(
          width: 35,
          alignment: Alignment.center,
          child: Text(
            displayValue,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}