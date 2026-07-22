import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'app_toast.dart';

class FileViewerScreen extends StatefulWidget {
  final String filePath;
  final String? fileName;

  const FileViewerScreen({super.key, required this.filePath, this.fileName});

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  late final String _ext;

  VideoPlayerController? _videoController;

  final _audioPlayer = AudioPlayer();
  bool _audioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    final name = widget.fileName ?? widget.filePath.split('/').last;
    _ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    if (_isVideo) _initVideo();
    if (_isAudio) _initAudio();
  }

  bool get _isImage => ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(_ext);
  bool get _isPdf => _ext == 'pdf';
  bool get _isVideo => ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(_ext);
  bool get _isAudio => ['mp3', 'wav', 'aac', 'm4a', 'ogg', 'flac'].contains(_ext);
  bool get _isDocument => ['doc', 'docx'].contains(_ext);
  bool get _isZip => _ext == 'zip';

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(widget.filePath));
    await _videoController!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _initAudio() async {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _audioPlaying = false);
    });
    await _audioPlayer.setSourceDeviceFile(widget.filePath);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _displayName =>
      widget.fileName ?? widget.filePath.split('/').last;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _displayName,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Save to Downloads',
            onPressed: _saveToDownloads,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isImage) return _buildImageViewer();
    if (_isPdf) return _buildPdfViewer();
    if (_isVideo) return _buildVideoViewer();
    if (_isAudio) return _buildAudioPlayer();
    if (_isDocument) return _buildDocumentFallback();
    return _buildUnsupported();
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(File(widget.filePath), fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return PDFView(
      filePath: widget.filePath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageSnap: true,
    );
  }

  Widget _buildVideoViewer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        const SizedBox(height: 12),
        VideoProgressIndicator(
          _videoController!,
          allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: Color(0xFF7C3AED)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
        IconButton(
          color: Colors.white,
          iconSize: 56,
          icon: Icon(
            _videoController!.value.isPlaying
                ? Icons.pause_circle
                : Icons.play_circle,
          ),
          onPressed: () {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          },
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    final progress = _audioDuration.inMilliseconds > 0
        ? (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    String fmt(Duration d) =>
        '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note, size: 80, color: Colors.white38),
            const SizedBox(height: 8),
            Text(
              _displayName,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Slider(
              value: progress,
              activeColor: const Color(0xFF7C3AED),
              inactiveColor: Colors.white24,
              onChanged: (v) {
                final pos = Duration(
                  milliseconds: (v * _audioDuration.inMilliseconds).round(),
                );
                _audioPlayer.seek(pos);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmt(_audioPosition),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  Text(fmt(_audioDuration),
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IconButton(
              iconSize: 72,
              color: Colors.white,
              icon: Icon(
                _audioPlaying ? Icons.pause_circle : Icons.play_circle,
              ),
              onPressed: () async {
                if (_audioPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.resume();
                }
                setState(() => _audioPlaying = !_audioPlaying);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Preview for ${_ext.toUpperCase()} is not supported directly.',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text('Open with Another App', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: () async {
                final result = await OpenFilex.open(widget.filePath);
                if (result.type != ResultType.done && mounted) {
                  AppToast.error(result.message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupported() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isZip ? Icons.folder_zip : Icons.insert_drive_file,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              _displayName,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isZip
                  ? 'ZIP files cannot be previewed.'
                  : 'This file format is not supported for preview.',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download),
              label: Text('Save to Downloads', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onPressed: _saveToDownloads,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDownloads() async {
    try {
      final bytes = await File(widget.filePath).readAsBytes();

      // Lets the user pick the destination via the system's native "Save As"
      // picker (Storage Access Framework on Android) instead of silently
      // writing to a hardcoded path - the latter also has no chance of
      // working on a real device since this app declares no storage
      // permission in AndroidManifest.xml.
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File',
        fileName: _displayName,
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath == null) return; // user cancelled the picker

      AppToast.success('File saved successfully');
    } catch (e) {
      if (!mounted) return;
      AppToast.error('Failed to save file: $e');
    }
  }
}
