import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InterviewCopilotApp());
}

// ------------------------------------------------------------------ theme
const kBg = Color(0xFF0A0D13);
const kPanel = Color(0xFF161C26);
const kPanel2 = Color(0xFF1E2632);
const kFg = Color(0xFFEEF3FA);
const kDim = Color(0xFF8395AA);
const kDim2 = Color(0xFF5F7086);
const kThem = Color(0xFF5AA9FF);
const kYou = Color(0xFF4ADE80);
const kHot = Color(0xFFFF5F7E);
const kLine = Color(0x14FFFFFF);

class InterviewCopilotApp extends StatelessWidget {
  const InterviewCopilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interview Copilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kThem, surface: kPanel),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ------------------------------------------------------------------ model
class Line {
  final String who; // 'them' | 'you' | 'sys'
  final String text;
  Line(this.who, this.text);
}

// ------------------------------------------------------------------ home
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _rec = AudioRecorder();
  final WhisperController _whisper = WhisperController();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _notes = TextEditingController();

  final List<Line> _lines = [];
  String _partial = '';
  bool _listening = false;
  String _status = 'idle';
  int _tab = 0;

  WhisperLiveSession? _session;
  StreamSubscription<String>? _partialSub;
  bool _busy = false;

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _loadNotes();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _scroll.dispose();
    _notes.dispose();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _notes.text = p.getString('ic_notes') ?? '');
  }

  Future<void> _saveNotes() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('ic_notes', _notes.text);
  }

  // ---------------- audio + whisper ----------------
  Future<void> _toggleListening() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_listening) {
        await _stop();
      } else {
        await _start();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _start() async {
    // `record` exposes its own permission check, so no extra plugin is needed.
    final bool granted = await _rec.hasPermission();
    if (!granted) {
      setState(() => _status = 'mic denied');
      _snack('Microphone permission is required.');
      return;
    }

    // First run downloads the Whisper model (~142 MB) once, then it is offline.
    try {
      final path = await _whisper.getPath(WhisperModel.baseEn);
      if (!File(path).existsSync()) {
        setState(() => _status = 'downloading model…');
        await _whisper.downloadModel(WhisperModel.baseEn);
      }
    } catch (e) {
      setState(() => _status = 'error');
      _snack('Model download failed — check internet, retry.');
      return;
    }

    setState(() {
      _status = 'loading model…';
      _partial = '';
    });

    try {
      final stream = await _rec.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));

      final session = await _whisper.transcribeLive(
        model: WhisperModel.baseEn,
        pcm16Stream: stream,
        lang: 'en',
        initialPrompt: 'Technical interview about AI: retrieval augmented '
            'generation, RAG, embeddings, vector database, chunking, LLM, '
            'latency, tokens, API, Python, production, deployment, cost.',
        suppressNonSpeechTokens: true,
      );
      _session = session;

      _partialSub = session.partials.listen((t) {
        if (!mounted) return;
        setState(() => _partial = t);
      });

      setState(() {
        _listening = true;
        _status = 'listening';
      });
    } catch (e) {
      setState(() => _status = 'error');
      _snack('Could not start: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await _rec.stop();
      final finalText = await _session?.stop() ?? '';
      await _partialSub?.cancel();
      _session = null;
      if (finalText.trim().isNotEmpty) {
        _lines.add(Line('them', finalText.trim()));
      }
    } catch (_) {}
    setState(() {
      _partial = '';
      _listening = false;
      _status = 'stopped';
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: kPanel2,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _tabs(),
            Expanded(child: _tab == 0 ? _transcript() : _notesPane()),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5EB0FF), Color(0xFFA78BFA), Color(0xFFF472B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.mic_rounded, size: 17, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Interview Copilot',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: kFg,
                letterSpacing: .2,
              ),
            ),
          ),
          _statusPill(),
        ],
      ),
    );
  }

  Widget _statusPill() {
    final live = _listening;
    final color = live ? kYou : (_status == 'error' ? kHot : kDim);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: live ? kYou.withValues(alpha: .12) : kPanel,
        border: Border.all(color: live ? kYou.withValues(alpha: .35) : kLine),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: live
                ? Tween<double>(begin: .45, end: 1.0).animate(_pulse)
                : const AlwaysStoppedAnimation<double>(1.0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Text(_status,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Row(
        children: [
          _tabBtn(0, 'Live Transcript'),
          const SizedBox(width: 5),
          _tabBtn(1, 'My Notes'),
        ],
      ),
    );
  }

  Widget _tabBtn(int i, String label) {
    final active = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? kPanel : Colors.transparent,
            border: Border.all(color: active ? kLine : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? kFg : kDim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _transcript() {
    if (_lines.isEmpty && _partial.isEmpty) return _emptyState();
    final items = <Widget>[];
    String lastWho = '';
    for (final l in _lines) {
      final grouped = l.who == lastWho;
      items.add(_bubble(l.who, l.text, grouped: grouped));
      lastWho = l.who;
    }
    if (_partial.isNotEmpty) {
      items.add(_bubble('them', _partial, live: true));
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 18),
      children: items,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: .92, end: 1.05).animate(
                  CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: kThem.withValues(alpha: .3), width: 1.5),
                ),
                child:
                    const Icon(Icons.headphones_rounded, size: 34, color: kThem),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Ready to listen',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: kFg)),
            const SizedBox(height: 6),
            const Text(
              'Put the call on speakerphone, then tap Start.\n'
              'Spoken words appear here in seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: kDim, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String who, String text,
      {bool grouped = false, bool live = false}) {
    final isYou = who == 'you';
    final isMeta = who == 'sys';
    final accent = isMeta ? kDim2 : (isYou ? kYou : kThem);
    final label = isMeta ? 'System' : (isYou ? 'You' : 'Interviewer');

    return Padding(
      padding: EdgeInsets.only(bottom: grouped ? 6 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!grouped && !isMeta)
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                border: Border.all(color: accent.withValues(alpha: .3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isYou ? Icons.person_rounded : Icons.support_agent_rounded,
                size: 14,
                color: accent,
              ),
            ),
          if (!grouped && !isMeta) const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              decoration: BoxDecoration(
                color: isMeta ? Colors.white.withValues(alpha: .028) : kPanel,
                borderRadius: BorderRadius.circular(13),
                border: Border(
                  left: BorderSide(
                      color: accent.withValues(alpha: live ? .95 : .7),
                      width: 2.5),
                  top: const BorderSide(color: kLine),
                  right: const BorderSide(color: kLine),
                  bottom: const BorderSide(color: kLine),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!grouped)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: accent,
                            ),
                          ),
                          if (live) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: kThem.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('live',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: kThem,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: live ? const Color(0xFFC2D5EA) : kFg,
                      fontStyle: isMeta ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesPane() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _notes,
              onChanged: (_) => _saveNotes(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  fontFamily: 'monospace',
                  color: kFg),
              decoration: InputDecoration(
                hintText: 'Your battle card lives here.\n\n'
                    '• Your STAR stories\n'
                    '• The numbers you want to hit\n'
                    '• Questions YOU will ask them\n\n'
                    "Glance — don't read.",
                hintStyle: const TextStyle(
                    color: kDim2, fontSize: 12.5, height: 1.7),
                filled: true,
                fillColor: kPanel,
                contentPadding: const EdgeInsets.all(13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: kLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: kLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: kThem.withValues(alpha: .45)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 11, color: kDim2),
              SizedBox(width: 5),
              Text('Saved on this device only',
                  style: TextStyle(fontSize: 10.5, color: kDim2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final words = _lines.fold<int>(
        0,
        (a, l) =>
            a +
            l.text
                .trim()
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .length);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text('${_lines.length}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: kFg,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Text('lines',
                      style: TextStyle(fontSize: 11, color: kDim)),
                  const SizedBox(width: 14),
                  Text('$words',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: kFg,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Text('words',
                      style: TextStyle(fontSize: 11, color: kDim)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleListening,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                gradient: _listening
                    ? const LinearGradient(
                        colors: [Color(0xFFFF5F7E), Color(0xFFE0405F)])
                    : const LinearGradient(
                        colors: [Color(0xFF5EB0FF), Color(0xFF7C6BF5)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_listening ? kHot : kThem).withValues(alpha: .35),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _listening ? 'Stop' : 'Start listening',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
