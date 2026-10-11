import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'admin_add_studio_screen.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => AdminHomeScreenState();
}

class AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _bookings = [];
  List<dynamic> _studios = [];
  List<dynamic> _promos = [];
  bool _isLoading = true;
  bool _isLoadingStudios = true;
  bool _isLoadingPromos = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _fetchStudios();
    _fetchPromos();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.dio.get('/admin/bookings');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _bookings = response.data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      developer.log('Failed to fetch bookings', error: e);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudios() async {
    setState(() => _isLoadingStudios = true);
    try {
      final response = await _api.dio.get('/studios');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _studios = response.data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      developer.log('Failed to fetch studios', error: e);
    }
    if (mounted) {
      setState(() => _isLoadingStudios = false);
    }
  }

  Future<void> _updateBookingStatus(int id, String action) async {
    try {
      final response = await _api.dio.put('/admin/bookings/$id/$action');
      if (response.statusCode == 200) {
        await _fetchBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status')),
        );
      }
    }
  }

  Future<void> _deleteStudio(int studioId, String studioName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Studio?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus studio "$studioName"?\n\nSemua jadwal dan riwayat pemesanan studio ini akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _api.dio.delete('/studios/$studioId');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Studio berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchStudios();
        await _fetchBookings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Gagal menghapus studio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus studio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddStudio() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddStudioScreen()),
    );
    if (result == true) {
      _fetchStudios();
    }
  }

  Future<void> _navigateToEditStudio(Map<String, dynamic> studio) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddStudioScreen(studioToEdit: studio),
      ),
    );
    if (result == true) {
      _fetchStudios();
    }
  }


  void _showConfirmDialog(int id, String action, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('Apakah Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateBookingStatus(id, action);
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_bookings.isEmpty) return const Center(child: Text('Tidak ada pesanan'));

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final b = _bookings[index];
          final bool isPending = b['status_pembayaran'] == 'Menunggu Konfirmasi';
          
          Color badgeColor = Colors.grey;
          if (b['status_pembayaran'] == 'Lunas') badgeColor = Colors.green;
          if (b['status_pembayaran'] == 'Dibatalkan') badgeColor = Colors.red;
          if (isPending) badgeColor = Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(b['nama_studio'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b['status_pembayaran'], 
                          style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('User: ${b['nama_lengkap']}'),
                  Text('Jadwal: ${b['tanggal_booking'].toString().substring(0,10)} | ${b['jam_mulai']} (${b['durasi']} jam)'),
                  Text('Total: Rp${b['total_harga']} | ${b['metode_pembayaran']}'),
                  
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _showConfirmDialog(b['id'], 'approve', 'Terima Lunas'),
                            child: const Text('ACC Lunas'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            onPressed: () => _showConfirmDialog(b['id'], 'reject', 'Tolak Booking'),
                            child: const Text('Tolak'),
                          ),
                        )
                      ],
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudioTab() {
    if (_isLoadingStudios) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchStudios,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelola Studio Musik',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_studios.length} Studio terdaftar',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _navigateToAddStudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_studios.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada studio terdaftar',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _navigateToAddStudio,
                      child: const Text('Tambah Studio Sekarang'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._studios.map((s) {
              final price = 'Rp${s['harga_per_jam'].toString().replaceAll(RegExp(r'\.00$'), '')}';
              final fullUrl = ApiService.getFullImageUrl(s['foto_url']?.toString());
              final bool hasValidUrl = fullUrl.isNotEmpty;
              final List facilities = (s['fasilitas'] as List?) ?? [];
              final List fotoUrls = (s['foto_urls'] as List?) ?? [];

              String jamBukaStr = '-';
              String jamTutupStr = '-';
              if (s['jam_buka'] != null) {
                jamBukaStr = s['jam_buka'].toString().substring(0, 5);
              }
              if (s['jam_tutup'] != null) {
                jamTutupStr = s['jam_tutup'].toString().substring(0, 5);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo + Basic Info Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: hasValidUrl
                                        ? Image.network(
                                            fullUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                              child: const Center(
                                                child: Icon(Icons.music_note, color: AppTheme.primaryColor),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            child: const Center(
                                              child: Icon(Icons.music_note, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                  ),
                                  if (fotoUrls.length > 1)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${fotoUrls.length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['nama_studio'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        s['lokasi'] ?? '',
                                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$price /jam',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),

                      // Operational Hours
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Jam Operasional: $jamBukaStr - $jamTutupStr WIB',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      // Description (Tentang Studio)
                      if (s['deskripsi'] != null && s['deskripsi'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          s['deskripsi'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Facilities list
                      if (facilities.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: facilities.map<Widget>((fac) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                fac.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Action Buttons: Edit & Hapus Studio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _navigateToEditStudio(Map<String, dynamic>.from(s)),
                            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryColor),
                            label: const Text('Edit', style: TextStyle(color: AppTheme.primaryColor)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _deleteStudio(s['id'], s['nama_studio'] ?? 'Studio'),
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _fetchPromos() async {
    setState(() => _isLoadingPromos = true);
    try {
      final response = await _api.dio.get('/promos');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _promos = response.data['data'] ?? [];
            _isLoadingPromos = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPromos = false);
    }
  }

  Future<void> _togglePromoStatus(int id, bool currentStatus) async {
    try {
      final res = await _api.dio.put('/promos/$id', data: {'aktif': !currentStatus});
      if (res.statusCode == 200) {
        _fetchPromos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(!currentStatus ? 'Kupon diaktifkan' : 'Kupon dinonaktifkan')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _deletePromo(int id, String kode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kupon Promo?'),
        content: Text('Apakah Anda yakin ingin menghapus kupon "$kode"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await _api.dio.delete('/promos/$id');
        if (res.statusCode == 200) {
          _fetchPromos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Kupon "$kode" berhasil dihapus')),
            );
          }
        }
      } catch (_) {}
    }
  }

  void _showPromoDialog({Map<String, dynamic>? promoToEdit}) {
    final isEdit = promoToEdit != null;
    final kodeCtrl = TextEditingController(text: promoToEdit?['kode'] ?? '');
    final namaAcaraCtrl = TextEditingController(text: promoToEdit?['nama_acara'] ?? '');
    final diskonCtrl = TextEditingController(text: promoToEdit != null ? promoToEdit['diskon_persen'].toString() : '');
    
    DateTime? startDate = promoToEdit?['tanggal_mulai'] != null 
        ? DateTime.tryParse(promoToEdit!['tanggal_mulai'].toString().substring(0, 10)) 
        : null;
    DateTime? endDate = promoToEdit?['tanggal_berakhir'] != null 
        ? DateTime.tryParse(promoToEdit!['tanggal_berakhir'].toString().substring(0, 10)) 
        : null;
    bool isAktif = promoToEdit != null ? (promoToEdit['aktif'] == true || promoToEdit['aktif'] == 1) : true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Kupon Promo' : 'Tambah Kupon Promo Baru',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: kodeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kode Kupon * (Contoh: NATAL2026)',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: namaAcaraCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Acara (Contoh: Diskon Natalan & Tahun Baru)',
                    prefixIcon: const Icon(Icons.event_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diskonCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Persentase Diskon % (1 - 100) *',
                    prefixIcon: const Icon(Icons.percent_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Periode Tanggal Kupon Berlaku:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : 'Mulai: Bebas',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => startDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_busy, size: 16),
                        label: Text(
                          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : 'Sampai: Bebas',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? (startDate ?? DateTime.now()),
                            firstDate: startDate ?? DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() => endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Status Kupon Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Nonaktifkan jika kupon ingin dihentikan sementara', style: TextStyle(fontSize: 11)),
                  value: isAktif,
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) => setModalState(() => isAktif = val),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final kode = kodeCtrl.text.trim().toUpperCase();
                            final diskon = int.tryParse(diskonCtrl.text.trim());

                            if (kode.isEmpty || diskon == null || diskon <= 0 || diskon > 100) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kode kupon dan persentase diskon (1-100%) wajib valid')),
                              );
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            final data = {
                              'kode': kode,
                              'nama_acara': namaAcaraCtrl.text.trim(),
                              'diskon_persen': diskon,
                              'tanggal_mulai': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : null,
                              'tanggal_berakhir': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
                              'aktif': isAktif,
                            };

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final res = isEdit
                                  ? await _api.dio.put('/promos/${promoToEdit['id']}', data: data)
                                  : await _api.dio.post('/promos', data: data);

                              if (res.statusCode == 200 || res.statusCode == 201) {
                                nav.pop();
                                _fetchPromos();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit ? 'Kupon berhasil diperbarui!' : 'Kupon baru berhasil ditambahkan!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              String msg = 'Gagal menyimpan kupon promo';
                              if (e is DioException && e.response?.data != null) {
                                msg = e.response?.data['message'] ?? msg;
                              }
                              messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? 'Simpan Perubahan' : 'Buat Kupon Diskon', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoTab() {
    if (_isLoadingPromos) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetchPromos,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withValues(alpha: 0.1), Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kupon Acara & Diskon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text(
                        'Atur batas tanggal acara dan batas 1x pakai per akun.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPromoDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_promos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada kupon promo diskon', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._promos.map((p) {
              final statusKupon = p['status_kupon'] ?? 'Aktif';
              Color statusBgColor = Colors.green.shade50;
              Color statusTextColor = Colors.green.shade700;

              if (statusKupon == 'Nonaktif') {
                statusBgColor = Colors.red.shade50;
                statusTextColor = Colors.red.shade700;
              } else if (statusKupon == 'Kedaluwarsa') {
                statusBgColor = Colors.grey.shade100;
                statusTextColor = Colors.grey.shade700;
              } else if (statusKupon == 'Mendatang') {
                statusBgColor = Colors.orange.shade50;
                statusTextColor = Colors.orange.shade800;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_offer, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['kode'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    p['nama_acara'] ?? 'Promo Spesial',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              statusKupon,
                              style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Besaran Diskon:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Text(
                                  '${p['diskon_persen']}% POTONGAN',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Periode Tanggal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Text(
                                  '${p['tanggal_mulai'] ?? 'Mulai sekarang'} s/d ${p['tanggal_berakhir'] ?? 'Tanpa batas'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ketentuan:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                Text(
                                  '1x Pakai per Akun',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Switch(
                                value: p['aktif'] == true || p['aktif'] == 1,
                                activeThumbColor: AppTheme.primaryColor,
                                onChanged: (val) => _togglePromoStatus(p['id'], p['aktif'] == true || p['aktif'] == 1),
                              ),
                              Text(
                                (p['aktif'] == true || p['aktif'] == 1) ? 'Aktif' : 'Nonaktif',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                tooltip: 'Edit Kupon',
                                onPressed: () => _showPromoDialog(promoToEdit: Map<String, dynamic>.from(p)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Hapus Kupon',
                                onPressed: () => _deletePromo(p['id'], p['kode'] ?? ''),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SENada Admin'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            )
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pemesanan Masuk'),
              Tab(text: 'Kelola Studio'),
              Tab(text: 'Kupon Promo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingTab(),
            _buildStudioTab(),
            _buildPromoTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToAddStudio,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Studio'),
        ),
      ),
    );
  }
}
