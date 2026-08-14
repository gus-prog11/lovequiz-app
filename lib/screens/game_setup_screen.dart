import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import '../services/presence_service.dart';
import '../services/premium_service.dart';
import '../services/user_services.dart';
import '../utils/game_config.dart';

// Inicial (letra/emoji) de un nombre para el avatar, segura ante nombres
// vacíos y caracteres fuera del plano BMP (no rompe pares sustitutos).
String _avatarInitial(String name) {
  if (name.isEmpty) return '?';
  return String.fromCharCode(name.runes.first).toUpperCase();
}

class GameSetupScreen extends StatefulWidget {
  final String mode;
  final String p1;
  final String p2;
  final String? roomCode;
  final String? playerName;
  final bool isHost;

  const GameSetupScreen({
    super.key,
    required this.mode,
    required this.p1,
    required this.p2,
    this.roomCode,
    this.playerName,
    this.isHost = false,
  });

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final List<String> _selectedCategories = [];
  bool _randomMode = false;
  bool _timerEnabled = false;
  int _timerSeconds = 30;
  int _totalQuestions = 25;
  bool _loading = false;
  bool _navigating = false;
  bool _transitioningToGame = false;
  bool _isPremium = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  String _hostPhotoUrl = '';
  String _guestPhotoUrl = '';

  // Inicializa el estado, carga premium y escucha la sala online.
  @override
  void initState() {
    super.initState();
    _loadPremium();
    if (widget.mode == 'online' && widget.roomCode != null) {
      // Mantener presencia activa durante la configuración para que el otro
      // jugador no parezca desconectado al iniciar la partida.
      PresenceService.setPresenceOnline(widget.roomCode!);
      _loadPlayerPhotos(widget.roomCode!);
      // Ambos escuchan la sala: el invitado para reflejar la configuración y
      // arrancar cuando el anfitrión inicia; el anfitrión para enterarse si la
      // sala se cierra o si la pareja abandona la configuración.
      _roomSubscription = FirestoreService.roomStream(
        widget.roomCode!,
      ).listen(_handleRoomSnapshot);
    }
  }

