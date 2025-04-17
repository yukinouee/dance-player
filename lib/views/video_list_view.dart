import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_controller.dart';
import '../widgets/video_item.dart';
import 'player_view.dart';

class VideoListView extends StatelessWidget {
  const VideoListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ビデオライブラリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<VideoController>(
        builder: (context, controller, child) {
          final videos = controller.videos;
          
          if (videos.isEmpty) {
            return const Center(
              child: Text('動画が見つかりません。右下のボタンから動画を選択してください。'),
            );
          }
          
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoItem(
                video: video,
                onTap: () {
                  controller.selectVideo(video);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlayerView(),
                    ),
                  );
                },
                onDelete: () {
                  controller.removeVideo(video);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = context.read<VideoController>();
          controller.pickVideo().then((_) {
            if (controller.currentVideo != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayerView(),
                ),
              );
            }
          });
        },
        tooltip: '動画を選択',
        child: const Icon(Icons.add),
      ),
    );
  }
}