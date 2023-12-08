import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mvc/router/router.dart';
import 'package:flutter_mvc/video.dart';
import 'package:get/route_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      defaultTransition: Transition.rightToLeft,
      //默认跳转动画
      getPages: RouterPage.routes,
    );
  }
}

const String videoUrl =
    'https://assets.mixkit.co/videos/preview/mixkit-spinning-around-the-earth-29351-large.mp4';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Video'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  insetPadding: const EdgeInsets.only(left: 0),
                  child: Platform.isAndroid
                      ? const VideoPlayerWidget(
                          videoUrl: videoUrl,
                        ) //Android视频播放器
                      : SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width * 9 / 16,
                          child: const UiKitView(
                            viewType:
                                'plugins.flutter.io/custom_platform_view_plugin',
                            creationParams: {
                              'videoUrl': videoUrl,
                            },
                            creationParamsCodec: StandardMessageCodec(),
                          ),
                        ), //iOS视频播放器
                );
              },
            );
          },
          child: const Text('点击播放视频'),
        ),
      ),
    );
  }
}
