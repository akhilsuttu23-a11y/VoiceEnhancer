import 'dart:math' as math;

class AudioProcessor {
  /// Standard 1st-Order High-Pass Filter using sample rate
  static List<double> applyHighPassFilter(
    List<double> audioData, {
    double cutoffHz = 80.0,
    double sampleRate = 44100.0,
  }) {
    if (audioData.isEmpty) return audioData;

    List<double> processed = List.from(audioData);
    double dt = 1.0 / sampleRate;
    double rc = 1.0 / (2 * math.pi * cutoffHz);
    double alpha = rc / (rc + dt);

    double previousOutput = processed[0];
    double previousInput = processed[0];

    for (int i = 0; i < processed.length; i++) {
      double input = processed[i];
      double output = alpha * (previousOutput + input - previousInput);
      processed[i] = output;
      previousInput = input;
      previousOutput = output;
    }

    return processed;
  }

  /// Gentle Treble Boost (High Shelf Equalizer) to restore voice clarity
  static List<double> applyTrebleBoost(
    List<double> audioData, {
    double gainDb = 3.0,
  }) {
    if (audioData.isEmpty || gainDb <= 0) return audioData;

    double factor = math.pow(10, gainDb / 20) as double;
    List<double> processed = List.from(audioData);

    double prevIn = 0.0;
    double prevOut = 0.0;
    double alpha = 0.6; // High frequency emphasis threshold

    for (int i = 0; i < processed.length; i++) {
      double input = processed[i];
      double highFreq = alpha * (prevOut + input - prevIn);
      prevIn = input;
      prevOut = highFreq;

      processed[i] = input + (highFreq * (factor - 1.0));
    }

    return processed;
  }

  /// Noise Gate with Soft Knee to avoid audio stuttering
  static List<double> applyNoiseGate(List<double> audioData, double threshold) {
    List<double> processed = List.from(audioData);

    for (int i = 0; i < processed.length; i++) {
      double absVal = processed[i].abs();
      if (absVal < threshold) {
        processed[i] *= (absVal / threshold);
      }
    }

    return processed;
  }

  /// Compression with dynamic ceiling
  static List<double> applyCompression(
    List<double> audioData,
    double ratio,
    double threshold,
  ) {
    List<double> processed = List.from(audioData);

    for (int i = 0; i < processed.length; i++) {
      double sample = processed[i];
      double absSample = sample.abs();

      if (absSample > threshold) {
        double compressed = threshold + (absSample - threshold) / ratio;
        processed[i] = sample.sign * compressed;
      }
    }

    return processed;
  }

  /// Main Enhancement Pipeline
  static List<double> enhanceAudio(
    List<double> audioData, {
    double noiseThreshold = 0.01,
    int smoothFactor = 1,
    bool enableSmoothing = false,
    bool enableCompression = true,
    bool enableHighPass = true,
    double sampleRate = 44100.0,
  }) {
    if (audioData.isEmpty) return audioData;

    List<double> processed = List.from(audioData);

    // 1. High-Pass Filter (removes rumble below 80Hz)
    if (enableHighPass) {
      processed = applyHighPassFilter(
        processed,
        cutoffHz: 80.0,
        sampleRate: sampleRate,
      );
    }

    // 2. Soft Noise Gate
    if (noiseThreshold > 0.0) {
      processed = applyNoiseGate(processed, noiseThreshold);
    }

    // 3. Dynamic Compression
    if (enableCompression) {
      processed = applyCompression(processed, 2.0, 0.3);
    }

    // 4. Boost Treble for voice clarity
    processed = applyTrebleBoost(processed, gainDb: 3.0);

    return processed;
  }
}