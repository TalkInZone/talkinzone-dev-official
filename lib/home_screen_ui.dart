// home_screen_ui.dart — versione completa
// ✅ Modifiche principali in questo file:
// 1) NEW: import 'visibility_detector' per rilevare la visibilità della bolla.
// 2) NEW: nuova callback final Function(VoiceMessage) onTextVisible;
// 3) NEW: wrap del contenuto TESTUALE con VisibilityDetector:
//         quando la frazione visibile ≥ 0.6 chiamiamo onTextVisible(message).
//    -> questo attiva la marcatura “letto” SOLO quando la bolla è realmente vista.

import 'package:flutter/material.dart';
import 'package:myapp/category_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import 'voice_message.dart';
import 'package:visibility_detector/visibility_detector.dart'; // NEW

class HomeScreenUI extends StatefulWidget {
  // Stato/props
  final bool showWelcomeMessage;
  final bool isInitialized;
  final bool showRadiusSelector;
  final bool showFilterSelector;
  final Set<MessageCategory> activeFilters;
  final bool showCategorySelector;
  final MessageCategory selectedCategory;
  final List<VoiceMessage> filteredMessages;
  final String? currentUserId;
  final Position? currentPosition;
  final double selectedRadius;
  final bool isRecording;
  final int recordingSeconds;
  final bool isLongPressRecording;
  final bool isWaitingForRelease;
  final String? playingMessageId;
  final List<double> radiusOptions;

  // NEW: input testo
  final TextEditingController textController;
  final String textError;
  final VoidCallback onSendText;

  // NEW: callback per “testo visibile in viewport” (≥ 60%)
  final Function(VoiceMessage) onTextVisible; // NEW

  // Callback
  final Function(VoiceMessage) onPlayMessage;
  final VoidCallback onToggleRadiusSelector;
  final Function(MessageCategory) onFilterToggled;
  final VoidCallback onToggleFilterSelector;
  final Function(MessageCategory) onCategorySelected;
  final VoidCallback onToggleCategorySelector;
  final VoidCallback onSettingsPressed;
  final VoidCallback onProfilePressed; // profilo nella barra blu
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onStopRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onWelcomeDismissed;

  // cambia raggio
  final Function(double) onRadiusChanged;

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
    required this.onSendText,
    required this.onTextVisible, // NEW
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
  });

  @override
  State<HomeScreenUI> createState() => _HomeScreenUIState();
}

