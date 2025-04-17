import 'package:flutter/material.dart';
import 'dart:io';
import '../models/video_model.dart';

class VideoItem extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const VideoItem({
    super.key,
    required this.video,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: video.thumbnailPath != null
            ? Image.file(
                File(video.thumbnailPath!),
                fit: BoxFit.cover,
              )
            : const Icon(Icons.video_file, size: 30),
      ),
      title: Text(
        video.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '追加日: ${video.addedDate.toLocal().toString().split(' ')[0]}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          const Icon(Icons.play_circle_outline),
        ],
      ),
      onTap: onTap,
    );
  }
}