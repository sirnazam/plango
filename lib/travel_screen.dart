import 'flight_service.dart';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_screen.dart';

// ─────────────────────────────────────────────
//  CONSTANTS (Your existing + enhanced)
// ─────────────────────────────────────────────
const kTeal = Color(0xFF0EADBB);
const kTealDark = Color(0xFF0A8A96);
const kTealLight = Color(0xFFE1F5EE);
const kBackground = Color(0xFFEAF4F8);
const kCard = Colors.white;
const kTextPrimary = Color(0xFF1A2A2F);
const kTextSecondary = Color(0xFF7A9098);
const kAmber = Color(0xFFF59E0B);
const kGreen = Color(0xFF22C55E);

// ─────────────────────────────────────────────
//  MODELS (Your existing + Interstate models)
// ─────────────────────────────────────────────

// Your existing models
class CountryDestination {
  final String code;
  final String name;
  final String flag;
  final String continent;
  final String currency;
  final List<String> states;

  const CountryDestination({
    required this.code,
    required this.name,
    required this.flag,
    required this.continent,
    required this.currency,
    this.states = const [],
  });
}

class FlightOption {
  final String airline;
  final String flightNo;
  final String departure;
  final String arrival;
  final String duration;
  final double price;
  final String type;
  final int stops;

  const FlightOption({
    required this.airline,
    required this.flightNo,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    required this.type,
    required this.stops,
  });
}

class HotelOption {
  final String name;
  final String location;
  final double pricePerNight;
  final double rating;
  final int reviews;
  final String tier;
  final List<String> amenities;

  const HotelOption({
    required this.name,
    required this.location,
    required this.pricePerNight,
    required this.rating,
    required this.reviews,
    required this.tier,
    required this.amenities,
  });
}

class TravelTransport {
  final String type;
  final String provider;
  final String route;
  final double price;
  final String duration;
  final String icon;

  const TravelTransport({
    required this.type,
    required this.provider,
    required this.route,
    required this.price,
    required this.duration,
    required this.icon,
  });
}

class ActiveBooking {
  final String tripId;
  final String origin;
  final String destination;
  final String flightAirline;
  final String flightNo;
  final String hotelName;
  final String transport;
  final DateTime? departureDate;
  final DateTime? returnDate;

  const ActiveBooking({
    required this.tripId,
    required this.origin,
    required this.destination,
    required this.flightAirline,
    required this.flightNo,
    required this.hotelName,
    required this.transport,
    this.departureDate,
    this.returnDate,
  });
}

// NEW: Interstate models from second file
class TransportMode {
  final int id;
  final String name;
  final String slug;
  final String icon;

