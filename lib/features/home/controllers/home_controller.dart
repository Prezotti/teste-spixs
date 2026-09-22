import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/config/app_config.dart';
import 'package:teste_spixs/core/errors/app_exception.dart';
import 'package:teste_spixs/core/location/location_permission_service.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/core/utils/debouncer.dart';
import 'package:teste_spixs/features/home/controllers/address_field.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';
import 'package:teste_spixs/features/home/domain/repositories/places_repository.dart';
import 'package:teste_spixs/features/route/domain/route_plan_args.dart';

class HomeController extends GetxController {
  HomeController({
    required this._placesRepository,
    required this._locationPermissionService,
    Debouncer? searchDebouncer,
  }) : _debouncer = searchDebouncer ?? Debouncer();

  static const minStops = 3;

  final PlacesRepository _placesRepository;
  final LocationPermissionService _locationPermissionService;
  final Debouncer _debouncer;

  final points = <AddressField>[].obs;
  final searchPanel = const AddressSearchPanel.idle().obs;
  final canConfirm = false.obs;

  int _searchSeq = 0;
  String? _sessionToken;
  int? _sessionFieldIndex;
  double? _biasLatitude;
  double? _biasLongitude;
  var _applyingSelection = false;

  @override
  void onInit() {
    super.onInit();
    for (var i = 0; i < minStops; i++) {
      points.add(AddressField(label: _labelFor(i)));
    }
  }

  @override
  void onReady() {
    super.onReady();
    _loadSearchBias();
  }

  @override
  void onClose() {
    _debouncer.dispose();
    for (final field in points) {
      field.dispose();
    }
    super.onClose();
  }

  void addPoint() {
    points.add(AddressField(label: _labelFor(points.length)));
  }

  void removePoint(int index) {
    if (index < minStops || index >= points.length) return;

    final panel = searchPanel.value;
    if (panel.index == index) {
      searchPanel.value = const AddressSearchPanel.idle();
    } else if (panel.index != null && panel.index! > index) {
      searchPanel.value = AddressSearchPanel(
        index: panel.index! - 1,
        suggestions: panel.suggestions,
        isLoading: panel.isLoading,
        errorText: panel.errorText,
      );
    }

    if (_sessionFieldIndex == index) {
      _endSession();
    } else if (_sessionFieldIndex != null && _sessionFieldIndex! > index) {
      _sessionFieldIndex = _sessionFieldIndex! - 1;
    }

    final field = points.removeAt(index);
    field.dispose();

    for (var i = index; i < points.length; i++) {
      points[i].label = _labelFor(i);
    }

    _syncCanConfirm();
    points.refresh();
  }

  void onQueryChanged(int index, String query) {
    if (_applyingSelection) return;
    final field = points[index];
    field.selected = null;
    field.error = null;
    _syncCanConfirm();
    points.refresh();
    _ensureSession(index);

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      _debouncer.cancel();
      searchPanel.value = const AddressSearchPanel.idle();
      return;
    }

    if (!AppConfig.hasGoogleMapsKey) {
      searchPanel.value = AddressSearchPanel.error(index, 'Configure a chave da Google Places API.');
      return;
    }