  // Procesa cada cambio de la sala durante la configuración.
  void _handleRoomSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!mounted || _navigating) return;

    if (!snapshot.exists || snapshot.data() == null) {
      _leaveSetup('La sala fue cerrada por la otra persona');
      return;
    }

    final data = snapshot.data()!;
    final status = data['status'] as String? ?? '';
    final remoteGuestUid = data['guestUid'] as String?;

    // Si el invitado abandonó la sala durante la configuración, el anfitrión
    // no puede quedarse esperando a una pareja que ya no está.
    if (widget.isHost &&
        status == 'setup' &&
        (remoteGuestUid == null || remoteGuestUid.isEmpty)) {
      _leaveSetup('Tu pareja abandonó la sala');
      return;
    }

    if (status == 'playing') {
      // El anfitrión navega desde `_startGame`; solo el invitado entra por el
      // cambio de estado remoto.
      if (widget.isHost) return;
      final categories = normalizeCategories(data['categories']);
      final timer = normalizeTimerSeconds(data['timerSeconds']);
      final totalQuestions = normalizeTotalQuestions(
        data['totalQuestions'],
        fallback: 30,
      );
      if (categories.isNotEmpty) {
        _navigateToPlay(categories, timer, totalQuestions);
      }
      return;
    }

    if (status == 'waiting' || status == 'setup') {
      // El anfitrión es dueño de su propia configuración: aplicar el eco de
      // sus propias escrituras solo provocaría parpadeos y desincronizaciones
      // (p. ej. en el modo aleatorio). Solo el invitado refleja lo remoto.
      if (widget.isHost) return;
      final remoteCategories = normalizeCategories(data['categories']);
      final remoteTimer = normalizeTimerSeconds(data['timerSeconds']);
      final remoteTotalQuestions = normalizeTotalQuestions(
        data['totalQuestions'],
        fallback: 25,
      );
      if (!mounted) return;
      setState(() {
        // La marca `random` publicada por el anfitrión se refleja como
        // modo aleatorio; las demás categorías se copian tal cual.
        _randomMode = remoteCategories.contains('random');
        _selectedCategories
          ..clear()
          ..addAll(remoteCategories);
        _timerEnabled = remoteTimer > 0;
        _timerSeconds = remoteTimer > 0 ? remoteTimer : 30;
        _totalQuestions = remoteTotalQuestions;
      });
    }
  }

  // Sale de la configuración avisando del motivo y liberando la sala.
  void _leaveSetup(String message) {
    if (!mounted || _navigating) return;
    _navigating = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _cleanupRoom();
    context.go('/pairing');
  }

  // Botón "Volver": libera la sala online y regresa al emparejamiento.
  Future<void> _handleBack() async {
    if (_navigating) return;
    _navigating = true;
    await _cleanupRoom();
    if (!mounted) return;
    context.go('/pairing');
  }

  // Libera la sala al salir de la configuración: el anfitrión la borra y el
  // invitado libera su plaza para que el anfitrión no se quede esperando.
  Future<void> _cleanupRoom() async {
    if (widget.mode != 'online' || widget.roomCode == null) return;
    if (widget.isHost) {
      await FirestoreService.deleteRoom(widget.roomCode!);
    } else {
      await FirestoreService.leaveRoomAsGuest(widget.roomCode!);
    }
  }

  // Cancela la suscripción a la sala al destruir el widget.
  //
  // Si la salida es hacia el juego NO se marca presencia offline: el
  // `GamePlayScreen` recién montado ya escribió presencia online y un offline
  // tardío dejaría al jugador "desconectado" para su pareja (el monitor de la
  // otra pantalla pausa el juego). Solo se apaga presencia al abandonar de
  // verdad (volver, sala cerrada o invitado que se va).
  @override
  void dispose() {
    _roomSubscription?.cancel();
    if (widget.mode == 'online' &&
        widget.roomCode != null &&
        !_transitioningToGame) {
      PresenceService.setPresenceOffline(widget.roomCode!);
    }
    super.dispose();
  }

  // Carga el estado de premium del usuario.
  Future<void> _loadPremium() async {
    final premium = await PremiumService.getPremiumStatus();
    if (mounted) setState(() => _isPremium = premium.isPremium);
  }

  // Carga las fotos de perfil de ambos jugadores desde Firestore.
  Future<void> _loadPlayerPhotos(String roomCode) async {
    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .get();
    final data = roomDoc.data();
    if (data == null || !mounted) return;

    final hostUid = data['hostUid'] as String?;
    final guestUid = data['guestUid'] as String?;

    if (hostUid != null && hostUid.isNotEmpty) {
      final hostUser = await UserService.getUser(hostUid);
      if (hostUser != null && mounted && hostUser.photoUrl.isNotEmpty) {
        setState(() => _hostPhotoUrl = hostUser.photoUrl);
      }
    }
    if (guestUid != null && guestUid.isNotEmpty) {
      final guestUser = await UserService.getUser(guestUid);
      if (guestUser != null && mounted && guestUser.photoUrl.isNotEmpty) {
        setState(() => _guestPhotoUrl = guestUser.photoUrl);
      }
    }
  }

  // Tarjeta de "Modo aleatorio": mezcla todos los temas con transiciones
  // emocionales coherentes (el motor libre, como se diseñó desde el inicio).
  Widget _buildRandomModeCard(AppColors ac) {
    const pink = AppColors.pink;
    return GestureDetector(
      onTap: () {
        if (widget.mode == 'online' && !widget.isHost) return;
        setState(() {
          _randomMode = !_randomMode;
          if (_randomMode) _selectedCategories.clear();
        });
        // En online el anfitrión publica la marca `random` para que el
        // invitado la vea y el juego se arme igual en ambos dispositivos. Al
        // apagar el modo aleatorio se publica una lista vacía (nunca la marca
        // sobrante), porque sin categorías elegidas la partida no es válida.
        if (widget.mode == 'online' && widget.isHost && widget.roomCode != null) {
          FirestoreService.updateSelectedCategories(
            widget.roomCode!,
            _randomMode ? const ['random'] : const <String>[],
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: ac.surfaceAlt,
          border: Border.all(
            color: _randomMode ? pink : ac.border,
            width: _randomMode ? 2 : 1,
          ),
          boxShadow: _randomMode
              ? [
                  BoxShadow(
                    color: pink.withValues(alpha: .25),
                    blurRadius: 25,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _randomMode
                    ? pink.withValues(alpha: .15)
                    : ac.borderLight.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.casino,
                color: _randomMode ? pink : ac.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Modo aleatorio",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Mezcla de todos los temas con transiciones "
                    "emocionales coherentes",
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_randomMode)
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: pink, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // Alterna la selección de una categoría y sincroniza con Firestore.
  void _toggleCategory(String id) {
    if (!widget.isHost && widget.mode == 'online') return;
    final cat = getCategoryById(id);
    if (cat != null && cat.isPremium && !_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Categoría Premium. ¡Obtén Premium para desbloquearla!',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        // Elegir una categoría apaga el modo aleatorio.
        _selectedCategories.add(id);
        _randomMode = false;
      }
    });
    if (widget.mode == 'online' && widget.isHost && widget.roomCode != null) {
      FirestoreService.updateSelectedCategories(
        widget.roomCode!,
        _selectedCategories,
      );
    }
  }

  // Navega a la pantalla de juego con la configuración seleccionada.
  void _navigateToPlay(
    List<String> categories,
    int timerSeconds,
    int totalQuestions,
  ) {
    if (!mounted) return;
    // La partida toma el relevo de la presencia: al salir de setup hacia el
    // juego no se debe apagar la presencia (el dispose lo respeta).
    _transitioningToGame = true;
    final params = <String, String>{
      'mode': widget.mode,
      'p1': widget.p1,
      'p2': widget.p2,
      'categories': categories.join(','),
      'timer': timerSeconds.toString(),
      'totalQuestions': totalQuestions.toString(),
    };
    if (widget.roomCode != null) params['roomCode'] = widget.roomCode!;
    if (widget.playerName != null) params['name'] = widget.playerName!;
    if (widget.mode == 'online') params['host'] = widget.isHost.toString();
    context.go('/play?${Uri(queryParameters: params).query}');
  }

  // Valida la configuración, guarda en Firestore y navega al juego.
  Future<void> _startGame() async {
    if (!_randomMode && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona al menos una categoría")),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final totalQuestions = _totalQuestions;
      // Modo aleatorio: sin categoría en local (el motor mezcla todo) y con la
      // marca `random` en online para que la sala conserve una categoría y la
      // pantalla de juego la muestre como "Mezcla" (el motor la ignora como
      // preferencia temática).
      final categories = _randomMode
          ? (widget.mode == 'online' ? const ['random'] : const <String>[])
          : _selectedCategories;
      if (widget.mode == 'online' && widget.roomCode != null) {
        // La sala se prepara con la configuración; las preguntas las genera el
        // anfitrión en `GamePlayScreen._initOnlineGame` con el motor
        // (`buildEngineMatch`) y se guardan en `engineRounds` (puente online).
        // Ya no se escribe el campo legacy `questions` para no duplicar la
        // generación: el recorrido del motor es la fuente.
        await FirestoreService.updateGameConfig(
          widget.roomCode!,
          categories,
          _timerEnabled ? _timerSeconds : 0,
          totalQuestions,
        );
      }
      if (!mounted) return;
      _navigateToPlay(
        categories,
        _timerEnabled ? _timerSeconds : 0,
        totalQuestions,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al iniciar juego: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Construye la pantalla de configuración con perfiles, categorías y temporizador.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    final bool canStart =
        (_randomMode || _selectedCategories.isNotEmpty) &&
        !_loading &&
        !(widget.mode == 'online' && !widget.isHost);
    // Configuración válida (independiente de la carga): se usa para atenuar el
    // botón solo cuando faltan opciones, no mientras se está iniciando la partida.
    final bool startReady =
        (_randomMode || _selectedCategories.isNotEmpty) &&
        !(widget.mode == 'online' && !widget.isHost);
    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: _handleBack,
                    icon: Icon(Icons.arrow_back, color: ac.textPrimary),
                    iconSize: 20,
                  ),

                  Text("Volver", style: TextStyle(color: ac.textPrimary)),
                ],
              ),
              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mode == 'online' && !widget.isHost
                        ? "Espera a que configuren su "
                        : "Configuren su ",
                    style: TextStyle(fontSize: 24, color: ac.textPrimary),
                  ),
                  Row(
                    children: [
                      Text(
                        "Partida ",
                        style: TextStyle(
                          color: AppColors.pink,
                          fontSize: 24,
                        ),
                      ),

                      Icon(
                        Icons.favorite_border,
                        color: AppColors.pink,
                        size: 24,
                      ),
                    ],
                  ),
                  Text(
                    "Elige las categorías y opciones para su juego",
                    style: TextStyle(fontSize: 12, color: ac.textSecondary),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // -------------------------Perfiles-------------------------------------
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ac.surfaceAlt,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: .25),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: .10),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: 24),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ac.borderLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: .15),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _hostPhotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _hostPhotoUrl,
                                fit: BoxFit.cover,
                                width: 68,
                                height: 68,
                              )
                            : Center(
                                child: ShaderMask(
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
                                    _avatarInitial(widget.p1),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: ac.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 18),
                    Text(
                      widget.p1,
                      style: TextStyle(fontSize: 18, color: ac.textPrimary),
                    ),
                    Spacer(),
                    Icon(
                      Icons.favorite_border,
                      color: AppColors.pink,
                      size: 24,
                    ),
                    Spacer(),
                    Text(
                      widget.p2,
                      style: TextStyle(fontSize: 18, color: ac.textPrimary),
                    ),
                    SizedBox(width: 18),

                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ac.borderLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pink.withValues(alpha: .15),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _guestPhotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _guestPhotoUrl,
                                fit: BoxFit.cover,
                                width: 68,
                                height: 68,
                              )
                            : Center(
                                child: ShaderMask(
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
                                    _avatarInitial(widget.p2),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: ac.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 24),
                  ],
                ),
              ),
              // -------------------------------------Categories-------------------------------
              SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "🎯 Elige las categorías",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ac.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            widget.mode == 'online' && !widget.isHost
                                ? 'El anfitrión elige las categorías...'
                                : 'Seleccionen las categorías que quieren jugar',
                            style: TextStyle(
                              fontSize: 12,
                              color: ac.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 460,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,

                          itemCount: categories.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.92,
                              ),
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final selected = _selectedCategories.contains(
                              cat.id,
                            );

                            return _CategoryCard(
                              category: cat,
                              selected: selected,
                              isPremium: _isPremium,
                              onTap: () => _toggleCategory(cat.id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildRandomModeCard(ac),
                      const SizedBox(height: 8),

                      const SizedBox(height: 32),

                      // Timer
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: ac.surfaceAlt,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: ac.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.pink.withValues(
                                      alpha: .12,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.timer_outlined,
                                    color: AppColors.pink,
                                  ),
                                ),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Temporizador",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ac.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _timerEnabled
                                            ? "Activado"
                                            : "Desactivado",
                                        style: TextStyle(
                                          color: _timerEnabled
                                              ? AppColors.pink
                                              : ac.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        "Limita el tiempo por pregunta",
                                        style: TextStyle(
                                          color: ac.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Switch(
                                  activeTrackColor: AppColors.pink,
                                  activeThumbColor: Colors.white,
                                  value: _timerEnabled,
                                  onChanged:
                                      (widget.mode == 'online' &&
                                          !widget.isHost)
                                      ? null
                                      : (v) {
                                          setState(() {
                                            _timerEnabled = v;
                                          });
                                          if (widget.mode == 'online' &&
                                              widget.isHost &&
                                              widget.roomCode != null) {
                                            FirestoreService.updateTimerSettings(
                                              widget.roomCode!,
                                              v ? _timerSeconds : 0,
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),

                              crossFadeState: _timerEnabled
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,

                              firstChild: const SizedBox(),

                              secondChild: Column(
                                children: [
                                  const SizedBox(height: 6),

                                  Text(
                                    "$_timerSeconds segundos",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: AppColors.pink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      Text(
                                        "10s",
                                        style: TextStyle(color: ac.textMuted),
                                      ),
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context)
                                              .copyWith(
                                                  activeTrackColor:
                                                      AppColors.pink,

                                                  inactiveTrackColor:
                                                      ac.borderLight,

                                                  thumbColor: AppColors.pink,

                                                  overlayColor: const Color(
                                                    0x22FF2E93,
                                                ),

                                                thumbShape:
                                                    const RoundSliderThumbShape(
                                                      enabledThumbRadius: 10,
                                                    ),

                                                trackHeight: 3,
                                              ),

                                          child: Slider(
                                            value: _timerSeconds.toDouble(),

                                            min: 10,

                                            max: 120,

                                            divisions: 22,

                                            onChanged:
                                                (widget.mode == 'online' &&
                                                    !widget.isHost)
                                                ? null
                                                : (v) {
                                                    setState(() {
                                                      _timerSeconds = v.toInt();
                                                    });
                                                  },
                                            onChangeEnd:
                                                (widget.mode == 'online' &&
                                                    !widget.isHost)
                                                ? null
                                                : (v) {
                                                    if (widget.isHost &&
                                                        widget.roomCode !=
                                                            null) {
                                                      FirestoreService.updateTimerSettings(
                                                        widget.roomCode!,
                                                        v.toInt(),
                                                      );
                                                    }
                                                  },
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "120s",
                                        style: TextStyle(color: ac.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Preguntas por partida
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: ac.surfaceAlt,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ac.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.pink.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: AppColors.pink,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Preguntas por partida",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ac.textPrimary,
                                ),
                              ),
                              Text(
                                "$_totalQuestions preguntas",
                                style: const TextStyle(
                                  color: AppColors.pink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.mode == 'online' && !widget.isHost
                                    ? 'El anfitrión elige la duración'
                                    : '¿Rápida, completa o maratón?',
                                style: TextStyle(
                                  color: ac.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        for (final count in const [10, 20, 25]) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: (widget.mode == 'online' &&
                                      !widget.isHost)
                                  ? null
                                  : () {
                                      setState(() => _totalQuestions = count);
                                      if (widget.mode == 'online' &&
                                          widget.isHost &&
                                          widget.roomCode != null) {
                                        FirestoreService.updateTotalQuestions(
                                          widget.roomCode!,
                                          count,
                                        );
                                      }
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: _totalQuestions == count
                                      ? AppColors.pink
                                      : ac.surfaceAlt,
                                  border: Border.all(
                                    color: _totalQuestions == count
                                        ? AppColors.pink
                                        : ac.border,
                                  ),
                                ),
                                child: Text(
                                  "$count",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _totalQuestions == count
                                        ? Colors.white
                                        : ac.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (count != 25) const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: startReady
                          ? const [AppColors.pink, AppColors.pinkGradientEnd]
                          : [
                              AppColors.pink.withValues(alpha: 0.35),
                              AppColors.pinkGradientEnd.withValues(alpha: 0.35),
                            ],
                    ),
                    boxShadow: startReady
                        ? [
                            BoxShadow(
                              color: AppColors.pink.withValues(alpha: .35),
                              blurRadius: 22,
                              spreadRadius: 1,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: FilledButton.icon(
                    onPressed: canStart ? _startGame : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: Colors.white60,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.favorite_border,
                            size: 24,
                            color: startReady ? Colors.white : Colors.white60,
                          ),
                    label: Text(
                      widget.mode == 'online' && !widget.isHost
                          ? "Esperando al anfitrión..."
                          : "¡Empezar! 🔥",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

class _CategoryCard extends StatelessWidget {
  final Category category;
  final bool selected;
  final bool isPremium;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.isPremium,
    required this.onTap,
  });

  // Construye una tarjeta de categoría seleccionable con icono y nombre.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    const Color pink = AppColors.pink;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),

          color: ac.surfaceAlt,

          border: Border.all(
            color: selected ? pink : ac.border,
            width: selected ? 2 : 1,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: pink.withValues(alpha: .25),
                    blurRadius: 25,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),

        child: Stack(
          children: [
            if (selected)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                ),
              ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  _icon(category.id),
                  width: 66,
                  height: 66,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 6),

                Text(
                  category.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _subtitle(category.id),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ac.textSecondary, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Retorna la ruta del asset correspondiente a cada categoría.
String _icon(String id) {
  switch (id) {
    case "romanticas":
      return "lib/assets/images/category_romance.png";
    case "divertidas":
      return "lib/assets/images/category_funny.png";
    case "calientes":
    case "incomodas":
    case "extremas":
    case "locas":
    case "retos":
      return "lib/assets/images/category_fire.png";
    default:
      return "lib/assets/images/category_fire.png";
  }
}

// Retorna la descripción de cada categoría.
String _subtitle(String id) {
  switch (id) {
    case "romanticas":
      return "Conversaciones románticas";

    case "divertidas":
      return "Preguntas divertidas";

    case "calientes":
      return "Para subir la temperatura";

    case "incomodas":
      return "Para probar los límites";

    case "extremas":
      return "Desafíos extremos";

    case "locas":
      return "Preguntas locas";

    case "retos":
      return "Desafíos para parejas";

    case "random":
      return "Mezcla de todo un poco";

    default:
      return "";
  }
}
