import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/studio_card.dart';
import 'studio_tab.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _api = ApiService();
  List<dynamic> _studios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudios();
  }

  Future<void> _fetchStudios() async {
    try {
      final response = await _api.dio.get('/studios');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _studios = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo, Dimitri Kurniawan 👋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
                    SizedBox(height: 2),
                    Text('Temukan studio musik favoritmu', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            TextField(
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudioTab(initialSearchQuery: value)));
                }
              },
              decoration: InputDecoration(
                hintText: 'Cari studio, lokasi, atau fasilitas',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF3F33A3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROMO MEMBER BARU', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Diskon 25% sesi\npertamamu', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Pakai kode NADABARU', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudioTab()));
                  },
                  child: const Text('Lihat semua', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryItem(Icons.mic_external_on, 'Band'),
                _buildCategoryItem(Icons.headset, 'Rekaman'),
                _buildCategoryItem(Icons.podcasts, 'Podcast'),
                _buildCategoryItem(Icons.piano, 'Piano'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Studio populer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudioTab()));
                  },
                  child: const Text('Lihat semua', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _studios.length > 3 ? 3 : _studios.length, // show up to 3
                      itemBuilder: (context, index) {
                        return StudioCard(studio: _studios[index], isHorizontal: true);
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            const Text('Rekomendasi untukmu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: _studios.skip(3).take(3).map((s) => StudioCard(studio: s, isHorizontal: false)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => StudioTab(initialCategory: label)));
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
