import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lovequiz_app/cards/pair_options_card.dart';
import 'package:lovequiz_app/models/user_model.dart';
import 'package:lovequiz_app/propertys/button_style.dart';
import 'package:lovequiz_app/services/user_services.dart';
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

  @override
  //Inicializa el estado del widget, asignando el modo inicial si se proporciona a través de los parámetros de la ruta. Esto permite que la pantalla de emparejamiento se configure automáticamente según la opción
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    loadUser();
    _player1Focus.addListener(_onFocusChange);
    _player2Focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  //Carga los datos del usuario actual desde Firebase Auth y Firestore.
  // Si el usuario está autenticado, obtiene su información de perfil y la almacena en el estado del widget para su uso posterior
  Future<void> loadUser() async {
    final name = FirebaseAuth.instance.currentUser;

    if (name == null) return;

    final data = await UserService.getUser(name.uid);

    if (!mounted) return;

    setState(() {
      user = data;
    });
  }

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
      context.push('/waiting?roomCode=$code&host=true');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al unirse: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleRandomMatch() async {
    if (_player1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa tu nombre")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: () => context.go('/Home'),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Emparejamiento",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

  Widget _buildModeSelection() {
    return ListView(
      children: [
        Row(
          children: [
            SizedBox(width: 32),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  const TextSpan(text: "Comienza "),
                  TextSpan(
                    text: "una nueva partida",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,

                      color: Color(0xFFE91E63),
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
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Icon(Icons.favorite_border_outlined, color: Colors.pink, size: 16),
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
              accentColor: const Color(0xffFF5C9D),

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

  Widget _buildLocalForm() {
    const Color cardBackground = Color(0xFF2E2933);

    Color subtileBorder = Colors.pinkAccent.withOpacity(.35);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF18111B), Color(0xFF0E0B10)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _mode = null),
            icon: const Icon(
              Icons.arrow_back,
              size: 18,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            label: const Text(
              "Volver",
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
          ),
          const SizedBox(height: 16),

          const Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),

              children: [
                TextSpan(
                  text: "Escriban sus ",
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: "nombres",
                  style: TextStyle(color: Color(0xFFFF5C95)),
                ),
                const TextSpan(
                  text: " ♡",
                  style: TextStyle(
                    color: Color(0xFFFF5C95),
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
            cardBackground: cardBackground,
            borderColor: subtileBorder,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          _buildNameInputField(
            controller: _player2Controller,
            hint: "Nombre 2",
            focusNode: _player2Focus,
            //hintText: "Nombre del primer jugador",
            cardBackground: cardBackground,
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
    );
  }

  Widget _buildNameInputField({
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color cardBackground,
    required Color borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focusNode.hasFocus ? Colors.pinkAccent : Colors.white24,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: focusNode.hasFocus
                ? Colors.pinkAccent.withOpacity(.35)
                : Colors.black.withOpacity(.20),
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
              color: focusNode.hasFocus ? Colors.pinkAccent : Colors.white54,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              selectionControls: materialTextSelectionControls,
              cursorColor: Colors.pinkAccent,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(.45),
                  fontSize: 18,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinForm() {
    const Color cardBackground = Color(0xFF2E2933);

    return Container(
      decoration: BoxDecoration(color: Color(0xFF0F0A0F)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _mode = null),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text(
                "Volver",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            const Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: "Ingresa el ",
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: "código",
                    style: TextStyle(color: Color(0xFFFF5C95)),
                  ),
                  TextSpan(
                    text: " ♡",
                    style: TextStyle(color: Color(0xFFFF5C95)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Escribe el código que compartió tu pareja.",
              style: TextStyle(
                color: Colors.white.withOpacity(.6),
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 32),

            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: Colors.pinkAccent),

                  const SizedBox(width: 14),

                  Expanded(
                    child: TextField(
                      controller: _roomCodeController,
                      cursorColor: Colors.pinkAccent,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 4,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: "ABC123",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(.35),
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
    );
  }
}
