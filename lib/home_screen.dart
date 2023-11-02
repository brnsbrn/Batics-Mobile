import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  bool _imageUploaded = false; // Menandakan apakah gambar sudah diunggah
  String _predictedMotif = ''; // Untuk menampilkan hasil prediksi

  Future _getImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _imageUploaded = true; // Setelah gambar diunggah, ubah status menjadi true
        _predictedMotif = ''; // Bersihkan hasil prediksi
      });
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    try {
      var uri = Uri.parse('http://10.0.2.2:5000/predict'); 
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);

        String className = data['class_name'];
        double confidence = double.parse(data['confidence']);

        setState(() {
          _predictedMotif = 'Motif: $className\nAkurasi: ${confidence.toStringAsFixed(2)}';
        });
      } else {
        setState(() {
          _predictedMotif = 'Terjadi kesalahan saat menghubungi server.';
        });
      }
    } catch (e) {
      setState(() {
        _predictedMotif = 'Terjadi kesalahan: $e';
      });
    }
  }

  void _clearImage() {
    setState(() {
      _image = null;
      _imageUploaded = false;
      _predictedMotif = '';
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeri'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Kamera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Klasifikasi Motif Batik'),
        backgroundColor: Color(0xFFFFD700), 
      ),
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20.0),
              _image == null
                  ? Container(
                      width: 200.0,
                      height: 200.0,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey, 
                          width: 2.0, // Lebar border
                        ),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 100.0,
                        color: Colors.black, // Warna hitam
                      ),
                    )
                  : Container(
                      width: 200.0,
                      height: 200.0,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black, 
                          width: 2.0, 
                        ),
                      ),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
              SizedBox(height: 20.0),
              Text(
                'Unggah Gambar Batik',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, 
                  fontFamily: 'CarthagePro',
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _imageUploaded
                        ? () {
                            // Jika gambar sudah diunggah, jalankan fungsi prediksi
                            _classifyImage(_image!);
                          }
                        : _showImageSourceDialog,
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFFFFD700), 
                    ),
                    child: Text(
                      _imageUploaded ? 'Lihat Motif' : 'Unggah Gambar',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white, // Warna teks putih
                        fontFamily: 'CarthagePro',
                      ),
                    ),
                  ),
                  SizedBox(width: 20.0), // Add some space between the buttons
                  if (_imageUploaded)
                    ElevatedButton(
                      onPressed: _clearImage,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red,
                      ),
                      child: Text(
                        'Ganti Gambar',
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.white,
                          fontFamily: 'CarthagePro',
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.0),
              _predictedMotif.isNotEmpty
                  ? Card(
                      color: Color(0xFFFFD700), // Warna latar belakang emas
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _predictedMotif,
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                            fontFamily: 'CarthagePro',
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
