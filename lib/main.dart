import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'controllers/video_controller.dart';
import 'services/file_service.dart';
import 'views/home_view.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // サービスの登録
  getIt.registerLazySingleton<IFileService>(() => FileService());
  
  // コントローラーの登録
  getIt.registerLazySingleton<VideoController>(
    () => VideoController(getIt<IFileService>()),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VideoController>(
          create: (_) => getIt<VideoController>(),
        ),
      ],
      child: MaterialApp(
        title: 'ダンスプレーヤー',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeView(),
      ),
    );
  }
}
