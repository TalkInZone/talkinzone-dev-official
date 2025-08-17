// =============================================================================
// 📦 FILE: home_screen_ui.dart
// =============================================================================
// Nuvolette chat ripristinate + nome utente ("Tu" sui miei messaggi), timer,
// viste, reazioni (pressione prolungata) e onda audio animata (solo in play).
// Nessuna progress bar nella nuvoletta. Dark mode compatibile (no API deprecate).
// =============================================================================

import 'dart:math' as math;
import 'dart:async'; // 🔴 MODIFICA: StreamSubscription per listeners reazioni
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔴 MODIFICA: Firestore

import 'category_utils.dart'
    show
        MessageCategory,
        CategorySelector,
        FilterSelector,
        loadCustomCategoryName,
        displayCategoryLabel;
import 'voice_message.dart';

// Helper compat: sostituisce withOpacity (deprecato)
Color _alpha(Color c, double opacity01) =>
    c.withAlpha(((opacity01.clamp(0.0, 1.0)) * 255).round());

// =============================================================================
// 🎨 Palette adattiva
// =============================================================================
class _AdaptivePalette {
  final Color surface;
  final Color onSurface;
  final Color surfaceAlt;
  final Color onSurfaceAlt;
  final Color bubbleMine;
  final Color onBubbleMine;
  final Color bubbleOther;
  final Color onBubbleOther;
  final bool isDark;

  _AdaptivePalette({
    required this.surface,
    required this.onSurface,
    required this.surfaceAlt,
    required this.onSurfaceAlt,
    required this.bubbleMine,
    required this.onBubbleMine,
    required this.bubbleOther,
    required this.onBubbleOther,
    required this.isDark,
  });

  static _AdaptivePalette of(BuildContext context, {Color? accent}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final actuallyDark = theme.brightness == Brightness.dark || platformDark;

    // Fallback dark “sicuro”
    final ColorScheme darkSafe = ColorScheme.dark(
      primary: accent ?? cs.primary,
      secondary: cs.secondary,
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFE6E6E6),
    );

    if (actuallyDark) {
      final c = theme.brightness == Brightness.dark ? cs : darkSafe;
      return _AdaptivePalette(
        surface: c.surface,
        onSurface: c.onSurface,
        surfaceAlt: c.surfaceContainerHighest,
        onSurfaceAlt: c.onSurface,
        bubbleMine: _alpha((accent ?? c.primary), 0.22),
        onBubbleMine: c.onSurface,
        bubbleOther: _alpha(c.surfaceContainerHighest, 0.35),
        onBubbleOther: c.onSurface,
        isDark: true,
      );
    } else {
      return _AdaptivePalette(
        surface: cs.surface,
        onSurface: cs.onSurface,
        surfaceAlt: cs.surfaceContainerHighest,
        onSurfaceAlt: cs.onSurface,
        bubbleMine: _alpha((accent ?? cs.primary), 0.12),
        onBubbleMine: cs.onSurface,
        bubbleOther: _alpha(cs.surfaceContainerHighest, 0.55),
        onBubbleOther: Colors.black87,
        isDark: false,
      );
    }
  }
}

// =============================================================================
/* 🧩 HomeScreenUI */
// =============================================================================
class HomeScreenUI extends StatefulWidget {
  final bool showWelcomeMessage;
  final bool isInitialized;
  final bool showRadiusSelector;
  final bool showFilterSelector;
  final bool showCategorySelector;

  final Set<MessageCategory> activeFilters;
  final MessageCategory selectedCategory;

  final List<VoiceMessage> filteredMessages;
  final String? currentUserId;
  final Position? currentPosition;

  final double selectedRadius;
  final List<double> radiusOptions;

  final bool isRecording;
  final int recordingSeconds;
  final bool isLongPressRecording;
  final bool isWaitingForRelease;

  final String? playingMessageId;

  final TextEditingController textController;
  final String textError;
  final bool isSendingText;

  final void Function(VoiceMessage) onPlayMessage;

