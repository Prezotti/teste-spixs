import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';
import 'package:teste_spixs/features/route/data/numbered_marker_icon.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';
import 'package:teste_spixs/features/route/domain/entities/route_maneuver.dart';
import 'package:teste_spixs/features/route/domain/repositories/directions_repository.dart';
import 'package:teste_spixs/features/route/domain/route_plan_args.dart';
import 'package:teste_spixs/features/route/domain/route_progress.dart';

class RouteController extends GetxController with WidgetsBindingObserver {
  RouteController({
    required this._directionsRepository,
    required this._locationPermissionService,
    required this.args,
    Future<BitmapDescriptor> Function(int number)? numberedIcon,
    Future<BitmapDescriptor> Function()? arrowIcon,
  }) : _numberedIcon = numberedIcon ?? NumberedMarkerIcon.forNumber,
       _arrowIconLoader = arrowIcon ?? NumberedMarkerIcon.arrow;

  final DirectionsRepository _directionsRepository;
  final LocationPermissionService _locationPermissionService;
  final RoutePlanArgs args;
  final Future<BitmapDescriptor> Function(int number) _numberedIcon;
  final Future<BitmapDescriptor> Function() _arrowIconLoader;

  static const _offRouteSamplesNeeded = 2;
  static const _recalcCooldown = Duration(seconds: 20);
  static const _cameraInterval = Duration(milliseconds: 300);
  static const _stepArrivalMeters = 35.0;
  static const _inaccurateGpsNotice = 'Sinal de GPS impreciso. Aguardando uma leitura melhor.';

  final isLoading = false.obs;
  final errorText = Rxn<String>();
  final route = Rxn<OptimizedRoute>();
  final isOrderExpanded = true.obs;
  final markersTick = 0.obs;
  final isNavigating = false.obs;
  final isRecalculating = false.obs;
  final notice = RxnString();
  final userPosition = Rxn<GeoPoint>();
  final userHeading = 0.0.obs;
  final showRecalcBanner = false.obs;
  final voiceOn = true.obs;
  final progressIndex = 1.obs;
  final progressTotal = 0.obs;

  final Map<int, BitmapDescriptor> _markerIcons = {};
  final Set<String> _visitedPlaceIds = {};

  StreamSubscription<Position>? _positionSub;
  DateTime? _lastCameraMove;
  Timer? _noticeTimer;
  Timer? _recalcBannerTimer;
  BitmapDescriptor? _arrowIcon;
  var _offRouteSamples = 0;
  var _maneuverIndex = 0;
  DateTime? _lastRecalcAt;

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

    final markers = <Marker>{
      if (current.origin != null && _markerIcons[1] != null)
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(current.origin!.latitude, current.origin!.longitude),
          infoWindow: const InfoWindow(title: '1', snippet: 'Sua localização'),
          icon: _markerIcons[1]!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
        ),
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

