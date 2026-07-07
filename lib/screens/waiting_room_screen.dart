import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firestore_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final bool isHost;
  final bool isRandom;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    this.isHost = false,
    this.isRandom = false,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  String? _guestName;
  String? _hostName;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    FirestoreService.roomStream(widget.roomCode).listen((snapshot) {
      if (!mounted || _navigating) return;
      final data = snapshot.data();
      if (data == null) return;

      final hostName = data['hostName'] as String?;
      final guestName = data['guestName'] as String?;
      final status = data['status'] as String? ?? 'waiting';

      if (mounted) {
        setState(() {
          _hostName = hostName;
          _guestName = guestName;
        });
      }

      if (widget.isHost && guestName != null && status == 'setup') {
        _navigateToSetup();
      } else if (!widget.isHost && status == 'setup') {
        _navigateToSetup();
      }
    });
  }

  void _navigateToSetup() {
    _navigating = true;
    if (!mounted) return;
    // p1 es el anfitrión, p2 es el invitado
    final p1Name = _hostName ?? widget.playerName;
    final p2Name = _guestName ?? widget.playerName;
    context.go(
      '/setup?mode=online&p1=${Uri.encodeComponent(p1Name)}&p2=${Uri.encodeComponent(p2Name)}&roomCode=${widget.roomCode}&name=${Uri.encodeComponent(widget.playerName)}&host=${widget.isHost}',
    );
  }

  Future<void> _handleContinue() async {
    await FirestoreService.setupRoom(widget.roomCode);
    if (!mounted) return;
    _navigateToSetup();
  }

  Future<void> _handleCancel() async {
    await FirestoreService.deleteRoom(widget.roomCode);
    if (!mounted) return;
    context.go('/pairing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    onPressed: _handleCancel,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Sala de Espera",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),

              // Room code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Código de la sala",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.roomCode,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isHost
                          ? "Comparte este código con tu pareja"
                          : "Esperando al anfitrión...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Host player info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        (_hostName ?? widget.playerName)[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hostName ?? widget.playerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Anfitrión",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      widget.isHost ? Icons.star : Icons.person,
                      color: widget.isHost
                          ? Colors.amber
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),

              // Guest player info (if joined)
              if (_guestName != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          _guestName![0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _guestName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.isHost ? "Invitado" : "Anfitrión",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.check_circle, color: Colors.green.shade400),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Status
              if (widget.isHost && _guestName == null)
                Text(
                  widget.isRandom
                      ? "Buscando oponente..."
                      : "Esperando a que tu pareja se una...",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              else if (!widget.isHost && _guestName == null)
                const SizedBox()
              else
                Text(
                  "¡Conectados!",
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (_guestName == null) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],

              const Spacer(),

              // Continue button (host only, when guest joined)
              if (widget.isHost && _guestName != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _handleContinue,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "Configurar Juego",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
