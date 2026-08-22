import 'dart:async';

import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:flutter/material.dart';

class InvitationCard extends StatelessWidget {
  const InvitationCard({
    required this.invitation,
    required this.processing,
    required this.onAccept,
    required this.onDecline,
    required this.onExpired,
    this.compact = false,
    super.key,
  });

  final JobInvitationModel invitation;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onExpired;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('invitation_${invitation.id}'),
    color: AppColors.amber.withValues(alpha: .08),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.near_me_outlined)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.category?.name ?? invitation.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (invitation.serviceMode != null)
                      Text(
                        invitation.serviceMode == 'immediate'
                            ? '⚡ Ahora'
                            : 'Programada',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              if (invitation.expiresAt != null)
                CountdownText(
                  expiresAt: invitation.expiresAt!,
                  onExpired: onExpired,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            invitation.description,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Aprox. ${invitation.distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if ([
            invitation.city,
            invitation.state,
          ].whereType<String>().where((value) => value.isNotEmpty).isNotEmpty)
            Text(
              [invitation.city, invitation.state]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(', '),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey('decline_${invitation.id}'),
                  onPressed: processing ? null : onDecline,
                  child: const Text('No me interesa'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: ValueKey('accept_${invitation.id}'),
                  onPressed: processing ? null : onAccept,
                  child: processing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Flexible(child: Text('Aceptando chamba…')),
                          ],
                        )
                      : const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class CountdownText extends StatefulWidget {
  const CountdownText({
    required this.expiresAt,
    required this.onExpired,
    super.key,
  });
  final DateTime expiresAt;
  final VoidCallback onExpired;
  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) _reported = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (_remaining <= Duration.zero && !_reported) {
      _reported = true;
      widget.onExpired();
    }
  }

  Duration get _remaining {
    final value = widget.expiresAt.toLocal().difference(DateTime.now());
    return value.isNegative ? Duration.zero : value;
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _remaining.inSeconds;
    final label =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: 'Tiempo aproximado restante $label',
      child: Chip(
        avatar: const Icon(Icons.timer_outlined, size: 17),
        label: Text(label),
      ),
    );
  }
}
