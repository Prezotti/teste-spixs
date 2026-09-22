import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/route/controllers/route_controller.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';

class RoutePage extends GetView<RouteController> {
  const RoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface100,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _StableMap(),
          const _MapStatusOverlay(),
          Column(
            children: [
              Obx(
                () => controller.isNavigating.value
                    ? const _NavBanner()
                    : const _TopPanel(),
              ),
              Expanded(
                child: Obx(
                  () => controller.isNavigating.value
                      ? const _NavControls()
                      : const _MyLocationButton(),
                ),
              ),
              Obx(
                () => controller.isNavigating.value
                    ? const _NavDestinationCard()
                    : const _BottomPanel(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StableMap extends StatefulWidget {
  const _StableMap();

  @override
  State<_StableMap> createState() => _StableMapState();
}

class _StableMapState extends State<_StableMap> {
  Worker? _routeWorker;
  Worker? _iconWorker;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<RouteController>();
    _routeWorker = ever(controller.route, (_) {
      if (mounted) setState(() {});
    });
    _iconWorker = ever(controller.markersTick, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _routeWorker?.dispose();
    _iconWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RouteController>();
    return GoogleMap(
      initialCameraPosition: controller.initialCamera,
      markers: controller.markers,
      polylines: controller.polylines,
      myLocationEnabled: !controller.isNavigating.value,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: controller.onMapCreated,
    );
  }
}

class _MyLocationButton extends GetView<RouteController> {
  const _MyLocationButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(
          right: AppSpacing.space3,
          bottom: AppSpacing.space3,
        ),
        child: Material(
          color: AppColors.surface200,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: controller.centerOnMe,
            child: const SizedBox(
              width: AppSpacing.space4 + AppSpacing.space3,
              height: AppSpacing.space4 + AppSpacing.space3,
              child: Icon(Icons.my_location, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBanner extends GetView<RouteController> {
  const _NavBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recalculating = controller.isRecalculating.value;
      final recalculated = controller.showRecalcBanner.value;
      final message = controller.notice.value;
      controller.userPosition.value;
      controller.route.value;
      final warning = recalculating || recalculated || message != null;
      final Widget body;
      if (recalculating) {
        body = const _StatusBannerBody(
          title: 'Recalculando…',
          body: 'Atualizando a rota com os pontos restantes.',
          busy: true,
        );
      } else if (recalculated) {
        body = const _RecalcBannerBody();
      } else if (message != null) {
        body = _StatusBannerBody(body: message);
      } else {
        body = const _ManeuverBannerBody();
      }
      return Material(
        color: warning ? AppColors.warning : AppColors.success,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space3,
              AppSpacing.space2,
              AppSpacing.space3,
              AppSpacing.space3,
            ),
            child: body,
          ),
        ),
      );
    });
  }
}

class _ManeuverBannerBody extends GetView<RouteController> {
  const _ManeuverBannerBody();

  @override
  Widget build(BuildContext context) {
    final here = controller.userPosition.value;
    final maneuver = controller.activeManeuver;
    final instruction = maneuver?.instruction ?? _fallbackInstruction(controller);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconForManeuver(maneuver?.maneuver),
          color: AppColors.onBrand,
          size: AppSpacing.space4,
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UIText.display(
                _formatDistance(controller.distanceToActiveStep(here)),
                color: AppColors.onBrand,
              ),
              UIText.body(instruction, color: AppColors.onBrand, maxLines: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBannerBody extends StatelessWidget {
  const _StatusBannerBody({
    this.title,
    required this.body,
    this.busy = false,
  });

  final String? title;
  final String body;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (busy)
          const SizedBox(
            width: AppSpacing.space4,
            height: AppSpacing.space4,
            child: CircularProgressIndicator(
              strokeWidth: AppSpacing.space1,
              color: AppColors.onBrand,
            ),
          )
        else
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.onBrand,
            size: AppSpacing.space4,
          ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                UIText.heading(title!, color: AppColors.onBrand),
                const SizedBox(height: AppSpacing.space1),
              ],
              UIText.body(body, color: AppColors.onBrand, maxLines: 3),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecalcBannerBody extends StatelessWidget {
  const _RecalcBannerBody();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.onBrand, size: AppSpacing.space4),
        SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UIText.heading('Rota recalculada', color: AppColors.onBrand),
              SizedBox(height: AppSpacing.space1),
              UIText.body(
                'Você se desviou da rota. Nova rota otimizada com os pontos restantes.',
                color: AppColors.onBrand,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavControls extends GetView<RouteController> {
  const _NavControls();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundMapButton(
              onTap: controller.voiceOn.toggle,
              child: Obx(
                () => Icon(
                  controller.voiceOn.value ? Icons.volume_up : Icons.volume_off,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            _RoundMapButton(
              onTap: controller.stopNavigation,
              child: const Icon(Icons.close, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  const _RoundMapButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface200,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.space4 + AppSpacing.space3,
          height: AppSpacing.space4 + AppSpacing.space3,
          child: child,
        ),
      ),
    );
  }
}

class _NavDestinationCard extends GetView<RouteController> {
  const _NavDestinationCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.route.value;
      if (current == null || current.stops.isEmpty) return const SizedBox.shrink();
      final next = current.stops.first;
      final index = controller.progressIndex.value;
      final total = controller.progressTotal.value;
      final fraction = total == 0 ? 0.0 : (index / total).clamp(0.0, 1.0);
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space3),
        child: Material(
          color: AppColors.surface200,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const UIText.caption('Próximo destino'),
                const SizedBox(height: AppSpacing.space1),
                UIText.heading(
                  next.place.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: UIText.body(
                        '${_formatDuration(next.legDurationSeconds)} · ${_formatDistance(next.legDistanceMeters)}',
                        color: AppColors.inkMuted,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        UIText.bodyStrong('$index de $total'),
                        const SizedBox(height: AppSpacing.space1),
                        SizedBox(
                          width: AppSpacing.space4 * 2,
                          child: ClipRRect(
                            borderRadius: AppRadius.smAll,
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: AppSpacing.space1.toDouble(),
                              color: AppColors.brand,
                              backgroundColor: AppColors.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _MapStatusOverlay extends GetView<RouteController> {
  const _MapStatusOverlay();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Align(
          alignment: Alignment.center,
          child: CircularProgressIndicator(color: AppColors.brand),
        );
      }

      final error = controller.errorText.value;
      if (error == null) return const SizedBox.shrink();

      return ColoredBox(
        color: AppColors.surface100,
        child: Center(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UIText.body(error, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.space3),
                UIPrimaryButton(
                  label: 'Tentar novamente',
                  onPressed: controller.loadRoute,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _TopPanel extends GetView<RouteController> {
  const _TopPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.route.value;
      if (current == null) {
        return Material(
          color: AppColors.surface200,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back),
                color: AppColors.ink,
              ),
            ),
          ),
        );
      }
      return _OrderCollapse(route: current);
    });
  }
}

class _BottomPanel extends GetView<RouteController> {
  const _BottomPanel();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.route.value;
      if (current == null || controller.isLoading.value) {
        return const SizedBox.shrink();
      }
      return _RouteSummary(route: current);
    });
  }
}

class _OrderCollapse extends GetView<RouteController> {
  const _OrderCollapse({required this.route});

  final OptimizedRoute route;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface200,
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final expanded = controller.isOrderExpanded.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: controller.toggleOrder,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space2,
                    AppSpacing.space1,
                    AppSpacing.space3,
                    AppSpacing.space1,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.ink,
                      ),
                      const Expanded(
                        child: UIText.heading('Ordem otimizada'),
                      ),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space3,
                          0,
                          AppSpacing.space3,
                          AppSpacing.space3,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < route.stops.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.space2),
                              _OrderRow(
                                number: route.stops[i].number,
                                title: route.stops[i].place.address,
                              ),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.number,
    required this.title,
  });

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.space4,
          height: AppSpacing.space4,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: UIText.caption('$number', color: AppColors.onBrand),
        ),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: UIText.body(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _RouteSummary extends GetView<RouteController> {
  const _RouteSummary({required this.route});

  final OptimizedRoute route;

  @override
  Widget build(BuildContext context) {
    final stops = route.stops.length;
    return Material(
      color: AppColors.surface200,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UIText.title(
                '${_formatDuration(route.durationSeconds)} (${_formatDistance(route.distanceMeters)})',
              ),
              const SizedBox(height: AppSpacing.space1),
              Obx(() {
                final message = controller.notice.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UIText.caption(
                      'Rota otimizada com $stops ${stops == 1 ? 'parada' : 'paradas'}',
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Container(
                        padding: AppSpacing.related,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: AppRadius.smAll,
                        ),
                        child: UIText.bodyStrong(message),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.space3),
              UIPrimaryButton(
                label: 'Iniciar',
                onPressed: controller.startNavigation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _fallbackInstruction(RouteController controller) {
  final stops = controller.route.value?.stops ?? const [];
  if (stops.isEmpty) return 'Siga em frente';
  return 'Siga para ${stops.first.place.address}';
}

IconData _iconForManeuver(String? maneuver) {
  final value = (maneuver ?? '').toUpperCase();
  if (value.contains('UTURN_LEFT')) return Icons.u_turn_left;
  if (value.contains('UTURN')) return Icons.u_turn_right;
  if (value.contains('LEFT')) return Icons.turn_left;
  if (value.contains('RIGHT')) return Icons.turn_right;
  if (value.contains('ROUNDABOUT')) return Icons.roundabout_right;
  return Icons.straight;
}

String _formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  final km = meters / 1000;
  final digits = km >= 10 ? 0 : 1;
  return '${km.toStringAsFixed(digits).replaceAll('.', ',')} km';
}

String _formatDuration(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}
