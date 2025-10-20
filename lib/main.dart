import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
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

// 寿司データクラス
class Sushi {
  final String emoji;
  final int price; // 100, 150, 200円
  final Color plateColor;
  final int keyIndex; // どの鍵盤を押すか
  double position; // 画面上の位置（0.0～1.0）
  bool isHit; // 押されたかどうか

  Sushi({
    required this.emoji,
    required this.price,
    required this.plateColor,
    required this.keyIndex,
    this.position = 0.0,
    this.isHit = false,
  });
}

// 簡単な曲データ（複数の曲を収録）
class SongData {
  // きらきら星
  static List<Map<String, dynamic>> getKirakiraBoshi() {
    const int baseKey = 39; // C4を基準
    return [
      // きらきら光る
      {'time': 0.0, 'key': baseKey, 'note': 'C'},
      {'time': 0.5, 'key': baseKey, 'note': 'C'},
      {'time': 1.0, 'key': baseKey + 7, 'note': 'G'},
      {'time': 1.5, 'key': baseKey + 7, 'note': 'G'},
      {'time': 2.0, 'key': baseKey + 9, 'note': 'A'},
      {'time': 2.5, 'key': baseKey + 9, 'note': 'A'},
      {'time': 3.0, 'key': baseKey + 7, 'note': 'G'},

      // おそらのほしよ
      {'time': 4.0, 'key': baseKey + 5, 'note': 'F'},
      {'time': 4.5, 'key': baseKey + 5, 'note': 'F'},
      {'time': 5.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 5.5, 'key': baseKey + 4, 'note': 'E'},
      {'time': 6.0, 'key': baseKey + 2, 'note': 'D'},
      {'time': 6.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 7.0, 'key': baseKey, 'note': 'C'},
    ];
  }

  // ちょうちょう
  static List<Map<String, dynamic>> getChoucho() {
    const int baseKey = 39; // C4
    return [
      {'time': 0.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 0.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 1.0, 'key': baseKey, 'note': 'C'},
      {'time': 1.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 2.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 2.5, 'key': baseKey + 4, 'note': 'E'},
      {'time': 3.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 4.0, 'key': baseKey + 2, 'note': 'D'},
      {'time': 4.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 5.0, 'key': baseKey + 2, 'note': 'D'},
      {'time': 6.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 6.5, 'key': baseKey + 5, 'note': 'F'},
      {'time': 7.0, 'key': baseKey + 4, 'note': 'E'},
    ];
  }

  // かえるのうた
  static List<Map<String, dynamic>> getKaeruNoUta() {
    const int baseKey = 39; // C4
    return [
      {'time': 0.0, 'key': baseKey, 'note': 'C'},
      {'time': 0.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 1.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 1.5, 'key': baseKey + 5, 'note': 'F'},
      {'time': 2.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 2.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 3.0, 'key': baseKey, 'note': 'C'},
      {'time': 4.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 4.5, 'key': baseKey + 5, 'note': 'F'},
      {'time': 5.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 5.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 6.0, 'key': baseKey, 'note': 'C'},
    ];
  }

  // メリーさんの羊
  static List<Map<String, dynamic>> getMaryHadALittleLamb() {
    const int baseKey = 39; // C4
    return [
      {'time': 0.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 0.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 1.0, 'key': baseKey, 'note': 'C'},
      {'time': 1.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 2.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 2.5, 'key': baseKey + 4, 'note': 'E'},
      {'time': 3.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 4.0, 'key': baseKey + 2, 'note': 'D'},
      {'time': 4.5, 'key': baseKey + 2, 'note': 'D'},
      {'time': 5.0, 'key': baseKey + 2, 'note': 'D'},
      {'time': 6.0, 'key': baseKey + 4, 'note': 'E'},
      {'time': 6.5, 'key': baseKey + 7, 'note': 'G'},
      {'time': 7.0, 'key': baseKey + 7, 'note': 'G'},
    ];
  }

  // 全曲リスト
  static List<Map<String, dynamic>> getAllSongs() {
    return [
      {'name': '⭐ きらきら星', 'data': getKirakiraBoshi(), 'duration': 8.0},
      {'name': '🦋 ちょうちょう', 'data': getChoucho(), 'duration': 8.0},
      {'name': '🐸 かえるのうた', 'data': getKaeruNoUta(), 'duration': 7.0},
      {'name': '🐑 メリーさんの羊', 'data': getMaryHadALittleLamb(), 'duration': 8.0},
    ];
  }
}

