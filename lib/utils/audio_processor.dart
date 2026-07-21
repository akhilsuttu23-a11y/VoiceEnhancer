class AudioProcessor {
  // 1. High-Pass Filter: Clears out low-frequency rumble, hums, and pops
  static List<double> applyHighPassFilter(List<double> audioData, double cutoff) {
    if (audioData.isEmpty) return audioData;
    
    List<double> processed = List.from(audioData);
    double alpha = cutoff / (cutoff + 2 * 3.14159);
    
    double previousOutput = 0;
    double previousInput = 0;
    
    for (int i = 0; i < processed.length; i++) {
      double input = processed[i];
      double output = alpha * (previousOutput + input - previousInput);
      processed[i] = output;
      previousInput = input;
      previousOutput = output;
    }
    
    return processed;
  }

  // 2. Noise Gate: Mutes silent background noise when not singing/talking
  static List<double> applyNoiseGate(List<double> audioData, double threshold) {
    List<double> processed = List.from(audioData);
    
    for (int i = 0; i < processed.length; i++) {
      if (processed[i].abs() < threshold) {
        processed[i] = 0;
      }
    }
    
    return processed;
  }

  // 3. Compression: Smooths out volume dynamics and spikes
  static List<double> applyCompression(List<double> audioData, double ratio, double threshold) {
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

  // 4. Moving Average Smoothing
  static List<double> applySmoothing(List<double> audioData, int windowSize) {
    if (audioData.length < windowSize || windowSize < 2) return audioData;
    
    List<double> smoothed = List.from(audioData);
    int halfWindow = windowSize ~/ 2;
    
    for (int i = 0; i < audioData.length; i++) {
      double sum = 0;
      int count = 0;
      
      for (int j = -halfWindow; j <= halfWindow; j++) {
        int index = i + j;
        if (index >= 0 && index < audioData.length) {
          sum += audioData[index];
          count++;
        }
      }
      
      if (count > 0) {
        smoothed[i] = sum / count;
      }
    }
    
    return smoothed;
  }

  // Pure Voice Enhancement Pipeline
  static List<double> enhanceAudio(
    List<double> audioData, {
    double noiseThreshold = 0.02,
    int smoothFactor = 2,
    bool enableSmoothing = true,
    bool enableCompression = true,
    bool enableHighPass = true,
  }) {
    if (audioData.isEmpty) return audioData;
    
    List<double> processed = List.from(audioData);
    
    if (enableHighPass) {
      processed = applyHighPassFilter(processed, 0.01);
    }

    processed = applyNoiseGate(processed, noiseThreshold);

    if (enableSmoothing && smoothFactor > 1) {
      processed = applySmoothing(processed, smoothFactor);
    }
    
    if (enableCompression) {
      processed = applyCompression(processed, 2.5, 0.25);
    }
    
    return processed;
  }
}