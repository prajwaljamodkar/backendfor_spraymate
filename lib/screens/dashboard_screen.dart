import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasChecked = false;
  String _status = 'GO';
  String _message = '';
  double _windSpeed = 0;
  double _temperature = 0;
  int _humidity = 0;
  String _windStatus = '';
  String _tempStatus = '';
  String _humidityStatus = '';
  double _deltaT = 0;
  String _deltaTStatus = '';
  double _wetBulbTemperature = 0;

  // Location state
  double? _latitude;
  double? _longitude;
  String _locationName = 'Detecting location...';
  bool _isLocating = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);

    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationName = 'Location services disabled';
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable location services'),
              backgroundColor: Colors.red.shade800,
            ),
          );
          _showManualLocationDialog();
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationName = 'Location permission denied';
            _isLocating = false;
          });
          _showManualLocationDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationName = 'Location permission permanently denied';
          _isLocating = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission permanently denied. Please enable in Settings.'),
              backgroundColor: Colors.red.shade800,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
          _showManualLocationDialog();
        }
        return;
      }

      // Try last known position first (instant, no GPS needed)
      Position? position = await Geolocator.getLastKnownPosition();

      // If no cached position, get current with timeout
      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Location request timed out');
          },
        );
      }

      setState(() {
        _latitude = position!.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocode to get place name
      await _reverseGeocode(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _locationName = 'Tap to enter location manually';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not detect location. You can enter coordinates manually.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        _showManualLocationDialog();
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        setState(() {
          _locationName =
              parts.isNotEmpty ? parts.join(', ') : 'Location found';
        });
      }
    } catch (_) {
      setState(() {
        _locationName = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      });
    }
  }

  void _showManualLocationDialog() {
    final latController = TextEditingController(
      text: _latitude?.toStringAsFixed(4) ?? '20.5937',
    );
    final lonController = TextEditingController(
      text: _longitude?.toStringAsFixed(4) ?? '78.9629',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1F1B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Enter Location',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GPS could not detect your location.\nPlease enter coordinates manually.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Latitude',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF2D322C)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF53D22D)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Longitude',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF2D322C)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF53D22D)),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text.trim());
              final lon = double.tryParse(lonController.text.trim());
              if (lat != null && lon != null) {
                setState(() {
                  _latitude = lat;
                  _longitude = lon;
                  _locationName =
                      '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
                });
                _reverseGeocode(lat, lon);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53D22D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCondition() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location not available. Tap the refresh button.'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.checkWeather(_latitude!, _longitude!);

      setState(() {
        _hasChecked = true;
        _status = data['status'] ?? 'GO';
        _message = data['message'] ?? '';
        _windSpeed = (data['windSpeed'] ?? 0).toDouble();
        _temperature = (data['temperature'] ?? 0).toDouble();
        _humidity = (data['humidity'] ?? 0).toInt();
        _windStatus = data['windStatus'] ?? '';
        _tempStatus = data['tempStatus'] ?? '';
        _humidityStatus = data['humidityStatus'] ?? '';
        _deltaT = (data['deltaT'] ?? 0).toDouble();
        _deltaTStatus = data['deltaTStatus'] ?? '';
        _wetBulbTemperature = (data['wetBulbTemperature'] ?? 0).toDouble();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Color get _statusColor {
    switch (_status) {
      case 'GO':
        return const Color(0xFF53D22D);
      case 'MODERATE':
        return const Color(0xFFFFC107);
      case 'NO_GO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (_status) {
      case 'GO':
        return 'Go';
      case 'MODERATE':
        return 'Moderate';
      case 'NO_GO':
        return 'No-Go';
      default:
        return '';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'GO':
        return Icons.check_rounded;
      case 'MODERATE':
        return Icons.warning_rounded;
      case 'NO_GO':
        return Icons.warning_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111310),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Spraymate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),

      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Status circle
              if (_hasChecked) ...[
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _statusColor.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _statusIcon,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _statusLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ] else ...[
                // Initial state - show prompt
                const SizedBox(height: 20),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2D322C),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_outlined,
                      size: 80,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ready to Check',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your location is being detected.\nTap below to check spray conditions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              // Location display
              GestureDetector(
                onTap: _showManualLocationDialog,
                child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F1B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D322C)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLocating
                          ? Icons.gps_not_fixed_rounded
                          : (_latitude != null
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded),
                      color: _latitude != null
                          ? const Color(0xFF53D22D)
                          : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_latitude != null && _longitude != null)
                            Text(
                              '${_latitude!.toStringAsFixed(4)}°N, ${_longitude!.toStringAsFixed(4)}°E',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isLocating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF53D22D),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.grey, size: 22),
                        onPressed: _fetchLocation,
                        tooltip: 'Refresh location',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              ),

              const SizedBox(height: 16),

              // Check Condition Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isLocating || _latitude == null)
                      ? null
                      : _checkCondition,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text(
                    _isLoading ? 'Checking...' : 'Check Condition',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53D22D),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        const Color(0xFF53D22D).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Factors section (only show after check)
              if (_hasChecked) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Factors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _FactorCard(
                  title: 'Delta T',
                  value: '${_deltaT.toStringAsFixed(1)}°C',
                  subtitle:
                      'Wet Bulb: ${_wetBulbTemperature.toStringAsFixed(1)}°C',
                  status: _deltaTStatus,
                  statusColor: _getFactorColor(_deltaTStatus),
                  icon: Icons.thermostat_auto_rounded,
                ),
                _FactorCard(
                  title: 'Wind Speed',
                  value: '${_windSpeed.toStringAsFixed(1)} mph',
                  status: _windStatus,
                  statusColor: _getFactorColor(_windStatus),
                  icon: Icons.air_rounded,
                ),
                _FactorCard(
                  title: 'Temperature',
                  value: '${_temperature.toStringAsFixed(1)}°C',
                  status: _tempStatus,
                  statusColor: _getFactorColor(_tempStatus),
                  icon: Icons.thermostat_rounded,
                ),
                _FactorCard(
                  title: 'Humidity',
                  value: '$_humidity%',
                  status: _humidityStatus,
                  statusColor: _getFactorColor(_humidityStatus),
                  icon: Icons.water_drop_outlined,
                ),
              ],
            ],
          ),
        ),
      ),

    );
  }

  Color _getFactorColor(String status) {
    switch (status) {
      case 'Good':
        return const Color(0xFF53D22D);
      case 'Moderate':
        return const Color(0xFFFFC107);
      case 'Too High':
        return Colors.red;
      case 'Too Low':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ─── Factor Card Widget ───

class _FactorCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? status;
  final Color? statusColor;
  final IconData icon;

  const _FactorCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.status,
    this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F1B),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: statusColor ?? Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                statusColor?.withValues(alpha: 0.2) ?? Colors.grey.shade800,
            child: Icon(
              icon,
              color: statusColor ?? Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                Text(value,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (status != null && status!.isNotEmpty)
            Text(
              status!,
              style: TextStyle(
                color: statusColor ?? Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
