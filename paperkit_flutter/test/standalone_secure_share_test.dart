import 'package:maskerv_flutter/features/image_media_tools/models/video_frame_models.dart';
import 'package:maskerv_flutter/features/security_tools/models/temporary_share_models.dart';
import 'package:maskerv_flutter/features/qr_tools/models/qr_parsed_payload.dart';
import 'package:maskerv_flutter/features/qr_tools/services/qr_payload_parser.dart';
import 'package:qr/qr.dart';

void main() {
  print('=== STARTING STANDALONE MASKERV UNIT & INTEGRATION TESTS ===');

  // 1. Video Probe Info Model
  final probeJson = {
    'filename': 'sample.mp4',
    'duration': 125.4,
    'width': 1920,
    'height': 1080,
    'fps': 29.97,
    'codec': 'h264',
    'has_audio': true,
    'size': 15728640,
    'format_name': 'mov,mp4',
  };
  final probe = VideoProbeInfo.fromJson(probeJson);
  assert(probe.filename == 'sample.mp4');
  assert(probe.duration == 125.4);
  assert(probe.durationFormatted == '2m 5.4s');
  assert(probe.resolutionStr == '1920x1080');
  assert(probe.sizeFormatted == '15.00 MB');
  assert(probe.hasAudio == true);
  print('[PASS] VideoProbeInfo model and formatting');

  // 2. Frame Extraction Result Model
  final frameJson = {
    'job_id': 'job_test_123',
    'total_frames': 2,
    'image_format': 'jpg',
    'width': 1920,
    'height': 1080,
    'zip_url': '/media/video-frames/job_test_123/zip',
    'frames': [
      {
        'frame_number': 1,
        'timestamp_sec': 0.0,
        'filename': 'frame_000001.jpg',
        'file_size': 45100,
        'data_url': 'data:image/jpeg;base64,abc123',
        'download_url': '/media/video-frames/job_test_123/frame/1',
      },
      {
        'frame_number': 2,
        'timestamp_sec': 1.0,
        'filename': 'frame_000002.jpg',
        'file_size': 48200,
        'data_url': 'data:image/jpeg;base64,def456',
        'download_url': '/media/video-frames/job_test_123/frame/2',
      }
    ]
  };
  final extractRes = FrameExtractionResult.fromJson(frameJson);
  assert(extractRes.jobId == 'job_test_123');
  assert(extractRes.totalFrames == 2);
  assert(extractRes.frames.length == 2);
  assert(extractRes.frames[0].frameNumber == 1);
  assert(extractRes.frames[1].timestampFormatted == '00:01.00');
  print('[PASS] FrameExtractionResult and ExtractedFrameItem models');

  // 3. Temporary Share Creation Result Model
  final now = DateTime.now();
  final expiry = now.add(const Duration(minutes: 10));
  final shareCreationJson = {
    'success': true,
    'share_id': 'pk_share_abc123',
    'share_url': 'https://maskerv-web.onrender.com/share/pk_share_abc123',
    'access_url': 'https://maskerv-web.onrender.com/share/pk_share_abc123',
    'original_filename': 'contract.pdf',
    'file_size': 2097152,
    'content_type': 'application/pdf',
    'created_at': now.toIso8601String(),
    'expires_at': expiry.toIso8601String(),
    'expires_in_seconds': 600,
  };
  final shareCreation = TemporaryShareCreationResult.fromJson(shareCreationJson);
  assert(shareCreation.success == true);
  assert(shareCreation.shareId == 'pk_share_abc123');
  assert(shareCreation.filename == 'contract.pdf');
  assert(shareCreation.expiresInSeconds == 600);
  print('[PASS] TemporaryShareCreationResult model');

  // 4. Temporary Share Metadata Model
  final metaJson = {
    'share_id': 'pk_share_abc123',
    'original_filename': 'contract.pdf',
    'file_size': 2097152,
    'content_type': 'application/pdf',
    'created_at': now.toIso8601String(),
    'expires_at': expiry.toIso8601String(),
    'remaining_seconds': 580,
    'status': 'active',
    'requires_password': true,
  };
  final meta = TemporaryShareMetadata.fromJson(metaJson);
  assert(meta.shareId == 'pk_share_abc123');
  assert(meta.fileSizeFormatted == '2.00 MB');
  assert(meta.isExpired == false);

  final expiredMetaJson = Map<String, dynamic>.from(metaJson);
  expiredMetaJson['remaining_seconds'] = 0;
  expiredMetaJson['status'] = 'expired';
  final expiredMeta = TemporaryShareMetadata.fromJson(expiredMetaJson);
  assert(expiredMeta.isExpired == true);
  print('[PASS] TemporaryShareMetadata model and expiration detection');

  // 5. QR Code Generation for Share URL
  final qrCode = QrCode.fromData(
    data: shareCreation.shareUrl,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qrImage = QrImage(qrCode);
  assert(qrImage.moduleCount > 20);
  print('[PASS] QR Code Matrix Generation for Secure Share URL (${qrImage.moduleCount}x${qrImage.moduleCount})');

  // 6. QR Payload Parser Verification for Secure Share Link
  final parsed = QrPayloadParser.parse(shareCreation.shareUrl);
  assert(parsed.type == QrPayloadType.url);
  assert(parsed.url == 'https://maskerv-web.onrender.com/share/pk_share_abc123');
  assert(!parsed.isSuspiciousUrl);
  print('[PASS] QR Payload Parser recognition of HTTPS Secure Share URL');

  print('=== ALL STANDALONE MASKERV TESTS COMPLETED SUCCESSFULLY! ===');
}
