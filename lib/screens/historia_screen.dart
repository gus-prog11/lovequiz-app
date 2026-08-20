import 'dart:io';
import 'dart:async';
import 'package:LoveQuiz/config/app_colors.dart';
import 'package:LoveQuiz/features/voice_memories/models/voice_memory.dart';
import 'package:LoveQuiz/features/voice_memories/repositories/voice_memory_repository.dart';
import 'package:LoveQuiz/models/couple_models.dart';
import 'package:LoveQuiz/models/emotional_model.dart';
import 'package:LoveQuiz/services/couple_data_service.dart';
import 'package:LoveQuiz/services/emotional_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:LoveQuiz/services/photo_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LoveQuiz/utils/app_toast.dart';

const _pink = AppColors.pink;
const _purple = AppColors.purple;
const _cyan = AppColors.cyan;

class HistoriaScreen extends StatefulWidget {
  const HistoriaScreen({super.key});

  @override
  State<HistoriaScreen> createState() => _HistoriaScreenState();
}

class _HistoriaScreenState extends State<HistoriaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CoupleProfile? _coupleProfile;
  bool _isLoading = true;
  int _selectedTab = 0;
  StreamSubscription<CoupleProfile?>? _coupleProfileSub;

  // Inicializa el controlador de pestañas y escucha el perfil de pareja.
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    // El stream mantiene el perfil actualizado en vivo (foto, nombre, etc.)
    // aunque la pestaña no se recree con el IndexedStack.
    _coupleProfileSub = CoupleDataService.coupleProfileStream().listen((
      profile,
    ) {
      if (!mounted) return;
      setState(() {
        _coupleProfile = profile;
        _isLoading = false;
      });
    }, onError: (Object e, StackTrace st) {
      debugPrint('[Historia] coupleProfileStream error: $e\n$st');
      if (!mounted) return;
      setState(() => _isLoading = false);
    });
  }

  // Libera el controlador de pestañas y la suscripción al perfil de pareja.
  @override
  void dispose() {
    _coupleProfileSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Muestra un modal para elegir entre generar o ingresar código de pareja.
  void _showConnectDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.favorite, color: _pink, size: 40),
            const SizedBox(height: 16),
            Text(
              'Conectar con tu pareja',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige cómo quieres enlazar',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _PinkButton(
                label: 'Generar código',
                icon: Icons.qr_code,
                onTap: () {
                  Navigator.pop(context);
                  _showGenerateCode();
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _PinkButton(
                label: 'Ingresar código',
                icon: Icons.edit,
                outlined: true,
                onTap: () {
                  Navigator.pop(context);
                  _showEnterCode();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Genera y muestra un código de enlace para compartir con la pareja.
  Future<void> _showGenerateCode() async {
    final code = await CoupleDataService.generateLinkCode();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tu código de enlace',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparte este código con tu pareja',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _pink.withValues(alpha: 0.3)),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Este código expira en 24 horas',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _PinkButton(
                label: 'Cerrar',
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Muestra un formulario para ingresar el código de enlace de la pareja.
  void _showEnterCode() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ingresa el código',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pide a tu pareja que te comparta su código',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppColors.of(context).textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'ABC123',
                hintStyle: TextStyle(
                  color: AppColors.of(context).textMuted,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: AppColors.of(context).surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _pink.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _pink),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _PinkButton(
                label: 'Conectar',
                onTap: () async {
                  final code = controller.text.trim().toUpperCase();
                  if (code.length != 6) {
                    AppToast.showError(context, 'El código debe tener 6 caracteres');
                    return;
                  }
                  Navigator.pop(context);
                  try {
                    final profile = await CoupleDataService.linkWithCode(code);
                    if (!mounted) return;
                    if (profile != null) {
                      setState(() => _coupleProfile = profile);
                      AppToast.showSuccess(context, '¡Pareja conectada!');
                    } else {
                      AppToast.showError(context, 'Código no válido o ya expiró');
                    }
                  } on CoupleAlreadyLinkedException catch (e) {
                    if (!mounted) return;
                    AppToast.showError(
                      context,
                      '${e.message}. Disuelve el enlace actual antes de '
                      'conectar',
                    );
                  } catch (e) {
                    debugPrint('[Historia] linkWithCode error: $e');
                    if (!mounted) return;
                    AppToast.showError(
                      context,
                      'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Descripción breve de lo que hace.
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.of(context).background,
        body: Center(child: CircularProgressIndicator(color: _pink)),
      );
    }

    if (_coupleProfile == null) {
      return _buildNoCoupleScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.of(context).surface,
              AppColors.of(context).background,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildVoiceMemoriesSection(),
            _buildProfilesSection(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  // Construye la pantalla cuando no hay pareja enlazada.
  Widget _buildNoCoupleScreen() {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.of(context).surface,
              AppColors.of(context).background,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: _pink.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Aún no tienes pareja enlazada',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Conecta con tu pareja para compartir recuerdos, promesas y momentos especiales',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.of(context).textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _showConnectDialog(),
                  icon: const Icon(Icons.link),
                  label: const Text('Conectar Pareja'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _pink,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
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

  // Construye el encabezado con el título de la historia.
  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nuestra Historia',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: _pink,
              onPressed: _showCoupleSettings,
            ),
          ],
        ),
      ),
    );
  }

  // Construye la sección destacada de Recuerdos de Voz: las voces grabadas
  // durante las partidas forman parte de la historia de la pareja.
  Widget _buildVoiceMemoriesSection() {
    final coupleId = _coupleProfile?.coupleId;
    if (coupleId == null || coupleId.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: StreamBuilder<List<VoiceMemory>>(
        stream: VoiceMemoryRepository.streamForCouple(coupleId),
        builder: (context, snapshot) {
          final count = snapshot.data?.length ?? 0;
          final subtitle = count > 0
              ? 'Tienen ${count == 1 ? '1 recuerdo de voz' : '$count recuerdos de voz'} guardados. '
                    'Escúchenlos antes de que expiren.'
              : 'Las voces que graban en sus partidas se guardan aquí. '
                    'Toca para descubrirlas.';
          return GestureDetector(
            onTap: () => context.push('/voice-memories'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_pink, AppColors.pinkGradientEnd],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.multitrack_audio_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recuerdos de voz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Construye la sección con los perfiles de ambos miembros de la pareja.
  Widget _buildProfilesSection() {
    if (_coupleProfile == null) return const SizedBox();

    final daysTogether = CoupleDataService.getDaysTogether(
      _coupleProfile!.startDate,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileCard(
                name: _coupleProfile!.user1Name,
                photo: _coupleProfile!.user1Photo,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_pink, _purple]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$daysTogether',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'días juntos',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.favorite, color: _pink, size: 28),
                ],
              ),
              _buildProfileCard(
                name: _coupleProfile!.user2Name,
                photo: _coupleProfile!.user2Photo,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.of(context).surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _pink.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              'Comenzaron: ${DateFormat('d MMMM yyyy', 'es_ES').format(_coupleProfile!.startDate.toDate())}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye una tarjeta de perfil circular con foto o inicial.
  Widget _buildProfileCard({required String name, required String photo}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [_pink, _purple]),
          ),
          child: photo.isEmpty
              ? Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CachedNetworkImage(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    );
  }

  // Construye la barra de pestañas con píldoras animadas: la pestaña activa
  // se resalta con una píldora de degradado que cambia suavemente.
  Widget _buildTabBar() {
    final tabs = [
      'Recuerdos',
      'Favoritas',
      'Frases',
      'Promesas',
      'Especiales',
      'Diario',
      'Línea',
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final selected = _selectedTab == index;
          return GestureDetector(
            onTap: () => _tabController.animateTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [_pink, _purple])
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _pink.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.of(context).textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Construye el contenido de las pestañas con sus respectivos widgets.
  Widget _buildTabContent() {
    if (_coupleProfile == null) return const SizedBox();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMemoriesTab(),
        _buildFavoritesTab(),
        _buildPhrasesTab(),
        _buildPromisesTab(),
        _buildSpecialEventsTab(),
        _buildDailyAnswersTab(),
        _buildTimelineTab(),
      ],
    );
  }

  // Construye la pestaña de recuerdos con lista o estado vacío.
  Widget _buildMemoriesTab() {
    return StreamBuilder<List<Memory>>(
      stream: CoupleDataService.memoriesStream(_coupleProfile!.coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final memories = snapshot.data ?? [];

        if (memories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Sin recuerdos aún',
            subtitle: 'Comparte fotos y momentos especiales',
            onAdd: _showAddMemoryDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: memories.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PinkButton(
                  label: 'Agregar recuerdo',
                  icon: Icons.add_a_photo_rounded,
                  onTap: _showAddMemoryDialog,
                ),
              );
            }

            return _buildMemoryCard(memories[index - 1]);
          },
        );
      },
    );
  }

  // Construye la pestaña de respuestas favoritas guardadas.
  Widget _buildFavoritesTab() {
    final coupleId = _coupleProfile?.coupleId ?? '';
    if (coupleId.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Sin respuestas favoritas',
        subtitle: 'Guarda respuestas especiales durante el juego',
      );
    }

    return StreamBuilder<List<FavoriteAnswer>>(
      stream: EmotionalService.favoriteAnswersStream(coupleId).map(
        (snap) => snap.docs
            .map(
              (doc) =>
                  FavoriteAnswer.fromMap(doc.data() as Map<String, dynamic>),
            )
            .toList(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'Sin respuestas favoritas',
            subtitle: 'Guarda respuestas especiales durante el juego',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) => _buildFavoriteCard(favorites[index]),
        );
      },
    );
  }

  // Construye una tarjeta para una respuesta favorita.
  Widget _buildFavoriteCard(FavoriteAnswer answer) {
    final ac = AppColors.of(context);
    final profile = _coupleProfile;
    final partnerName = FirebaseAuth.instance.currentUser?.uid == profile?.user1Id
        ? profile?.user2Name
        : profile?.user1Name;
    return _GradientCard(
      accent: _pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardIcon(icon: Icons.favorite_rounded, color: _pink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.question.replaceAll('{partner}', partnerName ?? 'tu pareja'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ac.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${answer.answer}"',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          answer.partnerName ?? 'Anónimo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _pink.withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(answer.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: ac.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construye la pestaña de las respuestas a la Pregunta del día. Cada día
  // guardado muestra la pregunta y las respuestas de ambos miembros de la
  // pareja (las disponibles hasta el momento).
  Widget _buildDailyAnswersTab() {
    final coupleId = _coupleProfile?.coupleId ?? '';
    if (coupleId.isEmpty) {
      return _buildEmptyState(
        icon: Icons.wb_sunny_outlined,
        title: 'Sin preguntas del día',
        subtitle: 'Responde la pregunta diaria desde el inicio y se guardará aquí',
      );
    }

    return StreamBuilder<List<DailyAnswer>>(
      stream: CoupleDataService.dailyAnswersStream(coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final answers = snapshot.data ?? [];

        if (answers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.wb_sunny_outlined,
            title: 'Sin preguntas del día',
            subtitle: 'Responde la pregunta diaria desde el inicio y se guardará aquí',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: answers.length,
          itemBuilder: (context, index) => _buildDailyAnswerCard(answers[index]),
        );
      },
    );
  }

  // Construye una tarjeta con la pregunta del día y las respuestas guardadas.
  Widget _buildDailyAnswerCard(DailyAnswer answer) {
    final ac = AppColors.of(context);
    final profile = _coupleProfile;
    final myName = FirebaseAuth.instance.currentUser?.uid == profile?.user1Id
        ? profile?.user1Name
        : profile?.user2Name;
    final partnerName = FirebaseAuth.instance.currentUser?.uid == profile?.user1Id
        ? profile?.user2Name
        : profile?.user1Name;

    return _GradientCard(
      accent: _pink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CardIcon(icon: Icons.wb_sunny_outlined, color: _pink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  answer.question.replaceAll('{partner}', partnerName ?? 'tu pareja'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: ac.surface,
                icon: Icon(Icons.more_vert, color: ac.textMuted, size: 18),
                onSelected: (value) {
                  if (value == 'delete') _deleteDailyAnswer(answer);
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAnswerLine(name: myName, answer: answer.answer1),
          const SizedBox(height: 8),
          _buildAnswerLine(name: partnerName, answer: answer.answer2),
          const SizedBox(height: 12),
          Text(
            _formatDate(answer.updatedAt),
            style: TextStyle(fontSize: 11, color: ac.textMuted),
          ),
        ],
      ),
    );
  }

  // Fila con el nombre de quien respondió y su respuesta (o un estado vacío).
  Widget _buildAnswerLine({required String? name, required String? answer}) {
    final ac = AppColors.of(context);
    if (answer == null || answer.trim().isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${name ?? 'Pareja'}: ',
            style: TextStyle(fontSize: 13, color: _pink.withValues(alpha: 0.8)),
          ),
          Expanded(
            child: Text(
              'Aún sin responder',
              style: TextStyle(
                fontSize: 13,
                color: ac.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${name ?? 'Pareja'}: ',
          style: TextStyle(fontSize: 13, color: _pink.withValues(alpha: 0.8)),
        ),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: ac.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Construye una tarjeta de recuerdo con foto de portada deslizable,
  // badge de cantidad y detalles (título, descripción y fecha).
  Widget _buildMemoryCard(Memory memory) {
    return _MemoryCard(
      memory: memory,
      onDelete: () => _deleteMemory(memory),
      onViewPhotos: (initialIndex) =>
          _showPhotoViewer(memory.photoUrls, initialIndex),
    );
  }

  // Abre un visor a pantalla completa para ver la imagen completa.
  void _showPhotoViewer(List<String> photoUrls, int initialIndex) {
    final pageNotifier = ValueNotifier<int>(initialIndex);
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: photoUrls.length,
                onPageChanged: (i) => pageNotifier.value = i,
                itemBuilder: (context, index) => InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[index],
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: _pink,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            if (photoUrls.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: pageNotifier,
                    builder: (context, page, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${page + 1}/${photoUrls.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Construye la pestaña de frases que definen a la pareja.
  Widget _buildPhrasesTab() {
    return StreamBuilder<List<DefiningPhrase>>(
      stream: CoupleDataService.definingPhrasesStream(_coupleProfile!.coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final phrases = snapshot.data ?? [];

        if (phrases.isEmpty) {
          return _buildEmptyState(
            icon: Icons.format_quote,
            title: 'Sin frases aún',
            subtitle: 'Comparte frases que los definan como pareja',
            onAdd: _showAddPhraseDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: phrases.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PinkButton(
                  label: 'Agregar frase',
                  icon: Icons.format_quote,
                  onTap: _showAddPhraseDialog,
                ),
              );
            }
            return _buildPhraseCard(phrases[index - 1]);
          },
        );
      },
    );
  }

  // Construye una tarjeta para una frase definitoria.
  Widget _buildPhraseCard(DefiningPhrase phrase) {
    final ac = AppColors.of(context);
    return _GradientCard(
      accent: _cyan,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardIcon(icon: Icons.format_quote_rounded, color: _cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${phrase.phrase}"',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _cyan,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 13,
                      color: ac.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Sobre ${phrase.author}',
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade400,
            iconSize: 20,
            onPressed: () => _deletePhrase(phrase),
          ),
        ],
      ),
    );
  }

  // Encabezado de sección con icono en círculo y título.
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        _CardIcon(icon: icon, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    );
  }

  // Construye la pestaña de promesas activas y cumplidas.
  Widget _buildPromisesTab() {
    return StreamBuilder<List<Promise>>(
      stream: CoupleDataService.promisesStream(_coupleProfile!.coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final promises = snapshot.data ?? [];

        if (promises.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_outline,
            title: 'Sin promesas aún',
            subtitle: 'Creen promesas mutuamente para fortalecer su vínculo',
            onAdd: _showAddPromiseDialog,
          );
        }

        final pending = promises.where((p) => !p.completed).toList();
        final completed = promises.where((p) => p.completed).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PinkButton(
                  label: 'Hacer promesa',
                  icon: Icons.favorite_outline,
                  onTap: _showAddPromiseDialog,
                ),
              ),
              if (pending.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Promesas Activas',
                  icon: Icons.favorite_rounded,
                  color: _pink,
                ),
                const SizedBox(height: 12),
                ...pending.map((p) => _buildPromiseCard(p)),
                const SizedBox(height: 24),
              ],
              if (completed.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Promesas Cumplidas',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                ...completed.map((p) => _buildPromiseCard(p, completed: true)),
              ],
            ],
          ),
        );
      },
    );
  }

  // Construye una tarjeta de promesa con checkbox de cumplimiento.
  Widget _buildPromiseCard(Promise promise, {bool completed = false}) {
    final accent = completed ? Colors.green : _pink;
    return _GradientCard(
      accent: accent,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _togglePromise(promise),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: accent.withValues(alpha: completed ? 0.6 : 0.4),
                ),
              ),
              child: completed
                  ? const Icon(Icons.check_rounded, color: Colors.green, size: 20)
                  : Icon(Icons.favorite_rounded, color: _pink, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              promise.promise,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: completed
                    ? AppColors.of(context).textMuted
                    : AppColors.of(context).textPrimary,
                decoration: completed ? TextDecoration.lineThrough : null,
                decorationColor: Colors.green,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade400,
            iconSize: 18,
            onPressed: () => _deletePromise(promise),
          ),
        ],
      ),
    );
  }

  // Construye la pestaña de eventos especiales registrados.
  Widget _buildSpecialEventsTab() {
    return StreamBuilder<List<SpecialEvent>>(
      stream: CoupleDataService.specialEventsStream(_coupleProfile!.coupleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.celebration_outlined,
            title: 'Sin eventos especiales',
            subtitle: 'Registren momentos especiales y emocionantes',
            onAdd: _showAddSpecialEventDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PinkButton(
                  label: 'Agregar evento',
                  icon: Icons.celebration_outlined,
                  onTap: _showAddSpecialEventDialog,
                ),
              );
            }
            return _buildSpecialEventCard(events[index - 1]);
          },
        );
      },
    );
  }

  // Construye una tarjeta de evento especial con emoji y descripción.
  Widget _buildSpecialEventCard(SpecialEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.of(context).surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_pink, _purple],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      event.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'd MMMM yyyy',
                              'es_ES',
                            ).format(event.eventDate.toDate()),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.white,
                  iconSize: 20,
                  onPressed: () => _deleteSpecialEvent(event),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              event.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.of(context).textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Construye la pestaña de línea del tiempo con eventos cronológicos.
  Widget _buildTimelineTab() {
    if (_coupleProfile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineEvent(
            emoji: '💑',
            title: 'Empezaron',
            date: _coupleProfile!.startDate.toDate(),
            description: 'El inicio de su hermosa historia de amor',
            isSpecial: true,
          ),
          StreamBuilder<List<Memory>>(
            stream: CoupleDataService.memoriesStream(_coupleProfile!.coupleId),
            builder: (context, snapshot) {
              final memories = snapshot.data ?? [];
              if (memories.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Agrega recuerdos para verlos en la línea del tiempo',
                    style: TextStyle(
                      color: AppColors.of(context).textMuted,
                      fontSize: 12,
                    ),
                  ),
                );
              }
              // En una línea del tiempo los recuerdos van de más antiguo a
              // más nuevo (el stream los entrega del más reciente al primero).
              final chronological = memories.reversed.toList();
              return Column(
                children: chronological.asMap().entries.map((entry) {
                  final memory = entry.value;
                  final isLast = entry.key == chronological.length - 1;
                  return _buildTimelineEvent(
                    emoji: '📸',
                    title: memory.title,
                    date: memory.createdAt.toDate(),
                    description: memory.description,
                    memory: memory,
                    isLast: isLast,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Construye un evento de la línea del tiempo: nodo con degradado y anillo
  // de luz, línea conectora punteada y tarjeta con píldora de fecha, título,
  // descripción y foto destacada opcional.
  Widget _buildTimelineEvent({
    required String emoji,
    required String title,
    required DateTime date,
    required String description,
    Memory? memory,
    bool isSpecial = false,
    bool isLast = false,
  }) {
    final dateLabel = DateFormat('d MMMM yyyy', 'es_ES').format(date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                _TimelineNode(emoji: emoji, isSpecial: isSpecial),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: _pink.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: isSpecial
                  ? _buildSpecialStartCard(
                      emoji: emoji,
                      title: title,
                      dateLabel: dateLabel,
                      description: description,
                    )
                  : _buildTimelineCard(
                      title: title,
                      dateLabel: dateLabel,
                      description: description,
                      memory: memory,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta destacada para el inicio de la historia con gradiente de fondo.
  Widget _buildSpecialStartCard({
    required String emoji,
    required String title,
    required String dateLabel,
    required String description,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink, _purple],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta regular de evento con foto destacada, píldora de fecha y texto.
  Widget _buildTimelineCard({
    required String title,
    required String dateLabel,
    required String description,
    Memory? memory,
  }) {
    final ac = AppColors.of(context);
    final photos = memory?.photoUrls ?? const <String>[];
    final hasPhoto = photos.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink.withValues(alpha: 0.06), ac.surfaceAlt],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pink.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhoto)
            GestureDetector(
              onTap: () => _showPhotoViewer(photos, 0),
              child: Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: photos.first,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: _pink,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            photos.length > 1
                                ? '${photos.length} fotos'
                                : 'Ver foto',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: _pink,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _pink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ac.textSecondary,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construye un estado vacío con icono, título y botón de agregar.
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAdd,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _pink.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: FilledButton.styleFrom(backgroundColor: _pink),
            ),
          ],
        ],
      ),
    );
  }

  // ─── DIÁLOGOS Y FUNCIONES ───────────────────────────────────────────────

  // Muestra un diálogo para agregar un nuevo recuerdo.
  void _showAddMemoryDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<String> selectedPhotos = [];
    List<String> selectedLocalPaths = [];
    bool uploading = false;
    const int maxPhotos = 20;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          'Agregar Recuerdo',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Título del recuerdo',
                    hintStyle: TextStyle(
                      color: AppColors.of(context).textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: _pink),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Descripción',
                    hintStyle: TextStyle(
                      color: AppColors.of(context).textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: _pink),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${selectedLocalPaths.length}/$maxPhotos imágenes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                    if (uploading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        selectedLocalPaths.length >= maxPhotos || uploading
                        ? null
                        : () async {
                            final remaining =
                                maxPhotos - selectedLocalPaths.length;
                            final picker = ImagePicker();
                            final picked = await picker.pickMultiImage(
                              limit: remaining,
                              imageQuality: 85,
                              maxHeight: 1024,
                              maxWidth: 1024,
                            );
                            if (picked.isEmpty) return;
                            final accepted = picked.take(remaining).toList();
                            setDialogState(() {
                              selectedLocalPaths.addAll(
                                accepted.map((p) => p.path),
                              );
                              uploading = true;
                            });
                            for (final image in accepted) {
                              try {
                                final result =
                                    await PhotoService.uploadImageFile(
                                      File(image.path),
                                    );
                                if (result != null && context.mounted) {
                                  setDialogState(
                                    () => selectedPhotos.add(result.url),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setDialogState(
                                    () => selectedLocalPaths.remove(image.path),
                                  );
                                  AppToast.showError(context, 'No se pudo subir una foto');
                                }
                              }
                            }
                            if (context.mounted) {
                              setDialogState(() => uploading = false);
                            }
                          },
                    icon: const Icon(Icons.photo),
                    label: Text(
                      selectedLocalPaths.length >= maxPhotos
                          ? 'Límite alcanzado'
                          : 'Seleccionar fotos',
                    ),
                    style: FilledButton.styleFrom(backgroundColor: _pink),
                  ),
                ),
                if (selectedLocalPaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final path in selectedLocalPaths)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: uploading
                          ? null
                          : () {
                              if (titleCtrl.text.isNotEmpty &&
                                  _coupleProfile != null) {
                                CoupleDataService.addMemory(
                                  coupleId: _coupleProfile!.coupleId,
                                  title: titleCtrl.text,
                                  description: descCtrl.text,
                                  photoUrls: selectedPhotos,
                                );
                                Navigator.pop(context);
                              }
                            },
                      style: FilledButton.styleFrom(backgroundColor: _pink),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Muestra un diálogo para agregar una frase definitoria.
  void _showAddPhraseDialog() {
    final phraseCtrl = TextEditingController();
    String selectedAuthor = _coupleProfile?.user1Name ?? 'Usuario';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          'Agregar Frase',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phraseCtrl,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe una frase que los defina',
                  hintStyle: TextStyle(color: AppColors.of(context).textMuted),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAuthor,
                dropdownColor: AppColors.of(context).surface,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  labelText: 'Sobre',
                  labelStyle: const TextStyle(color: _cyan),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
                items:
                    [
                          _coupleProfile?.user1Name ?? 'Usuario',
                          _coupleProfile?.user2Name ?? 'Pareja',
                        ]
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                onChanged: (value) => selectedAuthor = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (phraseCtrl.text.isNotEmpty && _coupleProfile != null) {
                CoupleDataService.addDefiningPhrase(
                  _coupleProfile!.coupleId,
                  phraseCtrl.text,
                  selectedAuthor,
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _cyan),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Muestra un diálogo para hacer una nueva promesa.
  void _showAddPromiseDialog() {
    final promiseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          'Hacer Promesa',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: TextField(
          controller: promiseCtrl,
          style: TextStyle(color: AppColors.of(context).textPrimary),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe tu promesa...',
            hintStyle: TextStyle(color: AppColors.of(context).textMuted),
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: _pink),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (promiseCtrl.text.isNotEmpty && _coupleProfile != null) {
                CoupleDataService.addPromise(
                  _coupleProfile!.coupleId,
                  promiseCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _pink),
            child: const Text('Prometer'),
          ),
        ],
      ),
    );
  }

  // Muestra un diálogo para registrar un evento especial.
  void _showAddSpecialEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          'Evento Especial',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  hintText: 'Título',
                  hintStyle: TextStyle(color: AppColors.of(context).textMuted),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _purple),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descripción',
                  hintStyle: TextStyle(color: AppColors.of(context).textMuted),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _purple),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && _coupleProfile != null) {
                CoupleDataService.addSpecialEvent(
                  coupleId: _coupleProfile!.coupleId,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  eventDate: selectedDate,
                  emoji: '💕',
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _purple),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Muestra una advertencia antes de borrar contenido y ejecuta la acción
  // solo si el usuario confirma.
  Future<void> _confirmDelete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final ac = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: ac.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: ac.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) onConfirm();
  }

  // Elimina un recuerdo de la pareja.
  void _deleteMemory(Memory memory) {
    _confirmDelete(
      title: '¿Eliminar recuerdo?',
      message:
          'Este recuerdo se borrará para ambos. Esta acción no se puede deshacer.',
      onConfirm: () {
        if (_coupleProfile != null) {
          CoupleDataService.deleteMemory(_coupleProfile!.coupleId, memory.id);
        }
      },
    );
  }

  // Elimina una frase definitoria de la pareja.
  void _deletePhrase(DefiningPhrase phrase) {
    _confirmDelete(
      title: '¿Eliminar frase?',
      message:
          'Esta frase se borrará para ambos. Esta acción no se puede deshacer.',
      onConfirm: () {
        if (_coupleProfile != null) {
          CoupleDataService.deleteDefiningPhrase(
            _coupleProfile!.coupleId,
            phrase.id,
          );
        }
      },
    );
  }

  // Elimina una promesa de la pareja.
  void _deletePromise(Promise promise) {
    _confirmDelete(
      title: '¿Eliminar promesa?',
      message:
          'Esta promesa se borrará para ambos. Esta acción no se puede deshacer.',
      onConfirm: () {
        if (_coupleProfile != null) {
          CoupleDataService.deletePromise(_coupleProfile!.coupleId, promise.id);
        }
      },
    );
  }

  // Marca una promesa como cumplida.
  void _togglePromise(Promise promise) {
    if (_coupleProfile != null && !promise.completed) {
      CoupleDataService.completePromise(_coupleProfile!.coupleId, promise.id);
    }
  }

  // Elimina un evento especial de la pareja.
  void _deleteSpecialEvent(SpecialEvent event) {
    _confirmDelete(
      title: '¿Eliminar evento?',
      message:
          'Este evento se borrará para ambos. Esta acción no se puede deshacer.',
      onConfirm: () {
        if (_coupleProfile != null) {
          CoupleDataService.deleteSpecialEvent(
            _coupleProfile!.coupleId,
            event.id,
          );
        }
      },
    );
  }

  // Elimina la respuesta a la pregunta del día de una fecha concreta.
  void _deleteDailyAnswer(DailyAnswer answer) {
    _confirmDelete(
      title: '¿Eliminar respuesta?',
      message:
          'Se eliminará la pregunta y sus respuestas de ese día. Esta acción no se puede deshacer.',
      onConfirm: () {
        if (_coupleProfile != null) {
          CoupleDataService.deleteDailyAnswer(
            _coupleProfile!.coupleId,
            answer.dateKey,
          );
        }
      },
    );
  }

  // Muestra la pantalla de configuración de la pareja.
  void _showCoupleSettings() {
    if (_coupleProfile == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Configuración de pareja',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.of(context).surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.of(context).textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disolver enlace',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Se eliminarán todos los datos compartidos',
                          style: TextStyle(
                            color: AppColors.of(context).textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDissolve();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Disolver enlace',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Muestra confirmación antes de disolver el enlace.
  void _confirmDissolve() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              '¿Disolver enlace?',
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Se eliminarán todos los recuerdos, frases, promesas y eventos especiales compartidos con ${_coupleProfile!.user2Name}. Esta acción no se puede deshacer.',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.of(context).textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _dissolveCouple();
            },
            child: const Text(
              'Disolver',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ejecuta la disolución del enlace de pareja.
  Future<void> _dissolveCouple() async {
    if (_coupleProfile == null) return;

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final partnerId = _coupleProfile!.user1Id == myUid
        ? _coupleProfile!.user2Id
        : _coupleProfile!.user1Id;

    try {
      await CoupleDataService.dissolveCouple(
        _coupleProfile!.coupleId,
        partnerId,
      );

      if (!mounted) return;

      setState(() => _coupleProfile = null);

      AppToast.showInfo(context, 'Enlace de pareja disuelto');
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Error: $e');
    }
  }

  // Formatea un timestamp como día/mes/año.
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Tarjeta base con gradiente sutil, sombra suave y borde de acento.
class _GradientCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;

  const _GradientCard({
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final ac = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.07),
            ac.surfaceAlt,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Icono dentro de un círculo suave con color de acento.
class _CardIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _CardIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

// Nodo circular con degradado, anillo de luz y emoji.
class _TimelineNode extends StatelessWidget {
  final String emoji;
  final bool isSpecial;

  const _TimelineNode({required this.emoji, this.isSpecial = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: isSpecial ? 0.45 : 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _pink.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_pink, _purple],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

// Línea punteada vertical conectora entre eventos.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dashWidth = 6.0;
    const dashSpace = 5.0;
    final cx = size.width / 2;
    var y = 0.0;
    while (y < size.height) {
      final end = (y + dashWidth).clamp(0.0, size.height);
      canvas.drawLine(Offset(cx, y), Offset(cx, end), paint);
      y += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

class _PinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined;

  const _PinkButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  // Construye un botón rosa con o sin borde y opcionalmente con icono.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : _pink,
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(color: _pink.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tarjeta de recuerdo con foto de portada deslizable, puntos de página,
// badge de cantidad y sección de detalles (título, descripción y fecha).
class _MemoryCard extends StatefulWidget {
  const _MemoryCard({
    required this.memory,
    required this.onDelete,
    required this.onViewPhotos,
  });

  final Memory memory;
  final VoidCallback onDelete;
  final void Function(int initialIndex) onViewPhotos;

  @override
  State<_MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<_MemoryCard> {
  final PageController _pageController = PageController();
  int _currentPhoto = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final hasPhotos = memory.photoUrls.isNotEmpty;
    final photoCount = memory.photoUrls.length;

    return GestureDetector(
      onTap: hasPhotos ? () => widget.onViewPhotos(_currentPhoto) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.of(context).surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pink.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPhotos)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: photoCount,
                      onPageChanged: (i) => setState(() => _currentPhoto = i),
                      itemBuilder: (context, index) => CachedNetworkImage(
                        imageUrl: memory.photoUrls[index],
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.black,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: _pink,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white70,
                              size: 56,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Sin fotos aún',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (memory.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            memory.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBadge(
                              context,
                              icon: Icons.calendar_today_rounded,
                              label: DateFormat(
                                'd MMM yyyy',
                                'es_ES',
                              ).format(memory.createdAt.toDate()),
                            ),
                            if (photoCount > 1) ...[
                              const SizedBox(width: 10),
                              _buildBadge(
                                context,
                                icon: Icons.photo_library_outlined,
                                label: '$photoCount fotos',
                              ),
                            ],
                          ],
                        ),
                        if (hasPhotos) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.remove_red_eye,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Ver fotos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      child: IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.white,
                        tooltip: 'Eliminar recuerdo',
                      ),
                    ),
                  ),
                  if (hasPhotos)
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Row(
                        children: List.generate(photoCount, (i) {
                          final active = i == _currentPhoto;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 5),
                            width: active ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? Colors.white : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            if (!hasPhotos) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (memory.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        memory.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.of(context).textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildBadge(
                          context,
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat(
                            'd MMM yyyy',
                            'es_ES',
                          ).format(memory.createdAt.toDate()),
                        ),
                        if (photoCount > 1) ...[
                          const SizedBox(width: 10),
                          _buildBadge(
                            context,
                            icon: Icons.photo_library_outlined,
                            label: '$photoCount fotos',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
