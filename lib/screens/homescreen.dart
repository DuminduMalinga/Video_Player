import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class VideoHomeScreen extends StatefulWidget {
  const VideoHomeScreen({super.key});

  @override
  State<VideoHomeScreen> createState() => _VideoHomeScreenState();
}

class _VideoHomeScreenState extends State<VideoHomeScreen> {
  VideoPlayerController? _controller;
  List<File> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _hasEnded = false;
  Timer? _progressTimer;
  File? _currentVideoFile;

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null && result.files.isNotEmpty) {
      File selectedVideo = File(result.files.first.path!);
      Directory folder = selectedVideo.parent;

      print('Loading videos from: ${folder.path}');

      List<File> files = folder
          .listSync()
          .whereType<File>()
          .where(
            (f) => [
              '.mp4',
              '.mov',
              '.mkv',
              '.avi',
              '.wmv',
              '.flv',
              '.webm',
              '.m4v',
              '.3gp',
            ].contains(p.extension(f.path).toLowerCase()),
          )
          .toList();

      files.sort((a, b) => a.path.compareTo(b.path));

      print('Found ${files.length} video files');

      setState(() {
        _playlist = files;
        _currentIndex = _playlist.indexWhere(
          (f) => f.path == selectedVideo.path,
        );
      });

      if (_playlist.isNotEmpty) {
        _playVideoAt(_currentIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${_playlist.length} videos from folder'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _playVideoAt(int index) async {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;

    _controller?.removeListener(_videoListener);
    await _controller?.dispose();
    _progressTimer?.cancel();

    _currentVideoFile = _playlist[index];
    _hasEnded = false;

    _controller = VideoPlayerController.file(_playlist[index]);
    await _controller!.initialize();
    setState(() => _isPlaying = true);
    _controller!.play();

    _controller!.addListener(_videoListener);

    _progressTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkVideoProgress(),
    );
  }

  void _checkVideoProgress() {
    if (_controller == null || !_controller!.value.isInitialized || _hasEnded)
      return;

    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;

    // Check if video has ended - more reliable detection
    if (dur > Duration.zero && pos >= dur && !_hasEnded) {
      _hasEnded = true;
      _progressTimer?.cancel();
      print('Video ended - moving to next video');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _nextVideo();
        }
      });
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    setState(() => _isPlaying = _controller!.value.isPlaying);

    // Also check for video end in listener
    final pos = _controller!.value.position;
    final dur = _controller!.value.duration;

    if (dur > Duration.zero && pos >= dur && !_hasEnded) {
      _hasEnded = true;
      _progressTimer?.cancel();
      print('Video ended via listener - moving to next video');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _nextVideo();
        }
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
      _isPlaying = _controller!.value.isPlaying;
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted ? _controller!.setVolume(1.0) : _controller!.setVolume(0.0);
      _isMuted = !_isMuted;
    });
  }

  void _seekForward() {
    if (_controller == null) return;
    _controller!.seekTo(
      _controller!.value.position + const Duration(seconds: 10),
    );
  }

  void _seekBackward() {
    if (_controller == null) return;
    _controller!.seekTo(
      _controller!.value.position - const Duration(seconds: 10),
    );
  }

  void _fastForward() {
    if (_controller == null) return;
    _controller!.seekTo(
      _controller!.value.position + const Duration(seconds: 30),
    );
  }

  void _fastBackward() {
    if (_controller == null) return;
    _controller!.seekTo(
      _controller!.value.position - const Duration(seconds: 30),
    );
  }

  Future<void> _refreshPlaylist() async {
    if (_currentVideoFile == null) return;
    Directory folder = _currentVideoFile!.parent;
    List<File> files = folder
        .listSync()
        .whereType<File>()
        .where(
          (f) => [
            '.mp4',
            '.mov',
            '.mkv',
            '.avi',
            '.wmv',
            '.flv',
            '.webm',
            '.m4v',
            '.3gp',
          ].contains(p.extension(f.path).toLowerCase()),
        )
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    setState(() {
      _playlist = files;
      _currentIndex = _playlist.indexWhere(
        (f) => f.path == _currentVideoFile!.path,
      );
    });
  }

  Future<void> _nextVideo() async {
    if (_playlist.isEmpty || _currentVideoFile == null) return;
    await _refreshPlaylist();
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _playVideoAt(_currentIndex);
  }

  Future<void> _previousVideo() async {
    if (_playlist.isEmpty || _currentVideoFile == null) return;
    await _refreshPlaylist();
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _playVideoAt(_currentIndex);
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Playlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_playlist.length} videos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Video list
              Expanded(
                child: ListView.builder(
                  itemCount: _playlist.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final isCurrentVideo = index == _currentIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isCurrentVideo
                            ? Colors.pinkAccent.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isCurrentVideo
                              ? Colors.pinkAccent
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrentVideo
                                ? Colors.pinkAccent
                                : Colors.white.withOpacity(0.1),
                          ),
                          child: Icon(
                            isCurrentVideo
                                ? Icons.play_circle
                                : Icons.video_file,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.basename(_playlist[index].path),
                          style: TextStyle(
                            color: isCurrentVideo
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            fontWeight: isCurrentVideo
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: isCurrentVideo
                            ? const Text(
                                'Now Playing',
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          _currentIndex = index;
                          _playVideoAt(index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Area
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _controller != null && _controller!.value.isInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                      : const Icon(
                          Icons.videocam,
                          size: 120,
                          color: Colors.white54,
                        ),

                  // Video name under the player
                  if (_currentVideoFile != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        p.basename(_currentVideoFile!.path),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Top Bar
            Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // App Name
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CineWave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _button(Icons.folder_open, _pickVideo),
                      if (_playlist.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        )
                      else
                        const Text(
                          'Select Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_playlist.length > 1) ...[
                            _button(
                              Icons.skip_previous,
                              _controller != null
                                  ? () => _previousVideo()
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            _button(
                              Icons.skip_next,
                              _controller != null ? () => _nextVideo() : null,
                            ),
                            const SizedBox(width: 8),
                          ],
                          _button(
                            Icons.playlist_play,
                            _playlist.isEmpty ? null : _showPlaylist,
                          ),
                          const SizedBox(width: 8),
                          _button(
                            _isMuted ? Icons.volume_off : Icons.volume_up,
                            _controller != null ? _toggleMute : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress
                    if (_controller != null && _controller!.value.isInitialized)
                      VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.pinkAccent,
                          backgroundColor: Colors.white24,
                          bufferedColor: Colors.white54,
                        ),
                      )
                    else
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _controller != null &&
                                  _controller!.value.isInitialized
                              ? _formatDuration(_controller!.value.position)
                              : '00:00',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _controller != null &&
                                  _controller!.value.isInitialized
                              ? _formatDuration(_controller!.value.duration)
                              : '00:00',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(
                          Icons.fast_rewind,
                          _controller != null ? _fastBackward : null,
                        ),
                        _controlButton(
                          Icons.replay_10,
                          _controller != null ? _seekBackward : null,
                        ),
                        _playPauseButton(),
                        _controlButton(
                          Icons.forward_10,
                          _controller != null ? _seekForward : null,
                        ),
                        _controlButton(
                          Icons.fast_forward,
                          _controller != null ? _fastForward : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(IconData icon, VoidCallback? onTap) {
    return Material(
      color: onTap != null ? Colors.pinkAccent : Colors.grey,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
        iconSize: 28,
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: onTap != null
            ? Colors.pinkAccent.withOpacity(0.8)
            : Colors.grey.withOpacity(0.5),
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
          iconSize: 36,
        ),
      ),
    );
  }

  Widget _playPauseButton() {
    bool hasController = _controller != null;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasController ? Colors.pinkAccent : Colors.grey,
        boxShadow: const [
          BoxShadow(color: Colors.white24, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
        iconSize: 52,
        onPressed: hasController ? _togglePlayPause : null,
      ),
    );
  }
}
