import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_colors.dart';
import '../data/questions.dart';
import '../models/category.dart';
import '../models/emotional_model.dart';
import '../services/firestore_service.dart';
import '../services/emotional_service.dart';
import '../services/achievement_service.dart';
import '../services/presence_service.dart';
import '../services/user_services.dart';
import '../features/voice_memories/widgets/voice_question_card.dart';
import '../features/voice_memories/widgets/voice_reveal_player.dart';
import '../features/voice_memories/services/voice_storage_service.dart';
import '../features/voice_memories/repositories/voice_memory_repository.dart';
import '../widgets/reaction_button.dart';
import '../features/game_engine/engine/playable_match_builder.dart';
import '../features/game_engine/data/engine_match_codec.dart';
import '../features/game_engine/data/online_restart_bridge.dart';
import '../features/game_engine/domain/enums/chapter.dart';
import '../features/game_engine/domain/enums/question_category.dart';
import '../features/game_engine/domain/enums/question_type.dart' as engine_types;
import '../features/game_engine/domain/models/game_round.dart';

class GamePlayScreen extends StatefulWidget {
  final String mode;
  final String p1;
  final String p2;
  final List<String> categories;
  final int timerSeconds;
  final String? roomCode;
  final String? playerName;
  final bool isHost;
  final int totalQuestions;

  const GamePlayScreen({
    super.key,
    required this.mode,
    required this.p1,
    required this.p2,
    required this.categories,
    required this.timerSeconds,
    this.roomCode,
    this.playerName,
    this.isHost = false,
    required this.totalQuestions,
  });

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  /// Database instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Variables de control del juego
  List<Question> _questions = []; // Lista de preguntas cargadas
  int _currentIndex = 0; // Índice de la pregunta actual
  int _turn = 0; // Turno actual (0 = jugador 1, 1 = jugador 2)
  bool _gameOver = false; // Indica si el juego ha terminado
  Timer? _timer; // Temporizador para limitar tiempo por pregunta
  int _remainingTime = 0; // Tiempo restante en segundos

  /// Guarda contra la reentrada de `_finishGame`: evita que un doble tap en
  /// la última pregunta (o el eco del `status: finished` por roomStream)
  /// guarde el historial y los logros más de una vez.
  bool _finishing = false;

  /// Guarda contra la reentrada de `_nextQuestion`: mientras la animación de
  /// la tarjeta esté en curso, un segundo tap no debe saltar una pregunta.
  bool _advancing = false;

  /// Guarda contra la reentrada de `_exitGame`: un doble tap en "Salir" no
  /// debe escribir presencia/finish dos veces ni navegar dos rutas (R5).
  bool _exiting = false;

  /// Rondas del motor alineadas con `_questions` (solo modo local con motor).
  /// Cada elemento guarda el recorrido emocional de la pregunta en el mismo
  /// índice, para mostrar el capítulo, la emoción y la intensidad reales.
  final List<GameRound> _engineRounds = [];

  /// Variables de animación
  late AnimationController
  _cardController; // Controla animaciones de las tarjetas
  late Animation<double> _cardAnimation; // Animación de la tarjeta de preguntas

  final TextEditingController _answerCtrl = TextEditingController();
  bool _answerSaved = false;

  /// Elección de cada jugador en la pregunta de comparación actual
  /// (índice 0 = jugador 1, índice 1 = jugador 2; null = aún sin elegir).
  /// En una comparación ambos responden la misma pregunta y al final se
  /// compara quién eligió qué.
  final List<String?> _comparisonChoices = [null, null];

  /// Instante de la última elección local en la comparación (modo local).
  ///
  /// Al pasarse el teléfono, un doble tap accidental del mismo jugador podía
  /// registrarse como la elección del OTRO jugador (el picker deriva del
  /// primer hueco libre). Con un debounce corto el segundo tap dentro de
  /// 400 ms se ignora y no se "responde por" la pareja (R2).
  DateTime? _lastLocalComparisonChoiceAt;

  /// Respuesta escrita de cada jugador en la pregunta de texto actual.
  /// En preguntas de texto ambos responden la misma pregunta y al final se
  /// revelan las dos respuestas (patrón igual a la comparación).
  final List<String?> _textAnswers = [null, null];

  /// URL del audio de cada jugador en la pregunta de voz actual (online).
  final List<String?> _voiceUrls = [null, null];

  /// Ruta local del audio de cada jugador en la pregunta de voz actual
  /// (local): el audio se conserva solo durante la pregunta para poder
  /// reproducirlo en la revelación (no se sube ni se persiste).
  final List<String?> _voiceLocalPaths = [null, null];

  /// Reacción decorativa visible en pantalla (emoji) y temporizador que la
  /// oculta a los ~3 segundos. `_ownReactionSeq` es un contador local para
  /// que cada tap dispare de nuevo aunque repita el mismo emoji, y
  /// `_lastSeenPartnerReactionSeq` evita reaccionar dos veces al mismo
  /// evento remoto.
  String? _reactionEmoji;
  Timer? _reactionHideTimer;
  Timer? _reactionClearTimer;
  int _ownReactionSeq = 0;
  int _lastSeenPartnerReactionSeq = 0;

  /// Reacción de la pareja que se muestra FUERA del botón (burbuja izquierda)
  /// y temporizador que la oculta a los ~3 segundos.
  String? _partnerReactionEmoji;
  Timer? _partnerReactionHideTimer;

  /// Variables de sincronización
  bool _initialized = false; // Indica si el juego ha sido inicializado
  StreamSubscription? _roomSubscription; // Escucha cambios en partidas online

  /// Error de inicialización online (C3): si la sala no responde (anfitrión
  /// que se cayó, red perdida, etc.), en lugar de un spinner infinito se
  /// muestra un mensaje con botón "Reintentar".
  String? _initError;
  Timer? _initTimeout;

  /// Variables de presencia
  bool _otherPlayerOnline = true; // Indica si el otro jugador está en línea
  bool _gamePausedDueToDisconnection =
      false; // Indica si el juego está pausado por desconexión
  bool _sawOtherPlayerOnline =
      false; // Evita pausas falsas antes de ver al otro jugador en línea
  StreamSubscription?
  _presenceSubscription; // Escucha cambios de presencia del otro jugador

  /// Contexto del diálogo de desconexión actualmente abierto (null si no hay).
  ///
  /// Al reconectarse la pareja, el diálogo debe cerrarse SÓLO si sigue abierto
  /// y popear usando su propio contexto: un `Navigator.pop(context)` genérico
  /// podía cerrar la ruta equivocada (otro diálogo, o la propia pantalla si el
  /// de desconexión ya se había cerrado) (R5).
  BuildContext? _disconnectDialogContext;

  /// Fotos de perfil
  String _hostPhotoUrl = '';
  String _guestPhotoUrl = '';

  /// ID de la pareja vinculada (para guardar respuestas favoritas)
  String _coupleId = '';

  /// Se completa cuando el coupleId de la pareja terminó de cargarse.
  /// El flujo de voz espera este futuro antes de crear un recuerdo para
  /// nunca usar un coupleId temporal (local_*) cuando el usuario ya
  /// pertenece a una pareja.
  final Completer<void> _coupleIdReady = Completer<void>();

  /// Índice en el que se aplicó el fallback "responder sin audio" (-1 si
  /// ninguno). Se usa para que la subida de audio de esa pregunta quede
  /// descartada y para no volver a ofrecer el fallback en la misma pregunta.
  int _appliedFallbackIndex = -1;

  /// Invitado online que pulsó "Jugar de nuevo": se queda en la pantalla de
  /// fin esperando a que el anfitrión publique el nuevo recorrido. NO se baja
  /// `_gameOver` en ese momento porque el roomStream solo aplica el restart
  /// con `_gameOver && status == 'playing'`; si se bajara antes, el invitado
  /// se quedaría con las preguntas VIEJAS mientras el anfitrión juega nuevas.
  bool _waitingForHostRestart = false;

  /// Inicializa el estado del widget y configura las animaciones
  /// Si el modo es online, inicializa el juego online; si no, carga las preguntas localmente
  // Descripción breve de lo que hace.
  @override
  void initState() {
    super.initState();
    _remainingTime = widget.timerSeconds;

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeInOut,
    );

    if (widget.mode == 'online' && widget.roomCode != null) {
      _initOnlineGame();
      // Timeout (C3): el invitado espera a que el anfitrión publique el
      // recorrido (`engineRounds`). Si en 30 s no llega (anfitrión se cayó,
      // sala rota, red), se abandona el spinner infinito y se ofrece reintentar.
      if (!widget.isHost) {
        _initTimeout = Timer(const Duration(seconds: 30), () {
          if (!mounted || _initialized) return;
          setState(() {
            _initError =
                'El anfitrión no respondió. Revisa tu conexión y vuelve a intentarlo.';
          });
        });
      }
    } else {
      _initLocalEngineGame();
    }

