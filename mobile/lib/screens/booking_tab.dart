import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  final ApiService _api = ApiService();
  List<dynamic> _activeBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveBookings();
    });
  }

  Future<void> _fetchActiveBookings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) throw Exception('User not logged in');

      final response = await _api.dio.get('/bookings/user/$userId');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            final allBookings = response.data['data'] as List<dynamic>;
            final now = DateTime.now();
            _activeBookings = allBookings.where((raw) {
              final b = Map<String, dynamic>.from(raw);
              if (b['status_pembayaran'] != 'Lunas') return false;
              if (b['kategori'] == 'Selesai' || b['kategori'] == 'Dibatalkan') return false;

              // Realtime check:
              try {
                final dateStr = (b['tanggal_booking_str'] ?? b['tanggal_booking']?.toString() ?? '').substring(0, 10);
                final jamMulaiStr = b['jam_mulai']?.toString() ?? '00:00:00';
                final jamSelesaiStr = b['jam_selesai']?.toString();
                final durasi = b['durasi'] is int ? b['durasi'] as int : int.tryParse(b['durasi']?.toString() ?? '1') ?? 1;

                final startParts = jamMulaiStr.split(':');
                final startHour = int.parse(startParts[0]);
                final startMin = int.parse(startParts[1]);
                final startDt = DateTime.parse('${dateStr}T${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}:00');

                DateTime endDt;
                if (jamSelesaiStr != null && jamSelesaiStr.isNotEmpty) {
                  final endParts = jamSelesaiStr.split(':');
                  final endHour = int.parse(endParts[0]);
                  final endMin = int.parse(endParts[1]);
                  endDt = DateTime.parse('${dateStr}T${endHour.toString().padLeft(2, '0')}:${endMin.toString().padLeft(2, '0')}:00');
                } else {
                  endDt = startDt.add(Duration(hours: durasi));
                }

                if (now.isAfter(endDt)) {
                  return false; // Already finished
                }
              } catch (_) {}

              return true;
            }).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Jadwal Aktif Saya', style: TextStyle(color: AppTheme.textPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Anda belum memiliki jadwal latihan aktif.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Usually we switch tab index to StudioTab via MainNavigationScreen,
                          // but since we are inside a tab, we can just show a snackbar or push a route
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan buka tab Studio untuk mencari tempat latihan!')));
                        },
                        child: const Text('Cari Studio Sekarang'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchActiveBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _activeBookings.length,
                    itemBuilder: (context, index) {
                      final b = _activeBookings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: b['status_pembayaran'] == 'Lunas' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      b['status_pembayaran'],
                                      style: TextStyle(
                                        color: b['status_pembayaran'] == 'Lunas' ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    b['tanggal_booking'].toString().substring(0, 10),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: ApiService.getFullImageUrl(b['foto_url']?.toString()).isNotEmpty
                                          ? Image.network(
                                              ApiService.getFullImageUrl(b['foto_url']?.toString()),
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                child: const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 30),
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                              child: const Icon(Icons.music_note, color: AppTheme.primaryColor, size: 30),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(b['nama_studio'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondaryColor),
                                            const SizedBox(width: 4),
                                            Text('${b['jam_mulai'].substring(0, 5)} - ${b['jam_selesai'].substring(0, 5)}', style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
