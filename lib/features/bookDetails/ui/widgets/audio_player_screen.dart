import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../core/theming/app_colors.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Auto-play when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String audioUrl = args?['audioUrl'] as String? ?? '';
      if (audioUrl.isNotEmpty) {
        _playAudio(audioUrl);
      }
    });
  }

  Future<void> _playAudio(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> _skipForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    await _seekTo(newPosition);
  }

  Future<void> _skipBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    await _seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void _changePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.25;
      } else if (_playbackSpeed == 1.25) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _audioPlayer.setPlaybackRate(_playbackSpeed);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String bookTitle = args?['title'] as String? ?? 'Audio Player';
    final String author = args?['author'] as String? ?? 'Unknown';
    final String? imageUrl = args?['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Audio Player',
          style: TextStyle(color: AppColors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Book Cover
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.audiotrack,
                        size: 100,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                      : Container(
                    color: AppColors.surface,
                    child: const Icon(
                      Icons.audiotrack,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Book Title
              Text(
                bookTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Author
              Text(
                author,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Progress Slider
              Column(
                children: [
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      _seekTo(Duration(seconds: value.toInt()));
                    },
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surface,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Playback Speed
                  IconButton(
                    onPressed: _changePlaybackSpeed,
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Skip Backward 10s
                  IconButton(
                    onPressed: _skipBackward,
                    iconSize: 40,
                    icon: const Icon(
                      Icons.replay_10,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Play/Pause Button
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _togglePlayPause,
                      iconSize: 40,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Skip Forward 10s
                  IconButton(
                    onPressed: _skipForward,
                    iconSize: 40,
                    icon: const Icon(
                      Icons.forward_10,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Volume (placeholder)
                  IconButton(
                    onPressed: () {
                      // TODO: Implement volume control
                    },
                    iconSize: 30,
                    icon: const Icon(
                      Icons.volume_up,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}