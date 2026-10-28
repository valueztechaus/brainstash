import 'package:flutter/material.dart';

import '../app.dart';
import '../models/idea.dart';
import '../services/voice_input.dart';
import '../state/idea_store.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/idea_card.dart';
import 'capture_sheet.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            key: const Key('voice-fab'),
            heroTag: 'voice',
            tooltip: 'Capture by voice',
            backgroundColor: AppColors.surfaceHigh,
            foregroundColor: AppColors.amber,
            onPressed: () => showCaptureSheet(context, voice: true),
            child: const Icon(Icons.mic_rounded),
          ),
          const SizedBox(height: 14),
          SizedBox.square(
            dimension: 64,
            child: FloatingActionButton(
              key: const Key('capture-fab'),
              heroTag: 'capture',
              tooltip: 'Capture new idea',
              onPressed: () => showCaptureSheet(context),
              child: const Icon(Icons.add_rounded, size: 30),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(store: store)),
              _body(context, store),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, IdeaStore store) {
    if (store.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(store.error!, style: const TextStyle(color: AppColors.danger))),
      );
    }
    final ideas = store.visible;
    if (ideas.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _Empty(filtered: store.total > 0),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.separated(
        itemCount: ideas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => IdeaCard(
          idea: ideas[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => DetailScreen(ideaId: ideas[i].id)),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.store});

  final IdeaStore store;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final _text = TextEditingController(text: widget.store.query);
  bool _listening = false;
  VoiceInput? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice = AppScope.of(context).voice;
  }

  @override
  void dispose() {
    if (_listening) _voice?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _set(String q) {
    _text.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    widget.store.setQuery(q);
    setState(() {});
  }

  Future<void> _toggleVoice() async {
    final voice = _voice!;
    if (_listening) {
      await voice.stop();
      return;
    }
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final status = await voice.prepare();
    if (!mounted) return;
    if (status != VoiceStatus.idle) {
      messenger.showSnackBar(SnackBar(
        content: Text(status == VoiceStatus.denied
            ? 'Allow Microphone and Speech Recognition for Brainstash in iOS Settings.'
            : "On-device speech recognition isn't available here."),
      ));
      return;
    }
    setState(() => _listening = true);
    await voice.start(
      pauseFor: const Duration(seconds: 2),
      listenFor: const Duration(seconds: 15),
      onText: (t) {
        if (mounted) _set(searchQueryFromSpeech(t));
      },
      onDone: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search'),
      controller: _text,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: (q) {
        widget.store.setQuery(q);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: _listening ? 'Listening… say what to find' : 'Search ideas',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textFaint),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_text.text.isNotEmpty && !_listening)
              IconButton(
                key: const Key('search-clear'),
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded, color: AppColors.textFaint),
                onPressed: () => _set(''),
              ),
            IconButton(
              key: const Key('search-voice'),
              tooltip: _listening ? 'Stop listening' : 'Search by voice',
              icon: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _listening ? AppColors.amber : AppColors.textMuted),
              onPressed: _toggleVoice,
            ),
          ],
        ),
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: _listening ? const BorderSide(color: AppColors.amber) : BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store});

  final IdeaStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Brainstash',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
              ),
              _StageMenu(store: store),
              IconButton(
                tooltip: 'Settings',
                style: IconButton.styleFrom(backgroundColor: AppColors.surfaceHigh),
                icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SearchBar(store: store),
          const SizedBox(height: 14),
          _KindChips(store: store),
        ],
      ),
    );
  }
}

class _KindChips extends StatelessWidget {
  const _KindChips({required this.store});

  final IdeaStore store;

  @override
  Widget build(BuildContext context) {
    final options = <IdeaKind?>[null, ...IdeaKind.values];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in options) _chip(k),
      ],
    );
  }

  Widget _chip(IdeaKind? k) {
    final on = store.kindFilter == k;
    return ChoiceChip(
      label: Text('${k?.label ?? 'All'} · ${store.countFor(k)}'),
      selected: on,
      showCheckmark: false,
      onSelected: (_) => store.setKindFilter(k),
      selectedColor: AppColors.amber,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: on ? AppColors.amber : AppColors.borderStrong),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: on ? AppColors.amberInk : const Color(0xFFC9CDD5),
        fontWeight: on ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class _StageMenu extends StatelessWidget {
  const _StageMenu({required this.store});

  final IdeaStore store;

  @override
  Widget build(BuildContext context) {
    final active = store.stageFilter != null;
    return PopupMenuButton<IdeaStage?>(
      tooltip: 'Filter by stage',
      icon: Icon(
        Icons.filter_list_rounded,
        color: active ? AppColors.amber : AppColors.textMuted,
      ),
      initialValue: store.stageFilter,
      onSelected: store.setStageFilter,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All stages')),
        for (final s in IdeaStage.values) PopupMenuItem(value: s, child: Text(s.label)),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(size: 88),
          const SizedBox(height: 20),
          Text(
            filtered ? 'Nothing matches' : 'Your stash is empty',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            filtered
                ? 'Try another search or filter.'
                : 'Tap + the moment an idea hits. Only a title is needed.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
