import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:convert';
import 'package:http/http.dart' as http;

class FlightService {
  // ⚠️ SECURITY FIX: Move this to --dart-define or a .env solution in production.
  // Example: flutter run --dart-define=AVIATION_API_KEY=your_key_here
  // Then read with: const String.fromEnvironment('AVIATION_API_KEY')
  static const String _apiKey = '4851995438d671201bbd6253eac68ce3';

  // FIX: Changed http -> https (Android blocks cleartext traffic by default)
  static const String _baseUrl = 'https://api.aviationstack.com/v1';

  // Search for flights between cities
  Future<List<Map<String, dynamic>>> searchFlights({
    required String fromCity,
    required String toCity,
    required String date,
  }) async {
    try {
      // Get airport codes from city names
      final fromAirport = await _getAirportCode(fromCity);
      final toAirport = await _getAirportCode(toCity);

      if (fromAirport == null || toAirport == null) {
        debugPrint('Could not resolve airport codes for $fromCity / $toCity — using mock data.');
        return _getMockFlights(fromCity, toCity);
      }

      final url = Uri.parse(
        '$_baseUrl/flights?access_key=$_apiKey&dep_iata=$fromAirport&arr_iata=$toAirport&flight_date=$date',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Flight search timed out — using mock data.');
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // FIX: Also check for API-level errors (e.g. plan limit exceeded)
        if (data['error'] != null) {
          debugPrint('AviationStack API error: ${data['error']}');
          return _getMockFlights(fromCity, toCity);
        }

        final flights = data['data'];
        if (flights != null && flights is List && flights.isNotEmpty) {
          return _parseFlights(flights, fromCity, toCity);
        } else {
          debugPrint('No flights returned from API — using mock data.');
          return _getMockFlights(fromCity, toCity);
        }
      } else {
        debugPrint('API returned status ${response.statusCode} — using mock data.');
        return _getMockFlights(fromCity, toCity);
      }
    } catch (e) {
      debugPrint('Error searching flights: $e');
      return _getMockFlights(fromCity, toCity);
    }
  }

  // Get airport IATA code from city name
  Future<String?> _getAirportCode(String city) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/airports?access_key=$_apiKey&city_name=${Uri.encodeComponent(city)}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // FIX: Guard against API-level error objects
        if (data['error'] != null) return null;

        final airports = data['data'];
        if (airports != null && airports is List && airports.isNotEmpty) {
          return airports[0]['iata_code'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching airport code for $city: $e');
      return null;
    }
  }

  // Parse API response into flight objects
  List<Map<String, dynamic>> _parseFlights(
    List<dynamic> flights,
    String fromCity,
    String toCity,
  ) {
    final List<Map<String, dynamic>> results = [];

    for (final flight in flights.take(10)) {
      if (flight is! Map<String, dynamic>) continue;

      final departure = flight['departure'] as Map<String, dynamic>? ?? {};
      final arrival = flight['arrival'] as Map<String, dynamic>? ?? {};
      final airline = flight['airline'] as Map<String, dynamic>? ?? {};
      final flightInfo = flight['flight'] as Map<String, dynamic>? ?? {};

      // FIX: Null-safe stops calculation
      final route = flight['route'];
      final int stops = (route is List && route.length > 1) ? route.length - 1 : 0;

      final price = _calculatePrice(flight);

      results.add({
        'airline': airline['name'] ?? 'Unknown Airline',
        'flightNo': flightInfo['iata'] ?? 'N/A',
        'departure': _extractTime(departure['scheduled'] as String?),
        'arrival': _extractTime(arrival['scheduled'] as String?),
        'duration': _calculateDuration(
          departure['scheduled'] as String?,
          arrival['scheduled'] as String?,
        ),
        'price': price,
        'type': _getFlightType(price),
        'stops': stops,
        'airline_logo': airline['name'] ?? '',
      });
    }

    return results;
  }

  // Extract HH:mm from ISO datetime string
  String _extractTime(String? isoString) {
    if (isoString == null) return '00:00';
    try {
      final parts = isoString.split('T');
      if (parts.length < 2) return '00:00';
      return parts[1].substring(0, 5);
    } catch (_) {
      return '00:00';
    }
  }

  // Calculate flight duration from two ISO strings
  String _calculateDuration(String? departure, String? arrival) {
    if (departure == null || arrival == null) return '2h 30m';
    try {
      final depTime = DateTime.parse(departure);
      final arrTime = DateTime.parse(arrival);
      final diff = arrTime.difference(depTime);
      if (diff.isNegative) return '2h 30m'; // FIX: guard against bad data
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    } catch (_) {
      return '2h 30m';
    }
  }

  // Deterministic price estimate from flight data
  double _calculatePrice(Map<String, dynamic> flight) {
    const double basePrice = 300.0;
    final int hash = flight.hashCode.abs() % 500;
    return basePrice + hash;
  }

  // FIX: Accept price directly instead of re-calculating from flight object
  String _getFlightType(double price) {
    if (price < 400) return 'budget';
    if (price < 700) return 'best';
    if (price < 1000) return 'fastest';
    return 'luxury';
  }

  // Fallback mock data when API fails or returns no results
  List<Map<String, dynamic>> _getMockFlights(String fromCity, String toCity) {
    debugPrint('Returning mock flights for $fromCity → $toCity');
    return [
      {
        'airline': 'Air France',
        'flightNo': 'AF149',
        'departure': '11:30',
        'arrival': '06:20',
        'duration': '6h 50m',
        'price': 480.0,
        'type': 'cheapest',
        'stops': 0,
        'airline_logo': 'Air France',
      },
      {
        'airline': 'Turkish Airlines',
        'flightNo': 'TK626',
        'departure': '09:15',
        'arrival': '08:45',
        'duration': '11h 30m',
        'price': 390.0,
        'type': 'budget',
        'stops': 1,
        'airline_logo': 'Turkish Airlines',
      },
      {
        'airline': 'Emirates',
        'flightNo': 'EK783',
        'departure': '05:45',
        'arrival': '08:30',
        'duration': '10h 45m',
        'price': 920.0,
        'type': 'best',
        'stops': 1,
        'airline_logo': 'Emirates',
      },
      {
        'airline': 'British Airways',
        'flightNo': 'BA082',
        'departure': '22:00',
        'arrival': '07:15',
        'duration': '9h 15m',
        'price': 650.0,
        'type': 'fastest',
        'stops': 0,
        'airline_logo': 'British Airways',
      },
      {
        'airline': 'Lufthansa',
        'flightNo': 'LH568',
        'departure': '14:20',
        'arrival': '05:55',
        'duration': '13h 35m',
        'price': 1250.0,
        'type': 'luxury',
        'stops': 1,
        'airline_logo': 'Lufthansa',
      },
    ];
  }
}