  final VoidCallback onToggleRadiusSelector;
  final void Function(MessageCategory) onFilterToggled;
  final VoidCallback onToggleFilterSelector;

  final void Function(MessageCategory) onCategorySelected;
  final VoidCallback onToggleCategorySelector;

  final VoidCallback onSettingsPressed;
  final VoidCallback onProfilePressed;

  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onStopRecording;
  final VoidCallback onStartRecording;

  final VoidCallback onWelcomeDismissed;
  final Future<void> Function(double) onRadiusChanged;

  final VoidCallback onSendText;

  final void Function(VoiceMessage) onTextVisible;

  final void Function(VoiceMessage, String) onToggleReaction;

  const HomeScreenUI({
    super.key,
    required this.showWelcomeMessage,
    required this.isInitialized,
    required this.showRadiusSelector,
    required this.showFilterSelector,
    required this.activeFilters,
    required this.showCategorySelector,
    required this.selectedCategory,
    required this.filteredMessages,
    required this.currentUserId,
    required this.currentPosition,
    required this.selectedRadius,
    required this.isRecording,
    required this.recordingSeconds,
    required this.isLongPressRecording,
    required this.isWaitingForRelease,
    required this.playingMessageId,
    required this.radiusOptions,
    required this.textController,
    required this.textError,
    required this.isSendingText,
    required this.onPlayMessage,
    required this.onToggleRadiusSelector,
    required this.onFilterToggled,
    required this.onToggleFilterSelector,
    required this.onCategorySelected,
    required this.onToggleCategorySelector,
    required this.onSettingsPressed,
    required this.onProfilePressed,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onStopRecording,
    required this.onStartRecording,
    required this.onWelcomeDismissed,
    required this.onRadiusChanged,
    required this.onSendText,
    required this.onTextVisible,
    required this.onToggleReaction,
  });

  @override
  State<HomeScreenUI> createState() => _HomeScreenUIState();
}

class _HomeScreenUIState extends State<HomeScreenUI> {
  final Set<String> _textVisibilityNotified = {};
  OverlayEntry? _reactionsOverlay;

  // 🔴 MODIFICA: stato reazioni
  final Map<String, Map<String, int>> _localReactions = {}; // ottimistico
  final Map<String, Map<String, int>> _remoteDocReactions =
      {}; // da messages.reactions
  final Map<String, Map<String, int>> _remoteEventReactions =
      {}; // da subcollection

  // 🔴 MODIFICA: subscriptions per doc + subcollection
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _docSubs = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _eventSubs = {};

  @override
  void initState() {
    super.initState();
    _refreshReactionSubscriptions(); // 🔴 MODIFICA
  }

