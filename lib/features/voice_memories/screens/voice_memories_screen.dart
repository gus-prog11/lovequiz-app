import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../voice_memories/repositories/voice_memory_repository.dart';
import '../../voice_memories/widgets/voice_memory_card.dart';
import '../../../config/app_colors.dart';
import '../../../services/user_services.dart';

const Color _pink = AppColors.pink;

class VoiceMemoriesScreen extends StatefulWidget {
  const VoiceMemoriesScreen({super.key});

  @override
  State<VoiceMemoriesScreen> createState() => _VoiceMemoriesScreenState();
}

class _VoiceMemoriesScreenState extends State<VoiceMemoriesScreen> {
  String? _coupleId;
  String? _userId;
  bool _loadingIds = true;

  @override
  void initState() {
    super.initState();
    _loadIds();
  }

  Future<void> _loadIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingIds = false);
      return;
    }
    _userId = uid;
    final user = await UserService.getUser(uid);
    if (!mounted) return;
    setState(() {
      _coupleId = user?.coupleId;
      _loadingIds = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuerdos de Voz'),
        centerTitle: true,
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(AppColors colors) {
    if (_loadingIds) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }

    if (_coupleId == null || _coupleId!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, color: _pink.withValues(alpha: 0.4), size: 64),
              const SizedBox(height: 16),
              Text(
                'Conecta con tu pareja para empezar a crear recuerdos de voz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_userId == null) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }

    return StreamBuilder(
      stream: VoiceMemoryRepository.streamForCouple(_coupleId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: colors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudieron cargar los recuerdos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: Text('Reintentar', style: TextStyle(color: _pink)),
                  ),
                ],
              ),
            ),
          );
        }

        final memories = snapshot.data ?? [];

        if (memories.isEmpty) {
          return _buildEmptyState(colors);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          itemCount: memories.length,
          itemBuilder: (context, index) {
            return VoiceMemoryCard(
              memory: memories[index],
              currentUserId: _userId!,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, color: _pink.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            Text(
              'Aún no tienen recuerdos de voz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Durante algunas partidas aparecerán preguntas especiales donde podrán grabar mensajes para conservar durante 7 días. Si ambos no los guardan, se eliminarán al expirar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
