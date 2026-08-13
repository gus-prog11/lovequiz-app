import 'package:LoveQuiz/cards/pair_options_card.dart';
import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/models/user_model.dart';
import 'package:LoveQuiz/propertys/button_style.dart';
import 'package:LoveQuiz/services/user_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/firestore_service.dart';

class PairingScreen extends StatefulWidget {
  final String? initialMode;

  const PairingScreen({super.key, this.initialMode});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  UserModel? user;
  String? selectedCard;
  String? _mode;
  final FocusNode _player1Focus = FocusNode();
  final FocusNode _player2Focus = FocusNode();
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  bool _loading = false;
  //Lista de opciones de emparejamiento con su configuración para mostrar en la UI y manejar la lógica de selección
  final List<Map<String, dynamic>> _options = [
    {
      "id": "local",
      "image": Image.asset(
        "lib/assets/images/icon_local.png",
        width: 34,
        height: 34,
      ),
      "label": "Mismo teléfono",
      "desc": "Jueguen juntos en un dispositivo",
      "emoji": "📱",
    },
    {
      "id": "create",
      "image": Image.asset(
        "lib/assets/images/icon_crear_sala.png",
        width: 34,
        height: 34,
      ),
      "label": "Crear sala",
      "desc": "Crea una sala e invita a tu pareja",
      "emoji": "🏠",
    },
    {
      "id": "join",
      "image": Image.asset(
        "lib/assets/images/icon_join.png",
        width: 34,
        height: 34,
      ),
      "label": "Unirse a sala",
      "desc": "Ingresa el código de tu pareja",
      "emoji": "🔗",
    },
    {
      "id": "random",
      "image": Image.asset(
        "lib/assets/images/icon_aleatory.png",
        width: 34,
        height: 34,
      ),
      "label": "Aleatorio",
      "desc": "Conecta con alguien al azar",
      "emoji": "🎲",
    },
  ];

