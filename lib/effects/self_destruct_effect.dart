// lib/effects/self_destruct_effect.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Effetto di autodistruzione:
/// - Parte automaticamente quando `DateTime.now() >= expiresAt`.
/// - Erosione (fori irregolari dai bordi verso l’interno) + fade sincronizzato.
/// - Poca "polvere" (decine di granelli), molto trasparente, vicino ai bordi.
/// - onStarted / onCompleted per coordinarsi col chiamante (es. rimozione).
class SelfDestructEffect extends StatefulWidget {
  final Widget child;
  final DateTime expiresAt;
  final Duration duration;
  final VoidCallback? onStarted;
  final VoidCallback? onCompleted;
  final bool enabled;

  const SelfDestructEffect({
    super.key,
    required this.child,
    required this.expiresAt,
    this.duration = const Duration(milliseconds: 2200),
    this.onStarted,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<SelfDestructEffect> createState() => _SelfDestructEffectState();
}

class _SelfDestructEffectState extends State<SelfDestructEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _ease; // per ondate morbide
  bool _started = false;

  // Particelle “polvere”
  late List<_Dust> _dust;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ease = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);

    // Seed deterministico per non avere flash incoerenti su rebuild
    _seed = widget.expiresAt.millisecondsSinceEpoch & 0x7fffffff;

    // Prepara poca polvere (25–35 elementi)
    final rnd = math.Random(_seed);
    final n = 25 + rnd.nextInt(11);
    _dust = List.generate(n, (i) => _Dust.random(rnd));

