import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../l10n/app_strings.dart';
import '../services/directions_service.dart';
import '../theme/app_colors.dart';

/// Carte de suivi du livreur ET du client, avec l'itinéraire entre les deux
/// clairement tracé : contrairement à un simple GoogleMap dans un
/// StreamBuilder (où `initialCameraPosition` n'a plus aucun effet après le
/// premier affichage et le marqueur "saute" d'un point à l'autre), ce widget
/// garde son propre GoogleMapController pour recentrer la caméra en douceur
/// à chaque nouvelle position reçue, anime le déplacement du marqueur
/// livreur au lieu d'un saut brutal, place la position actuelle du client
/// sur la même carte, et cadre automatiquement les deux points. Le trajet
/// entre eux est dessiné en trait épais et bien contrasté — suivant les
/// routes réelles si l'API Directions est configurée, sinon en ligne droite
/// marquée — pour que l'itinéraire soit net et immédiatement lisible.
class DriverMap extends StatefulWidget {
  final double lat;
  final double lng;
  final String? driverName;

  const DriverMap({super.key, required this.lat, required this.lng, this.driverName});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _moveController;
  late LatLng _displayedPosition;
  LatLng? _fromPosition;
  LatLng? _toPosition;

  final _directionsService = DirectionsService();
  StreamSubscription<Position>? _customerPositionSub;
  LatLng? _customerPosition;
  List<LatLng>? _routePoints;
  bool _boundsFitted = false;
  LatLng? _lastRouteOrigin;

  @override
  void initState() {
    super.initState();
    _displayedPosition = LatLng(widget.lat, widget.lng);
    _moveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..addListener(_onTick);
    _startWatchingCustomerPosition();
  }

  Future<void> _startWatchingCustomerPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final initial = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _customerPosition = LatLng(initial.latitude, initial.longitude));
      _fitBothIfNeeded();
      _refreshRoute();

      // Suit aussi la position du client en direct (pas seulement celle du
      // livreur) : s'il se déplace, son point sur la carte bouge lui aussi.
      _customerPositionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _customerPosition = LatLng(pos.latitude, pos.longitude));
      });
    } catch (_) {
      // Pas de localisation disponible (permission refusée, service coupé...)
      // — on affiche simplement la position du livreur seule, sans planter.
    }
  }

  /// Recalcule le tracé — seulement si le livreur a assez bougé depuis le
  /// dernier calcul (évite de spammer l'API Directions à chaque micro-mise
  /// à jour de position).
  Future<void> _refreshRoute() async {
    if (_customerPosition == null) return;
    if (_lastRouteOrigin != null && Geolocator.distanceBetween(
          _lastRouteOrigin!.latitude, _lastRouteOrigin!.longitude, _displayedPosition.latitude, _displayedPosition.longitude,
        ) < 40) {
      return;
    }
    _lastRouteOrigin = _displayedPosition;
    final route = await _directionsService.fetchRoute(origin: _displayedPosition, destination: _customerPosition!);
    if (mounted) setState(() => _routePoints = route);
  }

  void _onTick() {
    if (_fromPosition == null || _toPosition == null) return;
    final t = Curves.easeInOut.transform(_moveController.value);
    setState(() {
      _displayedPosition = LatLng(
        _fromPosition!.latitude + (_toPosition!.latitude - _fromPosition!.latitude) * t,
        _fromPosition!.longitude + (_toPosition!.longitude - _fromPosition!.longitude) * t,
      );
    });
  }

  @override
  void didUpdateWidget(covariant DriverMap old) {
    super.didUpdateWidget(old);
    if (old.lat == widget.lat && old.lng == widget.lng) return;
    final target = LatLng(widget.lat, widget.lng);
    _fromPosition = _displayedPosition;
    _toPosition = target;
    _moveController.forward(from: 0);
    if (_customerPosition != null) {
      _fitBounds(target, _customerPosition!);
      _refreshRoute();
    } else {
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  void _fitBothIfNeeded() {
    if (_boundsFitted || _customerPosition == null || _mapController == null) return;
    _boundsFitted = true;
    _fitBounds(_displayedPosition, _customerPosition!);
  }

  void _fitBounds(LatLng a, LatLng b) {
    final controller = _mapController;
    if (controller == null) return;
    final bounds = LatLngBounds(
      southwest: LatLng(a.latitude < b.latitude ? a.latitude : b.latitude, a.longitude < b.longitude ? a.longitude : b.longitude),
      northeast: LatLng(a.latitude > b.latitude ? a.latitude : b.latitude, a.longitude > b.longitude ? a.longitude : b.longitude),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  double? get _distanceMeters {
    if (_customerPosition == null) return null;
    return Geolocator.distanceBetween(
      _displayedPosition.latitude, _displayedPosition.longitude,
      _customerPosition!.latitude, _customerPosition!.longitude,
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _customerPositionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final distance = _distanceMeters;
    // Itinéraire réel si l'API Directions a renvoyé un tracé, sinon ligne
    // droite bien marquée entre livreur et client — jamais rien du tout.
    final hasRealRoute = _routePoints != null && _routePoints!.isNotEmpty;
    final polylinePath = hasRealRoute ? _routePoints! : (_customerPosition != null ? [_displayedPosition, _customerPosition!] : null);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _displayedPosition, zoom: 15),
          onMapCreated: (c) {
            _mapController = c;
            _fitBothIfNeeded();
          },
          polylines: {
            if (polylinePath != null)
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePath,
                color: AppColors.gold,
                width: 5,
                patterns: hasRealRoute ? const [] : [PatternItem.dash(18), PatternItem.gap(10)],
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('driver'),
              position: _displayedPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(title: widget.driverName ?? strings.t('yourDriver')),
            ),
            if (_customerPosition != null)
              Marker(
                markerId: const MarkerId('customer'),
                position: _customerPosition!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                infoWindow: InfoWindow(title: strings.t('yourPosition')),
              ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        if (distance != null)
          Positioned(
            left: 10, bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasRealRoute ? Icons.alt_route : Icons.straighten, size: 13, color: AppColors.goldDeep),
                const SizedBox(width: 4),
                Text(
                  distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '${distance.round()} m',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
