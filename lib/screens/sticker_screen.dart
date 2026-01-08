import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:pasteboard/pasteboard.dart';

class StickerGalleryScreen extends StatefulWidget {
  const StickerGalleryScreen({Key? key}) : super(key: key);

  @override
  State<StickerGalleryScreen> createState() => _StickerGalleryScreenState();
}

class _StickerGalleryScreenState extends State<StickerGalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 Tabs now
    _openStickerBox();
  }

  // Ensure the box is open before we try to use it
  Future<void> _openStickerBox() async {
    if (!Hive.isBoxOpen('stickerBox')) {
      await Hive.openBox<String>('stickerBox');
    }
    setState(() {}); // Rebuild once box is ready
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Sticker Collection", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Scrollable tabs in case of overflow
          labelColor: Colors.pinkAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pinkAccent,
          tabs: const [
            Tab(text: "My Stickers"), // NEW TAB
            Tab(text: "Emotions"),
            Tab(text: "Nature"),
            Tab(text: "Activities"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _CustomStickerPage(), // Custom Upload Page
          const _EmojiStickerGrid(stickers: ['🥰', '🤩', '🥳', '😎', '🥺', '🤯', '😴', '😡', '👻', '👽', '🤖', '💩']),
          const _EmojiStickerGrid(stickers: ['🌸', '🍄', '🌵', '🌴', '🌈', '☀️', '🌙', '❄️', '🔥', '🌊', '🍀', '🍁']),
          const _EmojiStickerGrid(stickers: ['🎨', '🎮', '🎸', '📚', '🧘‍♀️', '🚴‍♂️', '🏆', '🍕', '🚀', '✈️', '💡', '💊']),
        ],
      ),
    );
  }
}
// ==================================================
// PAGE 1: CUSTOM STICKER UPLOADER
// ==================================================
class _CustomStickerPage extends StatefulWidget {
  const _CustomStickerPage({Key? key}) : super(key: key);

  @override
  State<_CustomStickerPage> createState() => _CustomStickerPageState();
}

class _CustomStickerPageState extends State<_CustomStickerPage> {

  Future<void> _pickAndCreateSticker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final String localPath = '${appDir.path}/$fileName';

      await File(image.path).copy(localPath);

      var box = Hive.box<String>('stickerBox');
      box.add(localPath);
      setState(() {});
    }
  }

  void _deleteSticker(int index) {
    var box = Hive.box<String>('stickerBox');
    box.deleteAt(index);
    setState(() {});
  }

  // NEW: Logic to copy image bytes to clipboard
  Future<void> _copyStickerToClipboard(String path) async {
    try {
      // 1. Read the file as bytes
      final bytes = await File(path).readAsBytes();

      // 2. Write bytes to the OS Clipboard
      await Pasteboard.writeImage(bytes);

      // 3. Success Message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sticker copied! You can paste it now."),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error copying sticker: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('stickerBox')) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box<String>('stickerBox').listenable(),
      builder: (context, Box<String> box, _) {
        List<String> customStickers = box.values.toList();

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
          ),
          itemCount: customStickers.length + 1,
          itemBuilder: (context, index) {

            // Render Add Button
            if (index == 0) {
              return GestureDetector(
                onTap: _pickAndCreateSticker,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 35, color: Colors.pinkAccent.shade100),
                      const SizedBox(height: 5),
                      const Text("New", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }

            // Render Sticker
            final int stickerIndex = index - 1;
            final stickerPath = customStickers[stickerIndex];

            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  // TRIGGER COPY ON TAP
                  onTap: () => _copyStickerToClipboard(stickerPath),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      // Removed background color to allow transparency
                    ),
                    child: Center(
                      child: Image.file(
                        File(stickerPath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Delete Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _deleteSticker(stickerIndex),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
// ==================================================
// PAGE 2-4: EMOJI STICKERS (Reusable Grid)
// ==================================================
class _EmojiStickerGrid extends StatelessWidget {
  final List<String> stickers;

  const _EmojiStickerGrid({Key? key, required this.stickers}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.0,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        return _StickerItem(emoji: stickers[index]);
      },
    );
  }
}

class _StickerItem extends StatelessWidget {
  final String emoji;

  const _StickerItem({Key? key, required this.emoji}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: emoji));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied $emoji to clipboard!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 50),
          ),
        ),
      ),
    );
  }
}