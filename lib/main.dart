import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const PianoApp());
}

class PianoApp extends StatelessWidget {
  const PianoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Big Piano',
      theme: ThemeData(primarySwatch: Colors.blue),
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

  // 88鍵ピアノの鍵盤データ
  final List<Map<String, dynamic>> _keys = [];

  @override
  void initState() {
    super.initState();
    _generatePianoKeys();
  }

  void _generatePianoKeys() {
    // A0から C8まで88鍵
    final List<String> noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final List<bool> isBlackKey = [
      false,
      true,
      false,
      true,
      false,
      false,
      true,
      false,
      true,
      false,
      true,
      false,
    ];

    // A0 = 27.5 Hz から開始
    double baseFreq = 27.5; // A0
    int keyIndex = 0;

    // A0, A#0, B0 (3鍵)
    for (int i = 9; i < 12; i++) {
      _keys.add({
        'note': '${noteNames[i]}0',
        'frequency': baseFreq * pow(2, keyIndex / 12.0),
        'isBlack': isBlackKey[i],
        'color': _getKeyColor(keyIndex, isBlackKey[i]),
      });
      keyIndex++;
    }

    // C1からC8まで (84鍵)
    for (int octave = 1; octave <= 8; octave++) {
      int endIndex = (octave == 8) ? 1 : 12; // C8で終了
      for (int i = 0; i < endIndex; i++) {
        _keys.add({
          'note': '${noteNames[i]}$octave',
          'frequency': baseFreq * pow(2, keyIndex / 12.0),
          'isBlack': isBlackKey[i],
          'color': _getKeyColor(keyIndex, isBlackKey[i]),
        });
        keyIndex++;
      }
    }
  }

  Color _getKeyColor(int index, bool isBlack) {
    if (isBlack) {
      // 黒鍵用の暗いカラフル色
      final List<Color> blackColors = [
        Colors.purple[900]!,
        Colors.indigo[900]!,
        Colors.blue[900]!,
        Colors.teal[900]!,
        Colors.green[900]!,
        Colors.orange[900]!,
        Colors.red[900]!,
      ];
      return blackColors[index % blackColors.length];
    } else {
      // 白鍵用の明るいカラフル色
      final List<Color> whiteColors = [
        Colors.red[200]!,
        Colors.orange[200]!,
        Colors.yellow[200]!,
        Colors.green[200]!,
        Colors.blue[200]!,
        Colors.indigo[200]!,
        Colors.purple[200]!,
        Colors.pink[200]!,
        Colors.cyan[200]!,
        Colors.lime[200]!,
        Colors.amber[200]!,
        Colors.teal[200]!,
      ];
      return whiteColors[index % whiteColors.length];
    }
  }

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
      data.add(sample & 0xFF); // Low byte
      data.add((sample >> 8) & 0xFF); // High byte
      data.add(sample & 0xFF); // Low byte (Right)
      data.add((sample >> 8) & 0xFF); // High byte (Right)
    }

    return Uint8List.fromList(data);
  }

  void _playNote(String note) async {
    try {
      // 該当する鍵盤データを検索
      final keyData = _keys.firstWhere(
        (key) => key['note'] == note,
        orElse: () => {'frequency': 440.0},
      );

      double frequency = keyData['frequency'];

      // 簡単な正弦波データを生成
      final int sampleRate = 8000;
      final double duration = 0.5;
      final int samples = (sampleRate * duration).round();
      final List<int> data = [];

      for (int i = 0; i < samples; i++) {
        double time = i / sampleRate;
        double amplitude = sin(2 * pi * frequency * time) * 0.5;
        int sample = (amplitude * 127 + 128).round();
        data.add(sample);
      }

      // WAVヘッダーを作成（8ビット、モノラル）
      final int dataSize = data.length;
      final int fileSize = 44 + dataSize;

      final List<int> header = [
        // RIFF header
        0x52, 0x49, 0x46, 0x46, // "RIFF"
        fileSize & 0xFF,
        (fileSize >> 8) & 0xFF,
        (fileSize >> 16) & 0xFF,
        (fileSize >> 24) & 0xFF,
        0x57, 0x41, 0x56, 0x45, // "WAVE"
        // fmt chunk
        0x66, 0x6D, 0x74, 0x20, // "fmt "
        16, 0, 0, 0,
        1, 0,
        1, 0,
        0x40, 0x1F, 0, 0,
        0x40, 0x1F, 0, 0,
        1, 0,
        8, 0,

        // data chunk
        0x64, 0x61, 0x74, 0x61, // "data"
        dataSize & 0xFF,
        (dataSize >> 8) & 0xFF,
        (dataSize >> 16) & 0xFF,
        (dataSize >> 24) & 0xFF,
      ];

      final Uint8List wavFile = Uint8List.fromList([...header, ...data]);

      // 一時ファイルに保存してから再生
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_note_$note.wav');
      await tempFile.writeAsBytes(wavFile);

      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      print('音を再生しました: $note ($frequency Hz)');
    } catch (e) {
      print('音の再生でエラーが発生: $e');
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 100);
      }
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
        title: const Text('Big Piano - 88鍵フルサイズ'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '🎹 88鍵ピアノ - タップして演奏しよう！',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              child: Stack(
                children: [
                  // 白鍵のレイヤー
                  Row(
                    children: _keys
                        .where((key) => !key['isBlack'])
                        .map((key) => _buildWhiteKey(key))
                        .toList(),
                  ),
                  // 黒鍵のレイヤー（白鍵の上に配置）
                  Positioned.fill(child: Row(children: _buildBlackKeys())),
                ],
              ),
            ),
          ),
          // 演奏情報表示
          Container(
            height: 40,
            color: Colors.grey[800],
            child: const Center(
              child: Text(
                'A0 (27.5Hz) から C8 (4186Hz) まで88鍵',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteKey(Map<String, dynamic> keyData) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _playNote(keyData['note']),
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: keyData['color'],
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: [
                    Text(
                      keyData['note'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${keyData['frequency'].toStringAsFixed(1)}Hz',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBlackKeys() {
    final List<Widget> blackKeys = [];
    final whiteKeys = _keys.where((key) => !key['isBlack']).toList();

    for (int i = 0; i < whiteKeys.length - 1; i++) {
      final currentWhite = whiteKeys[i];
      final nextWhite = whiteKeys[i + 1];

      // 現在の白鍵と次の白鍵の間に黒鍵があるかチェック
      final blackKey = _keys.firstWhere(
        (key) =>
            key['isBlack'] &&
            key['frequency'] > currentWhite['frequency'] &&
            key['frequency'] < nextWhite['frequency'],
        orElse: () => {},
      );

      if (blackKey.isNotEmpty) {
        blackKeys.add(_buildBlackKey(blackKey, i));
      } else {
        blackKeys.add(Container()); // 空のスペース
      }
    }

    return blackKeys;
  }

  Widget _buildBlackKey(Map<String, dynamic> keyData, int position) {
    final whiteKeyCount = _keys.where((key) => !key['isBlack']).length;
    final keyWidth = MediaQuery.of(context).size.width / whiteKeyCount;

    return Positioned(
      left: keyWidth * (position + 0.7),
      top: 0,
      child: GestureDetector(
        onTap: () => _playNote(keyData['note']),
        child: Container(
          width: keyWidth * 0.6,
          height: MediaQuery.of(context).size.height * 0.6,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: keyData['color'],
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  children: [
                    Text(
                      keyData['note'],
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${keyData['frequency'].toStringAsFixed(1)}Hz',
                      style: const TextStyle(
                        fontSize: 6,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
