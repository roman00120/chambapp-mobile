import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    required this.categories,
    required this.onTap,
    super.key,
  });
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;

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
          return Semantics(
            button: true,
            label: 'Ver ${category.name}',
            child: InkWell(
              key: Key('category_${category.id}'),
              onTap: () => onTap(category),
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CategoryIcon(value: category.icon),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
  const _CategoryIcon({this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(value ?? '');
    if (uri?.hasScheme == true) {
      return Image.network(
        value!,
        width: 34,
        height: 34,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.handyman_outlined, size: 34),
      );
    }
    return const Icon(
      Icons.handyman_outlined,
      size: 34,
      color: AppColors.amberDark,
    );
  }
}
