import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/file_service.dart';

class VideoController with ChangeNotifier {
  final IFileService _fileService;
  
  List<VideoModel> _videos = [];
  VideoModel? _currentVideo;
  bool _isPlaying = false;

  VideoController(this._fileService);

  // ゲッター
  List<VideoModel> get videos => _videos;
  VideoModel? get currentVideo => _currentVideo;
  bool get isPlaying => _isPlaying;

  // 保存済みの動画を読み込む
  Future<void> loadVideos() async {
    try {
      _videos = await _fileService.getRecentVideos();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading videos: $e');
      _videos = [];
      notifyListeners();
    }
  }

  // 新しい動画を選択
  Future<void> pickVideo() async {
    try {
      final video = await _fileService.pickVideo();
      if (video != null) {
        // 既存のリストに動画がなければ追加
        if (!_videos.any((v) => v.path == video.path)) {
          _videos = [..._videos, video];
        }
        _currentVideo = video;
        _isPlaying = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  // 特定の動画を選択して再生
  void selectVideo(VideoModel video) {
    _currentVideo = video;
    _isPlaying = true;
    notifyListeners();
  }

  // 再生状態の切り替え
  void togglePlayback() {
    if (_currentVideo != null) {
      _isPlaying = !_isPlaying;
      notifyListeners();
    }
  }

  // 動画リストから削除
  void removeVideo(VideoModel video) {
    _videos = _videos.where((v) => v.id != video.id).toList();
    if (_currentVideo?.id == video.id) {
      _currentVideo = null;
      _isPlaying = false;
    }
    notifyListeners();
  }
}