  const TransportMode({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  factory TransportMode.fromMap(Map<String, dynamic> m) => TransportMode(
        id: m['id'],
        name: m['name'],
        slug: m['slug'],
        icon: m['icon'] ?? '🚌',
      );
}

class StateModel {
  final int id;
  final String name;
  final String countryCode;

  const StateModel({
    required this.id,
    required this.name,
    required this.countryCode,
  });

  factory StateModel.fromMap(Map<String, dynamic> m) => StateModel(
        id: m['id'],
        name: m['name'],
        countryCode: m['country_code'],
      );
}

class CountryModel {
  final String code;
  final String name;
  final String? flag;
  final String? currency;

  const CountryModel({
    required this.code,
    required this.name,
    this.flag,
    this.currency,
  });

  factory CountryModel.fromMap(Map<String, dynamic> m) => CountryModel(
        code: m['code'],
        name: m['name'],
        flag: m['flag'],
        currency: m['currency'],
      );
}

class InterstateRoute {
  final int routeId;
  final String country;
  final String countryCode;
  final String? countryFlag;
  final String originTerminal;
  final String originCity;
  final String originState;
  final String destinationTerminal;
  final String destinationCity;
  final String destinationState;
  final String operator;
  final double? operatorRating;
  final String? operatorWebsite;
  final String transportMode;
  final String modeSlug;
  final String modeIcon;
  final double? distanceKm;
  final int? durationMinutes;
  final double? priceMin;
  final double? priceMax;
  final String currency;
  final bool isActive;

  const InterstateRoute({
    required this.routeId,
    required this.country,
    required this.countryCode,
    this.countryFlag,
    required this.originTerminal,
    required this.originCity,
    required this.originState,
    required this.destinationTerminal,
    required this.destinationCity,
    required this.destinationState,
    required this.operator,
    this.operatorRating,
    this.operatorWebsite,
    required this.transportMode,
    required this.modeSlug,
    required this.modeIcon,
    this.distanceKm,
    this.durationMinutes,
    this.priceMin,
    this.priceMax,
    required this.currency,
    required this.isActive,
  });

  factory InterstateRoute.fromMap(Map<String, dynamic> m) => InterstateRoute(
        routeId: m['route_id'],
        country: m['country'] ?? '',
        countryCode: m['country_code'] ?? '',
        countryFlag: m['country_flag'],
        originTerminal: m['origin_terminal'] ?? '',
        originCity: m['origin_city'] ?? '',
        originState: m['origin_state'] ?? '',
        destinationTerminal: m['destination_terminal'] ?? '',
        destinationCity: m['destination_city'] ?? '',
        destinationState: m['destination_state'] ?? '',
        operator: m['operator'] ?? '',
        operatorRating: (m['operator_rating'] as num?)?.toDouble(),
        operatorWebsite: m['operator_website'],
        transportMode: m['transport_mode'] ?? '',
        modeSlug: m['mode_slug'] ?? '',
        modeIcon: m['mode_icon'] ?? '🚌',
        distanceKm: (m['distance_km'] as num?)?.toDouble(),
        durationMinutes: m['duration_minutes'],
        priceMin: (m['price_min'] as num?)?.toDouble(),
        priceMax: (m['price_max'] as num?)?.toDouble(),
        currency: m['currency'] ?? 'USD',
        isActive: m['is_active'] ?? true,
      );

  String get durationText {
    if (durationMinutes == null) return '';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

// ─────────────────────────────────────────────
//  SERVICE (NEW: Interstate service)
// ─────────────────────────────────────────────

class TravelService {
  static final _sb = Supabase.instance.client;

  static Future<List<CountryModel>> fetchCountriesWithRoutes() async {
    final res = await _sb
        .from('interstate_routes')
        .select('country_code, countries!inner(code, name, flag, currency)')
        .eq('is_active', true);

    final seen = <String>{};
    final list = <CountryModel>[];
    for (final row in res as List) {
      final c = row['countries'] as Map<String, dynamic>;
      if (seen.add(c['code'] as String)) {
        list.add(CountryModel.fromMap(c));
      }
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  static Future<List<StateModel>> fetchStatesForCountry(String countryCode) async {
    final res = await _sb
        .from('states')
        .select('id, name, country_code')
        .eq('country_code', countryCode)
        .order('name');
    return (res as List).map((e) => StateModel.fromMap(e)).toList();
  }

  static Future<List<TransportMode>> fetchTransportModes() async {
    final res = await _sb
        .from('transport_modes')
        .select('id, name, slug, icon')
        .eq('is_active', true)
        .order('id');
    return (res as List).map((e) => TransportMode.fromMap(e)).toList();
  }

  static Future<List<InterstateRoute>> searchRoutes({
    required String countryCode,
    required int originStateId,
    required int destinationStateId,
    int? transportModeId,
  }) async {
    final originState = await _sb
        .from('states')
        .select('name')
        .eq('id', originStateId)
        .single();
    final destState = await _sb
        .from('states')
        .select('name')
        .eq('id', destinationStateId)
        .single();

    var query = _sb
        .from('v_interstate_routes')
        .select()
        .eq('country_code', countryCode)
        .eq('origin_state', originState['name'])
        .eq('destination_state', destState['name'])
        .eq('is_active', true);

    if (transportModeId != null) {
      query = query.eq('transport_mode_id', transportModeId);
    }

    final res = await query;
    return (res as List).map((e) => InterstateRoute.fromMap(e)).toList();
  }
}

// ─────────────────────────────────────────────
//  MOCK DATA (Your existing)
// ─────────────────────────────────────────────
List<FlightOption> getFlights(String from, String to) => [
  const FlightOption(airline: 'Air France', flightNo: 'AF149', departure: '11:30', arrival: '06:20', duration: '6h 50m', price: 480, type: 'cheapest', stops: 0),
  const FlightOption(airline: 'Turkish Airlines', flightNo: 'TK626', departure: '09:15', arrival: '08:45', duration: '11h 30m', price: 390, type: 'budget', stops: 1),
  const FlightOption(airline: 'Emirates', flightNo: 'EK783', departure: '05:45', arrival: '08:30', duration: '10h 45m', price: 920, type: 'best', stops: 1),
  const FlightOption(airline: 'British Airways', flightNo: 'BA082', departure: '22:00', arrival: '07:15', duration: '9h 15m', price: 650, type: 'fastest', stops: 0),
  const FlightOption(airline: 'Lufthansa', flightNo: 'LH568', departure: '14:20', arrival: '05:55', duration: '13h 35m', price: 1250, type: 'luxury', stops: 1),
];

List<HotelOption> getHotels(String destination) => [
  const HotelOption(name: 'City Budget Inn', location: 'City Center', pricePerNight: 45, rating: 7.2, reviews: 834, tier: 'budget', amenities: ['WiFi', 'Breakfast']),
  const HotelOption(name: 'Comfort Stay Hotel', location: 'Downtown', pricePerNight: 89, rating: 8.1, reviews: 1204, tier: 'budget', amenities: ['WiFi', 'Pool', 'Gym']),
  const HotelOption(name: 'Grand Central Hotel', location: 'City Center', pricePerNight: 145, rating: 8.8, reviews: 2341, tier: 'mid', amenities: ['WiFi', 'Pool', 'Spa', 'Restaurant']),
  const HotelOption(name: 'Marina Boutique Hotel', location: 'Marina District', pricePerNight: 220, rating: 9.0, reviews: 1135, tier: 'mid', amenities: ['WiFi', 'Pool', 'Bar', 'Concierge']),
  const HotelOption(name: 'The Royal Palace Hotel', location: 'Old Town', pricePerNight: 380, rating: 9.2, reviews: 2247, tier: 'luxury', amenities: ['WiFi', 'Pool', 'Spa', 'Butler', 'Fine Dining']),
  const HotelOption(name: 'Presidential Suites', location: 'Business District', pricePerNight: 620, rating: 9.5, reviews: 430, tier: 'luxury', amenities: ['WiFi', 'Private Pool', 'Spa', 'Limo', 'Chef']),
];

List<TravelTransport> getTransport(String destination) => [
  const TravelTransport(type: 'Airport Bus', provider: 'City Express', route: 'Airport → City Center', price: 8, duration: '45 min', icon: '🚌'),
  const TravelTransport(type: 'Metro', provider: 'City Metro', route: 'Airport → Downtown', price: 3, duration: '30 min', icon: '🚇'),
  const TravelTransport(type: 'Taxi', provider: 'City Cab', route: 'Airport → Any Hotel', price: 35, duration: '25 min', icon: '🚕'),
  const TravelTransport(type: 'Ride Share', provider: 'Uber/Bolt', route: 'Door to Door', price: 22, duration: '20-35 min', icon: '🚗'),
  const TravelTransport(type: 'Car Rental', provider: 'Hertz / Avis', route: 'Self Drive · Daily', price: 55, duration: 'All day', icon: '🚙'),
  const TravelTransport(type: 'Train', provider: 'National Rail', route: 'City to City', price: 45, duration: '2h 30m', icon: '🚂'),
  const TravelTransport(type: 'Private Transfer', provider: 'Luxury Transfers', route: 'Airport → Hotel (VIP)', price: 120, duration: '20 min', icon: '🚐'),
];

const List<Map<String, dynamic>> cabinClasses = [
  {'label': 'Economy', 'icon': '💺', 'multiplier': 1.0},
  {'label': 'Business', 'icon': '🛋️', 'multiplier': 2.5},
  {'label': 'First Class', 'icon': '👑', 'multiplier': 4.0},
];

// ─────────────────────────────────────────────
//  MAIN SCREEN (Enhanced with Interstate)
// ─────────────────────────────────────────────
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> with SingleTickerProviderStateMixin {
  // Tab controller for Flights vs Interstate
  late TabController _tabController;

  // Your existing flow state
  int _step = 0;
  CountryDestination? _selectedOriginCountry;
  String? _selectedOriginState;
  CountryDestination? _selectedDestinationCountry;
  FlightOption? _selectedFlight;
  HotelOption? _selectedHotel;
  TravelTransport? _selectedTransport;
  String _flightFilter = 'all';
  String _hotelFilter = 'all';
  String _cabinClass = 'Economy';
  String _mapMode = 'hotels';
  bool _isSelectingOrigin = false;
  bool _isSelectingState = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _countrySearch = '';
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _passengers = 1;
  int _nights = 3;
  List<CountryDestination> _allCountries = [];
  bool _isLoadingCountries = true;
  String _countriesError = '';
  ActiveBooking? _activeBooking;
  bool _isLoadingActiveBooking = true;
  bool _isBooking = false;

  // NEW: Interstate state
  int _interstateStep = 0;
  List<CountryModel> _interstateCountries = [];
  List<StateModel> _interstateStates = [];
  List<TransportMode> _transportModes = [];
  List<InterstateRoute> _interstateResults = [];
  CountryModel? _selectedInterstateCountry;
  StateModel? _interstateOriginState;
  StateModel? _interstateDestState;
  TransportMode? _selectedTransportMode;
  String _interstateModeFilter = 'all';
  bool _loadingInterstateCountries = true;
  bool _loadingInterstateStates = false;
  bool _loadingInterstateResults = false;
  String? _interstateError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCountriesFromSupabase();
    _loadActiveBooking();
    _loadInterstateData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── SECTION LABEL WIDGET ───────────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

 
  // ─── YOUR EXISTING METHODS (unchanged) ────────────────────────────────────
  Future<void> _loadActiveBooking() async {
    setState(() => _isLoadingActiveBooking = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoadingActiveBooking = false);
        return;
      }
      final trips = await Supabase.instance.client
          .from('trips')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);

      if (trips.isEmpty) {
        setState(() {
          _activeBooking = null;
          _isLoadingActiveBooking = false;
        });
        return;
      }
      final trip = trips[0];
      final bookings = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('trip_id', trip['id']);

      String flightAirline = '';
      String flightNo = '';
      String hotelName = '';
      String transport = '';

      for (final b in bookings) {
        if (b['type'] == 'flight') {
          final meta = b['metadata'] as Map<String, dynamic>? ?? {};
          flightAirline = meta['airline'] ?? b['provider'] ?? '';
          flightNo = meta['flight_no'] ?? '';
        } else if (b['type'] == 'hotel') {
          hotelName = b['provider'] ?? '';
        } else if (b['type'] == 'transport') {
          transport = b['provider'] ?? '';
        }
      }

      setState(() {
        _activeBooking = ActiveBooking(
          tripId: trip['id'],
          origin: trip['origin'] ?? '',
          destination: trip['destination'] ?? '',
          flightAirline: flightAirline,
          flightNo: flightNo,
          hotelName: hotelName,
          transport: transport,
          departureDate: trip['start_date'] != null
              ? DateTime.tryParse(trip['start_date'])
              : null,
          returnDate: trip['end_date'] != null
              ? DateTime.tryParse(trip['end_date'])
              : null,
        );
        _isLoadingActiveBooking = false;
      });
    } catch (e) {
      debugPrint('Error loading active booking: $e');
      setState(() => _isLoadingActiveBooking = false);
    }
  }

  Future<void> _loadCountriesFromSupabase() async {
    setState(() {
      _isLoadingCountries = true;
      _countriesError = '';
    });
    try {
      developer.log('Attempting to load countries from Supabase...');
      final response = await Supabase.instance.client
          .from('countries')
          .select()
          .order('name');
      final List<CountryDestination> loadedCountries = [];
      for (var item in response) {
        loadedCountries.add(CountryDestination(
          code: item['code'],
          name: item['name'],
          flag: item['flag'] ?? '🌍',
          continent: item['continent'],
          currency: item['currency'] ?? 'USD',
          states: item['states'] != null
              ? List<String>.from(item['states'])
              : [],
        ));
      }
      setState(() {
        _allCountries = loadedCountries;
        _isLoadingCountries = false;
      });
    } catch (e) {
      setState(() {
        _countriesError = e.toString();
        _isLoadingCountries = false;
      });
    }
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          destinationCity: _selectedDestinationCountry?.name ?? 'Paris',
          selectedHotel: _selectedHotel?.name,
          meetingVenue: 'Conference Center',
        ),
      ),
    );
  }

