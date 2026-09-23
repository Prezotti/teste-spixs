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
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/route/domain/entities/geo_point.dart';
import 'package:teste_spixs/features/route/domain/entities/route_completion.dart';
import 'package:teste_spixs/features/route/domain/entities/optimized_route.dart';
import 'package:teste_spixs/features/route/domain/entities/route_maneuver.dart';
import 'package:teste_spixs/features/route/domain/entities/route_stop.dart';
import 'package:teste_spixs/features/route/domain/marker_glide.dart';
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
    DateTime Function()? now,
  }) : _numberedIcon = numberedIcon ?? NumberedMarkerIcon.forNumber,
       _arrowIconLoader = arrowIcon ?? NumberedMarkerIcon.arrow,
       _now = now ?? DateTime.now;

  final DirectionsRepository _directionsRepository;
  final LocationPermissionService _locationPermissionService;
  final RoutePlanArgs args;
  final Future<BitmapDescriptor> Function(int number) _numberedIcon;
  final Future<BitmapDescriptor> Function() _arrowIconLoader;
  final DateTime Function() _now;

  static const _offRouteSamplesNeeded = 2;
  static const _recalcCooldown = Duration(seconds: 20);
  static const _cameraInterval = Duration(milliseconds: 100);
  static const _glideTick = Duration(milliseconds: 50);
  static const _minGlide = Duration(milliseconds: 400);
  static const _maxGlide = Duration(milliseconds: 1200);
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
  final activeManeuverIndex = 0.obs;

  final Map<int, BitmapDescriptor> _markerIcons = {};
  final Set<String> _visitedPlaceIds = {};

  StreamSubscription<Position>? _positionSub;
  Timer? _glideTimer;
  _MarkerSlide? _slide;
  Position? _lastFix;
  DateTime? _lastGlideAt;
  DateTime? _lastCameraMove;
  Timer? _noticeTimer;
  Timer? _recalcBannerTimer;
  RouteCompletion? _completion;
  BitmapDescriptor? _arrowIcon;
  var _offRouteSamples = 0;
  var _routeSegment = 0;
  List<GeoPoint> _visiblePolyline = const [];
  DateTime? _lastRecalcAt;

  void toggleOrder() => isOrderExpanded.toggle();

  GoogleMapController? _mapController;

  CameraPosition get initialCamera {
    final origin = args.hasOrigin
        ? LatLng(args.originLatitude!, args.originLongitude!)
        : LatLng(args.stops.first.latitude, args.stops.first.longitude);
    return CameraPosition(target: origin, zoom: 16);
  }

  Set<Marker> get markers {
    final current = route.value;
    if (current == null) return const {};

    final markers = <Marker>{
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
    final index = activeManeuverIndex.value.clamp(0, maneuvers.length - 1);
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
    final source = isNavigating.value && _visiblePolyline.length >= 2
        ? _visiblePolyline
        : current.polyline;
    return {
      Polyline(
        polylineId: const PolylineId('optimized-route'),
        points: [for (final point in source) LatLng(point.latitude, point.longitude)],
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

    final planned = route.value!;
    _completion = RouteCompletion(
      deliveries: planned.stops.length,
      durationSeconds: planned.durationSeconds,
      distanceMeters: planned.distanceMeters,
    );
    progressTotal.value = planned.stops.length;
    progressIndex.value = 1;
    activeManeuverIndex.value = 0;
    _offRouteSamples = 0;
    _resetPolylineProgress();
    _resetMotion();
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
    _resetPolylineProgress();
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

    _lastFix = position;
    final here = GeoPoint(position.latitude, position.longitude);
    _glideTo(_matchedPoint(current, here), position.heading);
    if (_slide == null) _publishFrame(userPosition.value ?? here, current);
    _ensureGlideTimer();
    _afterFix(current, here, countDeviation: true);
  }

  void _onGlideTick() {
    if (!isNavigating.value) return;
    final slide = _slide;
    final current = route.value;
    if (slide != null && current != null) {
      final elapsed = _now().difference(slide.started).inMilliseconds;
      final t = elapsed / slide.duration.inMilliseconds;
      final point = MarkerGlide.pointBetween(slide.from, slide.to, t);
      userHeading.value = MarkerGlide.headingBetween(slide.fromHeading, slide.toHeading, t);
      _publishFrame(point, current);
      if (t >= 1) _slide = null;
    }
    final fix = _lastFix;
    if (!isNavigating.value || current == null || fix == null) return;
    _afterFix(current, GeoPoint(fix.latitude, fix.longitude), countDeviation: false);
  }

  void _afterFix(
    OptimizedRoute current,
    GeoPoint here, {
    required bool countDeviation,
  }) {
    final arrivedNow = _trackArrival(current, here);
    final remaining = [
      for (final stop in current.stops)
        if (!_visitedPlaceIds.contains(stop.place.placeId)) stop.place,
    ];

    if (remaining.isEmpty) {
      final summary = _completion ??
          RouteCompletion(
            deliveries: current.stops.length,
            durationSeconds: current.durationSeconds,
            distanceMeters: current.distanceMeters,
          );
      stopNavigation();
      if (Get.key.currentState != null) {
        Get.offNamed(AppRoutes.routeCompleted, arguments: summary);
      }
      return;
    }

    if (arrivedNow || !countDeviation) return;

    final progress = RouteProgressEvaluator.evaluate(
      position: here,
      polyline: current.polyline,
      stops: current.stops,
      alreadyVisited: _visitedPlaceIds,
    );
    if (_isBesideVisitedStop(current, here) || !progress.offRoute) {
      _offRouteSamples = 0;
      return;
    }

    _offRouteSamples++;
    if (_offRouteSamples < _offRouteSamplesNeeded || isRecalculating.value) return;
    final lastRecalc = _lastRecalcAt;
    if (lastRecalc != null && _now().difference(lastRecalc) < _recalcCooldown) return;
    _recalculate(here, remaining, announce: true);
  }

  bool _trackArrival(OptimizedRoute current, GeoPoint here) {
    RouteStop? next;
    for (final stop in current.stops) {
      if (_visitedPlaceIds.contains(stop.place.placeId)) continue;
      next = stop;
      break;
    }
    if (next == null) return false;

    final distance = RouteProgressEvaluator.distanceMeters(
      here,
      GeoPoint(next.place.latitude, next.place.longitude),
    );
    if (distance > RouteProgressEvaluator.arrivalThresholdMeters) return false;

    _visitedPlaceIds.add(next.place.placeId);
    final nextIndex = progressIndex.value + 1;
    progressIndex.value = nextIndex > progressTotal.value ? progressTotal.value : nextIndex;
    _offRouteSamples = 0;
    return true;
  }

  GeoPoint _matchedPoint(OptimizedRoute current, GeoPoint here) {
    if (current.polyline.length < 2) return here;
    final distance = RouteProgressEvaluator.distanceToPolylineMeters(here, current.polyline);
    if (distance > RouteProgressEvaluator.deviationThresholdMeters) return here;
    final slice = RouteProgressEvaluator.trimTraveled(
      position: here,
      polyline: current.polyline,
      fromSegment: _routeSegment,
    );
    return slice.points.isEmpty ? here : slice.points.first;
  }

  void _glideTo(GeoPoint target, double heading) {
    final headingTo = heading >= 0 && heading <= 360 ? heading : userHeading.value;
    final from = userPosition.value;
    final now = _now();
    if (from == null || _lastGlideAt == null) {
      userPosition.value = target;
      userHeading.value = headingTo;
      _lastGlideAt = now;
      _slide = null;
      return;
    }

    final gap = now.difference(_lastGlideAt!);
    _lastGlideAt = now;
    if (gap <= Duration.zero) {
      userPosition.value = target;
      userHeading.value = headingTo;
      _slide = null;
      return;
    }

    final millis = gap.inMilliseconds.clamp(_minGlide.inMilliseconds, _maxGlide.inMilliseconds);
    _slide = _MarkerSlide(
      from: from,
      to: target,
      fromHeading: userHeading.value,
      toHeading: headingTo,
      started: now,
      duration: Duration(milliseconds: millis),
    );
  }

  void _publishFrame(GeoPoint point, OptimizedRoute current) {
    userPosition.value = point;
    _advanceManeuver(current, point);
    _trimPolyline(point, current.polyline);
    markersTick.value++;
    _follow(point);
  }

  void _ensureGlideTimer() {
    if (_glideTimer != null) return;
    _glideTimer = Timer.periodic(_glideTick, (_) => _onGlideTick());
  }

  void _resetMotion() {
    _slide = null;
    _lastFix = null;
    _lastGlideAt = null;
    _glideTimer?.cancel();
    _glideTimer = null;
  }

  bool _isBesideVisitedStop(OptimizedRoute current, GeoPoint here) {
    for (final stop in current.stops) {
      if (!_visitedPlaceIds.contains(stop.place.placeId)) continue;
      final distance = RouteProgressEvaluator.distanceMeters(
        here,
        GeoPoint(stop.place.latitude, stop.place.longitude),
      );
      if (distance <= RouteProgressEvaluator.arrivalThresholdMeters) return true;
    }
    return false;
  }

  Future<void> _recalculate(GeoPoint here, List<PlaceDetails> remaining, {required bool announce}) async {
    if (isRecalculating.value || remaining.isEmpty) return;
    isRecalculating.value = true;
    markersTick.value++;
    notice.value = null;
    _noticeTimer?.cancel();
    _lastRecalcAt = _now();
    _offRouteSamples = 0;

    try {
      final optimized = await _directionsRepository.optimize(
        stops: remaining,
        originLatitude: here.latitude,
        originLongitude: here.longitude,
      );
      await _loadMarkerIcons(optimized);
      activeManeuverIndex.value = 0;
      _resetPolylineProgress();
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
    final next = RouteProgressEvaluator.activeManeuverIndex(
      position: here,
      maneuvers: current.maneuvers,
      currentIndex: activeManeuverIndex.value,
    );
    if (next != activeManeuverIndex.value) {
      activeManeuverIndex.value = next;
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
    _glideTimer?.cancel();
    _glideTimer = null;
  }

  void _resetPolylineProgress() {
    _routeSegment = 0;
    _visiblePolyline = const [];
  }

  void _trimPolyline(GeoPoint here, List<GeoPoint> polyline) {
    final slice = RouteProgressEvaluator.trimTraveled(
      position: here,
      polyline: polyline,
      fromSegment: _routeSegment,
    );
    _routeSegment = slice.segmentIndex;
    _visiblePolyline = slice.points;
  }

  Future<void> _follow(GeoPoint here) async {
    final map = _mapController;
    if (map == null) return;
    final now = _now();
    final lastMove = _lastCameraMove;
    if (lastMove != null && now.difference(lastMove) < _cameraInterval) return;
    _lastCameraMove = now;
    final target = LatLng(here.latitude, here.longitude);
    try {
      await map.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 19,
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
            zoom: 18,
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
      _resetPolylineProgress();
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
      await map.animateCamera(CameraUpdate.newLatLngZoom(LatLng(latitude, longitude), 18));
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
      final zoom = await map.getZoomLevel();
      if (zoom < 16) {
        final focus = current.origin ?? current.polyline.first;
        await map.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(focus.latitude, focus.longitude), 16),
        );
      }
    } catch (_) {
      // O mapa nativo pode ter sido recarregado no emulador.
    }
  }
}

class _MarkerSlide {
  const _MarkerSlide({
    required this.from,
    required this.to,
    required this.fromHeading,
    required this.toHeading,
    required this.started,
    required this.duration,
  });

  final GeoPoint from;
  final GeoPoint to;
  final double fromHeading;
  final double toHeading;
  final DateTime started;
  final Duration duration;
}
