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
  String? _mode;
  final TextEditingController _player1Controller = TextEditingController();
  final TextEditingController _player2Controller = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  bool _loading = false;

  final List<Map<String, dynamic>> _options = [
    {
      "id": "local",
      "icon": Icons.smartphone,
      "label": "Mismo teléfono",
      "desc": "Jueguen juntos en un dispositivo",
      "emoji": "📱",
    },
    {
      "id": "create",
      "icon": Icons.add_circle_outline,
      "label": "Crear sala",
      "desc": "Crea una sala e invita a tu pareja",
      "emoji": "🏠",
    },
    {
      "id": "join",
      "icon": Icons.login,
      "label": "Unirse a sala",
      "desc": "Ingresa el código de tu pareja",
      "emoji": "🔗",
    },
    {
      "id": "random",
      "icon": Icons.shuffle,
      "label": "Aleatorio",
      "desc": "Conecta con alguien al azar",
      "emoji": "🎲",
    },
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  void _handleLocalPlay() {
    if (_player1Controller.text.trim().isEmpty ||
        _player2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa los nombres de ambos jugadores")),
      );
      return;
    }
    context.push(
      '/setup?mode=local&p1=${Uri.encodeComponent(_player1Controller.text)}&p2=${Uri.encodeComponent(_player2Controller.text)}',
    );
  }

  Future<void> _handleCreateRoom() async {
    if (_player1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa tu nombre")));
      return;
    }
    setState(() => _loading = true);
    try {
      final code = await FirestoreService.createRoom(
        _player1Controller.text.trim(),
      );
      if (!mounted) return;
      context.push(
        '/waiting?roomCode=$code&name=${Uri.encodeComponent(_player1Controller.text)}&host=true',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear sala: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleJoinRoom() async {
    if (_player2Controller.text.trim().isEmpty ||
        _roomCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresa tu nombre y el código de la sala"),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final code = _roomCodeController.text.trim().toUpperCase();
      final joined = await FirestoreService.joinRoom(
        code,
        _player2Controller.text.trim(),
      );
      if (!mounted) return;
      if (!joined) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sala no encontrada o ya está llena"),
          ),
        );
        return;
      }
      context.push(
        '/waiting?roomCode=$code&name=${Uri.encodeComponent(_player2Controller.text)}&host=false',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al unirse: $e")),
      );
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
      final existingRoom = await FirestoreService.findRandomRoom(name);
      if (!mounted) return;
      if (existingRoom != null) {
        final joined = await FirestoreService.joinRoom(existingRoom, name);
        if (!mounted) return;
        if (joined) {
          context.push(
            '/waiting?roomCode=$existingRoom&name=${Uri.encodeComponent(name)}&host=false&random=true',
          );
          return;
        }
      }
      final code = await FirestoreService.createRoom(name, isRandom: true);
      if (!mounted) return;
      context.push(
        '/waiting?roomCode=$code&name=${Uri.encodeComponent(name)}&host=true&random=true',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
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
        Text(
          "¿Cómo quieren jugar? 💕",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_options.length, (index) {
          final opt = _options[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => setState(() => _mode = opt['id']),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(opt['emoji'], style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['label'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              opt['desc'],
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
                        opt['icon'],
                        size: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
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
      case 'create':
        return _buildCreateForm();
      case 'join':
        return _buildJoinForm();
      case 'random':
        return _buildRandomForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLocalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _mode = null),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text("Volver"),
        ),
        const SizedBox(height: 16),
        const Text(
          "Ingresa los nombres de los jugadores",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _player1Controller,
          decoration: InputDecoration(
            labelText: "Jugador 1",
            hintText: "Nombre del primer jugador",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _player2Controller,
          decoration: InputDecoration(
            labelText: "Jugador 2",
            hintText: "Nombre del segundo jugador",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _handleLocalPlay,
            icon: const Icon(Icons.play_arrow),
            label: const Text(
              "Continuar",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _mode = null),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text("Volver"),
        ),
        const SizedBox(height: 16),
        const Text(
          "Crear una sala",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Comparte el código con tu pareja",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _player1Controller,
          decoration: InputDecoration(
            labelText: "Tu nombre",
            hintText: "Ingresa tu nombre",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _loading ? null : _handleCreateRoom,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text(
              "Crear Sala",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _mode = null),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text("Volver"),
        ),
        const SizedBox(height: 16),
        const Text(
          "Unirse a una sala",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _player2Controller,
          decoration: InputDecoration(
            labelText: "Tu nombre",
            hintText: "Ingresa tu nombre",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _roomCodeController,
          decoration: InputDecoration(
            labelText: "Código de la sala",
            hintText: "Ej: ABC123",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.key),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _loading ? null : _handleJoinRoom,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: const Text(
              "Unirse",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandomForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _mode = null),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text("Volver"),
        ),
        const SizedBox(height: 16),
        const Text(
          "Emparejamiento aleatorio",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Conecta con alguien al azar",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _player1Controller,
          decoration: InputDecoration(
            labelText: "Tu nombre",
            hintText: "Ingresa tu nombre",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _loading ? null : _handleRandomMatch,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shuffle),
            label: const Text(
              "Buscar partida",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
