import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/court_themes.dart';
import '../theme/tennis_style.dart';

/// PRO: custom court creator — pick surface, surround, lines, accents and
/// player colors. Live preview, persisted per color.
class CustomThemeScreen extends StatefulWidget {
  final TennisAudio audio;
  final TennisSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  CourtThemeDef get _t => widget.settings.customTheme;

  // Curated club-friendly palette choices.
  static const List<Color> palette = [
    Color(0xFF4C8A3D), Color(0xFF3F7533), Color(0xFF2E5A26),
    Color(0xFFB4562F), Color(0xFF9C4826), Color(0xFF6E3319),
    Color(0xFF3A6EA5), Color(0xFF2F5C8A), Color(0xFF1B2A3A),
    Color(0xFF2E5FB8), Color(0xFF274F9C), Color(0xFF152A38),
    Color(0xFF2F6E68), Color(0xFF265C57), Color(0xFF12211F),
    Color(0xFF2A3A5E), Color(0xFF22304E), Color(0xFF0C1424),
    Color(0xFFC47A3D), Color(0xFFA86632), Color(0xFF33200F),
    Color(0xFFA03A2E), Color(0xFF863026), Color(0xFF2E1512),
    Color(0xFF3D7A34), Color(0xFF32662B), Color(0xFF182A16),
    Color(0xFFE0C284), Color(0xFFCDAE70), Color(0xFF4A3A24),
    Color(0xFFEFE8D8), Color(0xFFDCD2BC), Color(0xFF3A3428),
    Color(0xFFB0653A), Color(0xFF94542F), Color(0xFF2E1B0E),
    Color(0xFF2E4A7A), Color(0xFF263E66), Color(0xFF0E1830),
    Color(0xFFD4AF37), Color(0xFFF0D77A), Color(0xFF8A6D1A),
    Color(0xFFE8B04B), Color(0xFFF7D08A), Color(0xFF7A1F2B),
    Color(0xFFF5F2E8), Color(0xFFB9C7AE), Color(0xFF1E3320),
    Color(0xFFC0392B), Color(0xFF5DADE2), Color(0xFF2EA7A0),
  ];

  static const rows = [
    ('Court surface', 'court'),
    ('Service box shade', 'courtDark'),
    ('Surround area', 'surround'),
    ('Line paint', 'line'),
    ('Background', 'bg'),
    ('Cards', 'card'),
    ('Accent', 'accent'),
    ('Player one', 'pc0'),
    ('Player two', 'pc1'),
  ];

  Future<void> _pick(String key, String label) async {
    final s = widget.settings;
    final current = Color(s.customColors[key]!);
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _t.card,
            border: Border.all(color: _t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick $label', style: Tennis.display(20, theme: _t)),
              const SizedBox(height: 14),
              SizedBox(
                width: 300,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: palette.length,
                  itemBuilder: (_, i) {
                    final c = palette[i];
                    final selected = c.value == current.value;
                    return GestureDetector(
                      onTap: () {
                        widget.audio.click();
                        Navigator.of(context).pop(c);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(
                            color: selected
                                ? _t.accentLight
                                : Colors.white30,
                            width: selected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: Tennis.label(14, theme: _t)),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      widget.audio.click();
      await s.setCustomColor(key, chosen.value);
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return ClubBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title:
              Text('My Court', style: Tennis.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Design your own court. Every color is yours.',
                    style: Tennis.body(14, theme: t, color: t.muted),
                  ),
                  const SizedBox(height: 14),
                  // Live mini-court preview.
                  ClubCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PREVIEW',
                            style: Tennis.label(12, theme: t)),
                        const SizedBox(height: 10),
                        _MiniPreview(theme: t),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => _pick(r.$2, r.$1),
                        child: ClubCard(
                          theme: t,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(s.customColors[r.$2]!),
                                  border: Border.all(
                                      color: Colors.white70, width: 1.5),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(r.$1,
                                      style:
                                          Tennis.body(15, theme: t))),
                              Icon(Icons.chevron_right,
                                  color: t.muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TennisButton(
                          label: 'Reset',
                          theme: t,
                          onTap: () async {
                            widget.audio.click();
                            await s.resetCustomColors();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TennisButton(
                          label: 'Use My Court',
                          primary: true,
                          theme: t,
                          onTap: () async {
                            widget.audio.gameStart();
                            await s.setTheme('custom');
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny live preview of the custom court.
class _MiniPreview extends StatelessWidget {
  final CourtThemeDef theme;
  const _MiniPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.surround,
        border:
            Border.all(color: theme.accent.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Container(
          width: 190,
          height: 110,
          decoration: BoxDecoration(
            color: theme.court,
            border: Border.all(color: theme.line, width: 3),
          ),
          child: CustomPaint(
            painter: _PreviewPainter(theme: theme),
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final CourtThemeDef theme;
  _PreviewPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = Paint()
      ..color = theme.line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, h * 0.5), Offset(w, h * 0.5), line);
    canvas.drawLine(
        Offset(w / 2, 0), Offset(w / 2, h), line);
    // Two player dots.
    canvas.drawCircle(
        Offset(w * 0.3, h * 0.85), 6, Paint()..color = theme.playerColors[0]);
    canvas.drawCircle(
        Offset(w * 0.7, h * 0.15), 6, Paint()..color = theme.playerColors[1]);
    // Ball.
    canvas.drawCircle(
        Offset(w * 0.55, h * 0.55), 5, Paint()..color = const Color(0xFFD8DE3A));
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => true;
}
