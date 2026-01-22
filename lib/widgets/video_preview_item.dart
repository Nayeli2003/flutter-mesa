import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:io';

class VideoPreviewItem extends StatefulWidget {
  final String? path; // Para móvil
  final dynamic bytes; // Para Web

  const VideoPreviewItem({super.key, this.path, this.bytes});

  @override
  State<VideoPreviewItem> createState() => _VideoPreviewItemState();
}

class _VideoPreviewItemState extends State<VideoPreviewItem> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    // Inicialización según plataforma
    if (widget.bytes != null) {
      // Nota: video_player web requiere una URL o un Blob URL. 
      // Para bytes directos en web se usa un truco de URL.createObjectURL
      _videoController = VideoPlayerController.networkUrl(Uri.parse('')); 
    } else {
      _videoController = VideoPlayerController.file(File(widget.path!));
    }

    _videoController.initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          aspectRatio: _videoController.value.aspectRatio,
          autoPlay: false,
          looping: false,
        );
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
        ? AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: Chewie(controller: _chewieController!),
          )
        : const Center(child: CircularProgressIndicator());
  }
}