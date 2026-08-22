import 'package:flutter/material.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: value == 0 ? 'Sin calificación' : '$value de 5 estrellas',
    child: Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(5, (index) {
        final rating = index + 1;
        return Semantics(
          button: true,
          selected: rating <= value,
          label: '$rating estrella${rating == 1 ? '' : 's'}',
          child: IconButton(
            key: Key('rating_$rating'),
            tooltip: '$rating estrella${rating == 1 ? '' : 's'}',
            iconSize: 40,
            onPressed: onChanged == null ? null : () => onChanged!(rating),
            icon: Icon(
              rating <= value ? Icons.star : Icons.star_border,
              semanticLabel: null,
            ),
          ),
        );
      }),
    ),
  );
}

String ratingLabel(int rating) => switch (rating) {
  1 => 'Muy malo',
  2 => 'Malo',
  3 => 'Regular',
  4 => 'Muy bueno',
  5 => 'Excelente',
  _ => 'Selecciona una calificación',
};
