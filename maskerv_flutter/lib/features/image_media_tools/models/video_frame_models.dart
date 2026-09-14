class VideoProbeInfo {
  final String filename;
  final double duration;
  final int width;
  final int height;
  final double fps;
  final String codec;
  final bool hasAudio;
  final int size;
  final String formatName;

  const VideoProbeInfo({
    required this.filename,
    required this.duration,
    required this.width,
    required this.height,
    required this.fps,
    required this.codec,
    required this.hasAudio,
    required this.size,
    required this.formatName,
  });

  factory VideoProbeInfo.fromJson(Map<String, dynamic> json) {
    return VideoProbeInfo(
      filename: json['filename'] as String? ?? 'video.mp4',
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      fps: (json['fps'] as num?)?.toDouble() ?? 0.0,
      codec: json['codec'] as String? ?? 'unknown',
      hasAudio: json['has_audio'] as bool? ?? false,
      size: (json['size'] as num?)?.toInt() ?? 0,
      formatName: json['format_name'] as String? ?? 'mp4',
    );
  }

  String get resolutionStr => width > 0 && height > 0 ? '${width}x$height' : 'Unknown';

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = (duration % 60).toStringAsFixed(1);
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }

  String get sizeFormatted {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / 1024).toStringAsFixed(1)} KB';
  }
}

class ExtractedFrameItem {
  final int frameNumber;
  final double timestampSec;
  final String filename;
  final int fileSize;
  final String dataUrl;
  final String downloadUrl;

  const ExtractedFrameItem({
    required this.frameNumber,
    required this.timestampSec,
    required this.filename,
    required this.fileSize,
    required this.dataUrl,
    required this.downloadUrl,
  });

  factory ExtractedFrameItem.fromJson(Map<String, dynamic> json) {
    return ExtractedFrameItem(
      frameNumber: (json['frame_number'] as num?)?.toInt() ?? 1,
      timestampSec: (json['timestamp_sec'] as num?)?.toDouble() ?? 0.0,
      filename: json['filename'] as String? ?? 'frame.jpg',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      dataUrl: json['data_url'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  String get timestampFormatted {
    final minutes = timestampSec ~/ 60;
    final seconds = (timestampSec % 60).toStringAsFixed(2);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.padLeft(5, '0')}';
  }
}

class FrameExtractionResult {
  final String jobId;
  final int totalFrames;
  final String imageFormat;
  final int width;
  final int height;
  final List<ExtractedFrameItem> frames;
  final String zipUrl;

  const FrameExtractionResult({
    required this.jobId,
    required this.totalFrames,
    required this.imageFormat,
    required this.width,
    required this.height,
    required this.frames,
    required this.zipUrl,
  });

  factory FrameExtractionResult.fromJson(Map<String, dynamic> json) {
    final rawFrames = json['frames'] as List<dynamic>? ?? [];
    return FrameExtractionResult(
      jobId: json['job_id'] as String? ?? '',
      totalFrames: (json['total_frames'] as num?)?.toInt() ?? rawFrames.length,
      imageFormat: json['image_format'] as String? ?? 'jpg',
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      frames: rawFrames
          .map((f) => ExtractedFrameItem.fromJson(f as Map<String, dynamic>))
          .toList(),
      zipUrl: json['zip_url'] as String? ?? '',
    );
  }
}
