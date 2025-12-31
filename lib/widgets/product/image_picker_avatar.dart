import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A circular avatar widget with image picker functionality.
///
/// This widget displays a circular image with a tap-to-select gesture
/// for picking images from the gallery.
///
/// Example:
/// ```dart
/// ImagePickerAvatar(
///   initialImage: _imageFile,
///   onImageChanged: (file) => setState(() => _imageFile = file),
///   radius: 50,
/// )
/// ```
class ImagePickerAvatar extends StatefulWidget {
  /// The initial image to display
  final File? initialImage;

  /// Callback when image is changed
  final void Function(File?) onImageChanged;

  /// The radius of the circular avatar
  final double radius;

  /// Background color when no image is set
  final Color? backgroundColor;

  /// Icon to display when no image is set
  final IconData placeholderIcon;

  /// Size of the placeholder icon
  final double placeholderIconSize;

  /// Whether to show a loading indicator while picking
  final bool showLoadingIndicator;

  /// Creates an image picker avatar
  const ImagePickerAvatar({
    super.key,
    this.initialImage,
    required this.onImageChanged,
    this.radius = 50.0,
    this.backgroundColor,
    this.placeholderIcon = Icons.add_a_photo,
    this.placeholderIconSize = 30.0,
    this.showLoadingIndicator = true,
  });

  @override
  State<ImagePickerAvatar> createState() => _ImagePickerAvatarState();
}

class _ImagePickerAvatarState extends State<ImagePickerAvatar> {
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.initialImage;
  }

  @override
  void didUpdateWidget(ImagePickerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialImage != oldWidget.initialImage) {
      setState(() {
        _imageFile = widget.initialImage;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _imageFile = imageFile;
          _isLoading = false;
        });
        widget.onImageChanged(imageFile);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? 
                    theme.colorScheme.surfaceContainerHighest;

    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: bgColor,
        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
        child: _isLoading && widget.showLoadingIndicator
            ? const CircularProgressIndicator()
            : _imageFile == null
                ? Icon(
                    widget.placeholderIcon,
                    size: widget.placeholderIconSize,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
      ),
    );
  }
}