class PianoScreen extends StatefulWidget {
  const PianoScreen({Key? key}) : super(key: key);

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen>
    with TickerProviderStateMixin {
  // 🚀 究極最適化: 各鍵盤に専用AudioPlayer（88個）
  final List<AudioPlayer> _audioPlayers = [];
  
  // 事前生成された音声ファイルパス
  final Map<String, String> _audioFileCache = {};
  bool _isAudioCacheReady = false;

  // 88鍵ピアノの鍵盤データ
  final List<Map<String, dynamic>> _keys = [];

  // ゲームモード関連
  bool _isGameMode = false;
  final List<Sushi> _sushiList = [];
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  Timer? _gameTimer;
  double _gameTime = 0.0;
  bool _isPlaying = false;

  // 光るエフェクト用
  final Map<int, AnimationController> _glowControllers = {};
  final Map<int, bool> _isKeyGlowing = {};

  @override
  void initState() {
    super.initState();
    _generatePianoKeys();
    _initializeAudioPlayers();
    _initializeGlowControllers();
    _preGenerateAllAudioFiles();
  }

  void _initializeAudioPlayers() {
    // 88個の専用プレイヤー（各鍵盤に1つ）
    for (int i = 0; i < 88; i++) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop); // 低遅延モード
      _audioPlayers.add(player);
    }
  }

  void _initializeGlowControllers() {
    for (int i = 0; i < 88; i++) {
      _glowControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _isKeyGlowing[i] = false;
    }
  }

  // 🎵 全鍵盤の音声を事前生成
  Future<void> _preGenerateAllAudioFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();

      for (var i = 0; i < _keys.length; i++) {
        final keyData = _keys[i];
        final note = keyData['note'];
        final frequency = keyData['frequency'];

        // 最適化された音声データ生成
        final wavFile = _generateOptimizedWaveform(frequency, 0.8);
        
        // ファイルに保存
        final filePath = '${tempDir.path}/piano_$note.wav';
        final file = File(filePath);
        await file.writeAsBytes(wavFile);

        _audioFileCache[note] = filePath;
      }

      setState(() {
        _isAudioCacheReady = true;
      });

      print('✅ 全88鍵の音声ファイル生成完了！');
    } catch (e) {
      print('⚠️ 音声生成エラー: $e');
    }
  }

  // 最適化された波形生成
  Uint8List _generateOptimizedWaveform(double frequency, double duration) {
    final int sampleRate = 44100;
    final int samples = (sampleRate * duration).round();
    final List<int> data = [];

    for (int i = 0; i < samples; i++) {
      double time = i / sampleRate;

      // ピアノらしい音色（倍音合成）
      double amplitude = 
        sin(2 * pi * frequency * time) * 0.6 +
        sin(2 * pi * frequency * 2 * time) * 0.25 +
        sin(2 * pi * frequency * 3 * time) * 0.15 +
        sin(2 * pi * frequency * 4 * time) * 0.08;

      // 自然な減衰
      double envelope = exp(-time * 1.5);
      amplitude *= envelope;

      int sample = (amplitude * 127 + 128).round().clamp(0, 255);
      data.add(sample);
    }

    // WAVヘッダー
    final int dataSize = data.length;
    final int fileSize = 44 + dataSize;

    final List<int> header = [
      0x52, 0x49, 0x46, 0x46,
      fileSize & 0xFF, (fileSize >> 8) & 0xFF, (fileSize >> 16) & 0xFF, (fileSize >> 24) & 0xFF,
      0x57, 0x41, 0x56, 0x45,
      0x66, 0x6D, 0x74, 0x20,
      16, 0, 0, 0, 1, 0, 1, 0,
      0x44, 0xAC, 0, 0, 0x44, 0xAC, 0, 0,
      1, 0, 8, 0,
      0x64, 0x61, 0x74, 0x61,
      dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];

    return Uint8List.fromList([...header, ...data]);
  }

  void _generatePianoKeys() {
    final int samples = (sampleRate * duration).round();
    final List<int> data = [];

    for (int i = 0; i < samples; i++) {
      double time = i / sampleRate;

      // 基音 + 倍音で豊かな音色
      double amplitude = sin(2 * pi * frequency * time) * 0.5 + // 基音
          sin(2 * pi * frequency * 2 * time) * 0.2 + // 2倍音
          sin(2 * pi * frequency * 3 * time) * 0.1 + // 3倍音
          sin(2 * pi * frequency * 4 * time) * 0.05; // 4倍音

      // エンベロープ（フェードアウト）
      double envelope = exp(-time * 2);
      amplitude *= envelope;

      int sample = (amplitude * 127 + 128).round().clamp(0, 255);
      data.add(sample);
    }

    // WAVヘッダー生成
    final int dataSize = data.length;
    final int fileSize = 44 + dataSize;

    final List<int> header = [
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      fileSize & 0xFF, (fileSize >> 8) & 0xFF, (fileSize >> 16) & 0xFF,
      (fileSize >> 24) & 0xFF,
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0,
      1, 0, 1, 0,
      0x44, 0xAC, 0, 0, // 44100 Hz
      0x44, 0xAC, 0, 0,
      1, 0, 8, 0,
      0x64, 0x61, 0x74, 0x61, // "data"
      dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF,
      (dataSize >> 24) & 0xFF,
    ];

    return Uint8List.fromList([...header, ...data]);
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

  // 🚀 超高速音声再生（事前生成ファイルを使用）
  void _playNote(String note) async {
    if (!_isAudioCacheReady || !_audioCache.containsKey(note)) {
      // キャッシュ準備中の場合は簡易再生
      Vibration.vibrate(duration: 30);
      return;
    }

    try {
      // プールから次のプレイヤーを取得（ラウンドロビン方式）
      final player = _audioPlayerPool[_currentPlayerIndex];
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayerPool.length;

      // 既存の再生を停止（高速切り替え）
      await player.stop();

      // キャッシュされたファイルを即座に再生
      await player.play(DeviceFileSource(_audioCache[note]!));

      // 触覚フィードバック
      Vibration.vibrate(duration: 20);
    } catch (e) {
      print('⚠️ 音声再生エラー: $e');
    }
  }

  // ゲームモード関連メソッド
  void _toggleGameMode() {
    setState(() {
      _isGameMode = !_isGameMode;
      if (_isGameMode) {
        _startGame();
      } else {
        _stopGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _gameTime = 0.0;
      _sushiList.clear();
    });

    _spawnSushiFromSong();

    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _gameTime += 0.05;

        for (var sushi in _sushiList) {
          sushi.position += 0.008;
        }

        _sushiList.removeWhere((sushi) {
          if (sushi.position > 1.2 && !sushi.isHit) {
            _combo = 0;
            return true;
          }
          return sushi.position > 1.5;
        });

        if (_gameTime > 10.0 && _sushiList.isEmpty) {
          _endGame();
        }
      });
    });
  }

  void _stopGame() {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _sushiList.clear();
      for (var i = 0; i < 88; i++) {
        _isKeyGlowing[i] = false;
      }
    });
  }

  void _spawnSushiFromSong() {
    final song = SongData.getKirakiraBoshi();
    final List<String> sushiEmojis = ['🍣', '🍤', '🍱', '🐟', '🦑', '🦐'];
    final Random random = Random();

    for (var note in song) {
      Timer(Duration(milliseconds: (note['time'] * 1000).toInt()), () {
        if (!_isPlaying || !mounted) return;

        int price = [100, 150, 200][random.nextInt(3)];
        Color plateColor;

        if (price == 100) {
          plateColor = Colors.grey[300]!;
        } else if (price == 150) {
          plateColor = Colors.blue[300]!;
        } else {
          plateColor = Colors.yellow[300]!;
        }

        setState(() {
          _sushiList.add(Sushi(
            emoji: sushiEmojis[random.nextInt(sushiEmojis.length)],
            price: price,
            plateColor: plateColor,
            keyIndex: note['key'],
            position: 0.0,
          ));

          _makeKeyGlow(note['key']);
        });
      });
    }
  }

  void _makeKeyGlow(int keyIndex) {
    if (keyIndex < 0 || keyIndex >= 88) return;
    setState(() {
      _isKeyGlowing[keyIndex] = true;
    });
    _glowControllers[keyIndex]?.forward(from: 0.0);

    Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isKeyGlowing[keyIndex] = false;
      });
    });
  }

  void _onKeyPressedInGame(int keyIndex) {
    final targetSushi = _sushiList.firstWhere(
      (sushi) =>
          sushi.keyIndex == keyIndex &&
          !sushi.isHit &&
          sushi.position > 0.7 &&
          sushi.position < 0.95,
      orElse: () => Sushi(
        emoji: '',
        price: 0,
        plateColor: Colors.transparent,
        keyIndex: -1,
      ),
    );

    if (targetSushi.keyIndex != -1) {
      setState(() {
        targetSushi.isHit = true;
        _score += targetSushi.price;
        _combo++;
        if (_combo > _maxCombo) {
          _maxCombo = _combo;
        }
      });

      _playNote(_keys[keyIndex]['note']);
      Vibration.vibrate(duration: 50);
    } else {
      setState(() {
        _combo = 0;
      });
      _playNote(_keys[keyIndex]['note']);
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          '🎉 お会計',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¥$_score',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '最大コンボ: $_maxCombo',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _getScoreComment(),
              style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('もう一回'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopGame();
            },
            child: const Text('フリー演奏に戻る'),
          ),
        ],
      ),
    );
  }

  String _getScoreComment() {
    if (_score >= 2000) return '🏆 寿司職人マスター！';
    if (_score >= 1500) return '🥇 常連客レベル！';
    if (_score >= 1000) return '🥈 良い腕前です！';
    if (_score >= 500) return '🥉 まずまずですね！';
    return '💪 もっと練習しよう！';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    // 全てのAudioPlayerを破棄
    for (var player in _audioPlayerPool) {
      player.dispose();
    }
    for (var controller in _glowControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGameMode ? '🍣 寿司ピアノゲーム' : 'Big Piano - 88鍵フルサイズ'),
        backgroundColor: _isGameMode ? Colors.red[700] : Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_isGameMode ? Icons.music_note : Icons.sports_esports),
            onPressed: _toggleGameMode,
            tooltip: _isGameMode ? 'フリー演奏モード' : 'ゲームモード',
          ),
        ],
      ),
      body: Column(
        children: [
          // ゲームモード時は上部に寿司レーンとスコア表示
          if (_isGameMode) ...[
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.grey[900]!],
                  ),
                ),
                child: Stack(
                  children: [
                    // 寿司レーン
                    ..._sushiList.map((sushi) => _buildSushi(sushi)).toList(),

                    // 判定ライン
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: Colors.red.withOpacity(0.7),
                      ),
                    ),

                    // スコア表示
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💰 ¥$_score',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 5,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'コンボ: $_combo',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // フリーモード時は説明テキスト
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '🎹 88鍵ピアノ - タップして演奏しよう！',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          // ピアノ鍵盤エリア
          Expanded(
            flex: _isGameMode ? 7 : 10,
            child: Container(
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
    final keyIndex = _keys.indexOf(keyData);
    final isGlowing = _isKeyGlowing[keyIndex] ?? false;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          if (_isGameMode && _isPlaying) {
            _onKeyPressedInGame(keyIndex);
          } else {
            _playNote(keyData['note']);
          }
        },
        child: AnimatedBuilder(
          animation: _glowControllers[keyIndex] ??
              AnimationController(vsync: this, duration: Duration.zero),
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: keyData['color'],
                border: Border.all(
                  color: isGlowing ? Colors.yellow : Colors.grey,
                  width: isGlowing ? 4 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isGlowing
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 2),
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
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isGlowing ? Colors.white : Colors.black87,
                            shadows: isGlowing
                                ? [
                                    const Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        Text(
                          '${keyData['frequency'].toStringAsFixed(1)}Hz',
                          style: TextStyle(
                            fontSize: 8,
                            color: isGlowing ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
    final keyIndex = _keys.indexOf(keyData);
    final isGlowing = _isKeyGlowing[keyIndex] ?? false;

    return Positioned(
      left: keyWidth * (position + 0.7),
      top: 0,
      child: GestureDetector(
        onTapDown: (_) {
          if (_isGameMode && _isPlaying) {
            _onKeyPressedInGame(keyIndex);
          } else {
            _playNote(keyData['note']);
          }
        },
        child: AnimatedBuilder(
          animation: _glowControllers[keyIndex] ??
              AnimationController(vsync: this, duration: Duration.zero),
          builder: (context, child) {
            return Container(
              width: keyWidth * 0.6,
              height: MediaQuery.of(context).size.height *
                  (_isGameMode ? 0.42 : 0.6),
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: keyData['color'],
                border: Border.all(
                  color: isGlowing ? Colors.yellow : Colors.grey,
                  width: isGlowing ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isGlowing
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.8),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
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
            );
          },
        ),
      ),
    );
  }

  // 寿司を描画するウィジェット
  Widget _buildSushi(Sushi sushi) {
    final screenHeight = MediaQuery.of(context).size.height * 0.3;
    final whiteKeyCount = _keys.where((key) => !key['isBlack']).length;
    final keyWidth = MediaQuery.of(context).size.width / whiteKeyCount;

    int whiteKeyIndex = 0;
    for (int i = 0; i < sushi.keyIndex && i < _keys.length; i++) {
      if (!_keys[i]['isBlack']) {
        whiteKeyIndex++;
      }
    }

    return Positioned(
      top: screenHeight * sushi.position - 80,
      left: keyWidth * whiteKeyIndex,
      child: Opacity(
        opacity: sushi.isHit ? 0.3 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sushi.plateColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                sushi.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '¥${sushi.price}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
