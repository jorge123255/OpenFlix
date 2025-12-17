/// Utility functions to format MPV player statistics for display

/// Formats bitrate in human-readable format (Kbps/Mbps)
String formatBitrate(int? bitrate) {
  if (bitrate == null || bitrate == 0) return 'N/A';

  if (bitrate >= 1000000) {
    return '${(bitrate / 1000000).toStringAsFixed(2)} Mbps';
  } else if (bitrate >= 1000) {
    return '${(bitrate / 1000).toStringAsFixed(0)} Kbps';
  } else {
    return '$bitrate bps';
  }
}

/// Formats resolution string (e.g., "1920x1080")
String formatResolution(int? width, int? height) {
  if (width == null || height == null) return 'N/A';
  return '${width}x$height';
}

/// Formats codec name for display (removes unnecessary details)
String formatCodec(String? codec) {
  if (codec == null || codec.isEmpty) return 'N/A';

  // Simplify common codec names
  final lowerCodec = codec.toLowerCase();
  if (lowerCodec.contains('h264') || lowerCodec.contains('avc')) {
    return 'H.264/AVC';
  } else if (lowerCodec.contains('h265') || lowerCodec.contains('hevc')) {
    return 'H.265/HEVC';
  } else if (lowerCodec.contains('vp9')) {
    return 'VP9';
  } else if (lowerCodec.contains('vp8')) {
    return 'VP8';
  } else if (lowerCodec.contains('av1')) {
    return 'AV1';
  } else if (lowerCodec.contains('mpeg2')) {
    return 'MPEG-2';
  } else if (lowerCodec.contains('mpeg4')) {
    return 'MPEG-4';
  }

  // Return original if no simplification found
  return codec.toUpperCase();
}

/// Formats audio codec name
String formatAudioCodec(String? codec) {
  if (codec == null || codec.isEmpty) return 'N/A';

  final lowerCodec = codec.toLowerCase();
  if (lowerCodec.contains('aac')) {
    return 'AAC';
  } else if (lowerCodec.contains('mp3')) {
    return 'MP3';
  } else if (lowerCodec.contains('opus')) {
    return 'Opus';
  } else if (lowerCodec.contains('vorbis')) {
    return 'Vorbis';
  } else if (lowerCodec.contains('ac3') || lowerCodec.contains('ac-3')) {
    return 'AC-3';
  } else if (lowerCodec.contains('eac3') || lowerCodec.contains('e-ac-3')) {
    return 'E-AC-3';
  } else if (lowerCodec.contains('dts')) {
    return 'DTS';
  } else if (lowerCodec.contains('flac')) {
    return 'FLAC';
  } else if (lowerCodec.contains('pcm')) {
    return 'PCM';
  }

  return codec.toUpperCase();
}

/// Formats file size in human-readable format
String formatFileSize(int? bytes) {
  if (bytes == null || bytes == 0) return 'N/A';

  if (bytes >= 1073741824) {
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  } else if (bytes >= 1048576) {
    return '${(bytes / 1048576).toStringAsFixed(2)} MB';
  } else if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  } else {
    return '$bytes B';
  }
}

/// Formats framerate for display
String formatFramerate(double? fps) {
  if (fps == null || fps == 0) return 'N/A';
  return '${fps.toStringAsFixed(2)} fps';
}

/// Formats buffer percentage
String formatBufferPercentage(double? percentage) {
  if (percentage == null) return 'N/A';
  return '${percentage.toStringAsFixed(1)}%';
}

/// Formats dropped frames count
String formatDroppedFrames(int? dropped, int? total) {
  if (dropped == null) return 'N/A';
  if (total != null && total > 0) {
    final percentage = (dropped / total) * 100;
    return '$dropped (${percentage.toStringAsFixed(2)}%)';
  }
  return '$dropped';
}
