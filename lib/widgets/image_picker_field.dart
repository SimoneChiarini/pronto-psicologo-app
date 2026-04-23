import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class ImagePickerField extends StatefulWidget {
  final XFile? selectedImage;
  final String? currentImageUrl;
  final void Function(XFile file) onImageSelected;
  final String label;

  const ImagePickerField({
    super.key,
    required this.onImageSelected,
    this.selectedImage,
    this.currentImageUrl,
    this.label = 'Foto profilo',
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.selectedImage != null) _loadBytes(widget.selectedImage!);
  }

  @override
  void didUpdateWidget(ImagePickerField old) {
    super.didUpdateWidget(old);
    if (widget.selectedImage != old.selectedImage && widget.selectedImage != null) {
      _loadBytes(widget.selectedImage!);
    }
    if (widget.selectedImage == null) _imageBytes = null;
  }

  Future<void> _loadBytes(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) widget.onImageSelected(picked);
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Scegli dalla galleria'),
              onTap: () { Navigator.pop(ctx); _pick(ImageSource.gallery); },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Scatta una foto'),
                onTap: () { Navigator.pop(ctx); _pick(ImageSource.camera); },
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider? get _imageProvider {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return NetworkImage(widget.currentImageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showSourceDialog,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.glassBg,
                backgroundImage: provider,
                child: provider == null
                    ? const Icon(Icons.person_rounded, size: 52, color: AppColors.textTertiary)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.bgInverse,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.textInverse),
              ),
            ],
          ),
        ),
        if (widget.selectedImage != null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Immagine selezionata',
              style: TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ),
      ],
    );
  }
}
