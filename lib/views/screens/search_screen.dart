import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/weather_gradients.dart';
import '../../data/models/location.dart';
import '../../viewmodels/favorites_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../viewmodels/view_state.dart';
import '../../viewmodels/weather_viewmodel.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/loading_view.dart';

/// Layar pencarian kota, favorit, dan riwayat pencarian.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        colors: WeatherGradients.forCode(0, isDay: true),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: Theme.of(context).textTheme.bodyLarge,
                        cursorColor: Colors.white,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Cari kota...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: _clearQuery,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                        ),
                        onChanged: _onQueryChanged,
                        onSubmitted: (_) {
                          context.read<SearchViewModel>().retry();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer2<SearchViewModel, FavoritesViewModel>(
                  builder: (context, searchViewModel, favoritesViewModel, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _buildBody(
                        context,
                        searchViewModel,
                        favoritesViewModel,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQueryChanged(String value) {
    setState(() {});
    context.read<SearchViewModel>().onQueryChanged(value);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() {});
    context.read<SearchViewModel>().onQueryChanged('');
    _focusNode.requestFocus();
  }

  Future<void> _selectLocation(Location location) async {
    final searchViewModel = context.read<SearchViewModel>();
    final weatherViewModel = context.read<WeatherViewModel>();

    await searchViewModel.addToHistory(location);
    if (!mounted) return;

    unawaited(weatherViewModel.selectLocation(location));
    Navigator.of(context).pop();
  }

  Widget _buildBody(
    BuildContext context,
    SearchViewModel searchViewModel,
    FavoritesViewModel favoritesViewModel,
  ) {
    final query = searchViewModel.query.trim();

    if (query.isEmpty) {
      return _buildIdle(context, searchViewModel, favoritesViewModel);
    }

    if (query.length < AppConstants.minimumQueryLength) {
      return const EmptyView(
        key: ValueKey('short-query'),
        icon: Icons.keyboard_rounded,
        message: 'Ketik minimal 2 karakter untuk mencari kota.',
      );
    }

    switch (searchViewModel.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const LoadingView(
          key: ValueKey('search-loading'),
          message: 'Mencari kota...',
        );
      case ViewState.error:
        return ErrorView(
          key: const ValueKey('search-error'),
          title: 'Pencarian gagal',
          message:
              searchViewModel.errorMessage ??
              'Gagal mencari kota. Silakan coba lagi.',
          onRetry: searchViewModel.retry,
        );
      case ViewState.empty:
        return const EmptyView(
          key: ValueKey('search-empty'),
          icon: Icons.location_off_rounded,
          message: 'Kota tidak ditemukan.\nCoba nama kota lain.',
        );
      case ViewState.success:
        return ListView.separated(
          key: const ValueKey('search-results'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: searchViewModel.results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final location = searchViewModel.results[index];
            return _LocationTile(
              location: location,
              isFavorite: favoritesViewModel.isFavorite(location),
              onTap: () => _selectLocation(location),
              onToggleFavorite: () {
                favoritesViewModel.toggleFavorite(location);
              },
            );
          },
        );
    }
  }

  Widget _buildIdle(
    BuildContext context,
    SearchViewModel searchViewModel,
    FavoritesViewModel favoritesViewModel,
  ) {
    final favorites = favoritesViewModel.favorites;
    // Kota favorit tidak perlu muncul dua kali di daftar riwayat.
    final history = searchViewModel.history
        .where((location) => !favoritesViewModel.isFavorite(location))
        .toList();

    if (favorites.isEmpty && history.isEmpty) {
      return const EmptyView(
        key: ValueKey('search-idle-empty'),
        icon: Icons.travel_explore_rounded,
        message:
            'Cari kota untuk melihat cuaca.\n'
            'Ketik minimal 2 karakter.',
      );
    }

    return ListView(
      key: const ValueKey('search-idle'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (favorites.isNotEmpty) ...[
          const _SectionHeader(
            icon: Icons.star_rounded,
            title: 'Lokasi favorit',
          ),
          ...favorites.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationTile(
                location: location,
                isFavorite: true,
                onTap: () => _selectLocation(location),
                onToggleFavorite: () {
                  favoritesViewModel.toggleFavorite(location);
                },
              ),
            ),
          ),
        ],
        if (history.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.history_rounded,
            title: 'Riwayat pencarian',
            trailing: TextButton.icon(
              onPressed: () {
                unawaited(searchViewModel.clearHistory());
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Hapus'),
            ),
          ),
          ...history.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LocationTile(
                location: location,
                isFavorite: favoritesViewModel.isFavorite(location),
                onTap: () => _selectLocation(location),
                onToggleFavorite: () {
                  favoritesViewModel.toggleFavorite(location);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final Location location;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _LocationTile({
    required this.location,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      location.admin1,
      location.country,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

    return Material(
      color: AppTheme.glassColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.location_on_rounded,
                  size: 20,
                  color: isFavorite
                      ? const Color(0xFFFFD60A)
                      : Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Hapus dari favorit'
                    : 'Tambahkan ke favorit',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
                color: isFavorite
                    ? const Color(0xFFFFD60A)
                    : Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
