import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final videoController = context.read<VideoController>();
    final video = videoController.currentVideo;
    
    if (video != null) {
      _playerController = VideoPlayerController.file(File(video.path));
      
      await _playerController!.initialize();
      await _playerController!.setLooping(true);
      
      if (videoController.isPlaying) {
        await _playerController!.play();
      }
      
      setState(() {
        _isInitialized = true;
      });
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
      body: _isInitialized && _playerController != null
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