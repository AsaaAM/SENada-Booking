import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'booking_success_screen.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> studio;
  final String tanggalBooking;
  final String jamMulai;
  final int durasi;
  final double totalHarga;

  const BookingPaymentScreen({
    super.key,
    required this.studio,
    required this.tanggalBooking,
    required this.jamMulai,
    required this.durasi,
    required this.totalHarga,
  });

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final ApiService _api = ApiService();
  String _selectedMethod = 'BCA Virtual Account';
  bool _isLoading = false;

  final TextEditingController _promoController = TextEditingController();
  Map<String, dynamic>? _appliedPromo;
  bool _isValidatingPromo = false;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double get _discountAmount {
    if (_appliedPromo == null) return 0.0;
    final diskonPersen = (_appliedPromo!['diskon_persen'] as num?)?.toDouble() ?? 0.0;
    return (widget.totalHarga * diskonPersen) / 100.0;
  }

  double get _finalTotal {
    final result = widget.totalHarga - _discountAmount;
    return result < 0 ? 0.0 : result;
  }

  Future<void> _applyPromo() async {
    final kode = _promoController.text.trim();
    if (kode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode kupon promo terlebih dahulu')),
      );
      return;
    }

    setState(() => _isValidatingPromo = true);

    try {
      final response = await _api.dio.post('/promos/validate', data: {
        'kode': kode,
      });

      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _appliedPromo = response.data['data'];
            _isValidatingPromo = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Kupon promo berhasil diterapkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isValidatingPromo = false);
          _showErrorDialog(response.data['message'] ?? 'Kupon promo tidak dapat digunakan');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isValidatingPromo = false);
        String msg = 'Gagal memvalidasi kupon promo';
        if (e is DioException && e.response?.data != null) {
          msg = e.response?.data['message'] ?? msg;
        }
        _showErrorDialog(msg);
      }
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kupon promo dilepas')),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Kupon Tidak Valid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
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
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final response = await _api.dio.post('/bookings', data: {
        'studio_id': widget.studio['id'],
        'tanggal_booking': widget.tanggalBooking,
        'jam_mulai': widget.jamMulai,
        'durasi': widget.durasi,
        'total_harga': _finalTotal,
        'metode_pembayaran': _selectedMethod,
        'promo_kode': _appliedPromo?['kode'],
      });

      if (response.statusCode == 201 && response.data['success']) {
        final bookingId = response.data['data']['booking_id'] ?? response.data['data']['bookingId'];
        
        // Schedule notification
        try {
          final startTime = DateTime.parse('${widget.tanggalBooking} ${widget.jamMulai}');
          await NotificationService().scheduleBookingReminder(bookingId, widget.studio['nama_studio'], startTime);
        } catch (_) {}

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BookingSuccessScreen()),
            (route) => route.isFirst,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Pemesanan gagal diproses')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Terjadi kesalahan jaringan';
        if (e is DioException && e.response != null) {
          msg = e.response?.data['message'] ?? e.message ?? msg;
        } else {
          msg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildPaymentMethod(String name, IconData icon) {
    final isSelected = _selectedMethod == name;
    return ListTile(
      onTap: () => setState(() => _selectedMethod = name),
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
      ),
      tileColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Pembayaran', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rincian Pesanan
            const Text('Rincian Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.studio['nama_studio'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text('Tanggal: ${widget.tanggalBooking}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Jam: ${widget.jamMulai.substring(0, 5)} (${widget.durasi} jam)',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Metode Pembayaran
            const Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _buildPaymentMethod('BCA Virtual Account', Icons.account_balance),
            const SizedBox(height: 8),
            _buildPaymentMethod('Mandiri Virtual Account', Icons.account_balance),
            const SizedBox(height: 8),
            _buildPaymentMethod('GoPay', Icons.account_balance_wallet),
            const SizedBox(height: 8),
            _buildPaymentMethod('OVO', Icons.account_balance_wallet),

            const SizedBox(height: 24),
            // Kode Promo Acara / Kupon Diskon
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kupon Promo / Diskon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Maks. 1 kupon', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
              ],
            ),
            const SizedBox(height: 14),

            if (_appliedPromo == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Contoh: NATAL2026',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isValidatingPromo ? null : _applyPromo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                    ),
                    child: _isValidatingPromo
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Pakai', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ] else ...[
              // Active Applied Promo Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _appliedPromo!['kode'] ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade900),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Diskon ${_appliedPromo!['diskon_persen']}%',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _appliedPromo!['nama_acara'] ?? 'Promo Spesial',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Hapus Kupon',
                      onPressed: _removePromo,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),
            // Rincian Harga
            const Text('Rincian Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sewa Studio', style: TextStyle(color: AppTheme.textSecondaryColor)),
                      Text(currencyFormatter.format(widget.totalHarga), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Diskon Kupon (${_appliedPromo!['kode']})',
                          style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '-${currencyFormatter.format(_discountAmount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormatter.format(_finalTotal),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading 
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Bayar Sekarang (${currencyFormatter.format(_finalTotal)})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