    searchPanel.value = AddressSearchPanel.loading(index);
    _debouncer.run(() => _search(index, trimmed));
  }

  void onClear(int index) {
    final field = points[index];
    field.selected = null;
    field.error = null;
    _syncCanConfirm();
    points.refresh();

    if (searchPanel.value.index == index) {
      searchPanel.value = const AddressSearchPanel.idle();
    }
  }

  Future<void> selectPrediction(int index, PlacePrediction prediction) async {
    _debouncer.cancel();
    _dismissKeyboard();
    searchPanel.value = const AddressSearchPanel.idle();

    try {
      _ensureSession(index);
      final details = await _placesRepository.getDetails(
        prediction.placeId,
        sessionToken: _sessionToken!,
      );

      _applyingSelection = true;
      final field = points[index];
      field.selected = details;
      field.error = null;
      field.textController.text = details.address;
      _applyingSelection = false;
      _endSession();
      _syncCanConfirm();
      points.refresh();
    } on AppException catch (error) {
      _applyingSelection = false;
      searchPanel.value = AddressSearchPanel.error(index, error.message);
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  RoutePlanArgs? createRoutePlan() {
    if (!_validateSelections()) return null;

    return RoutePlanArgs(
      stops: [
        for (final field in points)
          if (field.selected != null) field.selected!,
      ],
      originLatitude: _biasLatitude,
      originLongitude: _biasLongitude,
    );
  }

  Future<void> confirmRoute() async {
    if (createRoutePlan() == null) return;

    if (_biasLatitude == null || _biasLongitude == null) {
      await _loadSearchBias();
    }

    final plan = createRoutePlan();
    if (plan == null) return;
    Get.toNamed(AppRoutes.route, arguments: plan);
  }

  bool _validateSelections() {
    var valid = true;

    for (var i = 0; i < points.length; i++) {
      final field = points[i];
      final requiredField = i < minStops;
      final typed = field.textController.text.trim().isNotEmpty;

      if (field.hasSelection) {
        field.error = null;
        continue;
      }

      if (requiredField || typed) {
        field.error = typed ? 'Selecione um endereço da lista' : 'Campo obrigatório';
        valid = false;
      } else {
        field.error = null;
      }
    }

    points.refresh();
    return valid;
  }

  String _labelFor(int index) {
    if (index < 26) return 'Ponto ${String.fromCharCode(65 + index)}';
    return 'Ponto ${index + 1}';
  }

  void _ensureSession(int index) {
    if (_sessionToken == null || _sessionFieldIndex != index) {
      _sessionToken = '${DateTime.now().microsecondsSinceEpoch}-$index';
      _sessionFieldIndex = index;
    }
  }

  void _endSession() {
    _sessionToken = null;
    _sessionFieldIndex = null;
  }

  Future<void> _search(int index, String query) async {
    if (index < 0 || index >= points.length) return;
    final field = points[index];
    final seq = ++_searchSeq;
    try {
      if (_biasLatitude == null || _biasLongitude == null) {
        await _loadSearchBias();
      }

      final result = await _placesRepository.search(
        query,
        sessionToken: _sessionToken ?? _fallbackToken(index),
        latitude: _biasLatitude,
        longitude: _biasLongitude,
      );

      if (seq != _searchSeq) return;
      final currentIndex = points.indexOf(field);
      if (currentIndex < 0) return;
      searchPanel.value = AddressSearchPanel.results(currentIndex, result);
    } on AppException catch (error) {
      if (seq != _searchSeq) return;
      final currentIndex = points.indexOf(field);
      if (currentIndex < 0) return;
      searchPanel.value = AddressSearchPanel.error(currentIndex, error.message);
    } catch (_) {
      if (seq != _searchSeq) return;
      final currentIndex = points.indexOf(field);
      if (currentIndex < 0) return;
      searchPanel.value = AddressSearchPanel.error(currentIndex, 'Não foi possível buscar endereços. Tente novamente.');
    }
  }

  String _fallbackToken(int index) {
    _ensureSession(index);
    return _sessionToken!;
  }

  Future<void> _loadSearchBias() async {
    final position = await _locationPermissionService.currentOrLast();
    if (position == null) return;
    _biasLatitude = position.latitude;
    _biasLongitude = position.longitude;
  }

  void _syncCanConfirm() {
    canConfirm.value = points.where((field) => field.hasSelection).length >= minStops;
  }
}

class AddressSearchPanel {
  const AddressSearchPanel({this.index, this.suggestions = const [], this.isLoading = false, this.errorText});

  const AddressSearchPanel.idle() : this();

  const AddressSearchPanel.loading(int index) : this(index: index, isLoading: true);

  factory AddressSearchPanel.results(int index, List<PlacePrediction> suggestions) {
    return AddressSearchPanel(
      index: index,
      suggestions: suggestions,
      errorText: suggestions.isEmpty ? 'Nenhum endereço encontrado.' : null,
    );
  }

  const AddressSearchPanel.error(int index, String message) : this(index: index, errorText: message);

  final int? index;
  final List<PlacePrediction> suggestions;
  final bool isLoading;
  final String? errorText;
}
