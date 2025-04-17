import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/video_controller.dart';
import 'video_list_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // ビデオの初期読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoController>().loadVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ダンスプレーヤー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 80),
            const SizedBox(height: 16),
            const Text(
              'ダンス動画プレーヤーへようこそ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '端末内の動画を選択して再生できます',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('ビデオライブラリを開く'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoListView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.video_file),
              label: const Text('新しい動画を選択'),
              onPressed: () {
                final controller = context.read<VideoController>();
                controller.pickVideo().then((_) {
                  if (controller.currentVideo != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VideoListView(),
                      ),
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}