class VideoModel {
  final String id;
  final String title;
  final String path;
  final DateTime addedDate;
  final Duration? duration;
  final String? thumbnailPath;

  const VideoModel({
    required this.id,
    required this.title,
    required this.path,
    required this.addedDate,
    this.duration,
    this.thumbnailPath,
  });

  // ファイルパスからビデオモデルを作成するファクトリーメソッド
  factory VideoModel.fromPath(String path) {
    final pathSegments = path.split('/');
    final fileName = pathSegments.last;
    final title = fileName.split('.').first;
    
    return VideoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      path: path,
      addedDate: DateTime.now(),
    );
  }

  // イミュータブルなモデルの更新用メソッド
  VideoModel copyWith({
    String? title,
    Duration? duration,
    String? thumbnailPath,
  }) {
    return VideoModel(
      id: id,
      title: title ?? this.title,
      path: path,
      addedDate: addedDate,
      duration: duration ?? this.duration,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}