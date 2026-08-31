import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    required this.onTap,
    this.selectedId,
    super.key,
  });
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;
  final int? selectedId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 350
          ? 2
          : constraints.maxWidth < 700
          ? 3
          : 4;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.12,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedId != null && selectedId == category.id;
          final primaryColor = Theme.of(context).colorScheme.primary;

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Ver ${category.name}',
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              elevation: isSelected ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).dividerColor.withValues(alpha: 0.25),
                  width: isSelected ? 2 : 1,
                ),
              ),
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              child: InkWell(
                key: Key('category_${category.id}'),
                onTap: () => onTap(category),
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CategoryIcon(
                            value: category.icon,
                            slug: category.slug,
                            color: isSelected ? primaryColor : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected ? primaryColor : null,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({this.value, this.slug, this.color});
  final String? value;
  final String? slug;
  final Color? color;

  static IconData _resolveIcon(String? icon, String? slug) {
    final key =
        (icon?.toLowerCase().trim() ?? slug?.toLowerCase().trim() ?? '');
    return switch (key) {
      'lightning-charge' ||
      'lightning' ||
      'bolt' ||
      'electricidad' => Icons.electric_bolt_outlined,
      'stars' || 'sparkles' || 'limpieza' => Icons.cleaning_services_outlined,
      'hammer' || 'carpinteria' => Icons.carpenter_outlined,
      'building' || 'construccion' => Icons.apartment_outlined,
      'car-front' ||
      'car-front-fill' ||
      'mecanica' ||
      'autolavado-y-detallado-automotriz' => Icons.directions_car_outlined,
      'droplet' || 'plomeria' => Icons.water_drop_outlined,
      'brush' || 'pintura' => Icons.format_paint_outlined,
      'wind' || 'aires-acondicionados' => Icons.air_outlined,
      'key' || 'cerrajeria' => Icons.vpn_key_outlined,
      'plug' || 'reparacion-electrodomesticos' => Icons.power_outlined,
      'heart-pulse' || 'enfermeria' => Icons.medical_services_outlined,
      'truck' || 'mudanzas' => Icons.local_shipping_outlined,
      'flower1' || 'jardineria' => Icons.yard_outlined,
      'pc-display' || 'informatica-mantenimiento-pc' => Icons.computer_outlined,
      'umbrella' || 'impermeabilizacion' => Icons.umbrella_outlined,
      'bricks' || 'demolicion' => Icons.foundation_outlined,
      'person-hearts' ||
      'cosmetica-y-estetica' => Icons.face_retouching_natural_outlined,
      'scissors' || 'costura' => Icons.content_cut_outlined,
      'wrench-adjustable' || 'herreria' => Icons.build_outlined,
      'window' || 'vidrieria' => Icons.window_outlined,
      'music-note-beamed' ||
      'mariachis-grupo-musical' => Icons.music_note_outlined,
      'cake2' || 'banquetes' => Icons.cake_outlined,
      'mic' || 'animacion-y-conduccion' => Icons.mic_outlined,
      'house-gear' || 'restauracion-de-inmuebles' => Icons.home_work_outlined,
      'tools' || 'restauracion-de-bienes' => Icons.home_repair_service_outlined,
      'pen' || 'tatuaje-y-perforacion' => Icons.edit_outlined,
      'egg-fried' || 'cocina' => Icons.restaurant_outlined,
      'basket' || 'lavanderia' => Icons.local_laundry_service_outlined,
      'activity' || 'entrenamiento-personal' => Icons.fitness_center_outlined,
      _ => Icons.handyman_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.amberDark;
    final uri = Uri.tryParse(value ?? '');
    if (uri?.hasScheme == true) {
      return Image.network(
        value!,
        width: 34,
        height: 34,
        errorBuilder: (_, _, _) => Icon(
          _resolveIcon(value, slug),
          size: 34,
          color: effectiveColor,
        ),
      );
    }
    return Icon(
      _resolveIcon(value, slug),
      size: 34,
      color: effectiveColor,
    );
  }
}
