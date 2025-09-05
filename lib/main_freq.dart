import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const PianoApp());
}

class PianoApp extends StatelessWidget {
  const PianoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Big Piano',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PianoScreen(),
    );
  }
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({Key? key}) : super(key: key);

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<String> _notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  final List<Color> _colors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];

  // 各音階の周波数（Hz）
  final Map<String, double> _frequencies = {
    'C': 261.63,
    'D': 293.66,
    'E': 329.63,
    'F': 349.23,
    'G': 392.00,
    'A': 440.00,
    'B': 493.88,
  };

  // 音声データを生成する関数
  Uint8List _generateWaveform(double frequency, double duration) {
    final int sampleRate = 44100;
    final int samples = (sampleRate * duration).round();
    final List<int> data = [];
    
    for (int i = 0; i < samples; i++) {
      double time = i / sampleRate;
      double amplitude = sin(2 * pi * frequency * time) * 0.3; // 音量を30%に
      int sample = (amplitude * 32767).round();
      
      // 16ビットステレオ（Left/Right同じ値）
      data.add(sample & 0xFF);        // Low byte
      data.add((sample >> 8) & 0xFF); // High byte
      data.add(sample & 0xFF);        // Low byte (Right)
      data.add((sample >> 8) & 0xFF); // High byte (Right)
    }
    
    return Uint8List.fromList(data);
  }

  void _playNote(String note) async {
    try {
      double frequency = _frequencies[note] ?? 440.0;
      
      // WAVヘッダーを作成
      final Uint8List waveData = _generateWaveform(frequency, 0.5); // 0.5秒
      final int dataSize = waveData.length;
      final int fileSize = 44 + dataSize;
      
      final List<int> header = [
        // RIFF header
        0x52, 0x49, 0x46, 0x46, // "RIFF"
        fileSize & 0xFF, (fileSize >> 8) & 0xFF, (fileSize >> 16) & 0xFF, (fileSize >> 24) & 0xFF,
        0x57, 0x41, 0x56, 0x45, // "WAVE"
        
        // fmt chunk
        0x66, 0x6D, 0x74, 0x20, // "fmt "
        16, 0, 0, 0,             // chunk size
        1, 0,                    // audio format (PCM)
        2, 0,                    // channels (stereo)
        0x44, 0xAC, 0, 0,        // sample rate (44100)
        0x10, 0xB1, 2, 0,        // byte rate
        4, 0,                    // block align
        16, 0,                   // bits per sample
        
        // data chunk
        0x64, 0x61, 0x74, 0x61, // "data"
        dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
      ];
      
      final Uint8List wavFile = Uint8List.fromList([...header, ...waveData]);
      
      // BytesSourceを使用して再生
      await _audioPlayer.play(BytesSource(wavFile));
      
    } catch (e) {
      print('音の再生でエラーが発生: $e');
      // フォールバック: システムビープ音
      FlutterBeep.beep();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Big Piano - 周波数生成版'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '🎹 タップして音を楽しもう！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _playNote(_notes[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    height: 80,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _notes[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_frequencies[_notes[index]]!.toStringAsFixed(1)} Hz',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
