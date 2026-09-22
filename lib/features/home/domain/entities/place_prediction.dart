class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
    this.distanceMeters,
  });

  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
  final int? distanceMeters;
}