  @override
  void didUpdateWidget(covariant HomeScreenUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filteredMessages != widget.filteredMessages) {
      _refreshReactionSubscriptions(); // 🔴 MODIFICA
    }
  }

  @override
  void dispose() {
    // 🔴 MODIFICA: chiusura listeners
    for (final s in _docSubs.values) {
      s.cancel();
    }
    for (final s in _eventSubs.values) {
      s.cancel();
    }
    _docSubs.clear();
    _eventSubs.clear();
    super.dispose();
  }

  // 🔴 MODIFICA: attach listeners a doc.reactions e a /reactions_events
  void _refreshReactionSubscriptions() {
    final ids = widget.filteredMessages.map((m) => m.id).toSet();

    // rimuovi vecchi
    for (final id in _docSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _docSubs[id]?.cancel();
        _docSubs.remove(id);
        _remoteDocReactions.remove(id);
      }
    }
    for (final id in _eventSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _eventSubs[id]?.cancel();
        _eventSubs.remove(id);
        _remoteEventReactions.remove(id);
      }
    }

    // aggiungi nuovi
    for (final m in widget.filteredMessages) {
      final docRef =
          FirebaseFirestore.instance.collection('messages').doc(m.id);
      if (!_docSubs.containsKey(m.id)) {
        _docSubs[m.id] = docRef.snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;
          final Map<String, int> counts =
              Map<String, int>.from(data['reactions'] ?? {});
          final prev = _remoteDocReactions[m.id];
          if (prev == null || !_mapEquals(prev, counts)) {
            setState(() {
              _remoteDocReactions[m.id] = counts;
            });
            _reconcileLocalIfCovered(
                m.id); // 🔴 MODIFICA: riconcilia locale→remoto
          }
        });
      }
      if (!_eventSubs.containsKey(m.id)) {
        final evRef = docRef.collection('reactions_events');
        _eventSubs[m.id] = evRef.snapshots().listen((qs) {
          final Map<String, int> acc = {};
          for (final d in qs.docs) {
            final data = d.data();
            final e = (data['emoji'] ?? '') as String;
            if (e.isEmpty) continue;
            acc[e] = (acc[e] ?? 0) + 1;
          }
          final prev = _remoteEventReactions[m.id];
          if (prev == null || !_mapEquals(prev, acc)) {
            setState(() {
              _remoteEventReactions[m.id] = acc;
            });
            _reconcileLocalIfCovered(m.id); // 🔴 MODIFICA
          }
        });
      }
    }
  }

  // 🔴 MODIFICA: somma sicura tra mappe conteggi
  Map<String, int> _sumCounts(Map<String, int> a, Map<String, int> b) {
    final out = <String, int>{}..addAll(a);
    b.forEach((k, v) => out[k] = (out[k] ?? 0) + v);
    return out;
  }

  // 🔴 MODIFICA: se il remoto copre (>=) il locale, rimuovo override locale
  void _reconcileLocalIfCovered(String id) {
    final local = _localReactions[id];
    if (local == null) return;
    final remote = _combinedRemoteCountsForMessage(id);
    if (_covers(remote, local)) {
      setState(() {
        _localReactions.remove(id);
      });
    }
  }

  // 🔴 MODIFICA: somma doc+event per confronto e UI
  Map<String, int> _combinedRemoteCountsForMessage(String id) {
    final a = _remoteDocReactions[id] ?? const <String, int>{};
    final b = _remoteEventReactions[id] ?? const <String, int>{};
    return _sumCounts(a, b);
  }

  // 🔴 MODIFICA: check superset (remote >= local per ogni emoji)
  bool _covers(Map<String, int> remote, Map<String, int> local) {
    for (final e in local.entries) {
      if ((remote[e.key] ?? 0) < e.value) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  String _formatRelative(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'Ora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.day)}/${two(ts.month)} ${two(ts.hour)}:${two(ts.minute)}';
  }

  String _formatDistanceMeters(double meters) {
    if (meters < 60) return 'Molto vicino';
    if (meters < 300) return 'Vicino';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // Bucket qualitativi (solo ricevuti)
  String _formatDistanceBucket(double meters) {
    if (meters <= 500) return 'molto vicino';
    if (meters > 500 && meters <= 1000) return 'vicino';
    if (meters > 1000 && meters <= 2000) return 'in zona';
    if (meters > 2000 && meters <= 3000) return 'distante';
    if (meters > 3000 && meters <= 6000) return 'molto distante';
    return 'molto distante';
  }

  double _distanceTo(VoiceMessage m) {
    if (widget.currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      widget.currentPosition!.latitude,
      widget.currentPosition!.longitude,
      m.latitude,
      m.longitude,
    );
  }

  void _notifyTextVisibleOnce(VoiceMessage m) {
    if (!m.isText) return;
    if (_textVisibilityNotified.contains(m.id)) return;
    _textVisibilityNotified.add(m.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTextVisible(m);
    });
  }

  void _hideReactionsOverlay() {
    _reactionsOverlay?.remove();
    _reactionsOverlay = null;
  }

  // 🔴 MODIFICA: persistenza reazione con fallback più robusto
  Future<void> _persistReaction(VoiceMessage message, String emoji) async {
    final docRef =
        FirebaseFirestore.instance.collection('messages').doc(message.id);
    try {
      await docRef.set({
        'reactions.$emoji': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // 🔴 MODIFICA: fallback su subcollection per QUALSIASI errore Firestore
      try {
        await docRef.collection('reactions_events').add({
          'emoji': emoji,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException {
        // Se fallisce anche qui, lascio lo stato locale finché non si riesce
        // (così non "sparisce" dalla UI).
      }
    }
  }

  // 🔴 MODIFICA: locale incrementale e niente più rimozione in whenComplete
  void _applyLocalReaction(VoiceMessage message, String emoji) {
    setState(() {
      final base = Map<String, int>.from(
        _localReactions[message.id] ??
            _combinedRemoteCountsForMessage(message.id),
      );
      base[emoji] = (base[emoji] ?? 0) + 1;
      _localReactions[message.id] = base;
    });

    _persistReaction(message, emoji).whenComplete(() {
      // 🔴 MODIFICA: NIENTE rimozione qui.
      // Verrà rimossa SOLO quando il remoto coprirà i valori locali
      // (_reconcileLocalIfCovered) in seguito agli snapshot.
    });

    // Mantengo il tuo callback (se usato altrove)
    widget.onToggleReaction(message, emoji);
  }

  void _showReactionsOverlay({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoiceMessage message,
  }) {
    _hideReactionsOverlay();
    HapticFeedback.mediumImpact();

    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;

    final offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = box.size;

    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    _reactionsOverlay = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideReactionsOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: offset.dx + (size.width / 2) - 180,
              top: (offset.dy - 64).clamp(12.0, double.infinity),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _alpha(Colors.black, 0.92),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x61000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: emojis.map((e) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _applyLocalReaction(message, e); // 🔴 MODIFICA
                          _hideReactionsOverlay();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_reactionsOverlay!);
  }

  @override
  Widget build(BuildContext context) {
    final canSendText = widget.textController.text.trim().isNotEmpty &&
        widget.textController.text.characters.length <= 250 &&
        !widget.isSendingText;

    final pal =
        _AdaptivePalette.of(context, accent: widget.selectedCategory.color);

    return Stack(
      children: [
        Column(
          children: [
            _TopBar(
              selectedCategory: widget.selectedCategory,
              onSettingsPressed: widget.onSettingsPressed,
              onProfilePressed: widget.onProfilePressed,
              onToggleCategorySelector: widget.onToggleCategorySelector,
              onToggleFilterSelector: widget.onToggleFilterSelector,
              onToggleRadiusSelector: widget.onToggleRadiusSelector,
              selectedRadius: widget.selectedRadius,
            ),

            if (widget.showCategorySelector)
              CategorySelector(
                selectedCategory: widget.selectedCategory,
                onCategorySelected: widget.onCategorySelected,
                onClose: widget.onToggleCategorySelector,
              ),

            if (widget.showFilterSelector)
              FilterSelector(
                activeFilters: widget.activeFilters,
                onFilterToggled: widget.onFilterToggled,
                onClose: widget.onToggleFilterSelector,
              ),

            if (widget.showRadiusSelector)
              _RadiusSelector(
                current: widget.selectedRadius,
                options: widget.radiusOptions,
                onSelected: widget.onRadiusChanged,
              ),

            const SizedBox(height: 4),

            // Lista nuvolette
            Expanded(
              child: widget.isInitialized
                  ? _MessagesList(
                      messages: widget.filteredMessages,
                      playingMessageId: widget.playingMessageId,
                      currentUserId: widget.currentUserId,
                      onPlayMessage: widget.onPlayMessage,
                      onToggleReaction: widget.onToggleReaction,
                      onTextVisible: _notifyTextVisibleOnce,
                      labelBuilder: (m) => displayCategoryLabel(
                        m.category,
                        messageCustomName: m.customCategoryName,
                      ),
                      // 👤 "Tu" sui miei, nome altrui sugli altri
                      userNameBuilder: (m) {
                        final myId = widget.currentUserId ?? '';
                        if (m.senderId == myId) return 'Tu';
                        final String n = (m.name).trim();
                        return n.isEmpty ? 'Anonimo' : n;
                      },
                      distanceBuilder: (m) {
                        final d = _distanceTo(m);
                        final isMine =
                            m.senderId == (widget.currentUserId ?? '');
                        return isMine
                            ? _formatDistanceMeters(d)
                            : _formatDistanceBucket(d);
                      },
                      timeBuilder: _formatRelative,
                      pal: pal,
                      showReactionsOverlay: _showReactionsOverlay,

                      // 🔴 MODIFICA: locale > (doc + eventi) > modello
                      reactionsBuilder: (m) {
                        final local = _localReactions[m.id];
                        if (local != null) return local;

                        final combined = _combinedRemoteCountsForMessage(m.id);
                        if (combined.isNotEmpty) return combined;

                        return m.reactions ?? const <String, int>{};
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),

            if (!widget.showWelcomeMessage)
              _ComposerBar(
                selectedCategory: widget.selectedCategory,
                isRecording: widget.isRecording,
                recordingSeconds: widget.recordingSeconds,
                isLongPressRecording: widget.isLongPressRecording,
                isWaitingForRelease: widget.isWaitingForRelease,
                textController: widget.textController,
                textError: widget.textError,
                isSendingText: widget.isSendingText,
                canSendText: canSendText,
                onSendText: widget.onSendText,
                onToggleCategorySelector: widget.onToggleCategorySelector,
                onPressStart: widget.onPressStart,
                onPressEnd: widget.onPressEnd,
                onStartRecording: widget.onStartRecording,
                onStopRecording: widget.onStopRecording,
              ),
          ],
        ),
        if (widget.showWelcomeMessage)
          _WelcomeOverlay(onClose: widget.onWelcomeDismissed),
      ],
    );
  }
}

// =============================================================================
// 🔼 Top bar
// =============================================================================
class _TopBar extends StatelessWidget {
  final MessageCategory selectedCategory;
  final VoidCallback onSettingsPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onToggleCategorySelector;
  final VoidCallback onToggleFilterSelector;
  final VoidCallback onToggleRadiusSelector;
  final double selectedRadius;

  const _TopBar({
    required this.selectedCategory,
    required this.onSettingsPressed,
    required this.onProfilePressed,
    required this.onToggleCategorySelector,
    required this.onToggleFilterSelector,
    required this.onToggleRadiusSelector,
    required this.selectedRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedCategory.color;
    final pal = _AdaptivePalette.of(context, accent: color);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Impostazioni',
              onPressed: onSettingsPressed,
              icon: const Icon(Icons.settings),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onToggleCategorySelector,
                child: FutureBuilder<String?>(
                  future: loadCustomCategoryName(),
                  builder: (context, snap) {
                    final label = displayCategoryLabel(
                      selectedCategory,
                      prefsCustomName: snap.data,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _alpha(pal.surfaceAlt, 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(selectedCategory.icon, size: 18, color: color),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.expand_more, color: color, size: 18),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Filtri',
              onPressed: onToggleFilterSelector,
              icon: const Icon(Icons.filter_list),
            ),
            IconButton(
              tooltip: 'Raggio',
              onPressed: onToggleRadiusSelector,
              icon: const Icon(Icons.radar),
            ),
            IconButton(
              tooltip: 'Profilo',
              onPressed: onProfilePressed,
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 📡 Radius selector
// =============================================================================
class _RadiusSelector extends StatelessWidget {
  final double current;
  final List<double> options;
  final Future<void> Function(double) onSelected;

  const _RadiusSelector({
    required this.current,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pal = _AdaptivePalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Card(
        color: pal.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Wrap(
            spacing: 8,
            children: options.map((r) {
              final selected = r == current;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  r >= 1000
                      ? '${(r / 1000).toStringAsFixed(1)} km'
                      : '${r.toStringAsFixed(0)} m',
                ),
                onSelected: (_) => onSelected(r),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 📨 Lista messaggi
// =============================================================================
class _MessagesList extends StatelessWidget {
  final List<VoiceMessage> messages;
  final String? playingMessageId;
  final String? currentUserId;
  final void Function(VoiceMessage) onPlayMessage;
  final void Function(VoiceMessage) onTextVisible;
  final String Function(VoiceMessage) labelBuilder;
  final String Function(VoiceMessage) userNameBuilder;
  final String Function(VoiceMessage) distanceBuilder;
  final String Function(DateTime) timeBuilder;
  final void Function(VoiceMessage, String) onToggleReaction;
  final _AdaptivePalette pal;
  final void Function({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoiceMessage message,
  }) showReactionsOverlay;

  // 🔴 MODIFICA: reazioni da mostrare
  final Map<String, int> Function(VoiceMessage) reactionsBuilder;

  const _MessagesList({
    required this.messages,
    required this.playingMessageId,
    required this.currentUserId,
    required this.onPlayMessage,
    required this.onTextVisible,
    required this.labelBuilder,
    required this.userNameBuilder,
    required this.distanceBuilder,
    required this.timeBuilder,
    required this.onToggleReaction,
    required this.pal,
    required this.showReactionsOverlay,
    required this.reactionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text('Nessun messaggio nella tua zona…',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      reverse: true, // chat-style
      padding: const EdgeInsets.only(bottom: 96, top: 6),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];

        if (m.isText &&
            (m.text ?? '').trim().isNotEmpty &&
            m.senderId != (currentUserId ?? '')) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onTextVisible(m));
        }

        final isMine = m.senderId == (currentUserId ?? '');
        final isPlaying = playingMessageId == m.id;
        final reactions = reactionsBuilder(m);

        return _ChatBubble(
          message: m,
          isMine: isMine,
          isPlaying: isPlaying,
          categoryLabel: labelBuilder(m),
          userName: userNameBuilder(m),
          distanceLabel: distanceBuilder(m),
          timeLabel: timeBuilder(m.timestamp),
          onPlay: () => onPlayMessage(m),
          onLongPress: (key) => showReactionsOverlay(
            context: context,
            anchorKey: key,
            message: m,
          ),
          onToggleReaction: (emoji) => onToggleReaction(m, emoji),
          pal: pal,
          reactions: reactions,
        );
      },
    );
  }
}

// =============================================================================
// 💬 Chat bubble (spazio reazioni DENTRO la bolla, sotto il body)
// =============================================================================
class _ChatBubble extends StatelessWidget {
  final VoiceMessage message;
  final bool isMine;
  final bool isPlaying;
  final String categoryLabel;
  final String userName; // 👈 "Tu" o nome utente
  final String distanceLabel;
  final String timeLabel;
  final VoidCallback onPlay;
  final void Function(GlobalKey) onLongPress;
  final void Function(String emoji) onToggleReaction;
  final _AdaptivePalette pal;

  // 🔴 MODIFICA: reazioni già composte
  final Map<String, int> reactions;

  _ChatBubble({
    required this.message,
    required this.isMine,
    required this.isPlaying,
    required this.categoryLabel,
    required this.userName,
    required this.distanceLabel,
    required this.timeLabel,
    required this.onPlay,
    required this.onLongPress,
    required this.onToggleReaction,
    required this.pal,
    required this.reactions,
  });

  final GlobalKey _bubbleKey = GlobalKey();

  String _countdownLeft(DateTime ts) {
    final expiry = ts.add(const Duration(minutes: 5));
    final left = expiry.difference(DateTime.now());
    final total = left.isNegative ? Duration.zero : left;
    final m = total.inMinutes;
    final s = total.inSeconds % 60;
    final mm = m.toString();
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final accent = message.category.color;

    final Color bubbleBg = isMine ? pal.bubbleMine : pal.bubbleOther;
    final Color textColor = isMine ? pal.onBubbleMine : pal.onBubbleOther;

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final cross = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    const Radius r = Radius.circular(16);
    final borderRadius = isMine
        ? const BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: r,
            bottomRight: Radius.circular(6),
          )
        : const BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomRight: r,
            bottomLeft: Radius.circular(6),
          );

    final bool hasReactions = reactions.entries.any((e) => e.value > 0);

    Widget viewsChip() {
      final views = message.views;
      final label = views <= 0 ? 'Nuovo' : views.toString();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_red_eye, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      );
    }

    Widget countdownChip() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 4),
          Text(
            _countdownLeft(message.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.86,
          ),
          child: Column(
            crossAxisAlignment: cross,
            children: [
              GestureDetector(
                key: _bubbleKey,
                onLongPress: () => onLongPress(_bubbleKey),
                child: Container(
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    borderRadius: borderRadius,
                    border: Border.all(color: _alpha(accent, 0.35), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: _alpha(Colors.black, 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: categoria + distanza
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                        child: Row(
                          children: [
                            Icon(message.category.icon,
                                size: 16, color: accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                categoryLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              distanceLabel,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),

                      // 👤 Nome utente
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body (testo o voce)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        child: message.isText
                            ? Text(
                                message.text ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                  height: 1.25,
                                ),
                              )
                            : _VoiceRow(
                                duration: message.duration,
                                isPlaying: isPlaying,
                                onPlay: onPlay,
                                accent: accent,
                                textColor: textColor,
                              ),
                      ),

                      // 🔴 MODIFICA: SPAZIO REAZIONI STABILE DENTRO LA BOLLA
                      if (hasReactions)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                          child: Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: _ReactionsPill(
                              reactions: reactions,
                              isMine: isMine,
                              pal: pal,
                            ),
                          ),
                        ),

                      // Footer: ora + countdown + viste
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                        child: Row(
                          children: [
                            Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            countdownChip(),
                            const SizedBox(width: 12),
                            viewsChip(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🔧 Widget pill reazioni (emoji + conteggio)
class _ReactionsPill extends StatelessWidget {
  final Map<String, int> reactions;
  final bool isMine;
  final _AdaptivePalette pal;

  const _ReactionsPill({
    required this.reactions,
    required this.isMine,
    required this.pal,
  });

  @override
  Widget build(BuildContext context) {
    final entries = reactions.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) {
        final c = b.value.compareTo(a.value);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    final bg =
        isMine ? _alpha(pal.bubbleMine, 0.9) : _alpha(pal.bubbleOther, 0.9);
    final border = _alpha(Colors.black, 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: _alpha(Colors.black, 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 2,
        children: entries.map((e) {
          final showCount = e.value > 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.key, style: const TextStyle(fontSize: 14)),
              if (showCount) ...[
                const SizedBox(width: 2),
                Text(
                  e.value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    // ignore: deprecated_member_use
                    color: pal.onSurface.withOpacity(0.75),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// 🎵 Riga audio con Onda ANIMATA (no progress bar)
// =============================================================================
class _VoiceRow extends StatefulWidget {
  final int duration;
  final bool isPlaying;
  final VoidCallback onPlay;
  final Color accent;
  final Color textColor;

  const _VoiceRow({
    required this.duration,
    required this.isPlaying,
    required this.onPlay,
    required this.accent,
    required this.textColor,
  });

  @override
  State<_VoiceRow> createState() => _VoiceRowState();
}

class _VoiceRowState extends State<_VoiceRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isPlaying) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant _VoiceRow old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon =
        widget.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill;
    return Row(
      children: [
        InkWell(
          onTap: widget.onPlay,
          child: Icon(icon, size: 36, color: widget.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 22,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AnimatedWavePainter(
                    color: _alpha(widget.accent, 0.85),
                    progress: _ctrl.value, // 0..1
                    playing: widget.isPlaying,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.duration}s',
          style: TextStyle(color: _alpha(widget.textColor, 0.8)),
        ),
      ],
    );
  }
}

class _AnimatedWavePainter extends CustomPainter {
  final Color color;
  final double progress; // 0..1
  final bool playing;

  _AnimatedWavePainter({
    required this.color,
    required this.progress,
    required this.playing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    final double amp = size.height / 3 * (playing ? 1.0 : 0.6);
    const double k = 10;
    final double phase = progress * 2 * math.pi;

    for (double x = 0; x <= size.width; x += 6) {
      final y = size.height / 2 + math.sin((x / k) + phase) * amp;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedWavePainter old) {
    return old.progress != progress ||
        old.color != color ||
        old.playing != playing;
  }
}

// =============================================================================
// 🧰 Composer
// =============================================================================
class _ComposerBar extends StatelessWidget {
  final MessageCategory selectedCategory;
  final bool isRecording;
  final int recordingSeconds;
  final bool isLongPressRecording;
  final bool isWaitingForRelease;

  final TextEditingController textController;
  final String textError;
  final bool isSendingText;
  final bool canSendText;

  final VoidCallback onSendText;
  final VoidCallback onToggleCategorySelector;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _ComposerBar({
    required this.selectedCategory,
    required this.isRecording,
    required this.recordingSeconds,
    required this.isLongPressRecording,
    required this.isWaitingForRelease,
    required this.textController,
    required this.textError,
    required this.isSendingText,
    required this.canSendText,
    required this.onSendText,
    required this.onToggleCategorySelector,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedCategory.color;
    final pal = _AdaptivePalette.of(context, accent: color);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggleCategorySelector,
              child: FutureBuilder<String?>(
                future: loadCustomCategoryName(),
                builder: (context, snap) {
                  final label = displayCategoryLabel(
                    selectedCategory,
                    prefsCustomName: snap.data,
                  );
                  return Row(
                    children: [
                      Icon(selectedCategory.icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(label,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 16, color: color),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 250,
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio (max 250)…',
                      counterText: '',
                      errorText: textError.isEmpty ? null : textError,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: _alpha(pal.surfaceAlt, 0.4),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) {
                      if (canSendText) onSendText();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: canSendText ? onSendText : null,
                  icon: isSendingText
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
                const SizedBox(width: 6),
                _MicButton(
                  accent: color,
                  isRecording: isRecording,
                  seconds: recordingSeconds,
                  isLongPressRecording: isLongPressRecording,
                  isWaitingForRelease: isWaitingForRelease,
                  onPressStart: onPressStart,
                  onPressEnd: onPressEnd,
                  onStartRecording: onStartRecording,
                  onStopRecording: onStopRecording,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final Color accent;
  final bool isRecording;
  final int seconds;
  final bool isLongPressRecording;
  final bool isWaitingForRelease;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _MicButton({
    required this.accent,
    required this.isRecording,
    required this.seconds,
    required this.isLongPressRecording,
    required this.isWaitingForRelease,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        isRecording ? accent : Theme.of(context).colorScheme.primaryContainer;
    final fg = isRecording
        ? Colors.white
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return GestureDetector(
      onLongPressStart: (_) => onPressStart(),
      onLongPressEnd: (_) => onPressEnd(),
      onTap: () {
        if (isRecording) {
          onStopRecording();
        } else {
          onStartRecording();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _alpha(accent, isRecording ? 0.45 : 0.15),
              blurRadius: isRecording ? 12 : 6,
              spreadRadius: isRecording ? 2 : 0,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.mic, color: fg),
            if (isRecording)
              Positioned(
                bottom: 6,
                child: Text(
                  seconds.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 👋 Overlay benvenuto
// =============================================================================
class _WelcomeOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _WelcomeOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final pal = _AdaptivePalette.of(context);
    return Container(
      color: _alpha(Colors.black, 0.35),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: pal.surface,
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.waving_hand, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Benvenuto!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completa i dati richiesti per iniziare a usare TalkInZone.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onClose,
                    child: const Text('Ho capito'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
