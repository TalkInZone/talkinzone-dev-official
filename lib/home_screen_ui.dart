// =============================================================================
// 📦 FILE: home_screen_ui.dart  (I18N-READY)
// =============================================================================
// ✅ What changed
// - All hard-coded strings now come from AppLocalizations (EN default).
// - Tiny helpers (_formatRelative/_formatDistance*) now use BuildContext to
//   access localized strings (no logic changes).
// - Tooltips, dialogs, snackbars, empty states, composer hint, etc. localized.
// - No changes to data flow, callbacks, or rendering logic.
//
// Requires: import of `gen_l10n/app_localizations.dart` and the ARB keys
// listed after this file.
// =============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gen_l10n/app_localizations.dart';
import 'category_utils.dart'
    show
        MessageCategory,
        CategorySelector,
        FilterSelector,
        loadCustomCategoryName,
        displayCategoryLabel;
import 'voice_message.dart';

Color _alpha(Color c, double opacity01) =>
    c.withAlpha(((opacity01.clamp(0.0, 1.0)) * 255).round());

// =============================================================================
// ⏱ TTL & self-destruct window
// =============================================================================
const Duration _kMessageTTL = Duration(minutes: 10);
const Duration _kDestructWindow = Duration(seconds: 6);

// =============================================================================
// 🎨 Adaptive palette
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
// 🧩 HomeScreenUI
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

  final TextEditingController textController;
  final String textError;
  final bool isSendingText;
  final VoidCallback onSendText;

  final void Function(VoiceMessage) onTextVisible;
  final void Function(VoiceMessage, String) onToggleReaction;

  final void Function(VoiceMessage message)? onRequestBlockUser;
  final void Function(VoiceMessage message)? onRequestReportUser;

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
    this.onRequestBlockUser,
    this.onRequestReportUser,
  });

  @override
  State<HomeScreenUI> createState() => _HomeScreenUIState();
}

class _HomeScreenUIState extends State<HomeScreenUI> {
  final Set<String> _textVisibilityNotified = {};
  OverlayEntry? _reactionsOverlay;

  final Map<String, Map<String, int>> _localReactions = {};
  final Map<String, Map<String, int>> _remoteDocReactions = {};
  final Map<String, String> _myReactionFromDoc = {};
  final Map<String, String> _myReactionLocal = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _docSubs = {};

  @override
  void initState() {
    super.initState();
    _refreshReactionSubscriptions();
  }

