import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../data/api_client.dart';
import 'common.dart';

/// Sample MP4 used when a post's `video` is the seed marker `sample`.
const kSampleVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

/// Real video player with placeholder poster & graceful failure.
class VideoBox extends StatefulWidget {
  final String source;
  final String seed;
  final bool autoPlay, loop, muted;
  final ValueChanged<VideoPlayerController>? onReady;
  const VideoBox({super.key, required this.source, required this.seed, this.autoPlay = false, this.loop = false, this.muted = false, this.onReady});

  @override
  State<VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<VideoBox> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final src = widget.source == 'sample' ? kSampleVideoUrl : ApiClient.instance.resolve(widget.source);
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(src));
      await c.initialize();
      await c.setLooping(widget.loop);
      await c.setVolume(widget.muted ? 0 : 1);
      if (widget.autoPlay) await c.play();
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() => _c = c);
      widget.onReady?.call(c);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return Stack(fit: StackFit.expand, children: [
        MedPlaceholder(seed: widget.seed, radius: 0),
        Center(
          child: _failed
              ? const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 36)
              : const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        ),
      ]);
    }
    return GestureDetector(
      onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
      child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: Colors.black, child: FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)))),
        ValueListenableBuilder(
          valueListenable: c,
          builder: (_, v, _) => v.isPlaying
              ? const SizedBox.shrink()
              : Center(
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.85)),
                    child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF12A594), size: 32),
                  ),
                ),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFF12A594), bufferedColor: Colors.white38, backgroundColor: Colors.white24)),
        ),
      ]),
    );
  }
}
