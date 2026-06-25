import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration; // In seconds
  final bool isSender;

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isSender,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);
    _initPlayer();
  }

  void _initPlayer() {
    _posSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
        });
      }
    });

    _durSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _totalDuration = d;
        });
      }
    });

    _compSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        Source source;
        if (widget.audioUrl.startsWith('data:audio')) {
          final base64Data = widget.audioUrl.split(',').last;
          source = BytesSource(base64Decode(base64Data));
        } else {
          source = UrlSource(widget.audioUrl);
        }
        await _audioPlayer.play(source);
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.isSender
        ? Colors.white
        : theme.colorScheme.primary;
    final secondaryColor = widget.isSender
        ? Colors.white.withValues(alpha: 0.6)
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 40,
              color: primaryColor,
            ),
            onPressed: _togglePlay,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds.toDouble() > 0
                        ? _totalDuration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (value) async {
                      final newPos = Duration(milliseconds: value.toInt());
                      await _audioPlayer.seek(newPos);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 10, color: secondaryColor),
                      ),
                      Text(
                        _formatDuration(_totalDuration),
                        style: TextStyle(fontSize: 10, color: secondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
