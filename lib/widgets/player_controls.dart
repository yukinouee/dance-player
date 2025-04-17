import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onPlayPause;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.onPlayPause,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  late VideoPlayerController _controller;
  bool _hideControls = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_updateState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _hideControls ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // プログレスバー
            Slider(
              value: _controller.value.position.inSeconds.toDouble(),
              min: 0.0,
              max: _controller.value.duration.inSeconds.toDouble(),
              onChanged: (value) {
                _controller.seekTo(Duration(seconds: value.toInt()));
              },
            ),
            
            // 再生時間の表示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_controller.value.position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    _formatDuration(_controller.value.duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // コントロールボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  color: Colors.white,
                  onPressed: () {
                    final newPosition = _controller.value.position - const Duration(seconds: 10);
                    _controller.seekTo(newPosition);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  color: Colors.white,
                  iconSize: 48.0,
                  onPressed: widget.onPlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  color: Colors.white,
                  onPressed: () {
                    final newPosition = _controller.value.position + const Duration(seconds: 10);
                    _controller.seekTo(newPosition);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}