  // Descripción breve de lo que hace.
  @override
  //Inicializa el estado del widget, asignando el modo inicial si se proporciona a través de los parámetros de la ruta. Esto permite que la pantalla de emparejamiento se configure automáticamente según la opción
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    loadUser();
    _player1Focus.addListener(_onFocusChange);
    _player2Focus.addListener(_onFocusChange);
  }

  // Actualiza el estado del widget cuando cambia el foco de un campo.
  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  //Carga los datos del usuario actual desde Firebase Auth y Firestore.
  // Si el usuario está autenticado, obtiene su información de perfil y la almacena en el estado del widget para su uso posterior
  // Carga los datos del usuario autenticado desde Firestore.
  Future<void> loadUser() async {
    final name = FirebaseAuth.instance.currentUser;

    if (name == null) return;

    final data = await UserService.getUser(name.uid);

    if (!mounted) return;

    setState(() {
      user = data;
    });
  }

  // Libera los controladores de texto y nodos de foco.
  @override
  //Libera los recursos de los controladores de texto cuando el widget se elimine para evitar fugas de memoria
  void dispose() {
    _player1Focus.dispose();
    _player2Focus.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  //Si el modo seleccionado es "local", verifica que ambos jugadores hayan ingresado sus nombres. Si es así, navega a la pantalla de configuración del juego pasando los nombres como parámetros en la ruta. Si falta algún nombre, muestra un mensaje de error utilizando un SnackBar
  // Valida los nombres y navega a la configuración del juego local.
  void _handleLocalPlay() {
    //trim quita espacios al inicio y al final del texto para evitar que se consideren nombres vacíos si el usuario solo ingresa espacios
    if (_player1Controller.text.trim().isEmpty ||
        _player2Controller.text.trim().isEmpty) {
      //Si alguno de los campos de nombre está vacío, muestra un mensaje de error y no navega a la siguiente pantalla
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa los nombres de ambos jugadores")),
      );
      return;
    }
    context.push(
      //Navega a la pantalla de configuración del juego pasando los nombres de los jugadores como parámetros en la URL.
      // Los nombres se codifican para que sean seguros en la URL
      '/setup?mode=local&p1=${Uri.encodeComponent(_player1Controller.text)}&p2=${Uri.encodeComponent(_player2Controller.text)}',
    );
  }

  // Crea una sala online y navega a la sala de espera.
  Future<void> _handleCreateRoom() async {
    setState(() {
      _loading = true;
    });
    try {
      final code = await FirestoreService.createRoom();
      if (!mounted) return;
      context.push('/waiting?roomCode=$code&host=true');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al crear sala: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Se une a una sala existente con el código ingresado.
  Future<void> _handleJoinRoom() async {
    if ( //_player2Controller.text.trim().isEmpty ||
    _roomCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el código de la sala")),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final code = _roomCodeController.text.trim().toUpperCase();
      final joined = await FirestoreService.joinRoom(code);
      if (!mounted) return;
      if (!joined) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sala no encontrada o ya está llena")),
        );
        return;
      }
      context.push('/waiting?roomCode=$code&host=false');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al unirse: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Busca una sala aleatoria disponible o crea una nueva.
  Future<void> _handleRandomMatch() async {
    if (_player1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text("Proximamente"))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final name = _player1Controller.text.trim();
      final existingRoom = await FirestoreService.findRandomRoom();
      if (!mounted) return;
      if (existingRoom != null) {
        final joined = await FirestoreService.joinRoom(existingRoom);
        if (!mounted) return;
        if (joined) {
          context.push(
            '/waiting?roomCode=$existingRoom&name=${Uri.encodeComponent(name)}&host=false&random=true',
          );
          return;
        }
      }
      final code = await FirestoreService.createRoom(isRandom: true);
      if (!mounted) return;
      context.push(
        '/waiting?roomCode=$code&name=${Uri.encodeComponent(name)}&host=true&random=true',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Maneja la selección de modo y ejecuta la acción correspondiente.
  Future<void> _onModeSelected(String mode) async {
    switch (mode) {
      case 'local':
        setState(() => _mode = "local");
        break;
      case 'join':
        setState(() => _mode = 'join');
        break;
      case 'create':
        await _handleCreateRoom();
        break;
      case 'random':
        await _handleRandomMatch();
        break;
    }
  }

  // Construye la pantalla de emparejamiento con selección o formulario.
  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Scaffold(
      backgroundColor: ac.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: Icon(Icons.arrow_back, color: ac.textPrimary),
                    style: IconButton.styleFrom(backgroundColor: ac.surfaceAlt),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Emparejamiento",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _mode == null ? _buildModeSelection() : _buildModeForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Construye la vista de selección de modo de juego.
  Widget _buildModeSelection() {
    final ac = AppColors.of(context);
    return ListView(
      children: [
        Row(
          children: [
            SizedBox(width: 32),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  color: ac.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  const TextSpan(text: "Comienza "),
                  TextSpan(
                    text: "una nueva partida",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,

                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        Row(
          children: [
            SizedBox(width: 32),
            Text(
              "Elige cómo quieres jugar:  ",
              style: TextStyle(fontSize: 14, color: ac.textSecondary),
            ),
            const Icon(
              Icons.favorite_border_outlined,
              color: AppColors.pink,
              size: 16,
            ),
          ],
        ),

        const SizedBox(height: 24),
        ...List.generate(_options.length, (index) {
          final opt = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PairOptionCard(
              title: opt['label'],
              subtitle: opt['desc'],
              image: opt['image'],
              accentColor: AppColors.pink,

              highlighted: selectedCard == opt["id"],
              onTap: () {
                setState(() {
                  selectedCard = opt["id"];
                });

                _onModeSelected(opt["id"]);
              },
            ),
          );
        }),
      ],
    );
  }

  // Construye el formulario correspondiente al modo seleccionado.
  Widget _buildModeForm() {
    switch (_mode) {
      case 'local':
        return _buildLocalForm();

      case 'join':
        return _buildJoinForm();
      case 'random':
      default:
        return const SizedBox();
    }
  }

  // Construye el formulario para jugar en el mismo teléfono.
  Widget _buildLocalForm() {
    final ac = AppColors.of(context);

    Color subtileBorder = AppColors.pink.withValues(alpha: .35);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ac.surface, ac.background],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _mode = null),
                    icon: Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: ac.textPrimary,
                    ),
                    label: Text(
                      "Volver",
                      style: TextStyle(color: ac.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),

                      children: [
                        TextSpan(
                          text: "Escriban sus ",
                          style: TextStyle(color: ac.textPrimary),
                        ),
                        const TextSpan(
                          text: "nombres",
                          style: TextStyle(color: AppColors.pink),
                        ),
                        const TextSpan(
                          text: " ♡",
                          style: TextStyle(
                            color: AppColors.pink,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildNameInputField(
                    controller: _player1Controller,
                    hint: "Nombre 1",
                    focusNode: _player1Focus,
                    //hintText: "Nombre del primer jugador",
                    borderColor: subtileBorder,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildNameInputField(
                    controller: _player2Controller,
                    hint: "Nombre 2",
                    focusNode: _player2Focus,
                    //hintText: "Nombre del primer jugador",
                    borderColor: subtileBorder,
                    icon: Icons.person_rounded,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AppButton(
                      onPressed: _handleLocalPlay,
                      icon: Icons.play_arrow,
                      text: "Continuar",
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

  // Construye un campo de entrada de nombre con animación de foco.
  Widget _buildNameInputField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color borderColor,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ac = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: ac.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focusNode.hasFocus ? AppColors.pink : ac.border,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: focusNode.hasFocus
                ? AppColors.pink.withValues(alpha: .35)
                : isLight
                ? const Color(0x08000000)
                : Colors.black.withValues(alpha: .20),
            blurRadius: focusNode.hasFocus ? 25 : 10,
            spreadRadius: focusNode.hasFocus ? 3 : 0,
          ),
        ],
      ),

      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              icon,
              key: ValueKey(focusNode.hasFocus),
              color: focusNode.hasFocus ? AppColors.pink : ac.textSecondary,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              selectionControls: materialTextSelectionControls,
              cursorColor: AppColors.pink,
              style: TextStyle(color: ac.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: ac.textMuted, fontSize: 18),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye el formulario para unirse a una sala con código.
  Widget _buildJoinForm() {
    final ac = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(color: ac.background),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _mode = null),
                      icon: Icon(Icons.arrow_back, color: ac.textPrimary),
                      label: Text(
                        "Volver",
                        style: TextStyle(color: ac.textPrimary),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(
                            text: "Ingresa el ",
                            style: TextStyle(color: ac.textPrimary),
                          ),
                          const TextSpan(
                            text: "código",
                            style: TextStyle(color: AppColors.pink),
                          ),
                          const TextSpan(
                            text: " ♡",
                            style: TextStyle(color: AppColors.pink),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Escribe el código que compartió tu pareja.",
                      style: TextStyle(color: ac.textSecondary, fontSize: 16),
                    ),

                    const SizedBox(height: 32),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ac.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ac.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key_rounded, color: AppColors.pink),

                          const SizedBox(width: 14),

                          Expanded(
                            child: TextField(
                              controller: _roomCodeController,
                              cursorColor: AppColors.pink,
                              style: TextStyle(
                                color: ac.textPrimary,
                                letterSpacing: 4,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: "ABC123",
                                hintStyle: TextStyle(
                                  color: ac.textMuted,
                                  letterSpacing: 4,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AppButton(
                        onPressed: _loading ? null : _handleJoinRoom,
                        icon: Icons.favorite,
                        text: _loading ? "Uniéndose..." : "Unirse",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
