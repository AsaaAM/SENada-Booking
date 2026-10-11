import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/studio_detail_screen.dart';

class StudioCard extends StatelessWidget {
  final dynamic studio;
  final bool isHorizontal;

  const StudioCard({super.key, required this.studio, this.isHorizontal = true});

  @override
  Widget build(BuildContext context) {
    // Format price
    final price = 'Rp${studio['harga_per_jam'].toString().replaceAll(RegExp(r'\.00$'), '')}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudioDetailScreen(studioId: studio['id']),
          ),
        );
      },
      child: Container(
        width: isHorizontal ? 180 : double.infinity,
        margin: EdgeInsets.only(
          right: isHorizontal ? 16 : 0,
          bottom: isHorizontal ? 0 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isHorizontal
            ? _buildVerticalLayout(price)
            : _buildHorizontalLayout(price),
      ),
    );
  }

  Widget _buildVerticalLayout(String price) {
    final fullUrl = ApiService.getFullImageUrl(studio['foto_url']?.toString());
    final bool hasValidUrl = fullUrl.isNotEmpty;
    final String lokasi = studio['lokasi']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 110,
            width: double.infinity,
            color: Colors.grey[200],
            child: hasValidUrl
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Center(child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 40)),
                    ),
                  )
                : Container(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Center(child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 40)),
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      studio['nama_studio'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        studio['rating'].toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      lokasi,
                      style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$price /jam',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(String price) {
    final fullUrl = ApiService.getFullImageUrl(studio['foto_url']?.toString());
    final bool hasValidUrl = fullUrl.isNotEmpty;
    final String lokasi = studio['lokasi']?.toString() ?? '';

    return Row(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          child: Container(
            width: 120,
            height: 120,
            color: Colors.grey[200],
            child: hasValidUrl
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: const Center(child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 40)),
                    ),
                  )
                : Container(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Center(child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 40)),
                  ),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        studio['nama_studio'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: AppTheme.primaryColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      studio['rating'].toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lokasi,
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$price /jam',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Lihat', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