  @override
  void didUpdateWidget(covariant HomeScreenUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filteredMessages != widget.filteredMessages) {
      _refreshReactionSubscriptions();
    }
  }

  @override
  void dispose() {
    for (final s in _docSubs.values) {
      s.cancel();
    }
    _docSubs.clear();
    super.dispose();
  }

  void _refreshReactionSubscriptions() {
    final ids = widget.filteredMessages.map((m) => m.id).toSet();

    for (final id in _docSubs.keys.toList()) {
      if (!ids.contains(id)) {
        _docSubs[id]?.cancel();
        _docSubs.remove(id);
        _remoteDocReactions.remove(id);
        _myReactionFromDoc.remove(id);
      }
    }

    for (final m in widget.filteredMessages) {
      final docRef =
          FirebaseFirestore.instance.collection('messages').doc(m.id);

      if (!_docSubs.containsKey(m.id)) {
        _docSubs[m.id] = docRef.snapshots().listen((snap) {
          final data = snap.data();
          if (data == null) return;

          final Map<String, int> counts = Map<String, int>.from(
            (data['reactions'] ?? const <String, int>{}).map((k, v) => MapEntry(
                  k.toString(),
                  v is int ? v : (v as num?)?.toInt() ?? 0,
                )),
          );

          final uid = widget.currentUserId ?? '';
          final Map<String, dynamic> byUserDyn =
              Map<String, dynamic>.from(data['reactionsByUser'] ?? {});
          final String? myEmoji =
              byUserDyn[uid] is String ? byUserDyn[uid] as String : null;

          setState(() {
            _remoteDocReactions[m.id] = counts;
            if (myEmoji != null) {
              _myReactionFromDoc[m.id] = myEmoji;
            } else {
              _myReactionFromDoc.remove(m.id);
            }
          });

          _reconcileLocalIfCovered(m.id);
        });
      }
    }
  }

  void _reconcileLocalIfCovered(String id) {
    final local = _localReactions[id];
    if (local == null) return;
    final remote = _remoteDocReactions[id] ?? const <String, int>{};
    if (_covers(remote, local)) {
      setState(() => _localReactions.remove(id));
    }
    if (_myReactionLocal.containsKey(id) &&
        _myReactionFromDoc.containsKey(id)) {
      setState(() => _myReactionLocal.remove(id));
    }
  }

  bool _covers(Map<String, int> remote, Map<String, int> local) {
    for (final e in local.entries) {
      if ((remote[e.key] ?? 0) < e.value) return false;
    }
    return true;
  }

  // ---------- Localized formatters ----------
  String _formatRelativeWithLoc(BuildContext context, DateTime ts) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return t.relNow;
    if (diff.inMinutes < 60) return t.relMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.relHoursAgo(diff.inHours);
    // Keep a short dd/MM HH:mm for both locales (simple & compact)
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.day)}/${two(ts.month)} ${two(ts.hour)}:${two(ts.minute)}';
  }

  String _formatDistanceMetersLoc(BuildContext context, double meters) {
    final t = AppLocalizations.of(context);
    if (meters < 60) return t.distVeryClose;
    if (meters < 300) return t.distClose;
    if (meters < 1000) return '${meters.toStringAsFixed(0)} ${t.unitM}';
    return '${(meters / 1000).toStringAsFixed(1)} ${t.unitKm}';
  }

  String _formatDistanceBucketLoc(BuildContext context, double meters) {
    final t = AppLocalizations.of(context);
    if (meters <= 500) return t.distVeryClose;
    if (meters <= 1000) return t.distClose;
    if (meters <= 2000) return t.distInArea;
    if (meters <= 3000) return t.distFar;
    return t.distVeryFar;
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

  // ------------------------ Firestore reazioni ------------------------
  Future<bool> _persistReaction(VoiceMessage message, String newEmoji) async {
    final uid = widget.currentUserId;
    if (uid == null) return false;
    final docRef =
        FirebaseFirestore.instance.collection('messages').doc(message.id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;

        final data = snap.data() as Map<String, dynamic>;

        final Map<String, int> counts = Map<String, int>.from(
          (data['reactions'] ?? const <String, int>{}).map(
            (k, v) => MapEntry(k.toString(), v is int ? v : (v as num).toInt()),
          ),
        );

        final Map<String, dynamic> rawByUser =
            Map<String, dynamic>.from(data['reactionsByUser'] ?? {});
        final Map<String, String> byUser = {};
        rawByUser.forEach((k, v) {
          if (v is String) byUser[k] = v;
        });

        final prevEmoji = byUser[uid];
        if (prevEmoji == newEmoji) return;

        if (prevEmoji != null) {
          final oldVal = (counts[prevEmoji] ?? 0) - 1;
          if (oldVal > 0) {
            counts[prevEmoji] = oldVal;
          } else {
            counts.remove(prevEmoji);
          }
        }

        counts[newEmoji] = (counts[newEmoji] ?? 0) + 1;
        byUser[uid] = newEmoji;

        tx.update(docRef, {
          'reactions': counts,
          'reactionsByUser': byUser,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _persistReactionRemoval(VoiceMessage message) async {
    final uid = widget.currentUserId;
    if (uid == null) return false;

    final docRef =
        FirebaseFirestore.instance.collection('messages').doc(message.id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;

        final data = snap.data() as Map<String, dynamic>;

        final Map<String, int> counts = Map<String, int>.from(
          (data['reactions'] ?? const <String, int>{}).map(
            (k, v) => MapEntry(k.toString(), v is int ? v : (v as num).toInt()),
          ),
        );

        final Map<String, dynamic> rawByUser =
            Map<String, dynamic>.from(data['reactionsByUser'] ?? {});
        final Map<String, String> byUser = {};
        rawByUser.forEach((k, v) {
          if (v is String) byUser[k] = v;
        });

        final prevEmoji = byUser[uid];
        if (prevEmoji == null) return;

        final newVal = (counts[prevEmoji] ?? 0) - 1;
        if (newVal > 0) {
          counts[prevEmoji] = newVal;
        } else {
          counts.remove(prevEmoji);
        }
        byUser.remove(uid);

        tx.update(docRef, {
          'reactions': counts,
          'reactionsByUser': byUser,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _applyLocalReaction(VoiceMessage message, String emoji) async {
    final prev = _myReactionLocal[message.id] ?? _myReactionFromDoc[message.id];

    Map<String, int>? before;
    setState(() {
      final base = Map<String, int>.from(
        _localReactions[message.id] ??
            _remoteDocReactions[message.id] ??
            (message.reactions ?? const <String, int>{}),
      );
      before = Map<String, int>.from(base);

      if (prev == null) {
        base[emoji] = (base[emoji] ?? 0) + 1;
      } else if (prev != emoji) {
        final old = (base[prev] ?? 0) - 1;
        if (old > 0) {
          base[prev] = old;
        } else {
          base.remove(prev);
        }
        base[emoji] = (base[emoji] ?? 0) + 1;
      }
      _localReactions[message.id] = base;
      _myReactionLocal[message.id] = emoji;
    });

    final ok = await _persistReaction(message, emoji);
    if (!ok) {
      setState(() {
        if (before != null) _localReactions[message.id] = before!;
        _myReactionLocal.remove(message.id);
      });
    } else {
      widget.onToggleReaction(message, emoji);
    }
  }

  Future<void> _applyLocalReactionRemoval(VoiceMessage message) async {
    final prev = _myReactionLocal[message.id] ?? _myReactionFromDoc[message.id];
    if (prev == null) return;

    Map<String, int>? before;
    setState(() {
      final base = Map<String, int>.from(
        _localReactions[message.id] ??
            _remoteDocReactions[message.id] ??
            (message.reactions ?? const <String, int>{}),
      );
      before = Map<String, int>.from(base);

      final nv = (base[prev] ?? 0) - 1;
      if (nv > 0) {
        base[prev] = nv;
      } else {
        base.remove(prev);
      }

      _localReactions[message.id] = base;
      _myReactionLocal.remove(message.id);
    });

    final ok = await _persistReactionRemoval(message);
    if (!ok) {
      setState(() {
        if (before != null) _localReactions[message.id] = before!;
        _myReactionLocal[message.id] = prev;
      });
    }
  }

  // ===========================================================================
  // 🎯 Reactions overlay (picker)
  // ===========================================================================
  void _showReactionsOverlay({
    required BuildContext context,
    required GlobalKey anchorKey,
    required VoiceMessage message,
  }) {
    _hideReactionsOverlay();
    HapticFeedback.mediumImpact();

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) {
      _showReactionsFallbackDialog(context, message);
      return;
    }

    final RenderBox? box =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        overlayState.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) {
      _showReactionsFallbackDialog(context, message);
      return;
    }

    final Offset anchor = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Size anchorSize = box.size;

    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

    const double emojiSize = 22.0;
    const double emojiPadH = 10.0;
    const double pillHPadEdge = 20.0;
    const double pillVPad = 12.0;

    const double pillHeightEstimate = emojiSize + (pillVPad * 2) + 4.0;

    final double neededWidth =
        (emojis.length * (emojiSize + (emojiPadH * 2))) + (pillHPadEdge * 2);
    const double sidePadding = 8.0;
    final double screenWidth = overlayBox.size.width;
    final double maxWidth = screenWidth - (sidePadding * 2);
    final double pillWidth = math.min(neededWidth, maxWidth);

    double left = anchor.dx + (anchorSize.width / 2) - (pillWidth / 2);
    final bool isReceived = message.senderId != (widget.currentUserId ?? '');
    if (isReceived) left += 5.0;
    left = left.clamp(sidePadding, screenWidth - pillWidth - sidePadding);

    double top = anchor.dy - pillHeightEstimate - 6.0;
    top = top.clamp(
      12.0,
      overlayBox.size.height - pillHeightEstimate - 12.0,
    );

    _reactionsOverlay = OverlayEntry(
      builder: (_) {
        final current =
            _myReactionLocal[message.id] ?? _myReactionFromDoc[message.id];

        Widget emojisStrip() {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: emojis.map((e) {
                final selected = current == e;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (selected) {
                      await _applyLocalReactionRemoval(message);
                      _hideReactionsOverlay();
                      return;
                    }
                    await _applyLocalReaction(message, e);
                    _hideReactionsOverlay();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: emojiPadH),
                    child: Opacity(
                      opacity: selected ? 0.55 : 1.0,
                      child: Text(
                        e,
                        style:
                            const TextStyle(fontSize: emojiSize, height: 1.2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }

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
              left: left,
              top: top,
              width: pillWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: pillHPadEdge,
                    vertical: pillVPad,
                  ),
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
                  clipBehavior: Clip.antiAlias,
                  child: emojisStrip(),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(_reactionsOverlay!);
  }

  void _showReactionsFallbackDialog(
      BuildContext context, VoiceMessage message) {
    final t = AppLocalizations.of(context);
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    final String? current =
        _myReactionLocal[message.id] ?? _myReactionFromDoc[message.id];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.reactionsTitle),
        content: Wrap(
          spacing: 8,
          children: emojis.map((e) {
            final selected = current == e;
            return InkWell(
              onTap: () async {
                HapticFeedback.selectionClick();
                if (selected) {
                  await _applyLocalReactionRemoval(message);
                } else {
                  await _applyLocalReaction(message, e);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Opacity(
                opacity: selected ? 0.55 : 1.0,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final canSendText = widget.textController.text.trim().isNotEmpty &&
        widget.textController.text.characters.length <= 250 &&
        !widget.isSendingText;

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
                     context,  // Aggiungi context come primo parametro
                     m.category,
                     messageCustomName: m.customCategoryName,
                     ),
                      userNameBuilder: (m) {
                        final myId = widget.currentUserId ?? '';
                        if (m.senderId == myId) return t.you;
                        final String n = (m.name).trim();
                        return n.isEmpty ? t.anonymous : n;
                      },
                      distanceBuilder: (m) {
                        final d = _distanceTo(m);
                        final isMine =
                            m.senderId == (widget.currentUserId ?? '');
                        return isMine
                            ? _formatDistanceMetersLoc(context, d)
                            : _formatDistanceBucketLoc(context, d);
                      },
                      timeBuilder: (ts) => _formatRelativeWithLoc(context, ts),
                      pal: _AdaptivePalette.of(
                        context,
                        accent: widget.selectedCategory.color,
                      ),
                      reactionsBuilder: (m) {
                        final local = _localReactions[m.id];
                        if (local != null) return local;
                        final doc = _remoteDocReactions[m.id];
                        if (doc != null && doc.isNotEmpty) return doc;
                        return m.reactions ?? const <String, int>{};
                      },
                      onRequestBlockUser: widget.onRequestBlockUser,
                      onRequestReportUser: widget.onRequestReportUser,
                      showReactionsOverlay: ({
                        required BuildContext context,
                        required GlobalKey anchorKey,
                        required VoiceMessage message,
                      }) =>
                          _showReactionsOverlay(
                        context: context,
                        anchorKey: anchorKey,
                        message: message,
                      ),
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
    final t = AppLocalizations.of(context);
    final color = selectedCategory.color;
    final pal = _AdaptivePalette.of(context, accent: color);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: t.tooltipSettings,
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
                    context,  // Aggiungi context come primo parametro
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
              tooltip: t.tooltipFilters,
              onPressed: onToggleFilterSelector,
              icon: const Icon(Icons.filter_list),
            ),
            IconButton(
              tooltip: t.tooltipRadius,
              onPressed: onToggleRadiusSelector,
              icon: const Icon(Icons.radar),
            ),
            IconButton(
              tooltip: t.tooltipProfile,
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

  String _radiusLabel(BuildContext context, double r) {
    final t = AppLocalizations.of(context);
    return (r >= 1000)
        ? '${(r / 1000).toStringAsFixed(1)} ${t.unitKm}'
        : '${r.toStringAsFixed(0)} ${t.unitM}';
  }

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
                label: Text(_radiusLabel(context, r)),
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
// 📨 Messages list
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

  final Map<String, int> Function(VoiceMessage) reactionsBuilder;

  final void Function(VoiceMessage message)? onRequestBlockUser;
  final void Function(VoiceMessage message)? onRequestReportUser;

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
    this.onRequestBlockUser,
    this.onRequestReportUser,
  });

  // ---------- Block fallback ----------
  Future<bool> _tryAppendBlocked({
    required String collection,
    required String field,
    required String uid,
    required String targetId,
  }) async {
    await FirebaseFirestore.instance.collection(collection).doc(uid).set({
      field: FieldValue.arrayUnion([targetId])
    }, SetOptions(merge: true));
    return true;
  }

  Future<void> _blockFlow(BuildContext context, VoiceMessage m) async {
    final t = AppLocalizations.of(context);

    final uid = currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.mustBeAuthenticatedToBlock)),
      );
      return;
    }
    if (m.senderId == uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.cannotBlockYourself)),
      );
      return;
    }
    if (m.senderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidUserIdToBlock)),
      );
      return;
    }

    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t.blockIgnoreTitle),
            content: Text(t.blockConfirmText(
              (m.name).trim().isEmpty ? t.anonymous : m.name.trim(),
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t.block),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    final attempts = <({String coll, String field})>[
      (coll: 'users', field: 'blockedUserIds'),
      (coll: 'utenti', field: 'id_bloccati'),
    ];

    FirebaseException? lastErr;
    for (final a in attempts) {
      try {
        await _tryAppendBlocked(
          collection: a.coll,
          field: a.field,
          uid: uid,
          targetId: m.senderId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.userBlockedSimple)),
          );
        }
        return;
      } on FirebaseException catch (e) {
        lastErr = e;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.blockError}: $e')),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      final code = lastErr?.code ?? 'unknown';
      final msg = lastErr?.message ?? lastErr.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.blockError}: [$code] $msg')),
      );
    }
  }

  // ---------- Report fallback ----------
  Future<void> _reportFlow(BuildContext context, VoiceMessage m) async {
    final t = AppLocalizations.of(context);

    if (onRequestReportUser != null) {
      onRequestReportUser!(m);
      return;
    }

    final TextEditingController reasonCtrl = TextEditingController();
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(t.reportUserTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.reportDescribeOptional),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: t.reportReasonHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(t.send),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final reporter = (currentUserId ?? 'anon');
    final payload = {
      'messageId': m.id,
      'targetUserId': m.senderId,
      'targetUserName': (m.name).trim().isEmpty ? 'Anonimo' : m.name.trim(),
      'reporterUserId': reporter,
      'reason': reasonCtrl.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'messageType': m.type,
      'category': m.category.name,
      'latitude': m.latitude,
      'longitude': m.longitude,
    };

    try {
      await FirebaseFirestore.instance.collection('reports').add(payload);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.reportSentThanks)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.reportNotSent}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showMessageActions(
    BuildContext context,
    VoiceMessage m,
    GlobalKey anchorKey,
  ) async {
    HapticFeedback.mediumImpact();
    final t = AppLocalizations.of(context);

    final isMine = m.senderId == (currentUserId ?? '');

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: pal.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: isMine
                    ? Text(t.cannotReportYourself)
                    : Text(t.reportUserTitleShort),
                subtitle: isMine
                    ? Text(t.operationNotAllowed)
                    : Text(t.reportUserSubtitle),
                enabled: !isMine,
                onTap: isMine
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _reportFlow(context, m);
                      },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: isMine
                    ? Text(t.cannotBlockYourself)
                    : Text(t.blockIgnoreTitleShort),
                subtitle: isMine
                    ? Text(t.operationNotAllowed)
                    : Text(t.blockIgnoreSubtitle),
                enabled: !isMine,
                onTap: isMine
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        if (onRequestBlockUser != null) {
                          try {
                            onRequestBlockUser!(m);
                            return;
                          } catch (_) {
                            // fallback below
                          }
                        }
                        await _blockFlow(context, m);
                      },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (messages.isEmpty) {
      return Center(
        child: Text(
          t.noMessagesInArea,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
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

        void openReactionsLocal(GlobalKey key) => showReactionsOverlay(
              context: context,
              anchorKey: key,
              message: m,
            );

        return _ChatBubble(
          key: ValueKey(m.id),
          message: m,
          isMine: isMine,
          isPlaying: isPlaying,
          categoryLabel: labelBuilder(m),
          userName: userNameBuilder(m),
          distanceLabel: distanceBuilder(m),
          timeLabel: timeBuilder(m.timestamp),
          onPlay: () => onPlayMessage(m),
          onLongPress: (key) => _showMessageActions(context, m, key),
          onOpenReactions: openReactionsLocal,
          onToggleReaction: (emoji) => onToggleReaction(m, emoji),
          pal: pal,
          reactions: reactions,
        );
      },
    );
  }
}

