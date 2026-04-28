import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class BranchMapPickerView extends StatefulWidget {
  const BranchMapPickerView({super.key});

  @override
  State<BranchMapPickerView> createState() => _BranchMapPickerViewState();
}

class _BranchMapPickerViewState extends State<BranchMapPickerView> {
  static const Color primary = Color(0xFFB85A1B);
  static const Color pageBg = Color(0xFFF7F7F9);
  static const LatLng fallbackPoint = LatLng(31.2028760, 16.5848760);

  final mapController = MapController();

  late LatLng selectedPoint;
  String addressText = '';
  bool loadingAddress = false;
  bool loadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments is Map)
        ? Map<String, dynamic>.from(Get.arguments)
        : <String, dynamic>{};

    final lat = (args['lat'] is num)
        ? (args['lat'] as num).toDouble()
        : double.tryParse('${args['lat'] ?? ''}');
    final lng = (args['lng'] is num)
        ? (args['lng'] as num).toDouble()
        : double.tryParse('${args['lng'] ?? ''}');
    addressText = (args['address_text'] ?? '').toString().trim();

    selectedPoint = (lat != null && lng != null)
        ? LatLng(lat, lng)
        : fallbackPoint;

    if (lat != null && lng != null) {
      if (addressText.isEmpty) {
        unawaited(_reverseGeocode());
      }
    } else {
      unawaited(_goToCurrentLocation(autoMode: true));
    }
  }

  Future<void> _reverseGeocode() async {
    if (!mounted) return;
    setState(() => loadingAddress = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${selectedPoint.latitude}&lon=${selectedPoint.longitude}&accept-language=ar',
      );

      final res = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'mandena-admin/1.0',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        final display = (j['display_name'] ?? '').toString().trim();
        if (display.isNotEmpty && mounted) {
          setState(() => addressText = display);
        }
      }
    } catch (_) {
      // تجاهل الخطأ هنا حتى لا نزعج المستخدم برسالة في كل سحب/تحريك.
    } finally {
      if (mounted) setState(() => loadingAddress = false);
    }
  }

  Future<void> _goToCurrentLocation({bool autoMode = false}) async {
    if (!mounted) return;
    setState(() => loadingCurrentLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!autoMode) {
          _showMessage('خدمة الموقع متوقفة. فعّل GPS ثم حاول مرة أخرى.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!autoMode) {
          _showMessage('تم رفض إذن الموقع.');
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!autoMode) {
          _showMessage(
            'إذن الموقع مرفوض نهائيًا. افتح الإعدادات ومنح صلاحية الموقع للتطبيق.',
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        selectedPoint = point;
      });

      mapController.move(point, 16);
      await _reverseGeocode();

      if (!autoMode) {
        _showMessage('تم جلب موقعك الحالي وعنوانه.');
      }
    } catch (_) {
      if (!autoMode) {
        _showMessage('تعذر جلب الموقع الحالي.');
      }
    } finally {
      if (mounted) setState(() => loadingCurrentLocation = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTap(TapPosition _, LatLng point) {
    setState(() {
      selectedPoint = point;
      addressText = '';
    });
    unawaited(_reverseGeocode());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          title: const Text('اختيار موقع الفرع'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: selectedPoint,
                      initialZoom: 15,
                      onTap: _onTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.mandena.admin',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPoint,
                            width: 52,
                            height: 52,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: primary,
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    left: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: loadingCurrentLocation
                                ? null
                                : () => _goToCurrentLocation(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primary,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: loadingCurrentLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primary,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            label: Text(
                              loadingCurrentLocation
                                  ? 'جارٍ جلب الموقع الحالي...'
                                  : 'استخدام موقعي الحالي',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'الإحداثيات المختارة',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lat: ${selectedPoint.latitude.toStringAsFixed(7)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lng: ${selectedPoint.longitude.toStringAsFixed(7)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'العنوان الحالي',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: loadingAddress
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('جارٍ جلب العنوان الحالي...'),
                              ),
                            ],
                          )
                        : Text(
                            addressText.isEmpty
                                ? 'لم يتم جلب عنوان بعد'
                                : addressText,
                            style: const TextStyle(height: 1.5),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reverseGeocode,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primary,
                            side: const BorderSide(color: primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('تحديث العنوان'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back(
                              result: {
                                'lat': selectedPoint.latitude,
                                'lng': selectedPoint.longitude,
                                'address_text': addressText,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'اعتماد الموقع',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