  void _openOriginPicker() {
    setState(() {
      _isSelectingOrigin = true;
      _isSelectingState = false;
      _step = 1;
    });
  }

  void _openDestinationPicker() {
    setState(() {
      _isSelectingOrigin = false;
      _isSelectingState = false;
      _step = 1;
    });
  }

  Future<void> _openGoogleFlights() async {
    final from = _selectedOriginState != null
        ? '$_selectedOriginState, ${_selectedOriginCountry?.name ?? ''}'
        : _selectedOriginCountry?.name ?? 'Lagos';
    final to = _selectedDestinationCountry?.name ?? 'Paris';
    final date = _departureDate != null
        ? '${_departureDate!.year}-${_departureDate!.month.toString().padLeft(2, '0')}-${_departureDate!.day.toString().padLeft(2, '0')}'
        : '';
    final query = 'flights from ${Uri.encodeComponent(from)} to ${Uri.encodeComponent(to)}${date.isNotEmpty ? ' on $date' : ''}';
    final url = Uri.parse('https://www.google.com/travel/flights?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open Google Flights', Colors.red);
    }
  }

  Future<void> _openBookingCom() async {
    final dest = _selectedDestinationCountry?.name ?? 'Paris';
    final url = Uri.parse(
      'https://www.booking.com/search.html?ss=${Uri.encodeComponent(dest)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open Booking.com', Colors.red);
    }
  }

  Future<void> _confirmAndSaveBooking() async {
    if (_selectedDestinationCountry == null) {
      _showSnack('Please select a destination first', Colors.orange);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showSnack('Please log in to book', Colors.orange);
      return;
    }

    setState(() => _isBooking = true);
    _showSnack('Confirming your booking...', kTeal);

    try {
      final origin = _selectedOriginState != null
          ? '$_selectedOriginState, ${_selectedOriginCountry?.name ?? ''}'
          : _selectedOriginCountry?.name ?? '';

      final tripResponse = await Supabase.instance.client
          .from('trips')
          .insert({
            'user_id': user.id,
            'origin': origin,
            'destination': _selectedDestinationCountry!.name,
            'start_date': _departureDate?.toIso8601String(),
            'end_date': _returnDate?.toIso8601String(),
            'status': 'Upcoming',
          })
          .select()
          .single();

      final tripId = tripResponse['id'];

      if (_selectedFlight != null) {
        final cabinMultiplier = cabinClasses
            .firstWhere((c) => c['label'] == _cabinClass)['multiplier'] as double;
        await Supabase.instance.client.from('bookings').insert({
          'user_id': user.id,
          'trip_id': tripId,
          'type': 'Flight',
          'provider': _selectedFlight!.airline,
          'confirmation_code': _selectedFlight!.flightNo,
          'booking_url': 'https://www.google.com/travel/flights',
          'metadata': {
            'airline': _selectedFlight!.airline,
            'flight_no': _selectedFlight!.flightNo,
            'departure': _selectedFlight!.departure,
            'arrival': _selectedFlight!.arrival,
            'duration': _selectedFlight!.duration,
            'price': (_selectedFlight!.price * cabinMultiplier * _passengers).toStringAsFixed(0),
            'cabin_class': _cabinClass,
            'passengers': _passengers,
            'stops': _selectedFlight!.stops,
            'origin': origin,
            'destination': _selectedDestinationCountry!.name,
          },
        });
      }

      if (_selectedHotel != null) {
        await Supabase.instance.client.from('bookings').insert({
          'user_id': user.id,
          'trip_id': tripId,
          'type': 'Hotel',
          'provider': _selectedHotel!.name,
          'confirmation_code': 'HTL-${DateTime.now().millisecondsSinceEpoch}',
          'booking_url': 'https://www.booking.com',
          'metadata': {
            'hotel': _selectedHotel!.name,
            'location': _selectedHotel!.location,
            'price_per_night': _selectedHotel!.pricePerNight,
            'nights': _nights,
            'total': (_selectedHotel!.pricePerNight * _nights).toStringAsFixed(0),
            'tier': _selectedHotel!.tier,
            'destination': _selectedDestinationCountry!.name,
          },
        });
      }

      if (_selectedTransport != null) {
        await Supabase.instance.client.from('bookings').insert({
          'user_id': user.id,
          'trip_id': tripId,
          'type': 'Transport',
          'provider': _selectedTransport!.provider,
          'confirmation_code': 'TRN-${DateTime.now().millisecondsSinceEpoch}',
          'booking_url': '',
          'metadata': {
            'type': _selectedTransport!.type,
            'provider': _selectedTransport!.provider,
            'route': _selectedTransport!.route,
            'price': _selectedTransport!.price,
            'duration': _selectedTransport!.duration,
          },
        });
      }

      setState(() => _isBooking = false);
      _showSnack('Booking confirmed! 🎉', kGreen);
      await _loadActiveBooking();
      if (mounted) setState(() => _step = 0);
    } catch (e) {
      setState(() => _isBooking = false);
      _showSnack('Booking failed: $e', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatPrice(double price) => '\$${price.toStringAsFixed(0)}';

  Color _tierColor(String tier) {
    switch (tier) {
      case 'budget': return kGreen;
      case 'mid': return kAmber;
      case 'luxury': return const Color(0xFF8B5CF6);
      default: return kTeal;
    }
  }

  Color _tierBg(String tier) {
    switch (tier) {
      case 'budget': return const Color(0xFFDCFCE7);
      case 'mid': return const Color(0xFFFEF3C7);
      case 'luxury': return const Color(0xFFEDE9FE);
      default: return kTealLight;
    }
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'budget': return '💚 Budget';
      case 'mid': return '🔶 Mid-Range';
      case 'luxury': return '💜 Luxury';
      case 'cheapest': return '💚 Cheapest';
      case 'fastest': return '⚡ Fastest';
      case 'best': return '⭐ Best Value';
      default: return tier;
    }
  }

  double _flightPriceWithCabin(double basePrice) {
    final multiplier = cabinClasses
        .firstWhere((c) => c['label'] == _cabinClass)['multiplier'] as double;
    return basePrice * multiplier * _passengers;
  }

  double _totalCost() {
    final f = _selectedFlight != null ? _flightPriceWithCabin(_selectedFlight!.price) : 0;
    final h = (_selectedHotel?.pricePerNight ?? 0) * _nights;
    final t = _selectedTransport?.price ?? 0;
    return f + h + t;
  }

  // ─── INTERSTATE METHODS ───────────────────────────────────────────────────
  Future<void> _selectInterstateCountry(CountryModel c) async {
    setState(() {
      _selectedInterstateCountry = c;
      _interstateOriginState = null;
      _interstateDestState = null;
      _interstateStates = [];
      _loadingInterstateStates = true;
      _interstateStep = 1;
    });
    try {
      final data = await TravelService.fetchStatesForCountry(c.code);
      setState(() {
        _interstateStates = data;
        _loadingInterstateStates = false;
      });
    } catch (e) {
      setState(() {
        _interstateError = 'Failed to load states';
        _loadingInterstateStates = false;
      });
    }
  }

  Future<void> _searchInterstateRoutes() async {
    if (_interstateOriginState == null || _interstateDestState == null) return;
    setState(() {
      _loadingInterstateResults = true;
      _interstateResults = [];
      _interstateStep = 2;
    });
    try {
      final data = await TravelService.searchRoutes(
        countryCode: _selectedInterstateCountry!.code,
        originStateId: _interstateOriginState!.id,
        destinationStateId: _interstateDestState!.id,
        transportModeId: _selectedTransportMode?.id,
      );
      setState(() {
        _interstateResults = data;
        _loadingInterstateResults = false;
      });
    } catch (e) {
      setState(() {
        _interstateError = 'Search failed: $e';
        _loadingInterstateResults = false;
      });
    }
  }

  void _resetInterstate() => setState(() {
        _interstateStep = 0;
        _selectedInterstateCountry = null;
        _interstateOriginState = null;
        _interstateDestState = null;
        _interstateResults = [];
        _interstateError = null;
        _interstateModeFilter = 'all';
        _selectedTransportMode = null;
      });

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildMainHeader(),
            _buildTabToggle(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildFlightsFlow(),
                  _buildInterstateFlow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAIN HEADER ──────────────────────────────────────────────────────────
  Widget _buildMainHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          const Text(
            'My Travel',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_outlined, color: kTextPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  // ─── TAB TOGGLE ───────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: kTextSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: '✈️  Flights'),
            Tab(text: '🚌  Interstate'),
          ],
        ),
      ),
    );
  }

  // ─── FLIGHTS FLOW (Your existing, wrapped) ────────────────────────────────
  Widget _buildFlightsFlow() {
    return _buildCurrentStep();
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildHomeStep();
      case 1: return _isSelectingState ? _buildStatePickerStep() : _buildCountryPickerStep();
      case 2: return _buildFlightsStep();
      case 3: return _buildHotelsStep();
      case 4: return _buildTransportStep();
      case 5: return _buildMapStep();
      case 6: return _buildConfirmStep();
      default: return _buildHomeStep();
    }
  }

  // ─── INTERSTATE FLOW (New) ────────────────────────────────────────────────
  Widget _buildInterstateFlow() {
    return Column(
      children: [
        _buildInterstateStepBar(),
        Expanded(
          child: _interstateError != null
              ? _buildInterstateError()
              : _interstateStep == 0
                  ? _buildInterstateCountryPicker()
                  : _interstateStep == 1
                      ? _buildInterstateStatePicker()
                      : _buildInterstateResults(),
        ),
      ],
    );
  }

  Widget _buildInterstateStepBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          if (_interstateStep > 0)
            GestureDetector(
              onTap: () => setState(() {
                _interstateStep = _interstateStep - 1;
                if (_interstateStep == 0) {
                  _selectedInterstateCountry = null;
                  _interstateOriginState = null;
                  _interstateDestState = null;
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: kTextPrimary),
              ),
            ),
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _interstateStep;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? kTeal : kTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            ['Country', 'Route', 'Results'][_interstateStep],
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  // ADD THIS MISSING METHOD HERE:
  Widget _buildInterstateCountryPicker() {
    if (_loadingInterstateCountries) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    if (_interstateError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(_interstateError!, style: const TextStyle(color: kTextPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInterstateData,
              style: ElevatedButton.styleFrom(backgroundColor: kTeal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_interstateCountries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚌', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No countries available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Interstate routes will appear here\nonce data is available',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInterstateData,
              style: ElevatedButton.styleFrom(backgroundColor: kTeal),
              child: const Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Country', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary)),
              SizedBox(height: 4),
              Text('Countries with interstate routes available', style: TextStyle(fontSize: 13, color: kTextSecondary)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _interstateCountries.length,
            itemBuilder: (ctx, i) {
              final c = _interstateCountries[i];
              return _buildInterstateCountryTile(c);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadInterstateData() async {
    setState(() {
      _loadingInterstateCountries = true;
      _interstateError = null;
    });
    
    try {
      final data = await TravelService.fetchCountriesWithRoutes();
      
      setState(() {
        _interstateCountries = data;
        _loadingInterstateCountries = false;
      });
      
      if (data.isNotEmpty) {
        final modes = await TravelService.fetchTransportModes();
        setState(() => _transportModes = modes);
      }
    } catch (e) {
      setState(() {
        _interstateError = 'Failed to load: $e';
        _loadingInterstateCountries = false;
      });
    }
  }

  Widget _buildInterstateCountryTile(CountryModel country) {
    return GestureDetector(
      onTap: () => _selectInterstateCountry(country),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(country.flag ?? '🌍', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(country.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextPrimary)),
                  Text(
                    '${country.code}${country.currency != null ? ' · ${country.currency}' : ''}',
                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInterstateStatePicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kTeal, kTealDark]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(_selectedInterstateCountry?.flag ?? '🌍', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedInterstateCountry?.name ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    Text(
                      _selectedInterstateCountry?.currency != null ? 'Currency: ${_selectedInterstateCountry!.currency}' : '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _resetInterstate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_loadingInterstateStates)
            const Center(child: CircularProgressIndicator(color: kTeal))
          else ...[
            // Transport mode filter
            const Text('Transport Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextPrimary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildModeChip(
                    label: 'All',
                    icon: '🔀',
                    selected: _interstateModeFilter == 'all',
                    onTap: () => setState(() {
                      _interstateModeFilter = 'all';
                      _selectedTransportMode = null;
                    }),
                  ),
                  ..._transportModes.map((m) => _buildModeChip(
                        label: m.name.split(' ').first,
                        icon: m.icon,
                        selected: _interstateModeFilter == m.slug,
                        onTap: () => setState(() {
                          _interstateModeFilter = m.slug;
                          _selectedTransportMode = m;
                        }),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Origin state
            const Text('From (Origin State)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextPrimary)),
            const SizedBox(height: 10),
            _buildStateDropdown(
              hint: 'Select origin state',
              states: _interstateStates,
              selected: _interstateOriginState,
              excluded: _interstateDestState,
              onChanged: (s) => setState(() => _interstateOriginState = s),
            ),
            const SizedBox(height: 16),

            // Swap icon
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  final tmp = _interstateOriginState;
                  _interstateOriginState = _interstateDestState;
                  _interstateDestState = tmp;
                }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kTealLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: kTeal.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.swap_vert, color: kTeal, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Destination state
            const Text('To (Destination State)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: kTextPrimary)),
            const SizedBox(height: 10),
            _buildStateDropdown(
              hint: 'Select destination state',
              states: _interstateStates,
              selected: _interstateDestState,
              excluded: _interstateOriginState,
              onChanged: (s) => setState(() => _interstateDestState = s),
            ),
            const SizedBox(height: 28),

            // Search button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_interstateOriginState != null && _interstateDestState != null) ? _searchInterstateRoutes : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  disabledBackgroundColor: kTeal.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  '🔍  Search Routes',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required String icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kTeal : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kTeal : Colors.grey.withOpacity(0.2)),
          boxShadow: selected
              ? [BoxShadow(color: kTeal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : kTextPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDropdown({
    required String hint,
    required List<StateModel> states,
    required StateModel? selected,
    required StateModel? excluded,
    required ValueChanged<StateModel?> onChanged,
  }) {
    final available = states.where((s) => s.id != excluded?.id).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected != null ? kTeal : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StateModel>(
          value: selected,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: kTextSecondary, fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: kTeal),
          items: available
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name, style: const TextStyle(fontSize: 14, color: kTextPrimary)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInterstateResults() {
    if (_loadingInterstateResults) {
      return const Center(child: CircularProgressIndicator(color: kTeal));
    }

    final filtered = _interstateModeFilter == 'all'
        ? _interstateResults
        : _interstateResults.where((r) => r.modeSlug == _interstateModeFilter).toList();

    return Column(
      children: [
        // Search summary bar
        Container(
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kTealLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kTeal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_interstateOriginState?.name} → ${_interstateDestState?.name}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                    ),
                    Text(
                      '${_selectedInterstateCountry?.flag ?? ''} ${_selectedInterstateCountry?.name ?? ''} · ${_interstateResults.length} route${_interstateResults.length != 1 ? 's' : ''} found',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _interstateStep = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),

        // Mode filter chips
        if (_transportModes.isNotEmpty)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _buildModeChip(
                  label: 'All',
                  icon: '🔀',
                  selected: _interstateModeFilter == 'all',
                  onTap: () => setState(() => _interstateModeFilter = 'all'),
                ),
                ..._transportModes.map((m) => _buildModeChip(
                      label: m.name.split(' ').first,
                      icon: m.icon,
                      selected: _interstateModeFilter == m.slug,
                      onTap: () => setState(() => _interstateModeFilter = m.slug),
                    )),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Results list
        Expanded(
          child: filtered.isEmpty
              ? _buildNoInterstateResults()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => InterstateRouteCard(
                    route: filtered[i],
                    currency: _selectedInterstateCountry?.currency,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNoInterstateResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🚌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('No routes found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTextPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Try a different origin/destination\nor transport mode',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _interstateStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: kTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Change Route', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInterstateError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_interstateError ?? 'Something went wrong', style: const TextStyle(color: kTextPrimary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _interstateError = null);
              _loadInterstateData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: kTeal),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── YOUR EXISTING WIDGET METHODS (unchanged) ─────────────────────────────
  Widget _buildHomeStep() {
    return Column(
      children: [
        _buildHeader('My Travel', showBack: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (_isLoadingActiveBooking)
                const Center(child: CircularProgressIndicator())
              else if (_activeBooking != null)
                _buildActiveTripCard()
              else
                _buildNoActiveTripCard(),
              const SizedBox(height: 16),
              _buildAiTipsCard(),
              const SizedBox(height: 16),
              _sectionLabel('Quick Actions'),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _quickAction('✈️', 'Book Flight', () {
                    setState(() {
                      _isSelectingOrigin = true;
                      _isSelectingState = false;
                      _step = 1;
                    });
                  }),
                  _quickAction('🏨', 'Book Hotel', () {
                    setState(() {
                      _isSelectingOrigin = false;
                      _isSelectingState = false;
                      _step = 1;
                    });
                  }),
                  _quickAction('🗺️', 'View Map', _openMap),
                  _quickAction('🚗', 'Transport', () {
                    setState(() {
                      _isSelectingOrigin = false;
                      _isSelectingState = false;
                      _step = 1;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              _sectionLabel('Popular Destinations'),
              const SizedBox(height: 8),
              if (_isLoadingCountries)
                const Center(child: CircularProgressIndicator())
              else if (_countriesError.isNotEmpty)
                Center(child: Text('Error: $_countriesError', style: const TextStyle(color: Colors.red)))
              else
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _allCountries.take(10).map((c) => _destinationChip(c)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard() {
    final b = _activeBooking!;
    final depStr = b.departureDate != null
        ? '${b.departureDate!.day}/${b.departureDate!.month}/${b.departureDate!.year}'
        : '';
    final retStr = b.returnDate != null
        ? '${b.returnDate!.day}/${b.returnDate!.month}/${b.returnDate!.year}'
        : '';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kTeal, kTealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✈️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Active Trip', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Spacer(),
              GestureDetector(
                onTap: _openMap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Text('View Map', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${b.origin} → ${b.destination}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (depStr.isNotEmpty)
            Text('$depStr${retStr.isNotEmpty ? ' – $retStr' : ''}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (b.flightAirline.isNotEmpty)
                _tripStat('✈️', b.flightAirline, b.flightNo),
              if (b.hotelName.isNotEmpty) ...[
                const SizedBox(width: 12),
                _tripStat('🏨', b.hotelName, '$_nights nights'),
              ],
              if (b.transport.isNotEmpty) ...[
                const SizedBox(width: 12),
                _tripStat('🚗', b.transport, 'Transfer'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveTripCard() {
    return GestureDetector(
      onTap: () => setState(() {
        _isSelectingOrigin = true;
        _isSelectingState = false;
        _step = 1;
      }),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kTeal, kTealDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('✈️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('No Active Trip', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Book your first trip!',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Tap here or use Quick Actions below to get started.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripStat(String icon, String title, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildAiTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kTealLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kTeal, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✦', style: TextStyle(color: kTeal, fontSize: 16)),
              SizedBox(width: 6),
              Text('AI Travel Tips', style: TextStyle(color: kTeal, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          _tip('🕐', 'Arrive 3 hours early for international flights'),
          _tip('💶', 'Euro (€). Current rate: 1 USD ≈ 0.92 EUR'),
          _tip('🌍', 'Learn basic phrases of your destination'),
          _tip('🔌', 'Check power plug types before you go'),
        ],
      ),
    );
  }

  Widget _tip(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: kTextPrimary))),
        ],
      ),
    );
  }

  Widget _quickAction(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE4E8), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _destinationChip(CountryDestination c) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDestinationCountry = c;
          _step = 2;
        });
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE4E8), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(c.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(c.name,
                style: const TextStyle(fontSize: 11, color: kTextPrimary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(c.currency, style: const TextStyle(fontSize: 10, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryPickerStep() {
    final filtered = _allCountries
        .where((c) =>
            c.name.toLowerCase().contains(_countrySearch.toLowerCase()) ||
            c.continent.toLowerCase().contains(_countrySearch.toLowerCase()))
        .toList();

    final Map<String, List<CountryDestination>> grouped = {};
    for (final c in filtered) {
      grouped.putIfAbsent(c.continent, () => []).add(c);
    }

    return Column(
      children: [
        _buildHeader(
          _isSelectingOrigin ? 'Resident Country (Origin)' : 'Destination Country',
          showBack: true,
          onBack: () => setState(() => _step = 0),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _countrySearch = v),
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Search country or continent...',
              hintStyle: const TextStyle(fontSize: 13, color: kTextSecondary),
              prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
              filled: true,
              fillColor: kCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDDE4E8), width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDDE4E8), width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: kTeal, width: 1)),
            ),
          ),
        ),
        if (_isLoadingCountries)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_countriesError.isNotEmpty)
          Expanded(child: Center(child: Text('Error: $_countriesError', style: const TextStyle(color: Colors.red))))
        else if (_allCountries.isEmpty)
          const Expanded(child: Center(child: Text('No countries found.')))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: grouped.entries
                  .map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kTextSecondary,
                                    letterSpacing: 0.5)),
                          ),
                          ...entry.value.map((c) => _countryRow(c)),
                          const SizedBox(height: 6),
                        ],
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _countryRow(CountryDestination c) {
    final isOriginSelected = _selectedOriginCountry?.code == c.code;
    final isDestinationSelected = _selectedDestinationCountry?.code == c.code;
    final selected = _isSelectingOrigin ? isOriginSelected : isDestinationSelected;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_isSelectingOrigin) {
            _selectedOriginCountry = c;
            _selectedOriginState = null;
            if (c.states.isNotEmpty) {
              _isSelectingState = true;
            } else {
              if (_selectedDestinationCountry == null) {
                _isSelectingOrigin = false;
                _step = 1;
              } else {
                _step = 2;
              }
            }
          } else {
            _selectedDestinationCountry = c;
            _step = 2;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kTealLight : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kTeal : const Color(0xFFDDE4E8),
              width: selected ? 1 : 0.5),
        ),
        child: Row(
          children: [
            Text(c.flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: kTextPrimary)),
                  Text('${c.continent} · ${c.currency}',
                      style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                ],
              ),
            ),
            if (c.states.isNotEmpty && _isSelectingOrigin)
              const Text('Has states →', style: TextStyle(fontSize: 10, color: kTeal)),
            if (selected)
              const Icon(Icons.check_circle, color: kTeal, size: 20)
            else
              const Icon(Icons.arrow_forward_ios, color: kTextSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatePickerStep() {
    final states = _selectedOriginCountry?.states ?? [];
    final filtered = states.where((s) => s.toLowerCase().contains(_countrySearch.toLowerCase())).toList();

    return Column(
      children: [
        _buildHeader(
          'Select Your State · ${_selectedOriginCountry?.flag ?? ''} ${_selectedOriginCountry?.name ?? ''}',
          showBack: true,
          onBack: () => setState(() {
            _isSelectingState = false;
            _step = 1;
          }),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: TextField(
            onChanged: (v) => setState(() => _countrySearch = v),
            style: const TextStyle(fontSize: 14, color: kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Search state...',
              hintStyle: const TextStyle(fontSize: 13, color: kTextSecondary),
              prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
              filled: true,
              fillColor: kCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDDE4E8), width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDDE4E8), width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: kTeal, width: 1)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedOriginState = null;
              _isSelectingState = false;
              if (_selectedDestinationCountry == null) {
                _isSelectingOrigin = false;
                _step = 1;
              } else {
                _step = 2;
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kTealLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kTeal, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🌍', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('Skip — Search all of ${_selectedOriginCountry?.name ?? ''} flights',
                      style: const TextStyle(color: kTeal, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: states.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No states available for this country.', style: TextStyle(color: kTextSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _isSelectingState = false;
                          if (_selectedDestinationCountry == null) {
                            _isSelectingOrigin = false;
                            _step = 1;
                          } else {
                            _step = 2;
                          }
                        }),
                        style: ElevatedButton.styleFrom(backgroundColor: kTeal),
                        child: const Text('Continue anyway', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final state = filtered[index];
                    final isSelected = _selectedOriginState == state;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedOriginState = state;
                        _isSelectingState = false;
                        if (_selectedDestinationCountry == null) {
                          _isSelectingOrigin = false;
                          _step = 1;
                        } else {
                          _step = 2;
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? kTealLight : kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isSelected ? kTeal : const Color(0xFFDDE4E8),
                              width: isSelected ? 1 : 0.5),
                        ),
                        child: Row(
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(state,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: kTextPrimary)),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: kTeal, size: 20)
                            else
                              const Icon(Icons.arrow_forward_ios, color: kTextSecondary, size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFlightsStep() {
    if (_selectedOriginCountry == null || _selectedDestinationCountry == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Please select both origin and destination'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {
                _isSelectingOrigin = true;
                _isSelectingState = false;
                _step = 1;
              }),
              style: ElevatedButton.styleFrom(backgroundColor: kTeal),
              child: const Text('Select Locations', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final originLabel = _selectedOriginState != null
        ? '$_selectedOriginState, ${_selectedOriginCountry!.name}'
        : _selectedOriginCountry!.name;

    return Column(
      children: [
        _buildHeader('Flights', showBack: true, onBack: () => setState(() => _step = 0)),
        _buildRouteBar(originLabel),
        _buildCabinClassSelector(),
        _buildFilterRow(
          options: const ['all', 'cheap', 'luxury'],
          labels: const ['All Flights', '💚 Cheapest First', '💜 Premium First'],
          selected: _flightFilter,
          onSelect: (v) => setState(() => _flightFilter = v),
        ),
        _aiSuggestionBanner(
          '✦ Searching real flights from ${_selectedOriginCountry?.name ?? "origin"} → ${_selectedDestinationCountry?.name ?? "destination"}',
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _searchRealFlights(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              final flights = snapshot.data ?? [];
              List<Map<String, dynamic>> filtered;
              
              if (_flightFilter == 'cheap') {
                filtered = List.from(flights)..sort((a, b) => a['price'].compareTo(b['price']));
              } else if (_flightFilter == 'luxury') {
                filtered = List.from(flights)..sort((a, b) => b['price'].compareTo(a['price']));
              } else {
                filtered = flights;
              }
              
              if (flights.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_land, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No flights found for this route'),
                      SizedBox(height: 8),
                      Text('Try different dates or destinations', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                children: [
                  ...filtered.map((f) => _buildRealFlightCard(f, originLabel)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openGoogleFlights,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kTealLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kTeal, width: 0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('✈️', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 8),
                          Text('Search More Flights on Google →',
                              style: TextStyle(color: kTeal, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_selectedFlight != null)
          _buildBottomBar('Continue to Hotels', () => setState(() => _step = 3)),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _searchRealFlights() async {
    final flightService = FlightService();
    final date = _departureDate ?? DateTime.now().add(const Duration(days: 7));
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return await flightService.searchFlights(
      fromCity: _selectedOriginCountry!.name,
      toCity: _selectedDestinationCountry!.name,
      date: dateStr,
    );
  }

  Widget _buildRealFlightCard(Map<String, dynamic> f, String originLabel) {
    final isSelected = _selectedFlight?.flightNo == f['flightNo'];
    final cabinMultiplier = cabinClasses
        .firstWhere((c) => c['label'] == _cabinClass)['multiplier'] as double;
    final totalPrice = (f['price'] as double) * cabinMultiplier * _passengers;
    
    final flightOption = FlightOption(
      airline: f['airline'],
      flightNo: f['flightNo'],
      departure: f['departure'],
      arrival: f['arrival'],
      duration: f['duration'],
      price: f['price'],
      type: f['type'],
      stops: f['stops'],
    );

    return GestureDetector(
      onTap: () => setState(() => _selectedFlight = flightOption),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kTealLight : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? kTeal : const Color(0xFFDDE4E8),
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: kBackground,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Center(child: Text('✈️', style: TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f['airline'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                      Text('${f['flightNo']} · $_cabinClass',
                          style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatPrice(totalPrice),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTeal)),
                    Text('$_passengers pax · $_cabinClass',
                        style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['departure'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                  Text(originLabel,
                      style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                ]),
                Expanded(
                  child: Column(children: [
                    Text(f['duration'],
                        style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                    Row(children: [
                      Expanded(child: Container(height: 1, color: const Color(0xFFDDE4E8))),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('✈️', style: TextStyle(fontSize: 12))),
                      Expanded(child: Container(height: 1, color: const Color(0xFFDDE4E8))),
                    ]),
                    Text(f['stops'] == 0 ? 'Non-stop' : '${f['stops']} stop',
                        style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(f['arrival'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
                  Text(_selectedDestinationCountry?.name ?? '',
                      style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _badge(_tierLabel(f['type']), _tierBg(f['type']), _tierColor(f['type'])),
                const Spacer(),
                if (isSelected)
                  GestureDetector(
                    onTap: _openGoogleFlights,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Book on Google →',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  _pill('Select', kBackground, kTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabinClassSelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cabinClasses.map((c) {
          final active = _cabinClass == c['label'];
          return GestureDetector(
            onTap: () => setState(() => _cabinClass = c['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? kTeal : kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? kTeal : const Color(0xFFCDD8DC),
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Text(c['icon'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(c['label'],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : kTextSecondary)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteBar(String originLabel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4E8), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _openOriginPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From', style: TextStyle(fontSize: 10, color: kTextSecondary)),
                  Row(
                    children: [
                      Text(_selectedOriginCountry?.flag ?? '🌍', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          originLabel,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: kTeal, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: kTealLight, shape: BoxShape.circle),
            child: const Icon(Icons.swap_horiz, color: kTeal, size: 20),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _openDestinationPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('To', style: TextStyle(fontSize: 10, color: kTextSecondary)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_selectedDestinationCountry?.flag ?? '🌍', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedDestinationCountry?.name ?? 'Select Destination',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: kTeal, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsStep() {
    final hotels = getHotels(_selectedDestinationCountry?.name ?? '');
    final filtered = _hotelFilter == 'all'
        ? hotels
        : hotels.where((h) => h.tier == _hotelFilter).toList();

    return Column(
      children: [
        _buildHeader(
          'Hotels · ${_selectedDestinationCountry?.flag ?? ''} ${_selectedDestinationCountry?.name ?? ''}',
          showBack: true,
          onBack: () => setState(() => _step = 2),
        ),
        _buildFilterRow(
          options: const ['all', 'budget', 'mid', 'luxury'],
          labels: const ['All', '💚 Budget', '🔶 Mid', '💜 Luxury'],
          selected: _hotelFilter,
          onSelect: (v) => setState(() => _hotelFilter = v),
        ),
        _aiSuggestionBanner(
            '✦ AI Pick: Grand Central Hotel — best balance of price & rating at \$145/night'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            children: [
              ...filtered.map((h) => _buildHotelCard(h)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openBookingCom,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kTealLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTeal, width: 0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏨', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('Search Real Hotels on Booking.com →',
                          style: TextStyle(
                              color: kTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openMap,
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: kTealLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kTeal, width: 0.5)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🗺️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('View Hotels on Map',
                          style: TextStyle(
                              color: kTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedFlight != null)
          _buildBottomBar('Continue to Transport', () => setState(() => _step = 4)),
      ],
    );
  }

  Widget _buildHotelCard(HotelOption h) {
    final isSelected = _selectedHotel?.name == h.name;
    return GestureDetector(
      onTap: () => setState(() => _selectedHotel = h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kTealLight : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? kTeal : const Color(0xFFDDE4E8),
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: _tierBg(h.tier),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                      child: Text(
                          h.tier == 'luxury'
                              ? '🏰'
                              : h.tier == 'mid'
                                  ? '🏩'
                                  : '🏠',
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary)),
                      Text('📍 ${h.location}',
                          style: const TextStyle(
                              fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatPrice(h.pricePerNight),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTeal)),
                    const Text('/night',
                        style: TextStyle(
                            fontSize: 10, color: kTextSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _starRating(h.rating),
                const SizedBox(width: 6),
                Text('${h.rating}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary)),
                Text(' (${h.reviews} reviews)',
                    style: const TextStyle(
                        fontSize: 11, color: kTextSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _badge(_tierLabel(h.tier), _tierBg(h.tier),
                    _tierColor(h.tier)),
                ...h.amenities.take(3).map((a) => _badge(
                    a,
                    const Color(0xFFF1F5F9),
                    kTextSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                        '$_nights nights = ${_formatPrice(h.pricePerNight * _nights)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: kTextPrimary))),
                if (isSelected)
                  GestureDetector(
                    onTap: _openBookingCom,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: kTeal,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('Book on Booking.com →',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  )
                else
                  _pill('Select', kBackground, kTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _starRating(double rating) {
    final full = rating ~/ 2;
    return Row(
        children: List.generate(
            5,
            (i) => Icon(i < full ? Icons.star : Icons.star_border,
                color: kAmber, size: 14)));
  }

  Widget _buildTransportStep() {
    final transport = getTransport(_selectedDestinationCountry?.name ?? '');
    return Column(
      children: [
        _buildHeader(
          'Transport · ${_selectedDestinationCountry?.flag ?? ''} ${_selectedDestinationCountry?.name ?? ''}',
          showBack: true,
          onBack: () => setState(() => _step = 3),
        ),
        _aiSuggestionBanner(
            '✦ AI Pick: City Metro at \$3 is cheapest. Car Rental at \$55/day for full flexibility.'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
            children: [
              ...transport.map((t) => _buildTransportCard(t)),
              GestureDetector(
                onTap: _openMap,
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: kTealLight,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: kTeal, width: 0.5)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🗺️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Text('View Transport on Map',
                          style: TextStyle(
                              color: kTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomBar('Review & Confirm Booking',
            () => setState(() => _step = 6)),
      ],
    );
  }

  Widget _buildTransportCard(TravelTransport t) {
    final isSelected = _selectedTransport?.provider == t.provider;
    return GestureDetector(
      onTap: () => setState(() => _selectedTransport = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? kTealLight : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? kTeal : const Color(0xFFDDE4E8),
              width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(t.icon,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.type,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary)),
                  Text(t.provider,
                      style: const TextStyle(
                          fontSize: 11, color: kTextSecondary)),
                  Text(t.route,
                      style: const TextStyle(
                          fontSize: 11, color: kTextSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatPrice(t.price),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTeal)),
                Text(t.duration,
                    style: const TextStyle(
                        fontSize: 10, color: kTextSecondary)),
                const SizedBox(height: 4),
                if (isSelected)
                  _pill('✓', kTeal, Colors.white)
                else
                  _pill('Pick', kBackground, kTeal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapStep() {
    return Column(
      children: [
        _buildHeader(
          _mapMode == 'hotels'
              ? 'Hotels Map · ${_selectedDestinationCountry?.name ?? ""}'
              : 'Transport Map · ${_selectedDestinationCountry?.name ?? ""}',
          showBack: true,
          onBack: () =>
              setState(() => _step = _mapMode == 'hotels' ? 3 : 4),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: Row(
            children: [
              _tabToggle('Hotels', _mapMode == 'hotels',
                  () => setState(() => _mapMode = 'hotels')),
              const SizedBox(width: 8),
              _tabToggle('Transport', _mapMode == 'transport',
                  () => setState(() => _mapMode = 'transport')),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _buildSimulatedMap(),
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildMapBottomSheet()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatedMap() {
    final items = _mapMode == 'hotels'
        ? getHotels(_selectedDestinationCountry?.name ?? '')
        : getTransport(_selectedDestinationCountry?.name ?? '');

    return Container(
      color: const Color(0xFFE8F4F0),
      child: Stack(
        children: [
          CustomPaint(
              painter: _MapGridPainter(), child: Container()),
          ...List.generate(items.length, (i) {
            final positions = [
              const Offset(0.25, 0.30),
              const Offset(0.55, 0.20),
              const Offset(0.70, 0.45),
              const Offset(0.35, 0.55),
              const Offset(0.60, 0.65),
              const Offset(0.20, 0.70),
              const Offset(0.80, 0.30),
            ];
            final pos = positions[i % positions.length];
            return Positioned(
              left: MediaQuery.of(context).size.width * pos.dx - 20,
              top: (MediaQuery.of(context).size.height * 0.4) * pos.dy,
              child: _mapPin(items[i]),
            );
          }),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🗺️', style: TextStyle(fontSize: 40)),
                SizedBox(height: 8),
                Text('Tap pins to see details',
                    style:
                        TextStyle(fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPin(dynamic item) {
    String label;
    Color color;
    if (item is HotelOption) {
      label = item.name.split(' ').first;
      color = _tierColor(item.tier);
    } else if (item is TravelTransport) {
      label = item.type;
      color = kTeal;
    } else {
      label = '';
      color = kTeal;
    }

    return GestureDetector(
      onTap: () {
        if (item is HotelOption) {
          setState(() => _selectedHotel = item);
          _showSnack(
              '${item.name} — \$${item.pricePerNight}/night', kTeal);
        } else if (item is TravelTransport) {
          setState(() => _selectedTransport = item);
          _showSnack('${item.type} — \$${item.price}', kTeal);
        }
      },
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
          Container(width: 2, height: 8, color: color),
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildMapBottomSheet() {
    final items = _mapMode == 'hotels'
        ? getHotels(_selectedDestinationCountry?.name ?? '')
            .take(3)
            .toList()
        : getTransport(_selectedDestinationCountry?.name ?? '')
            .take(3)
            .toList();

    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDE4E8),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: items.map((item) {
                if (item is HotelOption) return _mapHotelChip(item);
                if (item is TravelTransport) {
                  return _mapTransportChip(item);
                }
                return const SizedBox();
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapHotelChip(HotelOption h) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedHotel = h;
        _step = 3;
      }),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFDDE4E8), width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.name,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(h.location,
                style: const TextStyle(
                    fontSize: 10, color: kTextSecondary)),
            const Spacer(),
            Text('${_formatPrice(h.pricePerNight)}/night',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTeal)),
            _badge(_tierLabel(h.tier), _tierBg(h.tier),
                _tierColor(h.tier)),
          ],
        ),
      ),
    );
  }

  Widget _mapTransportChip(TravelTransport t) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTransport = t;
        _step = 4;
      }),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFFDDE4E8), width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t.icon} ${t.type}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary)),
            Text(t.provider,
                style: const TextStyle(
                    fontSize: 10, color: kTextSecondary)),
            const Spacer(),
            Text(_formatPrice(t.price),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTeal)),
            Text(t.duration,
                style: const TextStyle(
                    fontSize: 10, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmStep() {
    final originLabel = _selectedOriginState != null
        ? '$_selectedOriginState, ${_selectedOriginCountry?.name ?? ''}'
        : _selectedOriginCountry?.name ?? '?';

    return Column(
      children: [
        _buildHeader('Review Booking',
            showBack: true,
            onBack: () => setState(() => _step = 4)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [kTeal, kTealDark]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trip Summary',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '$originLabel → ${_selectedDestinationCountry?.name ?? "?"}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_selectedDestinationCountry?.flag ?? ''} ${_selectedDestinationCountry?.continent ?? ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(),
              const SizedBox(height: 12),
              if (_selectedFlight != null) ...[
                _sectionLabel('Selected Flight'),
                _confirmItem(
                  '✈️',
                  '${_selectedFlight!.airline} · $_cabinClass',
                  '${_selectedFlight!.departure} → ${_selectedFlight!.arrival} · ${_selectedFlight!.duration} · $_passengers pax',
                  _formatPrice(_flightPriceWithCabin(_selectedFlight!.price)),
                ),
              ],
              if (_selectedHotel != null) ...[
                _sectionLabel('Selected Hotel'),
                _confirmItem(
                  _selectedHotel!.tier == 'luxury' ? '🏰' : '🏨',
                  _selectedHotel!.name,
                  '${_selectedHotel!.location} · $_nights nights',
                  _formatPrice(_selectedHotel!.pricePerNight * _nights),
                ),
              ],
              if (_selectedTransport != null) ...[
                _sectionLabel('Selected Transport'),
                _confirmItem(
                  _selectedTransport!.icon,
                  _selectedTransport!.type,
                  _selectedTransport!.route,
                  _formatPrice(_selectedTransport!.price),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: kTealLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTeal, width: 0.5)),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Total Estimated Cost',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary))),
                    Text(_formatPrice(_totalCost()),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: kTeal)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isBooking ? null : _confirmAndSaveBooking,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      color: _isBooking
                          ? kTeal.withOpacity(0.6)
                          : kTeal,
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: _isBooking
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Confirming Booking...',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        : const Text('✅ Confirm & Save Booking',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openGoogleFlights,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTeal, width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✈️', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Book Flight on Google Flights →',
                          style: TextStyle(
                              color: kTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _openBookingCom,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kTeal, width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🏨', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('Book Hotel on Booking.com →',
                          style: TextStyle(
                              color: kTeal,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _step = 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDDE4E8), width: 0.5)),
                  child: const Center(
                      child: Text('Save for Later',
                          style: TextStyle(
                              color: kTextSecondary, fontSize: 15))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFFDDE4E8), width: 0.5)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _dateField('Departure', _departureDate,
                      () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)));
                if (d != null && mounted) {
                  setState(() => _departureDate = d);
                }
              })),
              const SizedBox(width: 10),
              Expanded(
                  child: _dateField('Return', _returnDate, () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)));
                if (d != null && mounted) {
                  setState(() {
                    _returnDate = d;
                    if (_departureDate != null) {
                      _nights =
                          d.difference(_departureDate!).inDays;
                    }
                  });
                }
              })),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Passengers',
                  style: TextStyle(
                      fontSize: 13, color: kTextPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(
                    () { if (_passengers > 1) _passengers--; }),
                child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: kBackground, shape: BoxShape.circle),
                    child: const Icon(Icons.remove,
                        size: 16, color: kTeal)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$_passengers',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary)),
              ),
              GestureDetector(
                onTap: () => setState(() => _passengers++),
                child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: kTeal, shape: BoxShape.circle),
                    child: const Icon(Icons.add,
                        size: 16, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateField(
      String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFDDE4E8), width: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: kTextSecondary)),
            const SizedBox(height: 2),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: date != null
                      ? kTextPrimary
                      : kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmItem(
      String icon, String title, String subtitle, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFDDE4E8), width: 0.5)),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: kTextSecondary)),
              ],
            ),
          ),
          Text(price,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kTeal)),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────────────
  Widget _buildHeader(String title,
      {bool showBack = false, VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: kCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFDDE4E8), width: 0.5)),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: kTextPrimary),
              ),
            ),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary),
                  overflow: TextOverflow.ellipsis)),
          if (_step > 0 && _step < 6)
            Row(
              children: List.generate(
                  5,
                  (i) => Container(
                        width: i < _step ? 16 : 8,
                        height: 4,
                        margin: const EdgeInsets.only(left: 3),
                        decoration: BoxDecoration(
                            color: i < _step
                                ? kTeal
                                : const Color(0xFFDDE4E8),
                            borderRadius: BorderRadius.circular(2)),
                      )),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
      {required List<String> options,
      required List<String> labels,
      required String selected,
      required Function(String) onSelect}) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = selected == options[i];
          return GestureDetector(
            onTap: () => onSelect(options[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? kTeal : kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? kTeal
                        : const Color(0xFFCDD8DC),
                    width: 0.5),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? Colors.white
                          : kTextSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _aiSuggestionBanner(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 4),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: kTealLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTeal, width: 0.5)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              color: kTeal,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildBottomBar(String label, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      color: kBackground,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: kTeal,
              borderRadius: BorderRadius.circular(14)),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: fg)),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg)),
    );
  }

  Widget _tabToggle(
      String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? kTeal : kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? kTeal : const Color(0xFFCDD8DC),
              width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : kTextSecondary)),
      ),
    );
  }
}

// ─── INTERSTATE ROUTE CARD WIDGET ───────────────────────────────────────────
class InterstateRouteCard extends StatefulWidget {
  final InterstateRoute route;
  final String? currency;

  const InterstateRouteCard({super.key, required this.route, this.currency});

  @override
  State<InterstateRouteCard> createState() => _InterstateRouteCardState();
}

class _InterstateRouteCardState extends State<InterstateRouteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    final priceText = r.priceMin != null
        ? '${r.currency} ${r.priceMin!.toStringAsFixed(0)}${r.priceMax != null ? ' – ${r.priceMax!.toStringAsFixed(0)}' : ''}'
        : 'Price on request';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _expanded
                  ? kTeal
                  : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Top row: mode icon + operator + price
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: kTealLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(r.modeIcon,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.operator,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: kTextPrimary)),
                            Row(
                              children: [
                                Text(r.transportMode,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: kTextSecondary)),
                                if (r.operatorRating != null) ...[
                                  const Text(' · ',
                                      style: TextStyle(
                                          color: kTextSecondary,
                                          fontSize: 11)),
                                  const Icon(Icons.star,
                                      size: 11,
                                      color: Color(0xFFFFC107)),
                                  Text(
                                      r.operatorRating!
                                          .toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: kTextSecondary)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(priceText,
                              style: const TextStyle(
                                  color: kTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                          if (r.durationMinutes != null)
                            Text(r.durationText,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Route line
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.originCity,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: kTextPrimary)),
                            Text(r.originTerminal,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(r.modeIcon,
                              style: const TextStyle(fontSize: 16)),
                          if (r.distanceKm != null)
                            Text(
                                '${r.distanceKm!.toStringAsFixed(0)} km',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: kTextSecondary)),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(r.destinationCity,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: kTextPrimary)),
                            Text(r.destinationTerminal,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Expanded details
            if (_expanded)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    const Divider(height: 16),
                    _DetailRow('Terminal (From)', r.originTerminal),
                    _DetailRow('Terminal (To)', r.destinationTerminal),
                    if (r.distanceKm != null)
                      _DetailRow('Distance',
                          '${r.distanceKm!.toStringAsFixed(0)} km'),
                    if (r.durationMinutes != null)
                      _DetailRow('Duration', r.durationText),
                    _DetailRow('Price Range', priceText),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Booking ${r.operator} — coming soon!'),
                              backgroundColor: kTeal,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Book with ${r.operator}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (r.operatorWebsite != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kTeal),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            minimumSize:
                                const Size(double.infinity, 44),
                          ),
                          child: const Text(
                            '🌐  Visit Operator Website',
                            style: TextStyle(
                                color: kTeal,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Expand toggle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: kTextSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, color: kTextSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary)),
        ],
      ),
    );
  }
}

// ─── MAP GRID PAINTER ──────────────────────────────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBFDAD4)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final blockPaint = Paint()
      ..color = const Color(0xFFCCEBE4).withOpacity(0.5);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.1, size.height * 0.1, 80, 60),
        blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.5, size.height * 0.4, 70, 50),
        blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(
            size.width * 0.7, size.height * 0.1, 60, 80),
        blockPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}