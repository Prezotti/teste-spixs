import 'package:flutter/painting.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/route/data/numbered_marker_icon.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';
import 'package:teste_spixs/features/route/domain/repositories/directions_repository.dart';
import 'package:teste_spixs/features/route/domain/route_plan_args.dart';

class RouteController extends GetxController {
  RouteController({
    required DirectionsRepository directionsRepository,
    required LocationPermissionService locationPermissionService,
    required this.args,
  }) : _directionsRepository = directionsRepository,
       _locationPermissionService = locationPermissionService;

  final DirectionsRepository _directionsRepository;
  final LocationPermissionService _locationPermissionService;
  final RoutePlanArgs args;

  final isLoading = false.obs;
  final errorText = Rxn<String>();
  final route = Rxn<OptimizedRoute>();
  final isOrderExpanded = true.obs;
  final markersTick = 0.obs;

  final Map<int, BitmapDescriptor> _markerIcons = {};

  void toggleOrder() => isOrderExpanded.toggle();

  GoogleMapController? _mapController;

  CameraPosition get initialCamera {
    final origin = args.hasOrigin
        ? LatLng(args.originLatitude!, args.originLongitude!)
        : LatLng(args.stops.first.latitude, args.stops.first.longitude);
    return CameraPosition(target: origin, zoom: 13);
  }

  Set<Marker> get markers {
    final current = route.value;
    if (current == null) return const {};

    return {
      for (final stop in current.stops)
        if (_markerIcons[stop.number] != null)
          Marker(
            markerId: MarkerId('stop-${stop.number}'),
            position: LatLng(stop.place.latitude, stop.place.longitude),
            infoWindow: InfoWindow(title: '${stop.number}', snippet: stop.place.address),
            icon: _markerIcons[stop.number]!,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: stop.number,
          ),
    };
  }

  Set<Polyline> get polylines {
    final current = route.value;
    if (current == null) return const {};

    return {
      Polyline(
        polylineId: const PolylineId('optimized-route'),
        points: [for (final point in current.polyline) LatLng(point.latitude, point.longitude)],
        color: AppColors.brand,
        width: AppSpacing.space1.toInt(),
      ),
    };
  }

  @override
  void onReady() {
    super.onReady();
    loadRoute();
  }

  @override
  void onClose() {
    _mapController = null;
    super.onClose();
  }

  Future<void> loadRoute() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorText.value = null;

    try {
      final optimized = await _directionsRepository.optimize(
        stops: args.stops,
        originLatitude: args.originLatitude,
        originLongitude: args.originLongitude,
      );
      await _loadMarkerIcons(optimized);
      route.value = optimized;
      await _fitCamera();
    } on AppException catch (error) {
      route.value = null;
      errorText.value = error.message;
    } catch (_) {
      route.value = null;
      errorText.value = 'Não foi possível calcular a rota. Tente novamente.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMarkerIcons(OptimizedRoute optimized) async {
    final icons = <int, BitmapDescriptor>{};
    for (final stop in optimized.stops) {
      icons[stop.number] = _markerIcons[stop.number] ?? await NumberedMarkerIcon.forNumber(stop.number);
    }
    _markerIcons
      ..clear()
      ..addAll(icons);
    markersTick.value++;
  }

  Future<void> centerOnMe() async {
    final map = _mapController;
    if (map == null) return;

    final position = await _locationPermissionService.currentOrLast();
    final latitude = position?.latitude ?? args.originLatitude;
    final longitude = position?.longitude ?? args.originLongitude;
    if (latitude == null || longitude == null) return;

    try {
      await map.animateCamera(CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 16));
    } catch (_) {
      // O mapa nativo pode ter sido recarregado no emulador.
    }
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await _fitCamera();
  }

  Future<void> _fitCamera() async {
    final current = route.value;
    final map = _mapController;
    if (current == null || map == null || current.polyline.isEmpty) return;

    var minLat = current.polyline.first.latitude;
    var maxLat = minLat;
    var minLng = current.polyline.first.longitude;
    var maxLng = minLng;

    for (final point in current.polyline) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    try {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
          AppSpacing.space4,
        ),
      );
    } catch (_) {
      // O mapa nativo pode ter sido recarregado no emulador.
    }
  }
}
