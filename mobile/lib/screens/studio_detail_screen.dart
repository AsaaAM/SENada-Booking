import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'schedule_selection_screen.dart';

class StudioDetailScreen extends StatefulWidget {
  final int studioId;

  const StudioDetailScreen({super.key, required this.studioId});

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _studio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudioDetail();
  }

  Future<void> _fetchStudioDetail() async {
    try {
      final response = await _api.dio.get('/studios/${widget.studioId}');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _studio = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data studio')),
        );
      }
    }
  }

  IconData _getFacilityIcon(String facilityName) {
    switch (facilityName.toLowerCase()) {
      case 'drum': return Icons.album;
      case 'ampli': return Icons.speaker;
      case 'mixer': return Icons.tune;
      case 'ac': return Icons.ac_unit;
      case 'wi-fi': return Icons.wifi;
      case 'vokal': return Icons.mic_external_on;
      case 'mic': return Icons.mic;
      case 'piano': return Icons.piano;
      case 'podcast': return Icons.podcasts;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_studio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Studio')),
        body: const Center(child: Text('Studio tidak ditemukan')),
      );
    }

    final price = 'Rp${_studio!['harga_per_jam'].toString().replaceAll(RegExp(r'\.00$'), '')}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Multi-image gallery
            Builder(
              builder: (context) {
                final List rawUrls = (_studio!['foto_urls'] as List?) ?? [];
                List<String> images = rawUrls
                    .map((u) => ApiService.getFullImageUrl(u.toString()))
                    .where((u) => u.isNotEmpty)
                    .toList();

                if (images.isEmpty && _studio!['foto_url'] != null) {
                  final u = ApiService.getFullImageUrl(_studio!['foto_url'].toString());
                  if (u.isNotEmpty) images.add(u);
                }

                if (images.isEmpty) {
                  return Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, size: 64, color: AppTheme.primaryColor),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final url = images[index];
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 12),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 280,
                                height: 200,
                                color: Colors.grey[200],
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: const Center(child: Icon(Icons.music_note, size: 64, color: AppTheme.primaryColor)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}/${images.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),


            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _studio!['nama_studio'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 20),
                          const SizedBox(width: 4),
                          Text(_studio!['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _studio!['lokasi'] ?? '',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14, height: 1.3),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Tentang studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(_studio!['deskripsi'] ?? '-', style: const TextStyle(color: AppTheme.textSecondaryColor, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  const Text('Fasilitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: (_studio!['fasilitas'] as List).map<Widget>((f) {
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getFacilityIcon(f), color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          Text(f, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jam operasional', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                            Text('${_studio!['jam_buka'].toString().substring(0,5)} - ${_studio!['jam_tutup'].toString().substring(0,5)} WIB', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        const Text('Buka', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // spacing for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mulai dari', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                    const Text(' /jam', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleSelectionScreen(studio: _studio!),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Booking Sekarang'),
            )
          ],
        ),
      ),
    );
  }
}
