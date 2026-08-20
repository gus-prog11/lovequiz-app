import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/user_services.dart';
import '../utils/app_toast.dart';
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
  final Set<String> _photosLoading = {};
  int _retryAttempts = 0;
  bool _hadGuest = false;

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
  // cancela la suscripción y vuelve a intentarlo con backoff exponencial
  // (2s, 4s, 8s, ... máx. 30s), para que la sala se recupere sola cuando
  // vuelve la conexión y nadie se quede colgado esperando. El backoff evita
  // golpear Firestore en bucle cerrado mientras la red sigue caída y, junto
  // con el SnackBar solo en el primer fallo, el spam de avisos (M6).
  void _subscribeToRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = FirestoreService.roomStream(widget.roomCode).listen(
      _onRoomSnapshot,
      onError: (Object _) {
        if (!mounted || _navigating) return;
        if (_retryAttempts == 0) {
          AppToast.showError(context, "Conexión perdida. Reintentando...");
        }
        final delaySeconds = _retryAttempts == 0
            ? 2
            : (2 * (1 << _retryAttempts)).clamp(4, 30).toInt();
        _retryAttempts++;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(seconds: delaySeconds), () {
          if (!mounted || _navigating) return;
          _subscribeToRoom();
        });
      },
    );
  }

  void _onRoomSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted || _navigating) return;

    // Un snapshot recibido indica que la conexión volvió: se resetea el
    // backoff de reintentos (M6).
    if (_retryAttempts != 0) _retryAttempts = 0;

    if (!snapshot.exists || snapshot.data() == null) {
      if (!mounted) return;
      AppToast.showError(context, "La sala fue cerrada por la otra persona");
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

    if (guestName != null && guestUid != null) _hadGuest = true;

    if (widget.isHost && guestName != null && status == 'setup') {
      _navigateToSetup();
    } else if (widget.isHost && _hadGuest && (guestName == null || guestUid == null)) {
      // El invitado abandonó la sala de espera: notificar al anfitrión.
      if (!mounted || _navigating) return;
      AppToast.showError(context, "Tu pareja salió de la sala");
      _navigating = true;
      FirestoreService.deleteRoom(widget.roomCode).catchError((_) {});
      if (!mounted) return;
      context.go('/pairing');
    } else if (!widget.isHost &&
        (status == 'setup' || status == 'playing')) {
      // `playing` cubre el caso en que la sala saltó de `waiting` a `playing`
      // sin pasar por `setup` visible: el invitado no debe quedarse colgado
      // esperando una transición que nunca llega. La pantalla de configuración
      // ya sabe arrancar sola cuando el anfitrión inicia la partida.
      _navigateToSetup();
    }
  }

  // Carga la foto de perfil de un usuario desde Firestore solo si no se cargó
  // aún para ese uid (cada snapshot reenvía nombre y estado). El uid se marca
  // como "en carga" ANTES del await: sin esto, dos snapshots seguidos lanzaban
  // dos `getUser` en carrera para el mismo uid (M5). Un fallo de red no debe
  // tumbar el stream (la foto es decorativa, se queda el placeholder).
  Future<void> _loadUserPhoto(String? uid, {required bool isHost}) async {
    if (uid == null || uid.isEmpty) return;
    if (_photosLoading.contains(uid)) return;
    final lastUid = isHost ? _lastHostUid : _lastGuestUid;
    if (uid == lastUid) return;
    _photosLoading.add(uid);
    try {
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
    } catch (e) {
      debugPrint('[WaitingRoom] loadUserPhoto error: $e');
    } finally {
      _photosLoading.remove(uid);
    }
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
    try {
      await FirestoreService.setupRoom(widget.roomCode);
    } catch (e) {
      debugPrint('[WaitingRoom] setupRoom error: $e');
      if (!mounted) return;
      AppToast.showError(context, 'No se pudo iniciar la configuración. Revisa tu conexión e inténtalo de nuevo.');
      return;
    }
    if (!mounted) return;
    _navigateToSetup();
  }

  // Pregunta confirmación, luego elimina o abandona la sala y vuelve al
  // emparejamiento.
  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la sala?'),
        content: const Text('Tu pareja será notificada de que saliste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
    // El back del sistema debe limpiar la sala (borrarla o liberar la plaza)
    // igual que el botón "Volver": sin esto, salir con el gesto dejaba la sala
    // huérfana en Firestore y la pareja se quedaba colgada esperando.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleCancel();
      },
      child: Scaffold(
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

                          Flexible(
                            child: Text(
                              widget.isHost
                                  ? "Comparte este código con tu pareja"
                                  : "Esperando al anfitrión...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: ac.textSecondary,
                              ),
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
      ),
    );
  }
}
