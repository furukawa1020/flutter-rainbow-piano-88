import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

void main() {
  runApp(const PianoApp());
}

class PianoApp extends StatelessWidget {
  const PianoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Sound Piano',
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
  // 88鍵ピアノの鍵盤データ
  final List<Map<String, dynamic>> _keys = [];
  
  @override
  void initState() {
    super.initState();
    _generatePianoKeys();
  }
  
  void _generatePianoKeys() {
    // A0から C8まで88鍵
    final List<String> noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final List<bool> isBlackKey = [false, true, false, true, false, false, true, false, true, false, true, false];
    
    // A0から開始（ピアノの最初の3鍵は A0, A#0, B0）
    _keys.add({'note': 'A', 'octave': 0, 'frequency': 27.5, 'isBlack': false});
    _keys.add({'note': 'A#', 'octave': 0, 'frequency': 29.14, 'isBlack': true});
    _keys.add({'note': 'B', 'octave': 0, 'frequency': 30.87, 'isBlack': false});
    
    // C1からC8まで
    for (int octave = 1; octave <= 8; octave++) {
      for (int i = 0; i < 12; i++) {
        if (octave == 8 && i > 0) break; // C8で終了
        
        final note = noteNames[i];
        final frequency = 261.63 * pow(2, (octave - 4) + (i / 12.0)); // C4 = 261.63Hz基準
        
        _keys.add({
          'note': note,
          'octave': octave,
          'frequency': frequency,
          'isBlack': isBlackKey[i],
        });
      }
    }
  }
  
  // 7色レインボーカラー取得
  Color _getRainbowColor(int index) {
    final colors = [
      Colors.red,     // 赤
      Colors.orange,  // オレンジ
      Colors.yellow,  // 黄色
      Colors.green,   // 緑
      Colors.blue,    // 青
      Colors.indigo,  // 藍
      Colors.purple,  // 紫
    ];
    return colors[index % colors.length];
  }
  
  // シンプルな音響フィードバック
  void _playSimpleSound(int keyIndex) async {
    try {
      // システム音を再生（複数種類を試す）
      await SystemSound.play(SystemSoundType.click);
      
      // 代替音響フィードバック
      await HapticFeedback.lightImpact();
      
      print('Playing key $keyIndex: ${_keys[keyIndex]['note']}${_keys[keyIndex]['octave']} (${_keys[keyIndex]['frequency'].toStringAsFixed(1)}Hz)');
      
    } catch (e) {
      print('Sound error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レインボーピアノ (シンプル音響)'),
        backgroundColor: Colors.deepPurple,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _keys.asMap().entries.map((entry) {
                  final index = entry.key;
                  final keyData = entry.value;
                  final isBlack = keyData['isBlack'];
                  
                  return _PianoKey(
                    keyData: keyData,
                    index: index,
                    isBlack: isBlack,
                    color: _getRainbowColor(index),
                    height: constraints.maxHeight - kToolbarHeight,
                    onPressed: () => _playSimpleSound(index),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PianoKey extends StatefulWidget {
  final Map<String, dynamic> keyData;
  final int index;
  final bool isBlack;
  final Color color;
  final double height;
  final VoidCallback onPressed;

  const _PianoKey({
    required this.keyData,
    required this.index,
    required this.isBlack,
    required this.color,
    required this.height,
    required this.onPressed,
  });

  @override
  State<_PianoKey> createState() => _PianoKeyState();
}

class _PianoKeyState extends State<_PianoKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        widget.onPressed();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.isBlack ? 30 : 50,
        height: widget.height,
        margin: EdgeInsets.symmetric(horizontal: widget.isBlack ? 0 : 1),
        decoration: BoxDecoration(
          color: _isPressed ? widget.color.withOpacity(0.7) : widget.color,
          border: Border.all(
            color: widget.isBlack ? Colors.white : Colors.black,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: _isPressed
              ? [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))]
              : [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 4))],
        ),
        transform: Matrix4.identity()..scale(1.0, _isPressed ? 0.98 : 1.0),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${widget.keyData['note']}${widget.keyData['octave']}',
                style: TextStyle(
                  color: widget.isBlack ? Colors.white : Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.keyData['frequency'].toStringAsFixed(0)}Hz',
                style: TextStyle(
                  color: widget.isBlack ? Colors.white70 : Colors.black54,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
