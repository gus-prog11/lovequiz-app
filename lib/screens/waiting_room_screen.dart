import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/user_services.dart';
import '../widgets/profile_avatar.dart';

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
  String _hostPhotoUrl = '';
  String _guestPhotoUrl = '';
  bool _navigating = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  Timer? _retryTimer;
  String? _lastHostUid;
  String? _lastGuestUid;

  // Inicializa la escucha de la sala en Firestore.
  @override
  void initState() {
    super.initState();
    _subscribeToRoom();
  }

  // Cancela la suscripción a la sala y cualquier reintento pendiente.
  @override
  void dispose() {
    _roomSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  // Escucha la sala en Firestore. Si el stream falla (por ejemplo, por red),
  // cancela la suscripción y vuelve a intentarlo 2 segundos después, para que
  // la sala se recupere sola cuando vuelve la conexión y nadie se quede
  // colgado esperando.
  void _subscribeToRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = FirestoreService.roomStream(widget.roomCode).listen(
      _onRoomSnapshot,
      onError: (Object _) {
        if (!mounted || _navigating) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Conexión perdida. Reintentando..."),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        _retryTimer?.cancel();
        _retryTimer = Timer(const Duration(seconds: 2), () {
          if (!mounted || _navigating) return;
          _subscribeToRoom();
        });
      },
    );
  }

  void _onRoomSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted || _navigating) return;

    if (!snapshot.exists || snapshot.data() == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La sala fue cerrada por la otra persona"),
        ),
      );
      context.go('/pairing');
      return;
    }

    final data = snapshot.data()!;
    final hostName = data['hostName'] as String?;
    final guestName = data['guestName'] as String?;
    final hostUid = data['hostUid'] as String?;
    final guestUid = data['guestUid'] as String?;
    final status = data['status'] as String? ?? 'waiting';

    if (mounted) {
      setState(() {
        _hostName = hostName;
        _guestName = guestName;
      });
    }

    _loadUserPhoto(hostUid, isHost: true);
    _loadUserPhoto(guestUid, isHost: false);

    if (widget.isHost && guestName != null && status == 'setup') {
      _navigateToSetup();
    } else if (!widget.isHost && status == 'setup') {
      _navigateToSetup();
    }
  }

  // Carga la foto de perfil de un usuario desde Firestore solo si no se cargó
  // aún para ese uid (cada snapshot reenvía nombre y estado).
  Future<void> _loadUserPhoto(String? uid, {required bool isHost}) async {
    if (uid == null || uid.isEmpty) return;
    final lastUid = isHost ? _lastHostUid : _lastGuestUid;
    if (uid == lastUid) return;
    final user = await UserService.getUser(uid);
    if (!mounted || user == null) return;
    setState(() {
      if (isHost) {
        _lastHostUid = uid;
        _hostPhotoUrl = user.photoUrl;
      } else {
        _lastGuestUid = uid;
        _guestPhotoUrl = user.photoUrl;
      }
    });
  }

  // Navega a la pantalla de configuración del juego.
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

  // Configura la sala y navega a la configuración del juego.
  Future<void> _handleContinue() async {
    await FirestoreService.setupRoom(widget.roomCode);
    if (!mounted) return;
    _navigateToSetup();
  }

  // Elimina o abandona la sala y vuelve al emparejamiento.
  //
  // `_navigating` se marca ANTES de borrar la sala: si se marcara después, el
  // listener vería el snapshot de la sala borrada y mostraría el aviso
  // "La sala fue cerrada por la otra persona" acusándote a ti mismo (además
  // de navegar dos veces). El host borra la sala y el invitado libera su
  // plaza; en ambos casos la salida ya está decidida y el listener debe
  // ignorar los snapshots que lleguen.
  Future<void> _handleCancel() async {
    _navigating = true;
    if (widget.isHost) {
      await FirestoreService.deleteRoom(widget.roomCode);
    } else {
      await FirestoreService.leaveRoomAsGuest(widget.roomCode);
    }
    if (!mounted) return;
    context.go('/pairing');
  }

  // Construye la pantalla de sala de espera con código y jugadores.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: _handleCancel,
                      icon: Icon(Icons.arrow_back, color: ac.textPrimary),
                      style: IconButton.styleFrom(
                        backgroundColor: ac.surfaceAlt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Sala de Espera",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Encabezado
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Icon(
                    Icons.favorite_border_outlined,
                    color: AppColors.pink,
                    size: 32,
                  ),
                ),
                Text(
                  widget.isHost && _guestName == null
                      ? "Esperando a tu pareja..."
                      : "Listos!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: ac.textPrimary,
                  ),
                ),
                Text(
                  "Comparte el codigo de la sala para invitar a tu pareja",
                  style: TextStyle(fontSize: 14, color: ac.textSecondary),
                ),
                SizedBox(height: 12),
                // Room code
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ac.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      width: 1.5,
                      color: AppColors.pink,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pink.withValues(alpha: 0.25),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Text(
                        "Código de la sala",
                        style: TextStyle(fontSize: 14, color: ac.textSecondary),
                      ),
                      Container(width: 120, height: 1, color: ac.divider),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFD3E3),
                              Color(0xFFFF8FB7),
                              AppColors.pink,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          widget.roomCode,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: ac.textPrimary,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.pink.withValues(alpha: .3),
                              thickness: 1,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.favorite_border,
                              color: AppColors.pink,
                              size: 18,
                            ),
                          ),

                          Expanded(
                            child: Divider(
                              color: AppColors.pink.withValues(alpha: .3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 32),

                          Icon(Icons.share_outlined, color: AppColors.pink),

                          Text(
                            widget.isHost
                                ? "Comparte este código con tu pareja"
                                : "Esperando al anfitrión...",
                            style: TextStyle(
                              fontSize: 12,
                              color: ac.textSecondary,
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
                    color: ac.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ac.border),
                  ),
                  child: Column(
                    children: [
                      // HOST
                      Row(
                        children: [
                          ProfileAvatar(
                            size: 64,
                            imageUrl: _hostPhotoUrl.isNotEmpty
                                ? _hostPhotoUrl
                                : null,
                            fallbackText: (_hostName ?? widget.playerName),
                            borderColor: AppColors.pink,
                            borderWidth: 2,
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Tú (Anfitrión)",
                                  style: TextStyle(
                                    color: AppColors.pink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hostName ?? widget.playerName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ac.textPrimary,
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
                              color: ac.borderLight,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.green,
                                  size: 10,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Conectado",
                                  style: TextStyle(color: ac.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(child: Divider(color: ac.divider)),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(
                              Icons.favorite,
                              color: AppColors.pink,
                              size: 24,
                            ),
                          ),

                          Expanded(child: Divider(color: ac.divider)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // INVITADO
                      Row(
                        children: [
                          ProfileAvatar(
                            size: 64,
                            imageUrl: _guestPhotoUrl.isNotEmpty
                                ? _guestPhotoUrl
                                : null,
                            fallbackText: _guestName ?? "?",
                            borderColor: Colors.white24,
                            borderWidth: 2,
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tu pareja",
                                  style: TextStyle(color: ac.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _guestName ?? "Esperando...",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ac.textPrimary,
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
                              color: ac.borderLight,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _guestName == null
                                      ? AppColors.pink
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _guestName == null ? "Buscando" : "Conectado",
                                  style: TextStyle(color: ac.textSecondary),
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
                    style: TextStyle(color: ac.textSecondary),
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

                const SizedBox(height: 24),

                // Continue button (host only, when guest joined)
                if (widget.isHost && _guestName != null)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AppColors.pink, AppColors.pinkGradientEnd],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: .35),
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
      ),
    );
  }
}
