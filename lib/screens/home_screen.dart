import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/copilot_controller.dart';
import '../widgets/copilot_footer.dart';
import '../widgets/copilot_header.dart';
import 'notes_view.dart';
import 'transcript_view.dart';

/// The one screen. It reads the controller and renders; it holds no logic.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CopilotController _c = CopilotController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _c.init();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            if (!_c.isInitialised) {
              return const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.them),
                  ),
                ),
              );
            }

            return Column(
              children: [
                CopilotHeader(status: _c.status, level: _c.level),
                _tabs(),
                Expanded(
                  child: _tab == 0
                      ? TranscriptView(
                          lines: _c.lines,
                          partial: _c.partial,
                          status: _c.status,
                          errorMessage: _c.errorMessage,
                          level: _c.level,
                          onStart: _c.toggle,
                          onClear: _c.clearTranscript,
                        )
                      : NotesView(
                          value: _c.notes,
                          onChanged: _c.updateNotes,
                        ),
                ),
                CopilotFooter(
                  lineCount: _c.lineCount,
                  wordCount: _c.wordCount,
                  listening: _c.isListening,
                  busy: _c.isBusy,
                  onToggle: _c.toggle,
                ),
              ],
            );
          },
        ),
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
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.panel : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.line : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(AppRadii.chip),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? AppColors.fg : AppColors.dim,
            ),
          ),
        ),
      ),
    );
  }
}
