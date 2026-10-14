import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;
  double _exposureOffset = 0.0;
  FlashMode _flashMode = FlashMode.off;
  
  int _selectedFilterIndex = 0;
  final List<Map<String, dynamic>> _colorGradingFilters = [
    {
      'name': 'NATURAL',
      'matrix': [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'name': 'CINEMATIC LOG',
      'matrix': [
        0.9, 0.1, 0.0, 0.0, 10.0,
        0.0, 0.85, 0.1, 0.0, 15.0,
        0.1, 0.1, 0.9, 0.0, 20.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'name': 'WARM GOLD',
      'matrix': [
        1.2, 0.1, 0.0, 0.0, 10.0,
        0.1, 1.0, 0.0, 0.0, 5.0,
        0.0, 0.0, 0.8, 0.0, -10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'name': 'MOODY TEAL & ORANGE',
      'matrix': [
        1.3, -0.1, -0.1, 0.0, 0.0,
        -0.1, 1.1, 0.1, 0.0, 0.0,
        -0.2, 0.2, 1.4, 0.0, 10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
    {
      'name': 'COLD MONO',
      'matrix': [
        0.33, 0.33, 0.33, 0.0, -20.0,
        0.33, 0.33, 0.33, 0.0, -10.0,
        0.33, 0.33, 0.33, 0.0, 10.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ]
    },
  ];

  String? _lastCapturedImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller.initialize();
      _maxZoom = await _controller.getMaxZoomLevel();
      _minZoom = await _controller.getMinZoomLevel();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) return;

    try {
      final XFile photo = await _controller.takePicture();
      setState(() {
        _lastCapturedImagePath = photo.path;
      });
    } catch (e) {
      debugPrint("Capture Error: $e");
    }
  }

  void _toggleCamera() {
    if (widget.cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _initCamera(_selectedCameraIndex);
  }

  void _toggleFlash() {
    setState(() {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        _flashMode = FlashMode.auto;
      } else {
        _flashMode = FlashMode.off;
      }
      _controller.setFlashMode(_flashMode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: (details) async {
              double zoom = (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
              await _controller.setZoomLevel(zoom);
              setState(() => _currentZoom = zoom);
            },
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(
                _colorGradingFilters[_selectedFilterIndex]['matrix'],
              ),
              child: Center(
                child: CameraPreview(_controller),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: GlassmorphicContainer(
              width: MediaQuery.of(context).size.width - 40,
              height: 60,
              borderRadius: 30,
              blur: 15,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
              ),
              borderGradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.always
                          ? LucideIcons.zap
                          : _flashMode == FlashMode.auto
                              ? LucideIcons.zapOff
                              : LucideIcons.slash,
                      color: _flashMode != FlashMode.off ? Colors.amber : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.refreshCw, color: Colors.white),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5, end: 0),
          ),
          Positioned(
            right: 15,
            top: MediaQuery.of(context).size.height * 0.25,
            child: RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: 200,
                child: Slider(
                  value: _exposureOffset,
                  min: -2.0,
                  max: 2.0,
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white24,
                  onChanged: (val) async {
                    setState(() => _exposureOffset = val);
                    await _controller.setExposureOffset(val);
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 30, top: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: min,
                children: [
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _colorGradingFilters.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedFilterIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilterIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber : Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.white30,
                              ),
                            ),
                            child: Text(
                              _colorGradingFilters[index]['name'],
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _lastCapturedImagePath != null
                              ? Image.file(File(_lastCapturedImagePath!), fit: BoxFit.cover)
                              : const Icon(LucideIcons.image, color: Colors.white54),
                        ),
                      ),
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