    _maybeSchedule();
  }

  @override
  void didUpdateWidget(covariant SelfDestructEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.enabled != widget.enabled) {
      _maybeSchedule();
    }
  }

  void _maybeSchedule() {
    if (!widget.enabled) return;

    final now = DateTime.now();
    if (now.isBefore(widget.expiresAt)) {
      final wait = widget.expiresAt.difference(now);
      Future.delayed(wait, _startIfNotStarted);
    } else {
      // già scaduto
      _startIfNotStarted();
    }
  }

  void _startIfNotStarted() {
    if (!mounted || _started) return;
    _started = true;
    widget.onStarted?.call();
    _ctrl
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) {
          widget.onCompleted?.call();
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ease.value; // 0..1
        // Erosione progressiva (0→1) con un leggero pre-delay per non essere “secca”
        final erode = (t <= 0.1) ? 0.0 : ((t - 0.1) / 0.9).clamp(0.0, 1.0);
        // Fade in ritardo e termina appena dopo l’erosione
        final fade =
            (t <= 0.2) ? 1.0 : (1.0 - ((t - 0.2) / 0.85)).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.passthrough,
          children: [
            // 1) Bolla con erosione + fade
            _ErodeMask(
              progress: erode,
              seed: _seed,
              child: Opacity(opacity: fade, child: widget.child),
            ),
            // 2) Poca polvere, solo nella prima metà ~1.2s
            if (_ctrl.isAnimating && t < 0.55)
              CustomPaint(
                painter: _DustPainter(
                  progress: t,
                  dust: _dust,
                ),
              ),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
//  EROSIONE: clip dinamico con fori che nascono dai bordi e crescono
// -----------------------------------------------------------------------------
class _ErodeMask extends StatelessWidget {
  final double progress; // 0..1
  final int seed;
  final Widget child;

  const _ErodeMask({
    required this.progress,
    required this.seed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (progress <= 0) return child;

    return ClipPath(
      clipper: _ErodeClipper(progress: progress, seed: seed),
      child: child,
    );
  }
}

class _ErodeClipper extends CustomClipper<Path> {
  final double progress;
  final int seed;

  _ErodeClipper({required this.progress, required this.seed});

  @override
  Path getClip(Size size) {
    final rnd = math.Random(seed);
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(16),
      ));

    // Numero fori limitato (effetto “sbriciolamento”, non confetti)
    final holes = Path();
    const int n = 18; // pochi fori principali
    const edgeInset = 6.0; // nascono dai bordi
    const maxR = 26.0; // raggio massimo del foro “maturo”

    for (int i = 0; i < n; i++) {
      // Distribuzione più densa su bordi e angoli
      final edge = i % 4; // 0:top,1:right,2:bottom,3:left
      final t = (i / n) + (rnd.nextDouble() * 0.07); // diversifica
      final along = (t % 1.0) * (edge.isEven ? size.width : size.height);

      double cx, cy;
      switch (edge) {
        case 0:
          cx = along;
          cy = edgeInset + rnd.nextDouble() * 8; // dal top verso il centro
          break;
        case 1:
          cx = size.width - edgeInset - rnd.nextDouble() * 8;
          cy = along;
          break;
        case 2:
          cx = along;
          cy = size.height - edgeInset - rnd.nextDouble() * 8;
          break;
        default:
          cx = edgeInset + rnd.nextDouble() * 8;
          cy = along;
      }

      // raggio cresce con progress, con jitter
      final jitter = 0.65 + rnd.nextDouble() * 0.5;
      final r = (progress * maxR * jitter).clamp(0.0, maxR);

      holes.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      // Piccoli satelliti per irregolarità
      if (i.isEven) {
        final ang = rnd.nextDouble() * math.pi * 2;
        final dist = 12 + rnd.nextDouble() * 14;
        final r2 = r * (0.45 + rnd.nextDouble() * 0.25);
        holes.addOval(Rect.fromCircle(
          center: Offset(
            cx + math.cos(ang) * dist * progress,
            cy + math.sin(ang) * dist * progress,
          ),
          radius: r2,
        ));
      }
    }

    // Micro-erosione (trama): piccoli “morsi” dal bordo verso dentro
    final micro = Path();
    const mCount = 32;
    for (int i = 0; i < mCount; i++) {
      final ang = rnd.nextDouble() * math.pi * 2;
      final d = (8 + rnd.nextDouble() * 18) * progress;
      final r = 2 + rnd.nextDouble() * 3;
      final c = Offset(size.width / 2, size.height / 2);
      final p = Offset(
        (c.dx + (size.width / 2 - 8) * math.cos(ang)) - math.cos(ang) * d,
        (c.dy + (size.height / 2 - 8) * math.sin(ang)) - math.sin(ang) * d,
      );
      micro.addOval(Rect.fromCircle(center: p, radius: r));
    }

    final holesAll = Path.combine(PathOperation.union, holes, micro);
    return Path.combine(PathOperation.difference, base, holesAll);
  }

  @override
  bool shouldReclip(_ErodeClipper old) =>
      old.progress != progress || old.seed != seed;
}

// -----------------------------------------------------------------------------
//  POLVERE: poche particelle, lente, molto trasparenti, vicino ai bordi
// -----------------------------------------------------------------------------
class _Dust {
  // Parametri “fisici”
  final Offset edgePos01; // punto di partenza (normalized) lungo bordo
  final double edge; // 0 top, 1 right, 2 bottom, 3 left
  final double delay; // 0..0.35 porzione inizio
  final double life; // 0.5..1.4 porzione totale tempo
  final double speed; // velocità base
  final double swirl; // lieve componente laterale
  final double gravity; // gravità minima
  final double size; // 1..2.5

  _Dust({
    required this.edgePos01,
    required this.edge,
    required this.delay,
    required this.life,
    required this.speed,
    required this.swirl,
    required this.gravity,
    required this.size,
  });

  factory _Dust.random(math.Random rnd) {
    return _Dust(
      edgePos01: Offset(rnd.nextDouble(), rnd.nextDouble()),
      edge: rnd.nextInt(4).toDouble(),
      delay: rnd.nextDouble() * 0.35,
      life: 0.5 + rnd.nextDouble() * 0.9,
      speed: 10 + rnd.nextDouble() * 18,
      swirl: (rnd.nextDouble() - 0.5) * 10,
      gravity: 6 + rnd.nextDouble() * 8,
      size: 1 + rnd.nextDouble() * 1.5,
    );
  }
}

class _DustPainter extends CustomPainter {
  final double progress; // 0..1 (tempo globale animazione)
  final List<_Dust> dust;

  _DustPainter({required this.progress, required this.dust});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.fill
      // ignore: deprecated_member_use
      ..color = Colors.black.withOpacity(0.06);

    for (final d in dust) {
      if (progress < d.delay) continue;
      final localT = ((progress - d.delay) / d.life).clamp(0.0, 1.0);
      if (localT <= 0 || localT > 1) continue;

      // Punto di partenza sul bordo
      Offset start;
      switch (d.edge.round()) {
        case 0:
          start = Offset(d.edgePos01.dx * size.width, 0);
          break;
        case 1:
          start = Offset(size.width, d.edgePos01.dy * size.height);
          break;
        case 2:
          start = Offset(d.edgePos01.dx * size.width, size.height);
          break;
        default:
          start = Offset(0, d.edgePos01.dy * size.height);
      }

      // Velocità bassa + lieve “soffio” laterale e attrazione al bordo
      final vx = (d.swirl) * (1 - localT) * 0.6;
      final vy = (d.gravity) * localT;

      final pos = start + Offset(vx, vy) * (d.speed / 60);

      // Opacità bassa, svanisce rapidamente
      final a = (1.0 - localT).clamp(0.0, 1.0) * 0.35;
      // ignore: deprecated_member_use
      p.color = Colors.black.withOpacity(a);

      canvas.drawCircle(pos, d.size, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dust != dust;
}
