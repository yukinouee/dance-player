import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/video_model.dart';

// サービスのインターフェース定義（抽象クラス）
abstract class IFileService {
  Future<List<VideoModel>> getRecentVideos();
  Future<VideoModel?> pickVideo();
}

// サービスの実装クラス
class FileService implements IFileService {
  // 最近選択した動画のリストを取得
  @override
  Future<List<VideoModel>> getRecentVideos() async {
    // 実際のアプリでは保存済みのビデオリストを返す
    // デモ用にサンプルデータを返す
    return [];
  }

  // ユーザーに動画を選択させる
  @override
  Future<VideoModel?> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final file = File(path);
      if (await file.exists()) {
        return VideoModel.fromPath(path);
      }
    }
    return null;
  }
}