import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

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
  bool _isPreSeekingToStart = false;

  // ループ範囲を設定可能に (デフォルトは500ms)
  int _loopRangeMs = 500;
  
  // ループ範囲の最小値と最大値（0.1秒～10秒）
  static const int _minLoopRangeMs = 100;
  static const int _maxLoopRangeMs = 10000;

  // 設定可能なループ範囲の選択肢（秒）
  static const List<double> _loopRangeOptions = [
    0.1, 0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 10.0
  ];
  
  // ループ範囲設定メニューの表示状態
  bool _showLoopRangeMenu = false;
  
  // ループ終端から何ミリ秒前に開始位置へのプリシークを始めるか
  static const int preSeekThresholdMs = 50;
  
  // 再生速度の選択肢
  static const List<double> _playbackSpeeds = [
    0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
  ];
  
  // 現在の再生速度のインデックス（デフォルトは1.0x = インデックス4）
  int _currentSpeedIndex = 4;
  
  // 再生速度メニューの表示状態
  bool _showSpeedMenu = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_updateState);
    
    // 初期速度を設定
    _controller.setPlaybackSpeed(_playbackSpeeds[_currentSpeedIndex]);
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

  // 倍速を変更する
  void _changePlaybackSpeed(int speedIndex) {
    if (speedIndex >= 0 && speedIndex < _playbackSpeeds.length) {
      setState(() {
        _currentSpeedIndex = speedIndex;
        _showSpeedMenu = false;
      });
      
      final newSpeed = _playbackSpeeds[_currentSpeedIndex];
      _controller.setPlaybackSpeed(newSpeed);
      
      // ユーザーに通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('再生速度: ${newSpeed}x'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 倍速メニューの表示切替
  void _toggleSpeedMenu() {
    setState(() {
      _showSpeedMenu = !_showSpeedMenu;
      if (_showSpeedMenu) {
        // 他のメニューを閉じる
        _showLoopRangeMenu = false;
      }
    });
  }
  
  // ループ範囲メニューの表示切替
  void _toggleLoopRangeMenu() {
    setState(() {
      _showLoopRangeMenu = !_showLoopRangeMenu;
      if (_showLoopRangeMenu) {
        // 他のメニューを閉じる
        _showSpeedMenu = false;
      }
    });
  }
  
  // ループ範囲を変更する
  void _changeLoopRange(double rangeInSeconds) {
    final rangeMs = (rangeInSeconds * 1000).toInt();
    if (rangeMs >= _minLoopRangeMs && rangeMs <= _maxLoopRangeMs) {
      setState(() {
        _loopRangeMs = rangeMs;
        _showLoopRangeMenu = false;
      });
      
      // ループ中ならループ範囲を更新
      if (_isLoopingSegment) {
        _updateLoopSegment();
      }
      
      // ユーザーに通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ループ範囲: 前後 $rangeInSeconds 秒'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 現在のループ範囲で再計算する
  void _updateLoopSegment() {
    if (!_isLoopingSegment) return;
    
    final currentPosition = _controller.value.position;
    
    // ループ中心時間（現在のループの中央値）
    Duration loopCenter;
    if (_loopStart != null && _loopEnd != null) {
      final centerMs = (_loopStart!.inMilliseconds + _loopEnd!.inMilliseconds) ~/ 2;
      loopCenter = Duration(milliseconds: centerMs);
    } else {
      loopCenter = currentPosition;
    }
    
    // 新しいループ範囲で再計算
    final loopStart = Duration(
      milliseconds: math.max(0, loopCenter.inMilliseconds - _loopRangeMs)
    );
    
    final loopEnd = Duration(
      milliseconds: math.min(
        _controller.value.duration.inMilliseconds,
        loopCenter.inMilliseconds + _loopRangeMs
      )
    );
    
    setState(() {
      _loopStart = loopStart;
      _loopEnd = loopEnd;
      _isPreSeekingToStart = false;
    });
    
    // 開始位置にシーク
    _controller.seekTo(loopStart);
  }

  // 現在時刻の前後指定時間でループ再生を設定
  void _setLoopSegment() {
    final currentPosition = _controller.value.position;
    
    // ループの開始位置（現在時刻-loopRangeMs、ただし0秒未満にはならない）
    final loopStart = Duration(
      milliseconds: math.max(0, currentPosition.inMilliseconds - _loopRangeMs)
    );
    
    // ループの終了位置（現在時刻+loopRangeMs、ただし動画長を超えない）
    final loopEnd = Duration(
      milliseconds: math.min(
        _controller.value.duration.inMilliseconds,
        currentPosition.inMilliseconds + _loopRangeMs
      )
    );
    
    setState(() {
      _isLoopingSegment = true;
      _loopStart = loopStart;
      _loopEnd = loopEnd;
      _isPreSeekingToStart = false;
    });
    
    // 開始位置にシーク
    _controller.seekTo(loopStart);
    
    // 必要に応じて再生を開始
    if (!_controller.value.isPlaying) {
      _controller.play();
    }
    
    // ループ範囲を秒に変換して表示
    final loopRangeSeconds = (_loopRangeMs / 1000).toStringAsFixed(1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_formatDuration(loopStart)} から ${_formatDuration(loopEnd)} までループ再生中 (±$loopRangeSeconds秒)'),
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
      _isPreSeekingToStart = false;
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
      _isPreSeekingToStart = false;
    }
  }
  
  // ループ再生中の位置チェックと調整
  void _checkAndAdjustLoop() {
    if (_isLoopingSegment && _loopStart != null && _loopEnd != null) {
      final currentPosition = _controller.value.position;
      
      if (currentPosition >= _loopEnd!) {
        // 終了位置を超えたら開始位置に戻る
        _controller.seekTo(_loopStart!);
        _isPreSeekingToStart = false;
      } 
      else if (currentPosition < _loopStart!) {
        // 開始位置より前にいる場合も開始位置に移動
        _controller.seekTo(_loopStart!);
        _isPreSeekingToStart = false;
      }
      else if (!_isPreSeekingToStart && 
               _loopEnd!.inMilliseconds - currentPosition.inMilliseconds <= preSeekThresholdMs) {
        // 終端の少し手前（preSeekThresholdMs以内）に来たら、事前に開始位置へシークを準備
        // ただし、再生は止めない（バッファリングだけ行う）
        _preloadLoopStart();
      }
    }
  }
  
  // ループ開始位置をプリロード（滑らかなループ再生のため）
  void _preloadLoopStart() {
    if (_loopStart != null && _controller.value.isPlaying) {
      _isPreSeekingToStart = true;
      
      // 非同期でシークを試みるが、現在の再生は続行
      // VideoPlayerControllerの内部バッファに開始位置をロードしておく
      _controller.seekTo(_loopStart!).then((_) {
        // シーク完了後、すぐに元の位置に戻る（ユーザーには見えない）
        if (mounted && _isLoopingSegment && _isPreSeekingToStart) {
          final currentPos = _controller.value.position;
          if (currentPos.inMilliseconds < _loopEnd!.inMilliseconds) {
            _controller.seekTo(currentPos);
          }
        }
      });
    }
  }

  // ループモード中に安全にシークする（ループ範囲内に制限）
  void _safeSeek(Duration position) {
    if (_isLoopingSegment && _loopStart != null && _loopEnd != null) {
      // ループ範囲内に収める
      final safePosition = Duration(
        milliseconds: math.min(
          math.max(position.inMilliseconds, _loopStart!.inMilliseconds),
          _loopEnd!.inMilliseconds
        )
      );
      _controller.seekTo(safePosition);
      _isPreSeekingToStart = false;
    } else {
      // 通常のシーク
      _controller.seekTo(position);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return "$minutes:$seconds.$milliseconds";
  }

  @override
  Widget build(BuildContext context) {
    // ループモード中はスライダーの範囲を制限
    double sliderMin = 0.0;
    double sliderMax = _controller.value.duration.inSeconds.toDouble();
    double sliderValue = _controller.value.position.inSeconds.toDouble();
    
    if (_isLoopingSegment && _loopStart != null && _loopEnd != null) {
      sliderMin = _loopStart!.inSeconds.toDouble();
      sliderMax = _loopEnd!.inSeconds.toDouble();
      // 現在位置がループ範囲外なら調整
      sliderValue = math.min(
        math.max(sliderValue, sliderMin),
        sliderMax
      );
    }

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
              value: sliderValue,
              min: sliderMin,
              max: sliderMax,
              onChanged: (value) {
                _safeSeek(Duration(seconds: value.toInt()));
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
                  // ループモード中はループ終了時間を表示、通常モードでは動画全体の長さを表示
                  Text(
                    _isLoopingSegment && _loopEnd != null
                        ? _formatDuration(_loopEnd!)
                        : _formatDuration(_controller.value.duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // ループ範囲選択メニュー (展開時のみ表示)
            if (_showLoopRangeMenu)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _loopRangeOptions.length,
                  itemBuilder: (context, index) {
                    final rangeInSeconds = _loopRangeOptions[index];
                    final rangeMs = (rangeInSeconds * 1000).toInt();
                    final isSelected = rangeMs == _loopRangeMs;
                    
                    return GestureDetector(
                      onTap: () => _changeLoopRange(rangeInSeconds),
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.lightGreenAccent.withOpacity(0.7)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${rangeInSeconds}s',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // 倍速選択メニュー (展開時のみ表示)
            if (_showSpeedMenu)
              Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _playbackSpeeds.length,
                  itemBuilder: (context, index) {
                    final speed = _playbackSpeeds[index];
                    final isSelected = index == _currentSpeedIndex;
                    
                    return GestureDetector(
                      onTap: () => _changePlaybackSpeed(index),
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.lightGreenAccent.withOpacity(0.7)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                    // ループモード中は安全にシーク
                    final newPosition = _controller.value.position - const Duration(seconds: 10);
                    _safeSeek(newPosition);
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
                    // ループモード中は安全にシーク
                    final newPosition = _controller.value.position + const Duration(seconds: 10);
                    _safeSeek(newPosition);
                  },
                ),
                // ループ再生ボタン
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLoopingSegment ? Icons.loop_outlined : Icons.loop,
                      ),
                      color: _isLoopingSegment ? Colors.lightGreenAccent : Colors.white,
                      tooltip: _isLoopingSegment ? 'ループ再生を解除' : '現在位置の前後をループ再生',
                      onPressed: _isLoopingSegment ? _cancelLoop : _setLoopSegment,
                    ),
                    // ループ設定ボタン
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _toggleLoopRangeMenu,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _showLoopRangeMenu 
                                ? Colors.lightGreenAccent 
                                : Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              '${(_loopRangeMs / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                color: _showLoopRangeMenu ? Colors.black : Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // 倍速ボタン
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.speed),
                      color: _showSpeedMenu ? Colors.lightGreenAccent : Colors.white,
                      tooltip: '再生速度を変更',
                      onPressed: _toggleSpeedMenu,
                    ),
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_playbackSpeeds[_currentSpeedIndex]}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}