// =============================================================================
// 💬 Chat bubble
// =============================================================================
class _ChatBubble extends StatefulWidget {
  final VoiceMessage message;
  final bool isMine;
  final bool isPlaying;

  final String categoryLabel;
  final String userName;
  final String distanceLabel;
  final String timeLabel;

  final VoidCallback onPlay;
  final void Function(GlobalKey) onLongPress;
  final void Function(GlobalKey) onOpenReactions;
  final void Function(String emoji) onToggleReaction;
  final _AdaptivePalette pal;
  final Map<String, int> reactions;

  const _ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isPlaying,
    required this.categoryLabel,
    required this.userName,
    required this.distanceLabel,
    required this.timeLabel,
    required this.onPlay,
    required this.onLongPress,
    required this.onOpenReactions,
    required this.onToggleReaction,
    required this.pal,
    required this.reactions,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _destructCtrl;
  Timer? _startTimer;
  bool _started = false;

  DateTime get _expiry => widget.message.timestamp.add(_kMessageTTL);

  @override
  void initState() {
    super.initState();
    _destructCtrl = AnimationController(
      vsync: this,
      duration: _kDestructWindow,
    );
    _scheduleDestruction();
  }

  @override
  void didUpdateWidget(covariant _ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id ||
        oldWidget.message.timestamp != widget.message.timestamp) {
      _startTimer?.cancel();
      _destructCtrl.stop();
      _destructCtrl.value = 0;
      _started = false;
      _scheduleDestruction();
    }
  }

  void _scheduleDestruction() {
    final now = DateTime.now();
    final startAt = _expiry.subtract(_kDestructWindow);
    if (now.isAfter(_expiry)) {
      _started = true;
      _destructCtrl.value = 1;
      return;
    }
    if (!now.isBefore(startAt)) {
      final elapsed = now.difference(startAt);
      final p = (elapsed.inMilliseconds / _kDestructWindow.inMilliseconds)
          .clamp(0.0, 1.0);
      _started = true;
      _destructCtrl.value = p;
      _destructCtrl.forward();
      return;
    }
    final delay = startAt.difference(now);
    _startTimer = Timer(delay, () {
      if (!mounted) return;
      _started = true;
      _destructCtrl.forward(from: 0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _destructCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _destructCtrl,
      builder: (_, __) {
        final progress = _started ? _destructCtrl.value : 0.0;
        return _ChatBubbleVisual(
          message: widget.message,
          isMine: widget.isMine,
          isPlaying: widget.isPlaying,
          categoryLabel: widget.categoryLabel,
          userName: widget.userName,
          distanceLabel: widget.distanceLabel,
          timeLabel: widget.timeLabel,
          onPlay: widget.onPlay,
          onLongPress: widget.onLongPress,
          onOpenReactions: widget.onOpenReactions,
          onToggleReaction: widget.onToggleReaction,
          pal: widget.pal,
          reactions: widget.reactions,
          destructProgress: progress,
          destructSeed: widget.message.id.hashCode,
        );
      },
    );
  }
}

class _ChatBubbleVisual extends StatelessWidget {
  final VoiceMessage message;
  final bool isMine;
  final bool isPlaying;

  final String categoryLabel;
  final String userName;
  final String distanceLabel;
  final String timeLabel;

  final VoidCallback onPlay;
  final void Function(GlobalKey) onLongPress;
  final void Function(GlobalKey) onOpenReactions;
  final void Function(String emoji) onToggleReaction;
  final _AdaptivePalette pal;
  final Map<String, int> reactions;

  // 🧨 SELF-DESTRUCT
  final double destructProgress;
  final int destructSeed;

  _ChatBubbleVisual({
    required this.message,
    required this.isMine,
    required this.isPlaying,
    required this.categoryLabel,
    required this.userName,
    required this.distanceLabel,
    required this.timeLabel,
    required this.onPlay,
    required this.onLongPress,
    required this.onOpenReactions,
    required this.onToggleReaction,
    required this.pal,
    required this.reactions,
    required this.destructProgress,
    required this.destructSeed,
  });

  final GlobalKey _bubbleKey = GlobalKey();

  String _countdownLeft(DateTime ts) {
    final expiry = ts.add(_kMessageTTL);
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
    final t = AppLocalizations.of(context);
    final accent = message.category.color;

    final Color bubbleBg = isMine ? pal.bubbleMine : pal.bubbleOther;
    final Color textColor = isMine ? pal.onBubbleMine : pal.onBubbleOther;

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

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
    final double maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;

    Widget viewsChip() {
      final views = message.views;
      final label = views <= 0 ? t.newLabel : views.toString();
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

    final double fade = destructProgress == 0
        ? 1.0
        : (1.0 - Curves.easeInOut.transform(destructProgress)).clamp(0.0, 1.0);

    final bubbleCore = _BubbleCore(
      key: _bubbleKey,
      bubbleBg: bubbleBg,
      borderRadius: borderRadius,
      accent: accent,
      message: message,
      categoryLabel: categoryLabel,
      distanceLabel: distanceLabel,
      userName: userName,
      textColor: textColor,
      isMine: isMine,
      hasReactions: hasReactions,
      reactions: reactions,
      pal: pal,
      timeLabel: timeLabel,
      countdownChip: countdownChip,
      viewsChip: viewsChip,
      onPlay: onPlay,
      isPlaying: isPlaying,
      onOpenReactions: () => onOpenReactions(_bubbleKey),
    );

    final erodible = (destructProgress > 0)
        ? _ErodeAndDust(
            progress: destructProgress,
            seed: destructSeed,
            borderRadius: borderRadius,
            // ignore: deprecated_member_use
            dustColor: pal.onSurface.withOpacity(0.18),
            child: bubbleCore,
          )
        : bubbleCore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => onLongPress(_bubbleKey),
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: Opacity(opacity: fade, child: erodible),
          ),
        ),
      ),
    );
  }
}

