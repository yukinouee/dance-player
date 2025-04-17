import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../controllers/video_controller.dart';
import '../widgets/player_controls.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  VideoPlayerController? _playerController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // 非同期処理を分離して実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVideoPlayer();
    });
  }

  Future<void> _initVideoPlayer() async {
    try {
      final videoController = context.read<VideoController>();
      final video = videoController.currentVideo;
      
      if (video != null) {
        // Windowsの場合、ファイルパスの処理が異なる可能性がある
        final file = File(video.path);
        if (!await file.exists()) {
          setState(() {
            _hasError = true;
            _errorMessage = 'ファイルが見つかりません: ${video.path}';
          });
          return;
        }
        
        // コントローラーを初期化して非同期で待機
        _playerController = VideoPlayerController.file(file);
        
        // 初期化を待機
        await _playerController!.initialize();
        
        // ループ設定
        await _playerController!.setLooping(true);
        
        if (videoController.isPlaying && mounted) {
          await _playerController!.play();
        }
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('動画プレーヤーの初期化エラー: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = '動画の読み込みに失敗しました: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<VideoController>(
          builder: (context, controller, _) {
            return Text(controller.currentVideo?.title ?? '動画プレーヤー');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _hasError 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('戻る'),
                  ),
                ],
              ),
            )
          : (_isInitialized && _playerController != null)
              ? Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _playerController!.value.aspectRatio,
                          child: VideoPlayer(_playerController!),
                        ),
                      ),
                    ),
                    PlayerControls(
                      controller: _playerController!,
                      onPlayPause: () {
                        final videoController = context.read<VideoController>();
                        videoController.togglePlayback();
                        
                        if (_playerController!.value.isPlaying) {
                          _playerController!.pause();
                        } else {
                          _playerController!.play();
                        }
                      },
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}