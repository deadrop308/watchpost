import 'package:cloud_functions/cloud_functions.dart';

/// Represents a single place suggestion from Google Places autocomplete.
class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

/// Represents the details of a place including coordinates.
class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

/// Handles all Google Places API calls via Cloud Functions proxy.
/// Using Cloud Functions avoids CORS issues on Flutter Web.
class PlacesService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Fetches autocomplete suggestions for the given input text.
  Future<List<PlaceSuggestion>> fetchAutocompleteSuggestions(
      String inputText) async {
    if (inputText.isEmpty) return [];

    try {
      final HttpsCallable callable =
      _functions.httpsCallable('placesAutocomplete');
      final result = await callable.call({'input': inputText});

      final Map<String, dynamic> responseData =
      Map<String, dynamic>.from(result.data);

      if (responseData['status'] != 'OK') return [];

      final List<dynamic> predictions = responseData['predictions'];

      return predictions.map((prediction) {
        return PlaceSuggestion(
          placeId: prediction['place_id'] as String,
          description: prediction['description'] as String,
        );
      }).toList();
    } catch (error) {
      return [];
    }
  }

  /// Fetches the details of a place by its place ID.
  Future<PlaceDetails?> fetchPlaceDetails(String placeId) async {
    try {
      final HttpsCallable callable =
      _functions.httpsCallable('placesDetails');
      final result = await callable.call({'placeId': placeId});

      final Map<String, dynamic> responseData =
      Map<String, dynamic>.from(result.data);

      if (responseData['status'] != 'OK') return null;

      final Map<String, dynamic> placeResult =
      Map<String, dynamic>.from(responseData['result']);
      final Map<String, dynamic> geometry =
      Map<String, dynamic>.from(placeResult['geometry']);
      final Map<String, dynamic> location =
      Map<String, dynamic>.from(geometry['location']);

      return PlaceDetails(
        formattedAddress: placeResult['formatted_address'] as String,
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
      );
    } catch (error) {
      return null;
    }
  }
}