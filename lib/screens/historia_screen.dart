import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovequiz_app/models/couple_models.dart';
import 'package:lovequiz_app/services/couple_data_service.dart';

const _pink = Color(0xFFFF2E93);
const _darkBg = Color(0xFF1A0914);
const _gold = Color(0xFFFFD700);
const _darkEnd = Color(0xFF0D0D0D);
const _purple = Color(0xFFB8439F);
const _cyan = Color(0xFF00D4FF);

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadCoupleProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupleProfile() async {
    final profile = await CoupleDataService.getCoupleProfile();
    if (mounted) {
      setState(() {
        _coupleProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _darkEnd,
        body: Center(child: CircularProgressIndicator(color: _pink)),
      );
    }

    if (_coupleProfile == null) {
      return _buildNoCoupleScreen();
    }

    return Scaffold(
      backgroundColor: _darkEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBg, _darkEnd],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildProfilesSection(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCoupleScreen() {
    return Scaffold(
      backgroundColor: _darkEnd,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBg, _darkEnd],
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
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Conecta con tu pareja para compartir recuerdos, promesas y momentos especiales',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Abrir diálogo para conectar pareja
                  },
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

  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [_pink, _gold],
              ).createShader(bounds),
              child: const Text(
                'Nuestra Historia',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: _pink,
              onPressed: () {
                // TODO: Configuración
              },
            ),
          ],
        ),
      ),
    );
  }

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
                      gradient: const LinearGradient(
                        colors: [_pink, _purple],
                      ),
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
                  Icon(
                    Icons.favorite,
                    color: _pink,
                    size: 28,
                  ),
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
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pink.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              'Comenzaron: ${DateFormat('d MMMM yyyy', 'es_ES').format(_coupleProfile!.startDate.toDate())}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String photo,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_pink, _purple],
            ),
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
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      'Recuerdos',
      'Frases',
      'Promesas',
      'Especiales',
      'Línea',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: _selectedTab == index,
              onSelected: (selected) {
                _tabController.animateTo(index);
              },
              label: Text(
                tabs[index],
                style: TextStyle(
                  color: _selectedTab == index ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: _pink,
              side: BorderSide(
                color: _selectedTab == index
                    ? _pink
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_coupleProfile == null) return const SizedBox();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMemoriesTab(),
        _buildPhrasesTab(),
        _buildPromisesTab(),
        _buildSpecialEventsTab(),
        _buildTimelineTab(),
      ],
    );
  }

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
          itemCount: memories.length,
          itemBuilder: (context, index) => _buildMemoryCard(memories[index]),
        );
      },
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pink.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (memory.photoUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: memory.photoUrls.length,
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      memory.photoUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: _pink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          memory.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade400,
                        onPressed: () => _deleteMemory(memory),
                      ),
                    ],
                  ),
                  if (memory.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      memory.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMM yyyy', 'es_ES')
                        .format(memory.createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 11,
                      color: _pink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          itemCount: phrases.length,
          itemBuilder: (context, index) => _buildPhraseCard(phrases[index]),
        );
      },
    );
  }

  Widget _buildPhraseCard(DefiningPhrase phrase) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _cyan.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '"${phrase.phrase}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _cyan,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 8),
            Text(
              'Sobre ${phrase.author}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

        final pending =
            promises.where((p) => !p.completed).toList();
        final completed =
            promises.where((p) => p.completed).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pending.isNotEmpty) ...[
                Text(
                  'Promesas Activas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                ...pending.map((p) => _buildPromiseCard(p)),
                const SizedBox(height: 24),
              ],
              if (completed.isNotEmpty) ...[
                Text(
                  'Promesas Cumplidas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.withValues(alpha: 0.8),
                  ),
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

  Widget _buildPromiseCard(Promise promise, {bool completed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: completed
                ? Colors.green.withValues(alpha: 0.3)
                : _pink.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: completed,
              onChanged: (_) => _togglePromise(promise),
              activeColor: Colors.green,
              side: BorderSide(
                color:
                    completed ? Colors.green : _pink.withValues(alpha: 0.5),
              ),
            ),
            Expanded(
              child: Text(
                promise.promise,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
                maxLines: 2,
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
      ),
    );
  }

  Widget _buildSpecialEventsTab() {
    return StreamBuilder<List<SpecialEvent>>(
      stream:
          CoupleDataService.specialEventsStream(_coupleProfile!.coupleId),
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
          itemCount: events.length,
          itemBuilder: (context, index) => _buildSpecialEventCard(events[index]),
        );
      },
    );
  }

  Widget _buildSpecialEventCard(SpecialEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _purple.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_pink, _purple],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            DateFormat('d MMMM yyyy', 'es_ES')
                                .format(event.eventDate.toDate()),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.white,
                    iconSize: 18,
                    onPressed: () => _deleteSpecialEvent(event),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                event.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_coupleProfile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineEvent(
            emoji: '💑',
            title: 'Empezaron',
            date: _coupleProfile!.startDate.toDate(),
            description:
                'El inicio de su hermosa historia de amor',
          ),
          _buildTimelineConnector(),
          StreamBuilder<List<Memory>>(
            stream: CoupleDataService.memoriesStream(_coupleProfile!.coupleId),
            builder: (context, snapshot) {
              final memories = snapshot.data ?? [];
              if (memories.isEmpty) {
                return Center(
                  child: Text(
                    'Agrega recuerdos para verlos en la línea del tiempo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Column(
                children: memories.asMap().entries.map((entry) {
                  final memory = entry.value;
                  final isLast = entry.key == memories.length - 1;
                  return Column(
                    children: [
                      _buildTimelineEvent(
                        emoji: '📸',
                        title: memory.title,
                        date: memory.createdAt.toDate(),
                        description: memory.description,
                      ),
                      if (!isLast) _buildTimelineConnector(),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent({
    required String emoji,
    required String title,
    required DateTime date,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_pink, _purple],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                DateFormat('d MMMM yyyy', 'es_ES').format(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 4, bottom: 8),
      child: Container(
        width: 2,
        height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_pink, _purple],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAdd,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: _pink.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Agregar'),
            style: FilledButton.styleFrom(
              backgroundColor: _pink,
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIÁLOGOS Y FUNCIONES ───────────────────────────────────────────────

  void _showAddMemoryDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<String> selectedPhotos = [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBg,
        title: const Text(
          'Agregar Recuerdo',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Título del recuerdo',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _pink),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descripción',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _pink),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Implementar carga de fotos con flutter_native_splash o similar
                  // final picker = ImagePicker();
                  // final images = await picker.pickMultiImage();
                },
                icon: const Icon(Icons.photo),
                label: const Text('Seleccionar fotos'),
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
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
    );
  }

  void _showAddPhraseDialog() {
    final phraseCtrl = TextEditingController();
    String selectedAuthor = _coupleProfile?.user1Name ?? 'Usuario';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBg,
        title: const Text(
          'Agregar Frase',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phraseCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe una frase que los defina',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedAuthor,
                dropdownColor: _darkBg,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sobre',
                  labelStyle: const TextStyle(color: _cyan),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
                items: [
                  _coupleProfile?.user1Name ?? 'Usuario',
                  _coupleProfile?.user2Name ?? 'Pareja',
                ]
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
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

  void _showAddPromiseDialog() {
    final promiseCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBg,
        title: const Text(
          'Hacer Promesa',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: promiseCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Escribe tu promesa...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

  void _showAddSpecialEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkBg,
        title: const Text(
          'Evento Especial',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Título',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: _purple),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Descripción',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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

  void _deleteMemory(Memory memory) {
    if (_coupleProfile != null) {
      CoupleDataService.deleteMemory(
        _coupleProfile!.coupleId,
        memory.id,
      );
    }
  }

  void _deletePhrase(DefiningPhrase phrase) {
    if (_coupleProfile != null) {
      CoupleDataService.deleteDefiningPhrase(
        _coupleProfile!.coupleId,
        phrase.id,
      );
    }
  }

  void _deletePromise(Promise promise) {
    if (_coupleProfile != null) {
      CoupleDataService.deletePromise(
        _coupleProfile!.coupleId,
        promise.id,
      );
    }
  }

  void _togglePromise(Promise promise) {
    if (_coupleProfile != null && !promise.completed) {
      CoupleDataService.completePromise(
        _coupleProfile!.coupleId,
        promise.id,
      );
    }
  }

  void _deleteSpecialEvent(SpecialEvent event) {
    if (_coupleProfile != null) {
      CoupleDataService.deleteSpecialEvent(
        _coupleProfile!.coupleId,
        event.id,
      );
    }
  }
}