class _HomeScreenUIState extends State<HomeScreenUI> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}';
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Ora';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m fa';
    return '${difference.inHours}h fa';
  }

  String _getTimeRemaining(DateTime timestamp) {
    final now = DateTime.now();
    final elapsed = now.difference(timestamp);
    final remaining = const Duration(minutes: 5) - elapsed;
    if (remaining.isNegative) return '0:00';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getSenderDisplayName(VoiceMessage message) {
    if (message.senderId == widget.currentUserId) return 'Tu';
    return message.name.isNotEmpty ? message.name : 'Anonimo';
  }

  String _formatDistanceGenerically(double meters) {
    if (meters < 1000) return 'Molto vicino';
    if (meters < 3000) return 'Vicino';
    if (meters < 7000) return 'Nelle vicinanze';
    return 'Lontano';
  }

  Widget _buildWelcomeDialog() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Benvenuto in TalkInZone!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Questa è una versione pre-alpha, disponibile per un mese.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "L'app è ancora in costruzione, ma ogni utilizzo ci aiuta a migliorarla.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "Il nostro obiettivo? Offrire uno strumento versatile per social, promozione ed eventi.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              "Provala e, se qualcosa ti viene in mente, il tuo feedback sarà più che benvenuto!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                const url = 'https://talkinzone-normative.vercel.app/';
                try {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Impossibile aprire il link'),
                          action: SnackBarAction(
                            label: 'COPIA LINK',
                            onPressed: () {
                              FlutterClipboard.copy(url);
                            },
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // ignore
                }
              },
              child: Text(
                'Informative sulla privacy',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onWelcomeDismissed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'INIZIA AD USARE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Visibility(
        visible: widget.showRadiusSelector,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (widget.isRecording
                        ? widget.selectedCategory.color
                        : Colors.blue)
                    .withAlpha(77),
                spreadRadius: widget.isRecording ? 8 : 4,
                blurRadius: widget.isRecording ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onToggleRadiusSelector,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleziona raggio di visualizzazione:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.radiusOptions.map((radius) {
                      final isSelected = widget.selectedRadius == radius;
                      return ChoiceChip(
                        label: Text(
                          radius < 1000
                              ? '${radius.toInt()} m'
                              : '${(radius / 1000).toStringAsFixed(0)} km',
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) widget.onRadiusChanged(radius);
                        },
                        selectedColor: Colors.blue[100],
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue[800] : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Messaggi entro ${widget.selectedRadius < 1000 ? '${widget.selectedRadius.toInt()} metri' : '${(widget.selectedRadius / 1000).toInt()} km'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showWelcomeMessage) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(child: _buildWelcomeDialog()),
      );
    }

    if (!widget.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inizializzazione in corso...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkInZone'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.place),
            onPressed: widget.onToggleRadiusSelector,
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (widget.activeFilters.length < MessageCategory.values.length)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: widget.onToggleFilterSelector,
          ),
          IconButton(
            icon: const Icon(Icons.person), // profilo nella barra blu
            onPressed: widget.onProfilePressed,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: widget.onSettingsPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRadiusSelector(),
          if (widget.showFilterSelector)
            FilterSelector(
              activeFilters: widget.activeFilters,
              onFilterToggled: widget.onFilterToggled,
              onClose: widget.onToggleFilterSelector,
            ),
          if (widget.showCategorySelector)
            CategorySelector(
              selectedCategory: widget.selectedCategory,
              onCategorySelected: widget.onCategorySelected,
              onClose: widget.onToggleCategorySelector,
            ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: widget.filteredMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic_none,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun messaggio nelle vicinanze',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.selectedRadius < 1000
                                ? 'Raggio di visualizzazione: ${widget.selectedRadius.toInt()} metri'
                                : 'Raggio di visualizzazione: ${(widget.selectedRadius / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: widget.filteredMessages.length,
                      itemBuilder: (context, index) {
                        final message = widget.filteredMessages[index];
                        final isPlaying = widget.playingMessageId == message.id;
                        final isCurrentUser =
                            message.senderId == widget.currentUserId;

                        double? distance;
                        if (widget.currentPosition != null) {
                          distance = Geolocator.distanceBetween(
                            widget.currentPosition!.latitude,
                            widget.currentPosition!.longitude,
                            message.latitude,
                            message.longitude,
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            if (message.isVoice) {
                              widget.onPlayMessage(message);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: message.category.color.withAlpha(25),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft:
                                        Radius.circular(isCurrentUser ? 18 : 4),
                                    bottomRight:
                                        Radius.circular(isCurrentUser ? 4 : 18),
                                  ),
                                  border: Border.all(
                                    color: message.category.color,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Intestazione (categoria + distanza)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              message.category.icon,
                                              size: 14,
                                              color: message.category.color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              message.category.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: message.category.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (distance != null)
                                          Row(
                                            children: [
                                              Icon(Icons.place,
                                                  size: 12,
                                                  color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDistanceGenerically(
                                                    distance),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // CORPO: testo o voce
                                    if (message.isText) ...[
                                      // —— TESTO —— //
                                      // NEW: wrappiamo il blocco di testo con VisibilityDetector.
                                      VisibilityDetector(
                                        key: Key('text-visible-${message.id}'),
                                        onVisibilityChanged: (info) {
                                          // soglia: almeno il 60% della bolla visibile
                                          if (info.visibleFraction >= 0.6) {
                                            widget.onTextVisible(message);
                                          }
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text ?? '',
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                            const SizedBox(height: 6),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      // —— VOCALE —— //
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isPlaying
                                                  ? Colors.red
                                                  : message.category.color,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPlaying
                                                  ? Icons.stop
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    // Mittente: "Tu" o nome
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.person,
                                                          size: 12,
                                                          color: isCurrentUser
                                                              ? message.category
                                                                  .color
                                                              : Colors
                                                                  .grey[600],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          _getSenderDisplayName(
                                                              message),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: isCurrentUser
                                                                ? message
                                                                    .category
                                                                    .color
                                                                : Colors
                                                                    .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    // Durata
                                                    Row(
                                                      children: [
                                                        Icon(Icons.graphic_eq,
                                                            size: 16,
                                                            color: message
                                                                .category
                                                                .color),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          _formatDuration(
                                                              message.duration),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: message
                                                                .category.color,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Tempo trascorso + rimanente
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getTimeAgo(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.category.color,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.timer,
                                                size: 12,
                                                color: Colors.orange[700]),
                                            const SizedBox(width: 2),
                                            Text(
                                              _getTimeRemaining(
                                                  message.timestamp),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Visualizzazioni
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.remove_red_eye,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          message.views > 0
                                              ? '${message.views}'
                                              : 'Nuovo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: message.views > 0
                                                ? Colors.grey[600]
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Barra registrazione (quando sta registrando)
          if (widget.isRecording)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.selectedCategory.color.withAlpha(25),
                border: Border(
                  top: BorderSide(
                    color: widget.selectedCategory.color,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.selectedCategory.icon,
                          color: widget.selectedCategory.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Registrando ${widget.selectedCategory.label}...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.selectedCategory.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.recordingSeconds.toString().padLeft(2, '0')} / 15',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.selectedCategory.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.recordingSeconds / 15.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.selectedCategory.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 4,
                        height: widget.recordingSeconds % 3 == index % 3
                            ? 30 - index * 5
                            : 20 - index * 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: widget.selectedCategory.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

          // Controlli registrazione (pulsante mic + selettore categoria)
          Container(
            padding:
                const EdgeInsets.only(top: 12, bottom: 8, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.isRecording)
                  GestureDetector(
                    onTap: widget.onToggleCategorySelector,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: widget.selectedCategory.color.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.selectedCategory.color,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        widget.selectedCategory.icon,
                        color: widget.selectedCategory.color,
                        size: 24,
                      ),
                    ),
                  ),
                if (!widget.isRecording) const SizedBox(width: 16),
                Listener(
                  onPointerDown: (_) => widget.onPressStart(),
                  onPointerUp: (_) => widget.onPressEnd(),
                  onPointerCancel: (_) => widget.onPressEnd(),
                  child: GestureDetector(
                    onTap: widget.isRecording
                        ? widget.onStopRecording
                        : widget.onStartRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: widget.isRecording
                            ? widget.selectedCategory.color
                            : Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isRecording
                                    ? widget.selectedCategory.color
                                    : Colors.blue)
                                .withAlpha(77),
                            spreadRadius: widget.isRecording ? 8 : 4,
                            blurRadius: widget.isRecording ? 16 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isRecording ? Icons.stop : Icons.mic,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Input messaggi testuali (seconda area, come in originale) ---
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Selettore categoria riuso
                    GestureDetector(
                      onTap: widget.onToggleCategorySelector,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.selectedCategory.color.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.selectedCategory.color,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          widget.selectedCategory.icon,
                          color: widget.selectedCategory.color,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: widget.textController,
                        maxLength: 250,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Scrivi (max 250)…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: widget.onSendText,
                      color: Colors.blue[700],
                      tooltip: 'Invia messaggio testuale',
                    ),
                  ],
                ),
                if (widget.textError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      widget.textError,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ FilterSelector ------------------
class FilterSelector extends StatelessWidget {
  final Set<MessageCategory> activeFilters;
  final Function(MessageCategory) onFilterToggled;
  final VoidCallback onClose;

  const FilterSelector({
    super.key,
    required this.activeFilters,
    required this.onFilterToggled,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(77),
            spreadRadius: 4,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtra per categoria:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MessageCategory.values.map((category) {
              final isActive = activeFilters.contains(category);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      size: 16,
                      color: isActive ? Colors.white : category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category.label,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                selected: isActive,
                onSelected: (_) => onFilterToggled(category),
                selectedColor: category.color,
                backgroundColor: Colors.grey[200],
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ------------------ CategorySelector ------------------
class CategorySelector extends StatelessWidget {
  final MessageCategory selectedCategory;
  final Function(MessageCategory) onCategorySelected;
  final VoidCallback onClose;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: selectedCategory.color.withAlpha(77),
            spreadRadius: 4,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seleziona categoria:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MessageCategory.values.map((category) {
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 16, color: category.color),
                    const SizedBox(width: 4),
                    Text(category.label),
                  ],
                ),
                selected: selectedCategory == category,
                onSelected: (selected) {
                  if (selected) onCategorySelected(category);
                },
                selectedColor: category.color.withAlpha(50),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: selectedCategory == category
                      ? category.color
                      : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
