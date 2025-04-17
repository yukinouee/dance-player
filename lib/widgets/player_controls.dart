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
  
  // ループ再生関連の状態
  bool _isLoopingSegment = false;
  Duration? _loopStart;
  Duration? _loopEnd;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_updateState);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    // ループタイマーがあれば破棄
    _cancelLoopIfActive();
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
      
      // ループ再生中は範囲をチェック
      _checkAndAdjustLoop();
    }
  }

  // 現在時刻の±2秒でループ再生を設定
  void _setLoopSegment() {
    final currentPosition = _controller.value.position;
    
    // ループの開始位置（現在時刻-2秒、ただし0秒未満にはならない）
    final loopStart = Duration(
      milliseconds: max(0, currentPosition.inMilliseconds - 500)
    );
    
    // ループの終了位置（現在時刻+2秒、ただし動画長を超えない）
    final loopEnd = Duration(
      milliseconds: min(
        _controller.value.duration.inMilliseconds,
        currentPosition.inMilliseconds + 500
      )
    );
    
    setState(() {
      _isLoopingSegment = true;
      _loopStart = loopStart;
      _loopEnd = loopEnd;
    });
    
    // 開始位置にシーク
    _controller.seekTo(loopStart);
    
    // 必要に応じて再生を開始
    if (!_controller.value.isPlaying) {
      _controller.play();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_formatDuration(loopStart)} から ${_formatDuration(loopEnd)} までループ再生中'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '解除',
          onPressed: _cancelLoop,
        ),
      ),
    );
  }
  
  // ループを解除
  void _cancelLoop() {
    setState(() {
      _isLoopingSegment = false;
      _loopStart = null;
      _loopEnd = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ループ再生を解除しました'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  // ループがアクティブな場合に解除
  void _cancelLoopIfActive() {
    if (_isLoopingSegment) {
      _isLoopingSegment = false;
      _loopStart = null;
      _loopEnd = null;
    }
  }
  
  // ループ再生中の位置チェックと調整
  void _checkAndAdjustLoop() {
    if (_isLoopingSegment && _loopStart != null && _loopEnd != null) {
      final currentPosition = _controller.value.position;
      
      // 終了位置を超えたら開始位置に戻る
      if (currentPosition >= _loopEnd!) {
        _controller.seekTo(_loopStart!);
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
  
  // intの最小値・最大値を計算するヘルパーメソッド
  int min(int a, int b) => a < b ? a : b;
  int max(int a, int b) => a > b ? a : b;

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
                  if (_isLoopingSegment && _loopStart != null && _loopEnd != null)
                    Text(
                      'ループ: ${_formatDuration(_loopStart!)} - ${_formatDuration(_loopEnd!)}',
                      style: const TextStyle(color: Colors.lightGreenAccent),
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
                // ループ再生ボタン
                IconButton(
                  icon: Icon(
                    _isLoopingSegment ? Icons.loop_outlined : Icons.loop,
                  ),
                  color: _isLoopingSegment ? Colors.lightGreenAccent : Colors.white,
                  tooltip: _isLoopingSegment ? 'ループ再生を解除' : '現在位置の前後2秒をループ再生',
                  onPressed: _isLoopingSegment ? _cancelLoop : _setLoopSegment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}