    _loadCoupleId();
  }

  /// Inicializa una partida local usando el motor emocional.
  ///
  /// Construye el recorrido completo (capítulo → emoción → intensidad) con el
  /// banco V1 y las categorías elegidas como preferencia temática blanda. Las
  /// rondas sin pregunta compatible se descartan; las demás se convierten a
  /// preguntas legacy para la pantalla actual.
  Future<void> _initLocalEngineGame() async {
    await _startLocalEngineGame();
    if (!mounted) return;
    _cardController.forward();
    _startTimer();
  }

  /// Convierte una ronda del motor a la pregunta legacy que consume la UI.
  Question _toLegacyQuestion(GameRound round) {
    final q = round.question!;
    return Question(
      text: q.text,
      category: q.category.name,
      type: q.type == engine_types.QuestionType.voz
          ? QuestionType.voiceMemory
          : QuestionType.normal,
    );
  }

  /// Categorías legacy seleccionadas en el setup → enum del motor.
  ///
  /// Solo se mapean ids de categorías reales del motor; ids desconocidos
  /// (como la marca legacy `random`) se descartan. Lista vacía = modo
  /// aleatorio (el motor mezcla todos los temas libremente). Lista no vacía =
  /// modo temático (el tema elegido es restricción fuerte).
  List<QuestionCategory> get _preferredEngineCategories {
    final result = <QuestionCategory>[];
    for (final id in widget.categories) {
      for (final category in QuestionCategory.values) {
        if (category.name == id) {
          result.add(category);
          break;
        }
      }
    }
    return result;
  }

  /// Carga el ID de la pareja vinculada para guardar respuestas favoritas.
  Future<void> _loadCoupleId() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final user = await UserService.getUser(uid);
      if (!mounted) return;
      if (user?.coupleId != null) {
        setState(() => _coupleId = user!.coupleId!);
      }
    } finally {
      // El flujo de voz que quedó esperando a _coupleIdReady debe poder
      // continuar (con el coupleId real si lo hay, o con la marca local).
      if (!_coupleIdReady.isCompleted) _coupleIdReady.complete();
    }
  }

  /// Inicializa una partida en línea
  /// El anfitrión genera las preguntas y las guarda en Firestore
  /// El cliente espera a recibir las preguntas del anfitrión
  /// Escucha cambios en Firestore para sincronizar el estado del juego
  /// También inicializa el monitoreo de presencia
  // Configura la partida en línea con Firestore y presencia.
  Future<void> _initOnlineGame() async {
    final code = widget.roomCode!;

    try {
      // Inicializar presencia del usuario actual
      await PresenceService.setPresenceOnline(code);

      // Cargar fotos de perfil de ambos jugadores
      _loadPlayerPhotos(code);

      if (widget.isHost) {
        final roomDoc = await _db.collection('rooms').doc(code).get();
        final roomData = roomDoc.data();
        final remoteRounds = roomData?['engineRounds'];

        if (remoteRounds is List && remoteRounds.isNotEmpty) {
          // El recorrido ya está en la sala (el invitado pudo entrar después):
          // se reconstruye sin volver a generarlo.
          _engineRounds
            ..clear()
            ..addAll(decodeEngineMatch(remoteRounds));
        } else {
          // El motor construye la partida. Las comparaciones ya se juegan a dos
          // dispositivos (Fase 3): cada uno elige en su teléfono y el resultado
          // se sincroniza por Firestore, así que no se excluye ningún formato.
          final rounds = await buildEngineMatch(
            preferredCategories: _preferredEngineCategories,
            totalRounds: widget.totalQuestions,
          );
          _engineRounds
            ..clear()
            ..addAll(rounds);
          await FirestoreService.saveEngineMatch(
            code,
            encodeEngineMatch(rounds),
          );
        }

        _questions = _engineRounds.map(_toLegacyQuestion).toList();

        if (!mounted) return;
        setState(() => _initialized = true);
        _cardController.forward();
        _startTimer();
      }
    } catch (e, st) {
      debugPrint('[GamePlay] _initOnlineGame error: $e\n$st');
      if (!mounted) return;
      // En vez de un spinner infinito, se muestra un error con "Reintentar".
      setState(() {
        _initError =
            'No se pudo iniciar el juego. Revisa tu conexión y vuelve a intentarlo.';
      });
      return;
    }

    // Monitorear presencia del otro jugador
    _monitorOtherPlayerPresence(code);

    _roomSubscription = FirestoreService.roomStream(code).listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      // Invitado: el recorrido del motor llega por `engineRounds`. Se
      // reconstruye igual que lo generó el anfitrión (mismo capítulo, emoción,
      // intensidad y pregunta) para que el viaje emocional sea idéntico en
      // ambos dispositivos.
      final engineData = data['engineRounds'];
      if (!widget.isHost &&
          engineData is List &&
          engineData.isNotEmpty &&
          !_initialized) {
        final rounds = decodeEngineMatch(engineData);
        setState(() {
          _engineRounds
            ..clear()
            ..addAll(rounds);
          _questions = rounds.map(_toLegacyQuestion).toList();
          _initialized = true;
        });
        _cardController.forward();
        _startTimer();
      }

      final remoteIndex = data['currentQuestion'] as int? ?? 0;
      final remoteTurn = data['turn'] as int? ?? 0;
      final status = data['status'] as String? ?? '';
      final isFinished = status == 'finished';

      // Sincronización de la comparación: cada dispositivo recibe la elección
      // de su pareja y la deja lista para la revelación. Los campos se limpian
      // en cada transición de pregunta, así que no hay respuestas viejas.
      //
      // Guard anti-contaminación (C5): `comparisonQ` marca la pregunta a la
      // que pertenece la elección. Si no coincide con la pregunta actual del
      // snapshot, un write tardío de la pregunta anterior se ignora.
      final remoteP1 = data['comparisonP1'] as String?;
      final remoteP2 = data['comparisonP2'] as String?;
      final comparisonQ = data['comparisonQ'] as int?;
      if ((remoteP1 != null || remoteP2 != null) &&
          (comparisonQ == null || comparisonQ == remoteIndex)) {
        setState(() {
          if (remoteP1 != null) _comparisonChoices[0] = remoteP1;
          if (remoteP2 != null) _comparisonChoices[1] = remoteP2;
        });
      }

      // Sincronización de respuestas escritas: cada dispositivo recibe la
      // respuesta de su pareja y ambas se revelan cuando los dos respondieron.
      final answerP1 = data['answerP1'] as String?;
      final answerP2 = data['answerP2'] as String?;
      final answerQ = data['answerQ'] as int?;
      if ((answerP1 != null || answerP2 != null) &&
          (answerQ == null || answerQ == remoteIndex)) {
        setState(() {
          if (answerP1 != null) _textAnswers[0] = answerP1;
          if (answerP2 != null) _textAnswers[1] = answerP2;
        });
      }

      // Reacción decorativa de la pareja: efímera, se muestra ~3 s. Cada rol
      // escribe su propio campo con un `seq` creciente para que un mismo emoji
      // repetido vuelva a disparar la animación.
      final partnerReaction = widget.isHost
          ? data['reactionP2']
          : data['reactionP1'];
      final reactionQ = data['reactionQ'] as int?;
      if (partnerReaction is Map &&
          (reactionQ == null || reactionQ == remoteIndex)) {
        final seq = partnerReaction['seq'] as int? ?? 0;
        final emoji = partnerReaction['emoji'] as String? ?? '';
        if (emoji.isNotEmpty && seq != _lastSeenPartnerReactionSeq) {
          _lastSeenPartnerReactionSeq = seq;
          _showPartnerReaction(emoji);
        }
      }

      if (isFinished && !_gameOver) {
        // Ambos dispositivos guardan su propio historial y logros: el que
        // respondió la última pregunta ya llegó aquí por `_nextQuestion`; el
        // otro entra por el `status: finished` del roomStream. `_finishGame`
        // es idempotente (guard `_finishing`), así que nadie se duplica.
        _finishGame();
        return;
      }

      // Fallback "responder sin audio" publicado por la pareja: la sala ahora
      // tiene una versión escrita de la pregunta ACTUAL, así que ambos
      // dispositivos la aplican juntos. Sin esto, uno se quedaría en la
      // tarjeta de voz esperando un audio que ya no se va a grabar.
      if (!_gameOver && remoteIndex == _currentIndex) {
        final remoteRounds = data['engineRounds'];
        if (remoteRounds is List && _currentIndex < remoteRounds.length) {
          try {
            final remoteRound = GameRound.fromMap(
              Map<String, dynamic>.from(
                remoteRounds[_currentIndex] as Map,
              ),
            );
            final local = _currentEngineRound;
            final localQ = local?.question;
            final remoteQ = remoteRound.question;
            if (remoteQ != null && localQ?.id != remoteQ.id) {
              _applyEngineRoundAtCurrentIndex(remoteRound);
            }
          } catch (_) {
            // Ronda no decodificable: se ignora (el snapshot de restart se
            // aplica por su propia ruta).
          }
        }
      }

      // AMBOS jugadores escuchan cambios de Firestore y actualizan su pantalla
      // Esto asegura que cuando uno presiona siguiente, el otro también ve el cambio
      if (_gameOver && status == 'playing') {
        _cardController.reset();
        _stopTimer();
        final content = parseOnlineRestartContent(data);
        if (content.usesEngine) {
          _applyRestartFromContent(
            content,
            remoteIndex: remoteIndex,
            remoteTurn: remoteTurn,
          );
        } else {
          setState(() {
            _currentIndex = remoteIndex;
            _turn = remoteTurn;
            _gameOver = false;
            _resetQuestionState();
          });
        }
        _cardController.forward();
        _startTimer();
        return;
      }

      // Actualizar cuando el otro jugador presiona siguiente
      if ((remoteIndex != _currentIndex || remoteTurn != _turn) && !_gameOver) {
        _cardController.reset();
        setState(() {
          _currentIndex = remoteIndex;
          _turn = remoteTurn;
          _resetQuestionState();
        });
        _cardController.forward();
        _startTimer();
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('[GamePlay] roomStream error: $e\n$st');
      if (!mounted) return;
      // El stream de Firestore rara vez emite errores (Firebase reintenta
      // internamente), pero si ocurre no debe tumbar la app: se pausa el juego
      // y se avisa al jugador para que no se pierda su progreso en silencio.
      _stopTimer();
      setState(() => _gamePausedDueToDisconnection = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Se perdió la conexión con la sala. Revisa tu internet e intenta de nuevo.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  /// Reintenta la inicialización online tras un error (C3): limpia el error,
  /// cancela suscripciones viejas y vuelve a intentar `_initOnlineGame`.
  Future<void> _retryInit() async {
    if (!mounted) return;
    setState(() => _initError = null);
    await _roomSubscription?.cancel();
    await _presenceSubscription?.cancel();
    _roomSubscription = null;
    _presenceSubscription = null;
    if (!mounted) return;
    _initOnlineGame();
  }

  /// Limpia los recursos cuando el widget se destruye
  /// Cancela el temporizador, la suscripción a Firestore y detiene las animaciones
  /// También limpia la presencia si es un juego online
  // Libera recursos, cancela suscripciones y limpia presencia.
  @override
  void dispose() {
    _timer?.cancel();
    _initTimeout?.cancel();
    _roomSubscription?.cancel();
    _presenceSubscription?.cancel();
    _reactionHideTimer?.cancel();
    _partnerReactionHideTimer?.cancel();
    _reactionClearTimer?.cancel();
    _cardController.dispose();
    _answerCtrl.dispose();

    // Marcar como desconectado si es un juego online
    if (widget.mode == 'online' && widget.roomCode != null) {
      PresenceService.setPresenceOffline(widget.roomCode!);
    }

    PresenceService.dispose();
    super.dispose();
  }

  // Carga las fotos de perfil de ambos jugadores desde Firestore.
  Future<void> _loadPlayerPhotos(String roomCode) async {
    try {
      final roomDoc = await _db.collection('rooms').doc(roomCode).get();
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
    } catch (e) {
      // Las fotos son decorativas: un fallo de red aquí no debe tumbar la
      // inicialización de la partida (M2). Se deja el placeholder por defecto.
      debugPrint('[GamePlay] loadPlayerPhotos error: $e');
    }
  }

  /// Monitorea la presencia del otro jugador
  /// Si se desconecta, pausa el juego y muestra una notificación
  /// Si se vuelve a conectar, reanuda el juego
  // Escucha la presencia del otro jugador y pausa/reanuda el juego.
  void _monitorOtherPlayerPresence(String roomCode) {
    _presenceSubscription = PresenceService.monitorOtherPlayerOnline(roomCode)
        .listen((otherPlayerOnline) {
          if (!mounted) return;

          if (otherPlayerOnline) {
            _sawOtherPlayerOnline = true;
          }

          // Si el estado cambió, actualizar y notificar
          if (otherPlayerOnline != _otherPlayerOnline) {
            setState(() => _otherPlayerOnline = otherPlayerOnline);

            if (!otherPlayerOnline &&
                _sawOtherPlayerOnline &&
                !_gamePausedDueToDisconnection &&
                !_gameOver) {
              // El otro jugador se desconectó
              _stopTimer();
              setState(() => _gamePausedDueToDisconnection = true);

              _showDisconnectionDialog(_partnerName);
            } else if (otherPlayerOnline &&
                _gamePausedDueToDisconnection &&
                !_gameOver) {
              // El otro jugador se reconectó
              setState(() => _gamePausedDueToDisconnection = false);

              // Cierra el diálogo de desconexión SOLO si sigue abierto y con
              // su propio contexto (no popea otra ruta por error, R5).
              final dialogCtx = _disconnectDialogContext;
              if (dialogCtx != null && mounted) {
                _disconnectDialogContext = null;
                if (dialogCtx.mounted) {
                  Navigator.of(dialogCtx, rootNavigator: true).pop();
                }
              }

              _startTimer();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('¡$_partnerName se ha reconectado!'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }, onError: (Object e, StackTrace st) {
          debugPrint('[GamePlay] presence error: $e\n$st');
          if (!mounted) return;
          _stopTimer();
          setState(() => _gamePausedDueToDisconnection = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se perdió la conexión con tu pareja. Revisa tu internet e intenta de nuevo.',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        });
  }

  /// Muestra un diálogo cuando el otro jugador se desconecta
  // Muestra un diálogo de desconexión del otro jugador.
  void _showDisconnectionDialog(String playerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Se guarda el contexto para poder cerrar EXACTAMENTE este diálogo
        // cuando la pareja se reconecta (no un pop genérico que pudiera caer
        // en otra ruta, R5).
        _disconnectDialogContext = dialogContext;
        // El back del sistema no debe cerrar este diálogo: si se cerrara, el
        // juego quedaría pausado sin forma de salir (solo quedaría esperar la
        // reconexión a ciegas). `barrierDismissible: false` no alcanza: el back
        // lo ignoraría (M4). La única salida es "Salir del juego" o que la
        // pareja se reconecte.
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.wifi_off, color: Colors.red, size: 32),
            title: Text('$playerName se desconectó'),
            content: const Text(
              'El otro jugador ha perdido la conexión. El juego se ha pausado. Por favor espera a que se reconecte.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _exitGame();
                },
                child: const Text('Salir del juego'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _disconnectDialogContext = null;
    });
  }

  // Guarda la respuesta escrita como favorita en Firestore.
  Future<void> _saveAsFavorite() async {
    if (_currentQuestion == null || _answerCtrl.text.trim().isEmpty) return;
    if (_coupleId.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = await EmotionalService.generateFavoriteAnswerId();
    await EmotionalService.saveFavoriteAnswer(
      FavoriteAnswer(
        id: id,
        userId: user.uid,
        coupleId: _coupleId,
        question: _currentQuestion!.text,
        answer: _answerCtrl.text.trim(),
        category: _currentQuestion!.category,
        partnerName: _turn == 0 ? widget.p2 : widget.p1,
        createdAt: Timestamp.now(),
      ),
    );
    await AchievementService.updateConfessionStats();
    setState(() => _answerSaved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Respuesta guardada como favorita!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Inicia una cuenta regresiva por pregunta.
  /// En preguntas de voz el contador no corre: ambos deben grabar con calma
  /// y el recuerdo no debe descartarse si el tiempo llega a 0. Tampoco corre
  /// en comparaciones online: cada jugador elige en su propio teléfono y un
  /// timeout no debe saltarse la elección de la pareja. Se cancela siempre el
  /// temporizador previo para que no quede corriendo al pasar de pregunta.
  void _startTimer() {
    if (widget.timerSeconds <= 0) return;
    _timer?.cancel();
    // Mientras el juego esté pausado por desconexión de la pareja no corre el
    // reloj: un timeout no debe avanzar la partida ni saltarse la respuesta
    // de alguien que no está conectado (R1). `_onPartnerReconnect` reanuda el
    // juego y vuelve a llamar `_startTimer`.
    if (_gamePausedDueToDisconnection) {
      _remainingTime = widget.timerSeconds;
      return;
    }
    if (_isVoiceQuestion) return;
    // En preguntas de texto y comparaciones online no corre el reloj: cada
    // jugador responde en su propio teléfono y un timeout no debe saltarse
    // la respuesta de la pareja.
    if ((_isComparisonQuestion || _isTextRevealQuestion) &&
        widget.mode == 'online') {
      return;
    }
    // En partidas online solo debe correr el reloj de quien lleva el turno:
    // si ambos dispositivos contaran en paralelo, un timeout en el teléfono
    // de la pareja avanzaría la partida en lugar de la dueña del turno.
    if (widget.mode == 'online' && !_isMyTurn) {
      _remainingTime = widget.timerSeconds;
      return;
    }
    _remainingTime = widget.timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
        if (widget.mode != 'online' || _isMyTurn) _nextQuestion();
      }
    });
  }

  /// Detiene el temporizador actual
  // Detiene el temporizador activo.
  void _stopTimer() {
    _timer?.cancel();
  }

  /// Limpia el estado de la pregunta actual (respuestas, elecciones, audios,
  /// reacciones y texto escrito) al cambiar de pregunta o reiniciar la partida.
  /// No muta el índice ni el turno: solo los datos temporales de la pregunta.
  void _resetQuestionState() {
    _comparisonChoices[0] = null;
    _comparisonChoices[1] = null;
    _textAnswers[0] = null;
    _textAnswers[1] = null;
    _voiceUrls[0] = null;
    _voiceUrls[1] = null;
    _deleteLocalVoiceFiles();
    _voiceLocalPaths[0] = null;
    _voiceLocalPaths[1] = null;
    _reactionEmoji = null;
    _reactionHideTimer?.cancel();
    _partnerReactionEmoji = null;
    _partnerReactionHideTimer?.cancel();
    _reactionClearTimer?.cancel();
    // El campo también se limpia aquí: cuando la pareja avanza por Firestore
    // (`roomStream`), `_nextQuestion` no pasa por este dispositivo y sin esto
    // una respuesta a medio escribir se colaría a la siguiente pregunta.
    _answerCtrl.clear();
  }

  /// Borra del disco los `.m4a` grabados localmente para la pregunta actual.
  ///
  /// En modo local los audios se reproducen desde la ruta local durante la
  /// revelación; una vez que se avanza (o se reinicia la partida) ya nadie los
  /// referencia, así que se eliminan para no acumular archivos con audio
  /// íntimo en el directorio de documentos (R6). La subida en modo online
  /// también borra su archivo local tras confirmarla.
  void _deleteLocalVoiceFiles() {
    for (var i = 0; i < _voiceLocalPaths.length; i++) {
      final path = _voiceLocalPaths[i];
      if (path == null) continue;
      _voiceLocalPaths[i] = null;
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('[GamePlayScreen] cleanup local voice failed: $e');
      }
    }
  }

  /// Avanza a la siguiente pregunta
  /// Si es la última pregunta, finaliza el juego
  /// Alterna el turno entre los dos jugadores y anima la transición
  /// Sincroniza el estado si el juego es en línea
  // Avanza a la siguiente pregunta o finaliza el juego.
  void _nextQuestion() {
    // Ignora taps duplicados mientras la tarjeta está en transición: un
    // doble tap en "Siguiente" no debe saltar una pregunta ni duplicar el fin.
    if (_advancing) return;
    _advancing = true;
    _stopTimer();
    if (_currentIndex >= _questions.length - 1) {
      // La partida terminó: se libera el bloqueo. Si no, `_advancing` quedaba
      // true para siempre y, tras un restart, la nueva partida ignoraría los
      // primeros taps de "Siguiente" (M1).
      _advancing = false;
      _finishGame();
      return;
    }
    _cardController.reset();
    setState(() {
      _currentIndex++;
      _turn = _turn == 0 ? 1 : 0;
      _answerCtrl.clear();
      _answerSaved = false;
      _appliedFallbackIndex = -1;
      _resetQuestionState();
    });
    _cardController.forward().whenComplete(() => _advancing = false);
    _startTimer();
    _syncGameState();
  }

  /// Registra la elección de un jugador en la comparación actual.
  ///
  /// ONLINE: cada dispositivo elige a su propio jugador y sincroniza la
  /// elección por Firestore; la pareja la recibe por `roomStream` y se muestra
  /// la revelación cuando ambos eligieron. El turno no se toca (la comparación
  /// la contestan los dos y el avance lo hace quien tenga el turno).
  ///
  /// LOCAL: ambos responden la misma pregunta pasándose el teléfono: el
  /// jugador 1 elige primero y el turno pasa al jugador 2; cuando ambos
  /// eligieron se detiene el temporizador y se muestra la revelación.
  void _onComparisonTap(String option) {
    if (_comparisonReady) return;
    _stopTimer();

    if (widget.mode == 'online') {
      final role = widget.isHost ? 0 : 1;
      if (_comparisonChoices[role] != null) return;
      setState(() => _comparisonChoices[role] = option);
      _syncComparisonChoice(role, option);
      return;
    }

    // Local: un doble tap del mismo jugador no debe responder por la pareja.
    // Cuando el jugador 1 elige, el turno pasa al 2 (picker deriva del primer
    // hueco libre); el tap inmediato que le sigue (rebote/doble tap) era
    // registrado como elección del jugador 2. Se ignora si llega dentro de
    // 400 ms de la última elección local (R2).
    final now = DateTime.now();
    final last = _lastLocalComparisonChoiceAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastLocalComparisonChoiceAt = now;

    final picker = _comparisonPicker;
    setState(() {
      _comparisonChoices[picker] = option;
      // Si falta el otro jugador, se pasa el turno para que elija.
      if (_comparisonChoices[0] == null || _comparisonChoices[1] == null) {
        _turn = picker == 0 ? 1 : 0;
      }
    });
    // Cuando ambos ya eligieron el temporizador queda parado: la revelación
    // se queda en pantalla hasta que alguien pulsa "Continuar".
    if (!_comparisonReady) _startTimer();
  }

  /// Sincroniza la elección de la comparación actual con Firestore.
  ///
  /// Cada dispositivo escribe únicamente su propio rol (`comparisonP1` para el
  /// anfitrión, `comparisonP2` para el invitado); el otro la recibe por
  /// `roomStream`.
  Future<void> _syncComparisonChoice(int role, String option) async {
    if (widget.mode != 'online' || widget.roomCode == null) return;
    try {
      final code = widget.roomCode!;
      await FirestoreService.saveComparisonChoice(
        code,
        player1Choice: role == 0 ? option : null,
        player2Choice: role == 1 ? option : null,
        questionIndex: _currentIndex,
      );
    } catch (e) {
      // Sin esto, una falla de red al enviar la elección producía una
      // excepción no manejada (fire-and-forget desde el tap) que podía
      // colgar el flujo de la comparación (R8).
      debugPrint('[GamePlay] syncComparisonChoice error: $e');
    }
  }

  /// Guarda la respuesta escrita de un jugador en la pregunta de texto actual.
  ///
  /// LOCAL: el primer jugador responde y el turno pasa al segundo; cuando
  /// ambos respondieron se detiene el temporizador y se muestra la revelación
  /// (patrón idéntico a la comparación).
  ///
  /// ONLINE: cada dispositivo responde en el suyo y sincroniza por Firestore;
  /// el avance lo hace quien tenga el turno cuando ambos respondieron.
  void _submitTextAnswer() {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty || _advancing) return;
    _stopTimer();

    if (widget.mode == 'online' && widget.roomCode != null) {
      final role = widget.isHost ? 0 : 1;
      if (_textAnswers[role] != null) return;
      setState(() {
        _textAnswers[role] = text;
        _answerCtrl.clear();
      });
      _syncTextAnswer(role, text);
      return;
    }

    final picker = _turn;
    setState(() {
      _textAnswers[picker] = text;
      _answerCtrl.clear();
      // Si falta el otro jugador, se pasa el turno para que responda.
      if (_textAnswers[0] == null || _textAnswers[1] == null) {
        _turn = picker == 0 ? 1 : 0;
      }
    });
    // Cuando ambos ya respondieron el temporizador queda parado: la
    // revelación se queda en pantalla hasta que alguien pulsa "Continuar".
    if (!_textRevealReady) _startTimer();
  }

  /// Sincroniza la respuesta escrita con Firestore (cada dispositivo escribe
  /// solo su propio rol; el otro la recibe por `roomStream`).
  Future<void> _syncTextAnswer(int role, String text) async {
    if (widget.mode != 'online' || widget.roomCode == null) return;
    try {
      await FirestoreService.saveTextAnswer(
        widget.roomCode!,
        player1Answer: role == 0 ? text : null,
        player2Answer: role == 1 ? text : null,
        questionIndex: _currentIndex,
      );
    } catch (e) {
      // Igual que en la comparación: una falla de red al enviar no debe
      // producir una excepción no manejada ni colgar la pregunta (R8).
      debugPrint('[GamePlay] syncTextAnswer error: $e');
    }
  }

  /// Reacción decorativa: se muestra localmente (y en la pareja online) durante
  /// ~3 segundos y luego desaparece. No se guarda en ningún lado.
  void _handleReact(String emoji) {
    _showReaction(emoji);
    if (widget.mode == 'online' && widget.roomCode != null) {
      _syncReaction(emoji);
    }
  }

  /// Muestra el emoji en pantalla y programa su ocultamiento a los 3 s.
  void _showReaction(String emoji) {
    _reactionHideTimer?.cancel();
    setState(() => _reactionEmoji = emoji);
    _reactionHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _reactionEmoji = null);
    });
  }

  /// Muestra en la burbuja izquierda (fuera del botón) la reacción que llega
  /// de la pareja y programa su ocultamiento a los 3 s. No toca la reacción
  /// propia.
  void _showPartnerReaction(String emoji) {
    _partnerReactionHideTimer?.cancel();
    setState(() => _partnerReactionEmoji = emoji);
    _partnerReactionHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _partnerReactionEmoji = null);
    });
  }

  /// Publica la reacción para que la pareja la vea (campo propio de la sala).
  /// Tras ~3.5 s limpia el campo para que la sala no acumule reacciones viejas.
  Future<void> _syncReaction(String emoji) async {
    final code = widget.roomCode;
    if (code == null) return;
    _ownReactionSeq++;
    final reaction = <String, dynamic>{
      'emoji': emoji,
      'seq': _ownReactionSeq,
    };
    await FirestoreService.sendReaction(
      code,
      player1Reaction: widget.isHost ? reaction : null,
      player2Reaction: widget.isHost ? null : reaction,
      questionIndex: _currentIndex,
    );
    // Si la pantalla se cerró mientras se publicaba la reacción, no se crea
    // el timer de limpieza: quedaría colgando y dispararía un write de
    // Firestore con un widget desmontado (M3).
    if (!mounted) return;
    _reactionClearTimer?.cancel();
    _reactionClearTimer = Timer(const Duration(milliseconds: 3500), () {
      if (!mounted || widget.roomCode == null) return;
      // Se limpia solo el campo propio para no borrar una reacción que la
      // pareja acabe de publicar (ambos pueden reaccionar en el mismo momento).
      FirestoreService.clearReaction(
        widget.roomCode!,
        player1: widget.isHost,
        player2: !widget.isHost,
      );
    });
  }

  /// Sincroniza el estado actual del juego con Firestore
  /// Actualiza el índice de pregunta y el turno para que el otro jugador lo vea
  // Sincroniza el estado del juego con Firestore para jugadores online.
  Future<void> _syncGameState() async {
    if (widget.mode == 'online' && widget.roomCode != null) {
      // Fire-and-forget desde `_nextQuestion`: sin try/catch una caída de red
      // (que es justo cuando más importa) rompería el flujo con una excepción
      // no manejada; la partida local sigue pero la pareja no avanzaría (R8).
      try {
        await FirestoreService.nextQuestion(
          widget.roomCode!,
          _currentIndex,
          _turn,
        );
      } catch (e) {
        debugPrint('[GamePlay] syncGameState error: $e');
      }
    }
  }

  /// Id del documento del recuerdo de voz de la ronda actual.
  ///
  /// Antes se usaba `voice_q<índice>`; como la ronda de voz (momento especial)
  /// ocupa SIEMPRE la misma posición, el mismo roomCode reutilizaba el
  /// documento en cada partida y un restart mezclaba el audio nuevo con los
  /// metadatos (createdAt, título, pregunta) del recuerdo anterior. El id de
  /// la pregunta es único en el banco: cada partida escribe en su propio
  /// documento y ambos dispositivos derivan el mismo id del recorrido.
  String _voiceMemoryId() {
    final questionId = _currentEngineRound?.question?.id;
    if (questionId != null && questionId.isNotEmpty) {
      return 'voice_$questionId';
    }
    return 'voice_q$_currentIndex';
  }

  /// Maneja la subida de un audio de voz a Cloudinary.
  /// ONLINE: ambos jugadores suben en paralelo y devuelve true cuando ambos
  /// ya subieron. En modo LOCAL no se sube ni se persiste nada (la tarjeta
  /// de voz avisa y avanza sin llamar a este callback).
  Future<bool> _handleVoiceUploaded(UploadedVoice uploaded) async {
    final index = _currentIndex;

    // Si esta pregunta de voz ya fue reemplazada por el fallback sin audio
    // (en este dispositivo o sincronizada por la pareja), el audio sobra: no
    // se persiste. Sin esto se crearía un recuerdo huérfano de un solo lado.
    if (_appliedFallbackIndex == index) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? _currentPlayer;
    final url = uploaded.downloadUrl;
    final publicId = uploaded.publicId;
    final gameId = widget.roomCode!;
    final role = widget.isHost ? 0 : 1;

    // Espera a que el coupleId de la pareja termine de cargarse antes de
    // crear el recuerdo. Evita la carrera en la que el audio se sube más
    // rápido que el perfil y acaba guardándose con un coupleId temporal
    // (local_*), lo que lo haría invisible en el historial.
    if (_coupleId.isEmpty) {
      await _coupleIdReady.future;
      if (!mounted) return false;
    }

    // La pregunta pudo avanzar (o cambiar a fallback) mientras se cargaba el
    // coupleId: el índice se capturó al inicio y si ya no coincide, o la
    // ronda ya no es de voz (fallback aplicado), se descarta para no escribir
    // en un recuerdo equivocado.
    if (_currentIndex != index ||
        _appliedFallbackIndex == index ||
        _currentEngineRound?.question?.type != engine_types.QuestionType.voz) {
      return false;
    }

    // La URL propia queda disponible para la revelación.
    _voiceUrls[role] = url;

    final coupleId = _coupleId.isNotEmpty
        ? _coupleId
        : 'local_${widget.roomCode ?? "session"}';
    final memoryId = _voiceMemoryId();

    final bothUploaded = await VoiceMemoryRepository.savePlayerAudio(
      memoryId: memoryId,
      gameId: gameId,
      coupleId: coupleId,
      question: _currentQuestion!.text,
      player1Id: widget.isHost ? uid : null,
      player1AudioUrl: widget.isHost ? url : null,
      player1PublicId: widget.isHost ? publicId : null,
      player2Id: widget.isHost ? null : uid,
      player2AudioUrl: widget.isHost ? null : url,
      player2PublicId: widget.isHost ? null : publicId,
    );
    return bothUploaded;
  }

  /// Emite true cuando el compañero sube su audio (solo online).
  /// Determina qué campo del documento observar según si este jugador
  /// es el anfitrión (player1) o el invitado (player2). Además guarda la URL
  /// del audio del compañero para que la revelación pueda reproducirlo.
  Stream<bool> _partnerUploadedStream() {
    final gameId = widget.roomCode!;
    final memoryId = _voiceMemoryId();
    final partnerIndex = widget.isHost ? 1 : 0;
    return VoiceMemoryRepository.streamMemory(gameId, memoryId)
        .map((memory) {
          if (memory == null) return false;
          final partnerUrl = widget.isHost
              ? memory.player2AudioUrl
              : memory.player1AudioUrl;
          if (partnerUrl.isNotEmpty && mounted) {
            setState(() => _voiceUrls[partnerIndex] = partnerUrl);
          }
          return partnerUrl.isNotEmpty;
        })
        .where((done) => done);
  }

  /// Se invoca cuando ambos jugadores ya subieron su audio (online): la
  /// pantalla intercambia la tarjeta de voz por la revelación.
  void _onVoiceBothUploaded() {
    if (!mounted) return;
    setState(() {});
  }

  /// Modo local: un jugador terminó de grabar su audio. Se conserva la ruta
  /// local (solo para esta pregunta) y se pasa el turno o se muestra la
  /// revelación cuando ambos grabaron.
  void _onVoiceRecordedLocal(String path) {
    _stopTimer();
    setState(() {
      _voiceLocalPaths[_turn] = path;
      if (_voiceLocalPaths[0] == null || _voiceLocalPaths[1] == null) {
        _turn = _turn == 0 ? 1 : 0;
      }
    });
    if (!_voiceRevealReady) _startTimer();
  }

  /// Maneja la continuación tras una pregunta de voz.
  /// ONLINE: ambos ya subieron, se avanza. LOCAL: el jugador 1 cambia turno,
  /// el jugador 2 avanza a la siguiente pregunta.
  void _handleVoiceContinue() {
    // Con revelación activa, ambos ya respondieron y "Continuar" avanza.
    if (_voiceRevealReady) {
      _nextQuestion();
      return;
    }

    if (widget.mode == 'online' && widget.roomCode != null) {
      _nextQuestion();
      return;
    }

    if (_turn == 0) {
      if (_advancing) return;
      _advancing = true;
      _stopTimer();
      _cardController.reset();
      setState(() {
        _turn = 1;
        _answerCtrl.clear();
      });
      _cardController.forward().whenComplete(() => _advancing = false);
      _startTimer();
      _syncGameState();
    } else {
      _nextQuestion();
    }
  }

  /// Finaliza el juego
  /// Detiene el temporizador y actualiza el estado en Firestore si es online
  // Finaliza la partida, guarda historial y actualiza logros.
  Future<void> _finishGame() async {
    if (_finishing) return;
    _finishing = true;
    _stopTimer();
    // Marcar el fin ANTES de los guardados para que el eco de `roomStream`
    // (status: finished) no reintente `_finishGame` en este dispositivo.
    if (mounted) setState(() => _gameOver = true);

    // ONLINE: publicar el fin PRIMERO (antes de los guardados locales, que
    // pueden tardar varios segundos). Así la pareja sale de la espera de la
    // última pregunta de inmediato. Si esta escritura se dejara para el final
    // y el anfitrión reinicia mientras el otro dispositivo todavía está
    // guardando, el write tardío volvería a marcar la sala como `finished`
    // a mitad del juego nuevo y sacaría a ambos jugadores de la partida.
    if (widget.mode == 'online' && widget.roomCode != null) {
      try {
        await FirestoreService.finishGame(widget.roomCode!);
      } catch (e) {
        // Si la sala ya terminó por el otro dispositivo, o la red falla, no
        // se detiene el cierre local de la partida (R8).
        debugPrint('[GamePlay] finishGame (game over) error: $e');
      }
    }

    try {
      await FirestoreService.saveGameHistory(
        player1: widget.p1,
        player2: widget.p2,
        mode: widget.mode,
        categories: widget.categories,
        questionsAnswered: _currentIndex + 1,
      );

      await AchievementService.updateGameStats(
        _currentIndex + 1,
        (widget.timerSeconds > 0
            ? (_currentIndex + 1) * widget.timerSeconds ~/ 60
            : 1),
      );
    } catch (_) {
      // Si falla el guardado local, la partida igual termina.
    }
  }

  /// Aplica el contenido de una partida reiniciada (motor) y resetea
  /// contadores locales. Host e invitado usan la misma ruta para mantener
  /// `_engineRounds` alineado con `_questions`.
  void _applyRestartFromContent(
    OnlineRestartContent content, {
    required int remoteIndex,
    required int remoteTurn,
  }) {
    setState(() {
      if (content.usesEngine) {
        _engineRounds
          ..clear()
          ..addAll(content.engineRounds);
        _questions = content.engineRounds.map(_toLegacyQuestion).toList();
      }
      _currentIndex = remoteIndex;
      _turn = remoteTurn;
      _gameOver = false;
      _resetQuestionState();
      _appliedFallbackIndex = -1;
      _advancing = false;
      _finishing = false;
      _waitingForHostRestart = false;
    });
  }

  /// Reinicia el juego con nuevas preguntas
  /// Carga nuevas preguntas y reinicia todos los contadores
  /// Si es online y es el anfitrión, actualiza Firestore
  // Reinicia el juego con nuevas preguntas y contadores.
  Future<void> _restartGame() async {
    _advancing = false;
    _finishing = false;
    _cardController.reset();
    _stopTimer();

    if (widget.mode == 'online' &&
        widget.roomCode != null &&
        widget.isHost) {
      // El host genera UNA vez y publica engineRounds; el invitado reconstruye
      // el mismo recorrido desde Firestore (no genera localmente).
      final rounds = await buildEngineMatch(
        preferredCategories: _preferredEngineCategories,
        totalRounds: widget.totalQuestions,
      );
      await FirestoreService.restartGame(
        widget.roomCode!,
        encodeEngineMatch(rounds),
      );
      if (!mounted) return;
      _applyRestartFromContent(
        OnlineRestartContent(engineRounds: rounds),
        remoteIndex: 0,
        remoteTurn: 0,
      );
    } else {
      if (widget.mode == 'online') {
        // Invitado: NO sale del game over todavía. Si bajara `_gameOver` aquí
        // (antes de recibir el nuevo engineRounds del host), el bloque del
        // roomStream que aplica el restart (`_gameOver && status == 'playing'`)
        // ya no aplicaría y el invitado se quedaría con las preguntas VIEJAS
        // mientras el anfitrión juega las nuevas. Se espera el contenido nuevo
        // por el roomStream y se avisa en la pantalla de fin.
        setState(() => _waitingForHostRestart = true);
        return;
      }
      setState(() {
        _questions = <Question>[];
        _engineRounds.clear();
        _initialized = false;
        _currentIndex = 0;
        _turn = 0;
        _gameOver = false;
        _resetQuestionState();
        _appliedFallbackIndex = -1;
      });
      await _startLocalEngineGame();
    }

    if (!mounted) return;
    _cardController.forward();
    _startTimer();
  }

  /// Lanza (sin esperar) la reconstrucción de la partida local del motor.
  Future<void> _startLocalEngineGame() async {
    final rounds = await buildEngineMatch(
      preferredCategories: _preferredEngineCategories,
      totalRounds: widget.totalQuestions,
    );
    if (!mounted) return;
    setState(() {
      _engineRounds
        ..clear()
        ..addAll(rounds);
      _questions = rounds.map(_toLegacyQuestion).toList();
      _initialized = true;
      _appliedFallbackIndex = -1;
    });
  }

  /// Reemplaza el Momento especial (voz) por una pregunta escrita del mismo
  /// tema, para quien no quiere (o no puede) hablar sin romper el desenlace.
  ///
  /// ONLINE: publica la pregunta escrita en `engineRounds[index]` para que la
  /// pareja la reciba por `roomStream` y ambos cambien a la misma pregunta.
  /// Sin esto, la pareja se queda en la tarjeta de voz esperando un audio que
  /// ya no se va a grabar.
  Future<void> _requestNoVoiceFallback() async {
    final round = _currentEngineRound;
    if (round == null || _appliedFallbackIndex == _currentIndex) return;

    // Excluye las preguntas que ya salieron en la partida para que el
    // fallback nunca repita una pregunta ya vista (el motor ya las registró
    // en `askedQuestionIds`, pero el fallback elige fuera de él).
    final usedQuestionIds = _engineRounds
        .map((r) => r.question?.id)
        .whereType<String>()
        .toSet();

    // ONLINE: si ambos pulsan "responder sin audio" a la vez, cada dispositivo
    // generaría su propio fallback y escribiría engineRounds.$index → el
    // último write ganaría y cada teléfono quedaría con una pregunta DISTINTA.
    // Se siembra la elección con datos que AMBOS comparten (código de sala +
    // índice + id de la pregunta de voz): los dos generan el MISMO fallback y
    // la escritura es idempotente.
    final Random? seed;
    if (widget.mode == 'online' && widget.roomCode != null) {
      seed = Random(
        '${widget.roomCode}:$_currentIndex:${round.question?.id}'.hashCode,
      );
    } else {
      seed = null;
    }
    final fallback = await pickNoVoiceFallback(
      round: round,
      preferredCategories: _preferredEngineCategories,
      usedQuestionIds: usedQuestionIds,
      random: seed,
    );
    if (!mounted || fallback == null) return;
    final replaced = round.copyWith(question: fallback);
    _applyEngineRoundAtCurrentIndex(replaced);
    if (widget.mode == 'online' && widget.roomCode != null) {
      // Publica el fallback para que la pareja cambie a la misma pregunta
      // escrita. Se reintenta: si la escritura falla, el otro dispositivo se
      // quedaría en la tarjeta de voz esperando un audio que ya no llega.
      var published = false;
      for (var attempt = 0; attempt < 3 && !published; attempt++) {
        try {
          await FirestoreService.applyNoVoiceFallback(
            widget.roomCode!,
            _currentIndex,
            replaced.toMap(),
          );
          published = true;
        } catch (_) {}
      }
      if (!published && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo sincronizar el cambio con tu pareja. '
              'Presiona de nuevo para reintentar.',
            ),
          ),
        );
      }
    }
  }

  /// Sustituye la ronda y la pregunta legacy de la pregunta ACTUAL por una
  /// versión escrita (fallback sin audio, local o sincronizado). Arranca el
  /// temporizador solo si esta pregunta escrita le toca contestar a este
  /// jugador, para que el de la pareja no avance la partida en su lugar.
  void _applyEngineRoundAtCurrentIndex(GameRound round) {
    if (!mounted || _currentIndex >= _engineRounds.length) return;
    setState(() {
      _engineRounds[_currentIndex] = round;
      _questions[_currentIndex] = _toLegacyQuestion(round);
      _appliedFallbackIndex = _currentIndex;
    });
    if (widget.mode != 'online' || _isMyTurn) _startTimer();
  }

  /// Salir del juego y volver a la pantalla principal
  /// Detiene el temporizador y finaliza la partida si es online
  // Sale del juego y vuelve a la pantalla principal.
  Future<void> _exitGame() async {
    // Idempotente: un doble tap en "Salir" (o back + diálogo) no debe escribir
    // presencia/finish dos veces ni navegar dos rutas (R5).
    if (_exiting) return;
    _exiting = true;
    _stopTimer();
    if (widget.mode == 'online' && widget.roomCode != null) {
      final code = widget.roomCode!;
      // Fire-and-forget con manejo de errores: si la red falla, la sala puede
      // quedar marcada como online/playing, pero no debe tirar la app ni
      // impedir la navegación (R8).
      try {
        await PresenceService.setPresenceOffline(code);
      } catch (e) {
        debugPrint('[GamePlay] setPresenceOffline error: $e');
      }
      try {
        await FirestoreService.finishGame(code);
      } catch (e) {
        debugPrint('[GamePlay] finishGame error: $e');
      }
    }
    if (mounted) context.go('/');
  }

  /// Intercepta el botón atrás del sistema para no salir del juego por
  /// accidente: si la partida sigue en curso pide confirmación y, si el
  /// juego ya terminó, sale directo.
  void _onSystemBack() {
    if (_gameOver) {
      _exitGame();
      return;
    }
    _confirmExitGame();
  }

  /// Muestra un diálogo de confirmación antes de abandonar la partida en
  /// curso (evita perder el progreso con un toque accidental de atrás).
  Future<void> _confirmExitGame() async {
    final ac = AppColors.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.danger,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Salir del juego',
              style: TextStyle(color: ac.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Si sales ahora se perderá el progreso de esta partida. ¿Seguro que querés salir?',
          style: TextStyle(color: ac.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salir',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) _exitGame();
  }

  /// Getters para obtener información del estado actual del juego
  /// _isMyTurn: Verifica si es mi turno (en online compara con el rol del usuario)
  // Verifica si es el turno del jugador actual.
  bool get _isMyTurn =>
      widget.mode != 'online' ||
      (_turn == 0 && widget.isHost) ||
      (_turn == 1 && !widget.isHost);

  /// _canAdvance: Determina si se puede avanzar a la siguiente pregunta
  ///
  /// En comparaciones online no se puede avanzar hasta que ambos jugadores
  /// eligieron: cada uno contesta en su teléfono y el "Continuar" debe
  /// esperar a que la pareja haya enviado su elección.
  bool get _canAdvance =>
      (widget.mode != 'online' || _isMyTurn) &&
      !_gamePausedDueToDisconnection &&
      !_comparisonPending &&
      !_textAnswerPending &&
      !_advancing;

  /// _currentPlayer: Obtiene el nombre del jugador en el turno actual
  // Obtiene el nombre del jugador en el turno actual.
  String get _currentPlayer => _turn == 0 ? widget.p1 : widget.p2;

  /// Nombre del compañero/a: en online siempre es la otra persona, aunque en
  /// este dispositivo `widget.p1`/`widget.p2` estén fijos como anfitrión e
  /// invitado. El invitado no debe ver su propio nombre como "pareja".
  String get _partnerName => widget.isHost ? widget.p2 : widget.p1;

  /// _currentQuestion: Obtiene la pregunta actual de la lista
  // Obtiene la pregunta actual de la lista.
  Question? get _currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
      ? _questions[_currentIndex]
      : null;

  bool get _isVoiceQuestion =>
      _currentQuestion?.type == QuestionType.voiceMemory;

  /// `true` cuando la pregunta actual es de texto con revelación: ambos
  /// jugadores responden la misma pregunta y al final se revelan (todo lo que
  /// no es voz, comparación, reto ni comodín).
  bool get _isTextRevealQuestion =>
      !_isVoiceQuestion &&
      !_isComparisonQuestion &&
      !_isRetoQuestion &&
      !_isComodinQuestion;

  /// `true` cuando ambos ya respondieron en la pregunta de texto actual y
  /// toca mostrar la revelación.
  bool get _textRevealReady =>
      _isTextRevealQuestion &&
      _textAnswers[0] != null &&
      _textAnswers[1] != null;

  /// `true` en preguntas de texto online mientras falta una respuesta: el
  /// jugador actual ya respondió (o no) y se espera a su pareja. Aquí no se
  /// puede avanzar ni correr el temporizador.
  bool get _textAnswerPending =>
      widget.mode == 'online' &&
      _isTextRevealQuestion &&
      !_textRevealReady;

  /// `true` cuando ambos audios de la pregunta de voz actual están listos:
  /// online llegan por Firestore (URLs) y local se conservan los archivos
  /// grabados en `_voiceLocalPaths` (solo durante la pregunta).
  bool get _voiceRevealReady {
    if (!_isVoiceQuestion) return false;
    if (widget.mode == 'online' && widget.roomCode != null) {
      return _voiceUrls[0] != null && _voiceUrls[1] != null;
    }
    return _voiceLocalPaths[0] != null && _voiceLocalPaths[1] != null;
  }

  /// `true` cuando la pregunta actual está en su momento de revelación
  /// (comparación, texto o voz): ya se pueden ver las respuestas y reaccionar.

  /// Ronda del motor de la pregunta actual (recorrido emocional real).
  GameRound? get _currentEngineRound =>
      _engineRounds.isNotEmpty && _currentIndex < _engineRounds.length
      ? _engineRounds[_currentIndex]
      : null;

  /// `true` cuando la pregunta actual es una comparación (ambos eligen y
  /// luego se comparan). Solo existe en partidas del motor.
  bool get _isComparisonQuestion =>
      _currentEngineRound?.question?.type == engine_types.QuestionType.comparacion;

  /// Opciones de la comparación actual (vacío si no es comparación).
  List<String> get _comparisonOptions =>
      _currentEngineRound?.question?.options ?? const [];

  /// `true` cuando la pregunta actual es un reto (acción, no solo responder).
  bool get _isRetoQuestion =>
      _currentEngineRound?.question?.type == engine_types.QuestionType.reto;

  /// `true` cuando la pregunta actual es un comodín: una acción o momento
  /// compartido que cambia la dinámica de la partida (no es una pregunta que
  /// se responde por escrito, se hace juntos).
  bool get _isComodinQuestion =>
      _currentEngineRound?.question?.type == engine_types.QuestionType.comodin;

  /// `true` cuando ambos ya eligieron en la comparación actual y toca mostrar
  /// el resultado (local: p1 elige, luego p2; online: cada uno en su teléfono
  /// y las elecciones llegan por Firestore, así que también se revela).
  bool get _comparisonReady =>
      _isComparisonQuestion &&
      _comparisonChoices[0] != null &&
      _comparisonChoices[1] != null;

  /// `true` en comparaciones online mientras falta una elección: el jugador
  /// actual ya eligió (o no) y se espera a que su pareja responda desde su
  /// propio dispositivo. Aquí no se puede avanzar ni correr el temporizador.
  bool get _comparisonPending =>
      widget.mode == 'online' &&
      _isComparisonQuestion &&
      !_comparisonReady;

  /// Quién responde ahora la comparación: el primer jugador en elegir es el
  /// que lleva el turno y el segundo es su pareja (se pasan el teléfono en la
  /// misma pregunta).
  int get _comparisonPicker {
    if (_comparisonChoices[0] == null && _comparisonChoices[1] == null) {
      return _turn;
    }
    return _comparisonChoices[0] == null ? 0 : 1;
  }

  /// Etiqueta legible de la categoría de la pregunta actual. La marca legacy
  /// `random` (modo aleatorio online) se muestra como "Mezcla".
  String get _currentCategoryLabel {
    final raw = _currentQuestion?.category ?? '';
    if (raw == 'random') return 'Mezcla';
    if (raw == 'generales') return 'Generales';
    return getCategoryById(raw)?.label ?? raw;
  }

  /// Barra del viaje emocional (solo partidas del motor).
  ///
  /// Un segmento por capítulo con tamaño proporcional a sus rondas: los
  /// capítulos ya recorridos quedan en rosa tenue, el actual en rosa, y los
  /// futuros en el tono de fondo. Debajo, un chip con la fase actual
  /// (capítulo · emoción · intensidad) para que la partida se sienta dirigida
  /// y el desenlace (Momento especial) destaque como el pico del recorrido.
  Widget _buildJourneyBar(AppColors ac) {
    final current = _currentEngineRound!;
    // Capítulos en orden de aparición, con su número de rondas.
    final chapters = <Chapter, int>{};
    for (final round in _engineRounds) {
      chapters[round.chapter] = (chapters[round.chapter] ?? 0) + 1;
    }
    final ordered = chapters.keys.toList();

    return Column(
      children: [
        Row(
          children: [
            for (final chapter in ordered) ...[
              Expanded(
                flex: chapters[chapter]!,
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _journeyColor(ac, chapter),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: ac.surfaceAlt,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_journeyIcon(current.chapter), size: 15, color: AppColors.pink),
              const SizedBox(width: 6),
              Text(
                current.chapter.label,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${current.emotion.emoji} ${current.emotion.label}',
                style: TextStyle(
                  color: ac.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                current.intensity.label,
                style: TextStyle(
                  color: ac.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Color del segmento del capítulo según su posición respecto a la ronda
  /// actual: recorrido (rosa tenue), actual (rosa), pendiente (fondo).
  Color _journeyColor(AppColors ac, Chapter chapter) {
    final currentChapterIndex = _engineRounds.indexWhere(
      (r) => r.chapter == _currentEngineRound!.chapter,
    );
    final firstOfChapter = _engineRounds.indexWhere(
      (r) => r.chapter == chapter,
    );
    if (firstOfChapter < currentChapterIndex) {
      return AppColors.pink.withValues(alpha: 0.3);
    }
    if (chapter == _currentEngineRound!.chapter) return AppColors.pink;
    return ac.surfaceAlt;
  }

  IconData _journeyIcon(Chapter chapter) {
    switch (chapter) {
      case Chapter.bienvenida:
        return Icons.waving_hand_outlined;
      case Chapter.calentamiento:
        return Icons.local_fire_department_outlined;
      case Chapter.conexion:
        return Icons.favorite_outline;
      case Chapter.momentoEspecial:
        return Icons.auto_awesome;
      case Chapter.cierre:
        return Icons.celebration_outlined;
    }
  }

  /// Zona de respuesta de una pregunta de comparación.
  ///
  /// LOCAL: se pasan el teléfono; cada jugador ve sus opciones con el
  /// encabezado "Elige {nombre}" y elige una.
  ///
  /// ONLINE: cada jugador elige en su propio teléfono. El encabezado usa el
  /// propio nombre y, una vez elegido, se muestra "Esperando a {pareja}..."
  /// mientras el otro envía su elección. Cuando los dos ya eligieron, ambos
  /// dispositivos revelan quién eligió qué y si coincidieron.
  Widget _buildComparisonOptions(AppColors ac) {
    if (_comparisonReady) return _buildComparisonReveal(ac);

    final online = widget.mode == 'online';
    final picker = online ? (widget.isHost ? 0 : 1) : _comparisonPicker;
    final pickerName = picker == 0 ? widget.p1 : widget.p2;
    final myChoice = _comparisonChoices[picker];
    final partnerName = picker == 0 ? widget.p2 : widget.p1;
    final waitingForPartner = online && myChoice != null;
    final options = _comparisonOptions;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ac.surfaceAlt,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            waitingForPartner ? 'Esperando a $partnerName...' : 'Elige $pickerName',
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _buildComparisonOption(ac, options[i], i, picker, enabled: !waitingForPartner),
        ],
      ],
    );
  }

  /// Revelación de una comparación: la elección de cada jugador y si
  /// coincidieron. Solo aparece cuando ambos ya respondieron.
  Widget _buildComparisonReveal(AppColors ac) {
    final p1Choice = _comparisonChoices[0]!;
    final p2Choice = _comparisonChoices[1]!;
    final matched = p1Choice == p2Choice;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: matched
                ? AppColors.pink.withValues(alpha: 0.12)
                : ac.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: matched ? AppColors.pink : ac.borderLight,
              width: matched ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite, size: 20, color: AppColors.pink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.p1} eligió:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  p1Choice,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: ac.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ac.borderLight, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_border, size: 20, color: AppColors.pink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.p2} eligió:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  p2Choice,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: matched
                ? AppColors.pink.withValues(alpha: 0.14)
                : Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(
                matched ? Icons.auto_awesome : Icons.tips_and_updates,
                size: 18,
                color: matched ? AppColors.pink : Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  matched
                      ? '¡Coincidieron!'
                      : 'Elecciones distintas · ¿de quién fue?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: matched ? AppColors.pink : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonOption(
    AppColors ac,
    String option,
    int index,
    int pickerIndex, {
    bool enabled = true,
  }) {
    final selected = _comparisonChoices[pickerIndex] == option;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap:
              enabled && !_comparisonReady ? () => _onComparisonTap(option) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.pink.withValues(alpha: 0.14)
                  : ac.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.pink : ac.borderLight,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.pink : ac.surface,
                    border: Border.all(
                      color: selected ? AppColors.pink : ac.textMuted,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : ac.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.pink : ac.textPrimary,
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

  /// Tarjeta de acción del comodín: en lugar de un campo de respuesta, muestra
  /// la acción que la pareja debe hacer junta. No hay nada que escribir: el
  /// comodín cambia la dinámica y se avanza cuando ambos lo completan.
  Widget _buildComodinAction(AppColors ac) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.pink.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, size: 28, color: AppColors.pink),
          const SizedBox(height: 8),
          Text(
            "Comodín: háganlo juntos.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ac.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "La pregunta de arriba es una acción compartida: cuando terminen,"
            " avancen con «¡Hecho!».",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Construye la interfaz principal del juego
  /// Si el juego terminó, muestra la pantalla de fin
  /// Si no está inicializado, muestra un indicador de carga
  /// Si no, muestra la pregunta actual con controles de navegación
  // Descripción breve de lo que hace.
  @override
  Widget build(BuildContext context) {
    if (_gameOver) {
      return _withBackGuard(_buildGameOver());
    }
    if (!_initialized || _currentQuestion == null) {
      final ac = AppColors.of(context);
      return _withBackGuard(
        Scaffold(
          backgroundColor: ac.background,
          body: Center(
            child: _initError != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, color: ac.textSecondary, size: 48),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _initError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ac.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _retryInit,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        widget.mode == 'online' && !widget.isHost
                            ? "Cargando juego..."
                            : "Preparando preguntas...",
                        style: TextStyle(color: ac.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      );
    }

    final ac = AppColors.of(context);

    return _withBackGuard(
      Scaffold(
        backgroundColor: ac.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: _confirmExitGame,
                      icon: Icon(Icons.logout, size: 16, color: ac.textPrimary),
                      label: Text(
                        "Salir",
                        style: TextStyle(fontSize: 12, color: ac.textPrimary),
                      ),
                    ),
                  if (widget.timerSeconds > 0 &&
                      !_isVoiceQuestion &&
                      !_comparisonPending &&
                      !_textAnswerPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingTime <= 5
                            ? Colors.red.withValues(alpha: 0.12)
                            : ac.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: _remainingTime <= 5
                                ? Colors.red
                                : ac.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_remainingTime}s",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _remainingTime <= 5
                                  ? Colors.red
                                  : ac.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.mode == 'online')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _otherPlayerOnline
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _otherPlayerOnline ? Icons.wifi : Icons.wifi_off,
                            size: 14,
                            color: _otherPlayerOnline
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _otherPlayerOnline ? "Online" : "Desconectado",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _otherPlayerOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Local",
                      style: TextStyle(fontSize: 12, color: ac.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              _buildPlayersHeader(ac),

              const SizedBox(height: 20),
              if (_isVoiceQuestion)
                Expanded(
                  child: ScaleTransition(
                    scale: _cardAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF5FA2),
                            Color(0xFFFF7A8A),
                            Color(0xFFB8439F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5FA2).withValues(alpha: .35),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ac.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: _voiceRevealReady
                            ? _buildVoiceReveal(ac)
                            : VoiceQuestionCard(
                          key: ValueKey(_voiceMemoryId()),
                          questionText: _currentQuestion!.text,
                          playerName:
                              (widget.mode == 'online' &&
                                  widget.roomCode != null)
                              ? (widget.isHost ? widget.p2 : widget.p1)
                              : (_turn == 0 ? widget.p2 : widget.p1),
                          coupleId: _coupleId.isNotEmpty
                              ? _coupleId
                              : 'local_${widget.roomCode ?? "session"}',
                          isLastQuestion:
                              _currentIndex >= _questions.length - 1,
                          onContinue: _handleVoiceContinue,
                          localMode: widget.mode != 'online',
                          onUploaded:
                              (widget.mode == 'online' &&
                                  widget.roomCode != null)
                              ? _handleVoiceUploaded
                              : null,
                          partnerUploadedStream:
                              (widget.mode == 'online' &&
                                  widget.roomCode != null)
                              ? _partnerUploadedStream()
                              : null,
                          onBothUploaded:
                              (widget.mode == 'online' &&
                                  widget.roomCode != null)
                              ? _onVoiceBothUploaded
                              : null,
                          onRecorded:
                              (widget.mode == 'online')
                              ? null
                              : _onVoiceRecordedLocal,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ScaleTransition(
                    scale: _cardAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF5FA2),
                            Color(0xFFFF7A8A),
                            Color(0xFFB8439F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5FA2).withValues(alpha: .35),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ac.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: ac.borderLight, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ac.surfaceAlt,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isRetoQuestion
                                          ? Icons.bolt
                                          : _isComodinQuestion
                                          ? Icons.auto_awesome
                                          : Icons.favorite,
                                      size: 16,
                                      color: AppColors.pink,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      _isRetoQuestion
                                          ? 'Reto · $_currentCategoryLabel'
                                          : _isComodinQuestion
                                          ? 'Comodín · $_currentCategoryLabel'
                                          : _currentCategoryLabel,
                                      style: TextStyle(
                                        color: ac.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_currentEngineRound != null) ...[
                                const SizedBox(height: 10),
                                _buildJourneyBar(ac),
                              ],
                              const SizedBox(height: 24),
                              Text(
                                _currentQuestion!.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: ac.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 40),
                              if (_isComparisonQuestion)
                                _buildComparisonOptions(ac)
                              else if (_isComodinQuestion)
                                _buildComodinAction(ac)
                              else if (_textRevealReady)
                                _buildTextReveal(ac)
                              else if (widget.mode == 'online' &&
                                  _textAnswers[widget.isHost ? 0 : 1] != null)
                                _buildAnswerSentWaiting(ac)
                              else
                                TextField(
                                  controller: _answerCtrl,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Escribe su respuesta...',
                                    hintStyle: TextStyle(color: ac.textMuted),
                                    filled: true,
                                    fillColor: ac.surfaceAlt,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon:
                                        _answerCtrl.text.isNotEmpty &&
                                            !_answerSaved
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.favorite,
                                              color: AppColors.pink,
                                            ),
                                            tooltip: 'Guardar como favorita',
                                            onPressed: _saveAsFavorite,
                                          )
                                        : null,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isVoiceQuestion &&
                  !_voiceRevealReady &&
                  _currentEngineRound != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _requestNoVoiceFallback,
                  icon: const Icon(
                    Icons.record_voice_over_outlined,
                    size: 18,
                  ),
                  label: const Text('Prefiero responder sin audio'),
                  style: TextButton.styleFrom(
                    foregroundColor: ac.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Pregunta ${_currentIndex + 1} de ${_questions.length}",
                    style: TextStyle(fontSize: 12, color: ac.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _questions.length,
                  minHeight: 7,
                  backgroundColor: ac.surfaceAlt,
                  borderRadius: BorderRadius.circular(4),
                  valueColor: AlwaysStoppedAnimation(AppColors.pink),
                ),
              ),
              const SizedBox(height: 24),

              if (!_isVoiceQuestion)
                _buildBottomAction(ac),
            ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Botón de acción inferior según el estado de la pregunta.
  ///
  /// En preguntas de texto con revelación el botón sirve para ENVIAR la
  /// respuesta (ambos responden, también quien no lleva el turno en online) y
  /// luego para continuar cuando la revelación está lista. El resto conserva
  /// el comportamiento anterior, siempre gateado por `_canAdvance`.
  Widget _buildBottomAction(AppColors ac) {
    final String label;
    final VoidCallback? onPressed;

    if (_isTextRevealQuestion) {
      final answered = widget.mode == 'online'
          ? _textAnswers[widget.isHost ? 0 : 1] != null
          : false;
      if (_textRevealReady) {
        label = 'Continuar';
        onPressed = _canAdvance ? _nextQuestion : null;
      } else if (widget.mode == 'online' && answered) {
        label = 'Esperando a tu pareja...';
        onPressed = null;
      } else {
        label = 'Enviar respuesta';
        onPressed = _answerCtrl.text.trim().isEmpty ? null : _submitTextAnswer;
      }
    } else if (_comparisonReady) {
      label = 'Continuar';
      onPressed = _canAdvance ? _nextQuestion : null;
    } else if (_gamePausedDueToDisconnection) {
      label = 'Esperando reconexión...';
      onPressed = null;
    } else if (_comparisonPending) {
      label = 'Esperando a tu pareja...';
      onPressed = null;
    } else if (widget.mode == 'online' && !_isMyTurn) {
      label = 'Esperando a tu pareja...';
      onPressed = null;
    } else if (_isComodinQuestion) {
      label = '¡Hecho!';
      onPressed = _canAdvance ? _nextQuestion : null;
    } else {
      label = 'Siguiente';
      onPressed = _canAdvance ? _nextQuestion : null;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [AppColors.pink, AppColors.pinkGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: .35),
              blurRadius: 20,
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.pink, AppColors.pinkGradientEnd],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  /// Encabezado con los dos perfiles: ya no hay "turno de X"; ambos jugadores
  /// se ven siempre arriba, con un resaltado sutil (anillo rosado) en quien
  /// lleva el avance de la pregunta.
  Widget _buildPlayersHeader(AppColors ac) {
    return Row(
      children: [
        Expanded(
          child: _buildPlayerHeader(
            ac,
            name: widget.p1,
            photoUrl: _hostPhotoUrl,
            active: _turn == 0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              Icon(Icons.favorite, color: AppColors.pink, size: 30),
              const SizedBox(height: 4),
              Text(
                'vs',
                style: TextStyle(fontSize: 11, color: ac.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildPlayerHeader(
            ac,
            name: widget.p2,
            photoUrl: _guestPhotoUrl,
            active: _turn == 1,
          ),
        ),
      ],
    );
  }

  /// Perfil de un jugador: avatar (foto o inicial), nombre y anillo rosado
  /// suave cuando ese jugador lleva el avance.
  Widget _buildPlayerHeader(
    AppColors ac, {
    required String name,
    required String photoUrl,
    required bool active,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.pink : ac.borderLight,
              width: active ? 2.5 : 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: ClipOval(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    width: 54,
                    height: 54,
                  )
                : _buildAvatarFallback(ac, name),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppColors.pink : ac.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Avatar de respaldo con la inicial del nombre (seguro ante nombres
  /// vacíos y emojis fuera del plano BMP).
  Widget _buildAvatarFallback(AppColors ac, String name) {
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    return Container(
      width: 54,
      height: 54,
      color: AppColors.pink.withAlpha(38),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.pink,
          ),
        ),
      ),
    );
  }

  /// Revelación de una pregunta de texto: la respuesta de cada jugador y la
  /// barra de reacciones. Solo aparece cuando ambos ya respondieron.
  Widget _buildTextReveal(AppColors ac) {
    return Column(
      children: [
        _buildAnswerCard(ac, widget.p1, _textAnswers[0]!),
        const SizedBox(height: 12),
        _buildAnswerCard(ac, widget.p2, _textAnswers[1]!),
        const SizedBox(height: 20),
        ReactionButton(
          onReact: _handleReact,
          reactionEmoji: _reactionEmoji,
          partnerReactionEmoji: _partnerReactionEmoji,
          partnerName: _partnerName,
        ),
      ],
    );
  }

  /// Tarjeta con la respuesta escrita de un jugador.
  Widget _buildAnswerCard(AppColors ac, String playerName, String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.borderLight, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 20, color: AppColors.pink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$playerName respondió:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  answer,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Estado "Respuesta enviada" de una pregunta de texto online: el jugador
  /// ya respondió y espera a que su pareja envíe la suya.
  Widget _buildAnswerSentWaiting(AppColors ac) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pink.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Respuesta enviada',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Esperando a que $_partnerName responda...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Revelación de una pregunta de voz: los dos audios reproducibles y la
  /// barra de reacciones. Online usa las URLs de Cloudinary; local reproduce
  /// los archivos grabados (conservados solo durante la pregunta).
  Widget _buildVoiceReveal(AppColors ac) {
    final isOnline = widget.mode == 'online' && widget.roomCode != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildVoiceRevealHeader(ac),
                  const SizedBox(height: 24),
                  _buildVoiceRevealRow(
                    ac,
                    widget.p1,
                    isOnline ? _voiceUrls[0] : null,
                    localPath: isOnline ? null : _voiceLocalPaths[0],
                  ),
                  const SizedBox(height: 12),
                  _buildVoiceRevealRow(
                    ac,
                    widget.p2,
                    isOnline ? _voiceUrls[1] : null,
                    localPath: isOnline ? null : _voiceLocalPaths[1],
                  ),
                  const SizedBox(height: 24),
                  ReactionButton(
          onReact: _handleReact,
          reactionEmoji: _reactionEmoji,
          partnerReactionEmoji: _partnerReactionEmoji,
          partnerName: _partnerName,
        ),
                  const SizedBox(height: 20),
                  _buildVoiceRevealContinue(ac),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Encabezado de la revelación de voz (idéntico a la tarjeta de voz).
  Widget _buildVoiceRevealHeader(AppColors ac) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: AppColors.pink, size: 16),
            SizedBox(width: 6),
            Text(
              'Momento de Voz',
              style: TextStyle(
                color: AppColors.pink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _currentQuestion!.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: ac.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Fila de audio de un jugador en la revelación de voz. Muestra un
  /// indicador mientras el audio aún no está disponible.
  Widget _buildVoiceRevealRow(
    AppColors ac,
    String playerName,
    String? url, {
    String? localPath,
  }) {
    if (url == null && localPath == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ac.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pink.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cargando el audio de $playerName...',
                style: TextStyle(color: ac.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return VoiceRevealPlayer(label: playerName, url: url, localPath: localPath);
  }

  /// Botón de continuación de la revelación de voz. En online solo avanza
  /// quien lleva el turno (igual que en las comparaciones).
  Widget _buildVoiceRevealContinue(AppColors ac) {
    final isLast = _currentIndex >= _questions.length - 1;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.pink, AppColors.pinkGradientEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: .35),
              blurRadius: 20,
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: _canAdvance ? _handleVoiceContinue : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            isLast ? 'Finalizar' : 'Continuar',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// Envuelve una pantalla para interceptar el botón atrás del sistema y
  /// evitar salir del juego por accidente.
  Widget _withBackGuard(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onSystemBack();
      },
      child: child,
    );
  }

  /// Construye la pantalla de fin del juego
  /// Muestra una animación de celebración, el número de preguntas respondidas
  /// y opciones para jugar de nuevo o volver al inicio
  // Construye la pantalla de fin con celebración y opciones.
  Widget _buildGameOver() {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: (value - 0.5) * 0.2,
                      child: Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.amber.shade400,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  "Fin del Juego!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "${widget.p1} y ${widget.p2} respondieron ${_currentIndex + 1} preguntas juntos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: ac.textSecondary),
                ),
                const SizedBox(height: 40),
                if (_waitingForHostRestart) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Esperando a que ${widget.p1} reinicie la partida...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: ac.textSecondary),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _restartGame,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Jugar de Nuevo",
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _exitGame,
                    icon: const Icon(Icons.favorite),
                    label: const Text(
                      "Volver al Inicio",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
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
      ),
    );
  }
}
