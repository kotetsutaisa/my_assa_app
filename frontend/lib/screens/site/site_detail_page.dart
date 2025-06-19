import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/site_model.dart';
import 'package:frontend/utils/formatters.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SiteDetailPage extends ConsumerStatefulWidget {
  final SiteModel site;

  const SiteDetailPage({super.key, required this.site});

  @override
  ConsumerState<SiteDetailPage> createState() => _SiteDetailPage();
}

class _SiteDetailPage extends ConsumerState<SiteDetailPage> {
  late LatLng _location;

  @override
  void initState() {
    super.initState();
    if (widget.site.latitude != null && widget.site.longitude != null) {
      _location = LatLng(widget.site.latitude!, widget.site.longitude!);
    }
  }

  Future<void> _openInGoogleMaps() async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${_location.latitude},${_location.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Google Mapsを開けません';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('現場詳細'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).colorScheme.outline,
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現場名
            Text(
              widget.site.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildDetailRow(context, '住所', widget.site.address ?? '未登録'),
            _buildDetailRow(context, '元請け', widget.site.generalContractorName ?? '未登録'),
            _buildDetailRow(context, '所長', widget.site.managerName ?? '未登録'),
            widget.site.managerPhone != null
              ? _buildPhoneRow(context, widget.site.managerPhone!)
              : _buildDetailRow(context, '電話番号', '未登録'),
            _buildDetailRow(context, '備考', widget.site.memo ?? ''),
            const SizedBox(height: 24),

            Text(
              '地図',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _location,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('site'),
                      position: _location,
                      infoWindow: InfoWindow(title: widget.site.name),
                      onTap: _openInGoogleMaps,
                    ),
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _buildDetailRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80, // ラベルの幅を固定
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}


Widget _buildPhoneRow(BuildContext context, String phone) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '電話番号',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('電話をかけられません')),
                );
              }
            },
            child: Text(
              formatPhoneNumber(phone),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ),
      ],
    ),
  );
}