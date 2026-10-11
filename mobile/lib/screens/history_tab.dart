import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ApiService _api = ApiService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) throw Exception('User not logged in');

      final response = await _api.dio.get('/bookings/user/$userId');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _bookings = response.data['data'] ?? [];
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

  String _getBookingCategory(Map<String, dynamic> b) {
    // 1. Cek jika sudah dibatalkan
    if (b['status_pembayaran'] == 'Dibatalkan' || b['kategori'] == 'Dibatalkan') {
      return 'Dibatalkan';
    }

    // 2. Cek waktu secara realtime (apakah sudah lewat jam selesai)
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

      final now = DateTime.now();
      if (now.isAfter(endDt)) {
        return 'Selesai';
      }
    } catch (_) {}

    // 3. Fallback ke kategori dari backend jika ada
    if (b['kategori'] != null && b['kategori'].toString().isNotEmpty) {
      return b['kategori'].toString();
    }

    if (b['status_pembayaran'] == 'Lunas') {
      return 'Berlangsung';
    }

    return 'Menunggu Konfirmasi';
  }

  bool _canCancelBooking(Map<String, dynamic> b) {
    final cat = _getBookingCategory(b);
    if (cat == 'Selesai' || cat == 'Dibatalkan') return false;

    try {
      final dateStr = (b['tanggal_booking_str'] ?? b['tanggal_booking']?.toString() ?? '').substring(0, 10);
      final jamMulaiStr = b['jam_mulai']?.toString() ?? '00:00:00';
      final startParts = jamMulaiStr.split(':');
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      final startDt = DateTime.parse('${dateStr}T${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')}:00');

      final diffMinutes = startDt.difference(DateTime.now()).inMinutes;
      // Syarat pembatalan: minimal 2 jam (120 menit) sebelum jadwal mulai
      return diffMinutes >= 120;
    } catch (_) {
      return b['bisa_dibatalkan'] == true;
    }
  }

  Future<void> _cancelBooking(int id) async {
    try {
      final response = await _api.dio.put('/bookings/$id/cancel');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _fetchHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Pesanan berhasil dibatalkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Gagal membatalkan pesanan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      String message = 'Gagal membatalkan pesanan';
      if (e is DioException && e.response?.data != null) {
        message = e.response?.data['message'] ?? message;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCancelAction(Map<String, dynamic> b) {
    final canCancel = _canCancelBooking(b);
    final bookingId = b['id'];

    if (!canCancel) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tidak Dapat Dibatalkan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pesanan tidak dapat dibatalkan karena waktu mulai kurang dari 2 jam atau jadwal sudah lewat/dimulai.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kebijakan: Pembatalan hanya dapat dilakukan minimal 2 jam sebelum waktu sesi latihan dimulai.',
                        style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin membatalkan pesanan di ${b['nama_studio']}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jadwal studio akan dikembalikan ke status Tersedia untuk pengguna lain.',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali', style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBooking(bookingId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String tabType) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final filteredList = _bookings.where((raw) {
      final b = Map<String, dynamic>.from(raw);
      final category = _getBookingCategory(b);

      if (tabType == 'Menunggu') {
        return category == 'Menunggu Konfirmasi';
      } else if (tabType == 'Berlangsung') {
        return category == 'Berlangsung';
      } else {
        // Tab Selesai/Batal
        return category == 'Selesai' || category == 'Dibatalkan';
      }
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Belum ada pesanan $tabType',
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final b = Map<String, dynamic>.from(filteredList[index]);
          final category = _getBookingCategory(b);
          final canCancel = _canCancelBooking(b);
          final fullImageUrl = ApiService.getFullImageUrl(b['foto_url']?.toString());
          final dateStr = (b['tanggal_booking_str'] ?? b['tanggal_booking']?.toString() ?? '').substring(0, 10);
          final jamMulai = (b['jam_mulai']?.toString() ?? '00:00').substring(0, 5);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Tanggal, Status Chip & Total Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 13, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Status Badge
                      _buildStatusBadge(category),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Middle Row: Gambar Studio + Info Studio
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 65,
                          height: 65,
                          color: Colors.grey[200],
                          child: fullImageUrl.isNotEmpty
                              ? Image.network(
                                  fullImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 30),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(Icons.music_note, color: AppTheme.primaryColor, size: 30),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['nama_studio'] ?? 'Studio Musik',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Jam: $jamMulai (${b['durasi'] ?? 1} jam)',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b['metode_pembayaran'] ?? 'Transfer',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                ),
                                Text(
                                  'Rp${b['total_harga']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Action Button & Keterangan Pembatalan untuk Tab Berlangsung
                  if (tabType == 'Berlangsung') ...[
                    const SizedBox(height: 12),
                    // Keterangan aturan pembatalan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pesanan tidak dapat dibatalkan jika kurang dari 2 jam sebelum mulai.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: canCancel
                          ? OutlinedButton.icon(
                              onPressed: () => _handleCancelAction(b),
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Batalkan Pesanan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => _handleCancelAction(b),
                              icon: const Icon(Icons.lock_clock, size: 16),
                              label: const Text('Tidak Dapat Dibatalkan (< 2 Jam)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade600,
                                side: BorderSide(color: Colors.grey.shade300),
                                backgroundColor: Colors.grey.shade100,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                    ),
                  ],

                  // Tombol Batalkan untuk Tab Menunggu Konfirmasi
                  if (tabType == 'Menunggu') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleCancelAction(b),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Batalkan Pesanan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String category) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (category) {
      case 'Selesai':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        icon = Icons.check_circle_outline;
        label = 'Selesai';
        break;
      case 'Dibatalkan':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        label = 'Dibatalkan';
        break;
      case 'Berlangsung':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.play_circle_outline;
        label = 'Berlangsung';
        break;
      case 'Menunggu Konfirmasi':
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.hourglass_top_rounded;
        label = 'Menunggu';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Riwayat Pesanan', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'Menunggu'),
              Tab(text: 'Berlangsung'),
              Tab(text: 'Selesai/Batal'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList('Menunggu'),
            _buildList('Berlangsung'),
            _buildList('Selesai/Batal'),
          ],
        ),
      ),
    );
  }
}
