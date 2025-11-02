/// Video Processing Service
/// 
/// Handles video capture, frame extraction, and video processing operations.
/// Integrates with ffmpeg_kit_flutter for advanced video processing capabilities.
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class VideoProcessingService {
  static const String _tag = 'VideoProcessingService';

  /// Extract frames from a video file at specified FPS
  /// 
  /// [videoPath] - Path to the input video file
  /// [outputDir] - Directory to save extracted frames
  /// [fps] - Frames per second to extract (default: 2)
  /// Returns list of extracted frame file paths
  Future<List<String>> extractFramesFromVideo(
    String videoPath,
    String outputDir, {
    int fps = 2,
  }) async {
    try {
      final outputDirectory = Directory(outputDir);
      if (!await outputDirectory.exists()) {
        await outputDirectory.create(recursive: true);
      }

      // Output pattern for frames
      final outputPattern = '$outputDir/frame_%04d.jpg';

      // FFmpeg command to extract frames
      final command = '-i "$videoPath" -vf "fps=$fps" -y "$outputPattern"';

      print('$_tag: Executing FFmpeg command: $command');

      // Execute FFmpeg
      final result = await FFmpegKit.execute(command);
      final returnCode = await result.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Get list of extracted frames
        final frames = await _getFrameFiles(outputDir);
        print('$_tag: Successfully extracted ${frames.length} frames');
        return frames;
      } else {
        final errorLog = await result.getFailStackTrace();
        throw Exception('FFmpeg failed: $errorLog');
      }
    } catch (e) {
      print('$_tag: Frame extraction failed: $e');
      rethrow;
    }
  }

  /// Get list of frame files from output directory
  Future<List<String>> _getFrameFiles(String outputDir) async {
    final directory = Directory(outputDir);
    if (!await directory.exists()) return [];

    final files = await directory.list().toList();
    final frameFiles = files
        .where((file) => file is File && file.path.endsWith('.jpg'))
        .map((file) => (file as File).path)
        .toList();

    // Sort files by name to ensure correct order
    frameFiles.sort();
    return frameFiles;
  }

  /// Compress video to reduce file size
  /// 
  /// [inputPath] - Path to input video
  /// [outputPath] - Path for compressed output
  /// [quality] - Compression quality (1-31, lower = better quality)
  Future<String> compressVideo(
    String inputPath,
    String outputPath, {
    int quality = 23,
  }) async {
    try {
      // FFmpeg command for video compression
      final command = '-i "$inputPath" -c:v libx264 -crf $quality -preset medium -y "$outputPath"';

      print('$_tag: Compressing video with command: $command');

      final result = await FFmpegKit.execute(command);
      final returnCode = await result.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('$_tag: Video compressed successfully');
        return outputPath;
      } else {
        final errorLog = await result.getFailStackTrace();
        throw Exception('Video compression failed: $errorLog');
      }
    } catch (e) {
      print('$_tag: Video compression failed: $e');
      rethrow;
    }
  }

  /// Get video information (duration, resolution, etc.)
  Future<Map<String, dynamic>> getVideoInfo(String videoPath) async {
    try {
      // FFprobe command to get video information
      final command = '-i "$videoPath" -v quiet -print_format json -show_format -show_streams';

      final result = await FFmpegKit.execute(command);
      final output = await result.getOutput();

      if (output != null) {
        // Parse JSON output (simplified parsing)
        final videoStream = await _parseVideoMetadata(output);
        return videoStream;
      } else {
        throw Exception('Failed to get video information');
      }
    } catch (e) {
      print('$_tag: Failed to get video info: $e');
      rethrow;
    }
  }

  /// Parse video metadata from FFprobe output
  Future<Map<String, dynamic>> _parseVideoMetadata(String output) async {
    try {
      // Simple parsing for demonstration
      // In a real implementation, you would use jsonDecode
      final durationMatch = RegExp(r'"duration":\s*([\d.]+)').firstMatch(output);
      final widthMatch = RegExp(r'"width":\s*(\d+)').firstMatch(output);
      final heightMatch = RegExp(r'"height":\s*(\d+)').firstMatch(output);

      return {
        'duration': durationMatch?.group(1) != null 
            ? double.parse(durationMatch!.group(1)!) 
            : 0.0,
        'width': widthMatch?.group(1) != null 
            ? int.parse(widthMatch!.group(1)!) 
            : 0,
        'height': heightMatch?.group(1) != null 
            ? int.parse(heightMatch!.group(1)!) 
            : 0,
      };
    } catch (e) {
      print('$_tag: Failed to parse video metadata: $e');
      return {};
    }
  }

  /// Create a video thumbnail at specified time
  Future<String> createVideoThumbnail(
    String videoPath,
    String thumbnailPath, {
    double timeInSeconds = 1.0,
  }) async {
    try {
      final command = '-i "$videoPath" -ss $timeInSeconds -vframes 1 -y "$thumbnailPath"';

      final result = await FFmpegKit.execute(command);
      final returnCode = await result.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print('$_tag: Video thumbnail created successfully');
        return thumbnailPath;
      } else {
        final errorLog = await result.getFailStackTrace();
        throw Exception('Thumbnail creation failed: $errorLog');
      }
    } catch (e) {
      print('$_tag: Thumbnail creation failed: $e');
      rethrow;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTemporaryFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('$_tag: Failed to delete file $path: $e');
      }
    }
  }

  /// Create frames directory in app's temporary directory
  Future<String> createFramesDirectory() async {
    final tempDir = Directory.systemTemp;
    final framesDir = Directory('${tempDir.path}/avatar_frames_${DateTime.now().millisecondsSinceEpoch}');
    
    if (!await framesDir.exists()) {
      await framesDir.create();
    }
    
    return framesDir.path;
  }
}