// (Self-destruct visuals unchanged…)
class _ErodeAndDust extends StatelessWidget {
  final double progress;
  final int seed;
  final BorderRadius borderRadius;
  final Color dustColor;
  final Widget child;

  const _ErodeAndDust({
    required this.progress,
    required this.seed,
    required this.borderRadius,
    required this.dustColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _ErosionClipper(
            progress: progress,
            seed: seed,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
        if (progress > 0 && progress <= 0.9)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DustPainter(
                  progress: progress,
                  seed: seed ^ 0x9E3779B9,
                  color: dustColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ErosionClipper extends CustomClipper<Path> {
  final double progress;
  final int seed;
  final BorderRadius borderRadius;

  _ErosionClipper({
    required this.progress,
    required this.seed,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final base = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
      );

    final rnd = math.Random(seed);
    final holes = Path();

    const int maxHoles = 18;
    final int count = (maxHoles * progress.clamp(0.1, 1.0)).ceil();

    for (int i = 0; i < count; i++) {
      final side = rnd.nextInt(4);
      final t = rnd.nextDouble();
      final edgeInset = 2.0 + 8.0 * progress;
      double cx, cy;

      switch (side) {
        case 0:
          cx = 8 + t * (size.width - 16);
          cy = edgeInset + rnd.nextDouble() * (8.0 * progress);
          break;
        case 1:
          cx = size.width - edgeInset - rnd.nextDouble() * (8.0 * progress);
          cy = 8 + t * (size.height - 16);
          break;
        case 2:
          cx = 8 + t * (size.width - 16);
          cy = size.height - edgeInset - rnd.nextDouble() * (8.0 * progress);
          break;
        default:
          cx = edgeInset + rnd.nextDouble() * (8.0 * progress);
          cy = 8 + t * (size.height - 16);
      }

      final baseR = 6.0 + 22.0 * progress;
      final jitter = (rnd.nextDouble() - 0.5) * (8.0 * progress);
      final radius = (baseR + jitter).clamp(3.0, 28.0);

      holes.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      if (progress > 0.25 && rnd.nextBool()) {
        final int micro = 1 + rnd.nextInt(2);
        for (int k = 0; k < micro; k++) {
          final dx = (rnd.nextDouble() - 0.5) * (radius * 0.8);
          final dy = (rnd.nextDouble() - 0.5) * (radius * 0.8);
          final rr = radius * (0.25 + rnd.nextDouble() * 0.25);
          holes.addOval(
              Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: rr));
        }
      }
    }

    final clip = Path.combine(PathOperation.difference, base, holes);
    return clip;
  }

  @override
  bool shouldReclip(covariant _ErosionClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.seed != seed ||
        oldClipper.borderRadius != borderRadius;
  }
}

class _DustPainter extends CustomPainter {
  final double progress;
  final int seed;
  final Color color;

  _DustPainter(
      {required this.progress, required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    final emitStrength = Curves.easeInOut
        .transform(
          (progress <= 0.66)
              ? (progress / 0.66)
              : (1.0 - (progress - 0.66) / 0.34),
        )
        .clamp(0.0, 1.0);

    if (emitStrength <= 0) return;

    const int baseParticles = 24;
    final num n = (baseParticles * emitStrength).clamp(6, baseParticles);

    for (int i = 0; i < n; i++) {
      final birth = rnd.nextDouble() * 0.33;
      final life = 0.1 + rnd.nextDouble() * 0.25 + 0.6;
      final age = progress - birth;
      if (age <= 0 || age > life) continue;
      final t = (age / life).clamp(0.0, 1.0);
      final ease = Curves.easeOut.transform(t);

      final side = rnd.nextInt(4);
      final s = rnd.nextDouble();
      double ax, ay;
      switch (side) {
        case 0:
          ax = 8 + s * (size.width - 16);
          ay = 8;
          break;
        case 1:
          ax = size.width - 8;
          ay = 8 + s * (size.height - 16);
          break;
        case 2:
          ax = 8 + s * (size.width - 16);
          ay = size.height - 8;
          break;
        default:
          ax = 8;
          ay = 8 + s * (size.height - 16);
      }
      final outward = switch (side) {
        0 => const Offset(0, -1),
        1 => const Offset(1, 0),
        2 => const Offset(0, 1),
        _ => const Offset(-1, 0),
      };
      final lateral = Offset(
          (rnd.nextDouble() - 0.5) * 0.6, (rnd.nextDouble() - 0.5) * 0.6);

      final speed = 8.0 + rnd.nextDouble() * 10.0;
      Offset pos = Offset(ax, ay) +
          (outward * (speed * ease)) +
          (lateral * (6.0 * ease));

      final back = (Offset(ax, ay) - pos) * 0.15 * (1.0 - ease);
      pos += back;

      pos = pos.translate(0, 0.5 * ease);

      final radius = 0.8 + rnd.nextDouble() * 1.6;
      final alpha = (0.22 * (1.0 - t)).clamp(0.0, 0.22);
      // ignore: deprecated_member_use
      paint.color = color.withOpacity(alpha);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seed != seed ||
        oldDelegate.color != color;
  }
}

// =============================================================================
// 💡 Bubble core
// =============================================================================
class _BubbleCore extends StatelessWidget {
  final Color bubbleBg;
  final BorderRadius borderRadius;
  final Color accent;
  final VoiceMessage message;
  final String categoryLabel;
  final String distanceLabel;
  final String userName;
  final Color textColor;
  final bool isMine;
  final bool hasReactions;
  final Map<String, int> reactions;
  final _AdaptivePalette pal;
  final String timeLabel;
  final Widget Function() countdownChip;
  final Widget Function() viewsChip;
  final VoidCallback onPlay;
  final bool isPlaying;
  final VoidCallback onOpenReactions;

  const _BubbleCore({
    super.key,
    required this.bubbleBg,
    required this.borderRadius,
    required this.accent,
    required this.message,
    required this.categoryLabel,
    required this.distanceLabel,
    required this.userName,
    required this.textColor,
    required this.isMine,
    required this.hasReactions,
    required this.reactions,
    required this.pal,
    required this.timeLabel,
    required this.countdownChip,
    required this.viewsChip,
    required this.onPlay,
    required this.isPlaying,
    required this.onOpenReactions,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final container = Container(
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
          // Header category + distance
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: Row(
              children: [
                Icon(message.category.icon, size: 16, color: accent),
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
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 2),
                Text(
                  distanceLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Username
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
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

          // Body (text or voice)
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

          // Reactions pill
          if (hasReactions)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Align(
                alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: _ReactionsPill(
                  reactions: reactions,
                  isMine: isMine,
                  pal: pal,
                ),
              ),
            ),

          // Footer: time + emoji + countdown + views
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: t.tooltipReactions,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    onPressed: onOpenReactions,
                    icon: const Icon(Icons.emoji_emotions_outlined),
                  ),
                ),
                const SizedBox(width: 4),
                countdownChip(),
                const SizedBox(width: 12),
                viewsChip(),
              ],
            ),
          ),
        ],
      ),
    );

    if (!message.isText) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPlay,
        child: container,
      );
    }
    return container;
  }
}

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
                      color: _alpha(pal.onSurface, 0.75),
                      fontWeight: FontWeight.w700),
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
// 🎵 Voice row
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
                    progress: _ctrl.value,
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
  final double progress;
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
    final t = AppLocalizations.of(context);
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
                context,  // Aggiungi context come primo parametro
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
                      hintText: t.composerHint,
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
// 👋 Welcome overlay
// =============================================================================
class _WelcomeOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _WelcomeOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
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
                  Text(
                    t.welcomeTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.welcomeBody,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onClose,
                    child: Text(t.understood),
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
