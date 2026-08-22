import 'dart:async';

import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/service_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery, this.categorySlug, super.key});
  final String? initialQuery;
  final String? categorySlug;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String? _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categorySlug != widget.categorySlug ||
        oldWidget.initialQuery != widget.initialQuery) {
      _query = widget.initialQuery;
      _controller.text = widget.initialQuery ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final input = ServiceSearchQuery(
      query: _query,
      categorySlug: widget.categorySlug,
    );
    final services = ref.watch(servicesProvider(input));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categorySlug == null ? 'Buscar' : 'Servicios por categoría',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                key: const Key('service_search'),
                controller: _controller,
                onChanged: _changed,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Buscar servicio o profesional',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: services.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  title: 'No pudimos buscar',
                  message: error,
                  onRetry: () => ref.invalidate(servicesProvider(input)),
                ),
                data: (items) => items.isEmpty
                    ? const Center(
                        child: Text(
                          'No encontramos servicios con esos criterios.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(servicesProvider(input));
                          await ref.read(servicesProvider(input).future);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final service = items[index];
                            return ServiceCard(
                              service: service,
                              onTap: () =>
                                  context.push('/services/${service.id}'),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
