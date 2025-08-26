import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoHomeScreen extends StatefulWidget {
  const VideoHomeScreen({super.key});

  @override
  State<VideoHomeScreen> createState() => _VideoHomeScreenState();
}

class _VideoHomeScreenState extends State<VideoHomeScreen> {
  VideoPlayerController? _controller;
  final List<String> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isFullScreen = false;

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        if (file.path != null && !_playlist.contains(file.path!)) {
          _playlist.add(file.path!);
        }
      }

      setState(() {
        _currentIndex = _playlist.length - result.files.length;
      });

      _loadVideo(_playlist[_currentIndex]);
    }
  }

  Future<void> _loadVideo(String path) async {
    _controller?.dispose();
    _controller = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
        _isPlaying = true;
      });
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      if (_isMuted) {
        _controller!.setVolume(1.0);
        _isMuted = false;
      } else {
        _controller!.setVolume(0.0);
        _isMuted = true;
      }
    });
  }

  void _seekForward() {
    if (_controller == null) return;
    final newPos = _controller!.value.position + const Duration(seconds: 10);
    _controller!.seekTo(newPos);
  }

  void _seekBackward() {
    if (_controller == null) return;
    final newPos = _controller!.value.position - const Duration(seconds: 10);
    _controller!.seekTo(newPos);
  }

  Future<void> _nextVideo() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      await _loadVideo(_playlist[_currentIndex]);
    }
  }

  Future<void> _previousVideo() async {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      await _loadVideo(_playlist[_currentIndex]);
    }
  }

  String _getFileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.video_library,
                        color: Colors.white,
                      ),
                      onPressed: _pickVideo,
                    ),
                    const Text(
                      'Modern Video Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.playlist_play,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Show Playlist
                        showModalBottomSheet(
                          backgroundColor: Colors.black87,
                          context: context,
                          builder: (_) {
                            return ListView.builder(
                              itemCount: _playlist.length,
                              itemBuilder: (ctx, i) {
                                return ListTile(
                                  title: Text(
                                    _getFileName(_playlist[i]),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _loadVideo(_playlist[i]);
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Video Display
              Expanded(
                flex: 4,
                child: Center(
                  child: _controller != null && _controller!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      : const Icon(
                          Icons.videocam,
                          size: 100,
                          color: Colors.white54,
                        ),
                ),
              ),

              // Progress bar + duration
              if (_controller != null && _controller!.value.isInitialized)
                Column(
                  children: [
                    VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.pink,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.blueGrey,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: _previousVideo,
                    iconSize: 36,
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: _seekBackward,
                    iconSize: 36,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.pink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlayPause,
                      iconSize: 48,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: _seekForward,
                    iconSize: 36,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: _nextVideo,
                    iconSize: 36,
                  ),
                ],
              ),

              // Bottom Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                    IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFullScreen = !_isFullScreen;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