    final here = userPosition.value;
    final arrow = _arrowIcon;
    if (isNavigating.value && here != null && arrow != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(here.latitude, here.longitude),
          icon: arrow,
          rotation: userHeading.value,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1000,
        ),
      );
    }
    return markers;
  }

  RouteManeuver? get activeManeuver {
    final maneuvers = route.value?.maneuvers ?? const [];
    if (maneuvers.isEmpty) return null;
    final index = _maneuverIndex.clamp(0, maneuvers.length - 1);
    return maneuvers[index];
  }

  int distanceToActiveStep(GeoPoint? here) {
    final maneuver = activeManeuver;
    if (maneuver != null && here != null) {
      return RouteProgressEvaluator.distanceMeters(here, maneuver.end).round();
    }
    final stops = route.value?.stops ?? const [];
    if (stops.isEmpty) return 0;
    if (here == null) return stops.first.legDistanceMeters;
    return RouteProgressEvaluator.distanceMeters(
      here,
      GeoPoint(stops.first.place.latitude, stops.first.place.longitude),
    ).round();
  }

  Set<Polyline> get polylines {
    final current = route.value;
    if (current == null) return const {};

    final updating = showRecalcBanner.value || isRecalculating.value;
    return {
      Polyline(
        polylineId: const PolylineId('optimized-route'),
        points: [for (final point in current.polyline) LatLng(point.latitude, point.longitude)],
        color: updating ? AppColors.warning : AppColors.brand,
        width: AppSpacing.space1.toInt(),
        patterns: updating
            ? [PatternItem.dash(20), PatternItem.gap(12)]
            : const <PatternItem>[],
      ),
    };
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    loadRoute();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPositionStream();
    _noticeTimer?.cancel();
    _recalcBannerTimer?.cancel();
    _mapController = null;
    super.onClose();
  }

  Future<void> startNavigation() async {
    if (isNavigating.value || route.value == null) return;

    final granted = await _locationPermissionService.isGranted() || await _locationPermissionService.request();
    if (!granted) {
      _showNotice('Permissão de localização negada. Ative para navegar.');
      return;
    }

    if (!await _locationPermissionService.isServiceEnabled()) {
      _showNotice('O GPS do celular está desligado. Ative para navegar.');
      return;
    }

    progressTotal.value = route.value!.stops.length;
    progressIndex.value = 1;
    _maneuverIndex = 0;
    _offRouteSamples = 0;
    showRecalcBanner.value = false;
    try {
      _arrowIcon ??= await _arrowIconLoader();
    } catch (_) {
      _arrowIcon = null;
    }
    isNavigating.value = true;
    _lastCameraMove = null;
    markersTick.value++;
    _startPositionStream();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastCameraMove = null;
      _resumePositionStream();
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausePositionStream();
    }
  }

  void stopNavigation() {
    final here = userPosition.value;
    _stopPositionStream();
    isNavigating.value = false;
    isRecalculating.value = false;
    showRecalcBanner.value = false;
    userPosition.value = null;
    if (notice.value == _inaccurateGpsNotice) {
      notice.value = null;
      _noticeTimer?.cancel();
    }
    markersTick.value++;
    _faceNorth(here);
  }

  void _onPosition(Position position) {
    final current = route.value;
    if (!isNavigating.value || current == null) return;

    if (!RouteProgressEvaluator.acceptsFix(position.accuracy)) {
      _showNotice(_inaccurateGpsNotice, sticky: true);
      return;
    }
    if (notice.value == _inaccurateGpsNotice) {
      notice.value = null;
      _noticeTimer?.cancel();
    }

    final here = GeoPoint(position.latitude, position.longitude);
    userPosition.value = here;
    if (position.heading >= 0 && position.heading <= 360) {
      userHeading.value = position.heading;
    }
    _advanceManeuver(current, here);
    markersTick.value++;
    _follow(here);

    final progress = RouteProgressEvaluator.evaluate(
      position: here,
      polyline: current.polyline,
      stops: current.stops,
      alreadyVisited: _visitedPlaceIds,
    );
    final arrived = progress.visitedPlaceIds.difference(_visitedPlaceIds);
    _visitedPlaceIds.addAll(progress.visitedPlaceIds);

    final remaining = [
      for (final stop in current.stops)
        if (!_visitedPlaceIds.contains(stop.place.placeId)) stop.place,
    ];

    if (remaining.isEmpty) {
      stopNavigation();
      _showNotice('Você concluiu as paradas.');
      return;
    }

    if (arrived.isNotEmpty) {
      final next = progressIndex.value + arrived.length;
      progressIndex.value = next > progressTotal.value ? progressTotal.value : next;
      _recalculate(here, remaining, announce: false);
      return;
    }

    if (!progress.offRoute) {
      _offRouteSamples = 0;
      return;
    }

    _offRouteSamples++;
    if (_offRouteSamples < _offRouteSamplesNeeded || isRecalculating.value) return;
    final lastRecalc = _lastRecalcAt;
    if (lastRecalc != null && DateTime.now().difference(lastRecalc) < _recalcCooldown) {
      return;
    }
    _recalculate(here, remaining, announce: true);
  }

  Future<void> _recalculate(GeoPoint here, List<PlaceDetails> remaining, {required bool announce}) async {
    if (isRecalculating.value || remaining.isEmpty) return;
    isRecalculating.value = true;
    markersTick.value++;
    notice.value = null;
    _noticeTimer?.cancel();
    _lastRecalcAt = DateTime.now();
    _offRouteSamples = 0;

    try {
      final optimized = await _directionsRepository.optimize(
        stops: remaining,
        originLatitude: here.latitude,
        originLongitude: here.longitude,
      );
      await _loadMarkerIcons(optimized);
      _maneuverIndex = 0;
      route.value = optimized;
      markersTick.value++;
      if (announce) _showRecalcBanner();
    } on AppException catch (error) {
      _showNotice(error.message);
    } catch (_) {
      _showNotice('Não foi possível recalcular a rota.');
    } finally {
      isRecalculating.value = false;
      markersTick.value++;
    }
  }

  Future<void> _reportGpsFailure() async {
    if (!isNavigating.value) return;
    final enabled = await _locationPermissionService.isServiceEnabled();
    if (!isNavigating.value) return;
    _showNotice(
      enabled
          ? 'Não foi possível ler o GPS. Tente novamente.'
          : 'O GPS do celular está desligado.',
    );
  }

  void _showRecalcBanner() {
    showRecalcBanner.value = true;
    markersTick.value++;
    _recalcBannerTimer?.cancel();
    _recalcBannerTimer = Timer(const Duration(seconds: 5), () {
      showRecalcBanner.value = false;
      markersTick.value++;
    });
  }

  void _advanceManeuver(OptimizedRoute current, GeoPoint here) {
    final maneuvers = current.maneuvers;
    while (_maneuverIndex < maneuvers.length - 1) {
      final distance = RouteProgressEvaluator.distanceMeters(here, maneuvers[_maneuverIndex].end);
      if (distance > _stepArrivalMeters) break;
      _maneuverIndex++;
    }
  }

  void _showNotice(String message, {bool sticky = false}) {
    notice.value = message;
    _noticeTimer?.cancel();
    if (sticky) return;
    _noticeTimer = Timer(const Duration(seconds: 5), () {
      if (notice.value == message) notice.value = null;
    });
  }

  void _startPositionStream() {
    _stopPositionStream();
    _positionSub = _locationPermissionService.watch().listen(
      _onPosition,
      onError: (_) => _reportGpsFailure(),
    );
  }

  void _pausePositionStream() {
    if (!isNavigating.value) return;
    _stopPositionStream();
  }

  void _resumePositionStream() {
    if (!isNavigating.value || _positionSub != null) return;
    _startPositionStream();
  }

  void _stopPositionStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _follow(GeoPoint here) async {
    final map = _mapController;
    if (map == null) return;
    final now = DateTime.now();
    final lastMove = _lastCameraMove;
    if (lastMove != null && now.difference(lastMove) < _cameraInterval) return;
    _lastCameraMove = now;
    final target = LatLng(here.latitude, here.longitude);
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17,
            bearing: userHeading.value,
          ),
        ),
      );
    } catch (_) {
      // O mapa nativo pode ter sido recarregado no emulador.
    }
  }

  Future<void> _faceNorth(GeoPoint? here) async {
    final map = _mapController;
    if (map == null || here == null) return;
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(here.latitude, here.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (_) {}
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
    if (optimized.origin != null) {
      icons[1] = _markerIcons[1] ?? await _numberedIcon(1);
    }
    for (final stop in optimized.stops) {
      icons[stop.number] = _markerIcons[stop.number] ?? await _numberedIcon(stop.number);
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
