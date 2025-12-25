import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class TestImagePicker extends StatefulWidget {
  const TestImagePicker({super.key});

  @override
  State<TestImagePicker> createState() => _TestImagePickerState();
}

class _TestImagePickerState extends State<TestImagePicker> {
  Uint8List? _imageBytes;
  String? _error;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null) {
      Uint8List? bytes = result.files.single.bytes;
      if (bytes == null && result.files.single.path != null) {
        bytes = await File(result.files.single.path!).readAsBytes();
      }
      if (bytes != null) {
        setState(() {
          _imageBytes = bytes;
          _error = null;
        });
      } else {
        setState(() => _error = "Greška pri čitanju slike!");
      }
      print("imageBytes: ${_imageBytes?.length}");
      // print("base64Image: ${_base64Image?.substring(0, 30)}...");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Slika test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 220,
                height: 280,
                color: Colors.grey[300],
                child: _imageBytes != null
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Icon(Icons.upload, size: 80),
              ),
            ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
