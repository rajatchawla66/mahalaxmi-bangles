import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class CropImageDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;

  final String? title;
  final String? instruction;

  const CropImageDialog({
    super.key,
    required this.imageBytes,
    required this.aspectRatio,
    this.title,
    this.instruction,
  });

  @override
  State<CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<CropImageDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.crop, color: Color(0xFF800020)),
                  const SizedBox(width: 8),
                  Text(
                    widget.title ?? 'Crop & Adjust Image',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2A2A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    onCropped: (croppedData) {
                      Navigator.of(context).pop(croppedData);
                    },
                    aspectRatio: widget.aspectRatio,
                    initialSize: 0.9,
                    interactive: true,
                  ),
                  if (_isCropping)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'Cropping...',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.instruction ??
                'Tip: Drag/pinch to position the content fully inside the frame.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isCropping
                        ? null
                        : () {
                            setState(() {
                              _isCropping = true;
                            });
                            _cropController.crop();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF800020), // Maroon brand color
                    ),
                    child: const Text('Apply Crop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
