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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  IconButton(
                    onPressed: _handleCancel,
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 57, 57, 57),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Sala de Espera",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Encabezado
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Icon(
                  Icons.favorite_border_outlined,
                  color: Colors.pink.shade700,
                  size: 32,
                ),
              ),
              Text(
                widget.isHost && _guestName == null
                    ? "Esperando a tu pareja..."
                    : "Listos!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                "Comparte el codigo de la sala para invitar a tu pareja",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 12),
              // Room code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF151219),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 1.5,
                    color: const Color(0xFFFF5C9D),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF5C9D).withOpacity(0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    const Text(
                      "Código de la sala",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    Container(width: 120, height: 1, color: Colors.white10),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFD3E3), // Rosa claro arriba
                            Color(0xFFFF8FB7), // Rosa medio
                            Color(0xFFFF5C95), // Rosa intenso abajo
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        widget.roomCode,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.pinkAccent.withOpacity(.3),
                            thickness: 1,
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.favorite_border,
                            color: Colors.pinkAccent,
                            size: 18,
                          ),
                        ),

                        Expanded(
                          child: Divider(
                            color: Colors.pinkAccent.withOpacity(.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 32),

                        Icon(Icons.share_outlined, color: Colors.pinkAccent),

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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Host player info
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF171218),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(.08)),
                ),
                child: Column(
                  children: [
                    // HOST
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFF5C9D),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (_hostName ?? widget.playerName)[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5C9D),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tú (Anfitrión)",
                                style: TextStyle(
                                  color: Color(0xFFFF5C9D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _hostName ?? widget.playerName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white.withOpacity(.04),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.circle, color: Colors.green, size: 10),
                              SizedBox(width: 8),
                              Text("Conectado"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white10)),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.favorite,
                            color: Color(0xFFFF5C9D),
                            size: 24,
                          ),
                        ),

                        Expanded(child: Divider(color: Colors.white10)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // INVITADO
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _guestName == null
                                  ? "?"
                                  : _guestName![0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tu pareja",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _guestName ?? "Esperando...",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white.withOpacity(.04),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: _guestName == null
                                    ? Colors.pinkAccent
                                    : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _guestName == null ? "Buscando" : "Conectado",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4F93), Color(0xFFFF6DA8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4F93).withOpacity(.35),
                          blurRadius: 22,
                          spreadRadius: 1,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: _handleContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 24,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Configurar juego",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
