import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  // Notifikasi switches state
  bool _notifySchedule = true;
  bool _notifyPromo = false;
  bool _notifyStatus = true;
  bool _notifySound = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).userId;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await _api.dio.get('/users/$userId');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _userProfile = response.data['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MODAL SHEETS ---

  // 1. DETAIL POIN & REWARD SHEET
  void _showPointsSheet(int currentPoints) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Poin Nada Anda',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$currentPoints Poin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tingkat Member: Musisi Silver',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Voucher & Hadiah Menarik',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            _buildRewardItem(
              title: 'Diskon Booking 15%',
              points: 100,
              icon: Icons.confirmation_number_outlined,
              color: Colors.blue,
              currentPoints: currentPoints,
            ),
            _buildRewardItem(
              title: 'Gratis 2 Botol Minuman',
              points: 50,
              icon: Icons.local_drink_outlined,
              color: Colors.teal,
              currentPoints: currentPoints,
            ),
            _buildRewardItem(
              title: 'Sewa Tambahan Headphone 1 Jam',
              points: 80,
              icon: Icons.headphones_outlined,
              color: Colors.purple,
              currentPoints: currentPoints,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dapatkan +50 Poin setiap kali menyelesaikan sesi booking studio!',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem({
    required String title,
    required int points,
    required IconData icon,
    required Color color,
    required int currentPoints,
  }) {
    final canRedeem = currentPoints >= points;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$points Poin Nada', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canRedeem
                ? () {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Selamat! Voucher "$title" berhasil ditukarkan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              canRedeem ? 'Tukar' : 'Kurang',
              style: TextStyle(
                fontSize: 12,
                color: canRedeem ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. EDIT PROFIL SHEET
  void _showEditProfileSheet() {
    final nameCtrl = TextEditingController(text: _userProfile?['nama_lengkap'] ?? 'Dimitri Kurniawan');
    final phoneCtrl = TextEditingController(text: _userProfile?['no_hp'] ?? '081234567890');
    final emailText = _userProfile?['email'] ?? 'thedimitris@email.com';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor, width: 2),
                      ),
                      child: const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp / HP',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: emailText),
                decoration: InputDecoration(
                  labelText: 'Email Akun (Permanen)',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);

                          if (nameCtrl.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Nama lengkap tidak boleh kosong')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                            final res = await _api.dio.put('/users/$userId', data: {
                              'nama_lengkap': nameCtrl.text.trim(),
                              'no_hp': phoneCtrl.text.trim(),
                            });

                            if (res.statusCode == 200 && res.data['success']) {
                              navigator.pop();
                              _fetchProfile();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Profil berhasil diperbarui!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Gagal memperbarui profil'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. UBAH KATA SANDI SHEET
  void _showChangePasswordSheet() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ubah Kata Sandi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Demi keamanan akun, pastikan kata sandi baru terdiri minimal 8 karakter.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: oldPasswordCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Lama',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureOld = !obscureOld),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newPasswordCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureNew = !obscureNew),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Ulangi Kata Sandi Baru',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx);

                          if (oldPasswordCtrl.text.isEmpty || newPasswordCtrl.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Semua kolom kata sandi wajib diisi')),
                            );
                            return;
                          }
                          if (newPasswordCtrl.text.length < 8) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Kata sandi baru minimal 8 karakter')),
                            );
                            return;
                          }
                          if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Konfirmasi kata sandi baru tidak cocok')),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                            final res = await _api.dio.put('/users/$userId/change-password', data: {
                              'password_lama': oldPasswordCtrl.text,
                              'password_baru': newPasswordCtrl.text,
                            });

                            if (res.statusCode == 200 && res.data['success']) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Kata sandi berhasil diubah!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            String msg = 'Gagal mengubah kata sandi';
                            if (e is DioException && e.response?.data != null) {
                              msg = e.response?.data['message'] ?? msg;
                            }
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Simpan Kata Sandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. PENGATURAN NOTIFIKASI SHEET
  void _showNotificationSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Atur pemberitahuan untuk pengalaman latihan musik terbaik Anda.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildNotificationSwitch(
                title: 'Pengingat Jadwal Latihan',
                subtitle: 'Kirim notifikasi 2 jam & 1 jam sebelum sesi mulai',
                icon: Icons.alarm,
                value: _notifySchedule,
                onChanged: (val) {
                  setState(() => _notifySchedule = val);
                  setModalState(() {});
                },
              ),
              _buildNotificationSwitch(
                title: 'Promo & Diskon Studio',
                subtitle: 'Dapatkan info promo spesial studio musik favorit',
                icon: Icons.local_offer_outlined,
                value: _notifyPromo,
                onChanged: (val) {
                  setState(() => _notifyPromo = val);
                  setModalState(() {});
                },
              ),
              _buildNotificationSwitch(
                title: 'Status Pesanan & Pembayaran',
                subtitle: 'Update saat booking dikonfirmasi atau dibatalkan',
                icon: Icons.receipt_long_outlined,
                value: _notifyStatus,
                onChanged: (val) {
                  setState(() => _notifyStatus = val);
                  setModalState(() {});
                },
              ),
              _buildNotificationSwitch(
                title: 'Suara & Getar Aplikasi',
                subtitle: 'Bunyikan nada saat ada notifikasi masuk',
                icon: Icons.volume_up_outlined,
                value: _notifySound,
                onChanged: (val) {
                  setState(() => _notifySound = val);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Preferensi notifikasi disimpan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Preferensi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 5. PUSAT BANTUAN SHEET
  void _showHelpCenterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.support_agent_rounded, color: Colors.teal.shade700, size: 28),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pusat Bantuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Siap melayani 24/7 untuk Anda', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Pertanyaan Umum (FAQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _buildFaqTile(
              question: 'Bagaimana cara membatalkan booking?',
              answer: 'Buka menu Riwayat Pesanan pada tab Berlangsung. Anda dapat membatalkan pesanan maksimal 2 jam sebelum waktu sesi latihan dimulai.',
            ),
            _buildFaqTile(
              question: 'Berapa lama masa berlaku Poin Nada?',
              answer: 'Poin Nada berlaku selama 1 tahun sejak diperoleh dari pemesanan studio yang berstatus Selesai.',
            ),
            _buildFaqTile(
              question: 'Apakah bisa memesan untuk hari berikutnya?',
              answer: 'Bisa! Anda dapat memilih tanggal di halaman detail studio hingga 14 hari ke depan.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Membuka WhatsApp Customer Support... (+62 812-3456-7890)')),
                      );
                    },
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('WhatsApp CS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Email bantuan: support@senada.com')),
                      );
                    },
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        title: Text(question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
        children: [
          Text(answer, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
        ],
      ),
    );
  }

  // 6. TENTANG SENADA SHEET
  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF8E84F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 14),
            const Text('SENada Music Studio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Versi 1.0.0 (Build 2026)',
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi booking studio musik pintar yang menghubungkan musisi dengan studio rekaman dan latihan musik terbaik di seluruh Indonesia secara realtime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('⚡ Real-time Booking', style: TextStyle(fontSize: 11))),
                Chip(label: Text('🎵 Poin Hadiah', style: TextStyle(fontSize: 11))),
                Chip(label: Text('🔒 Pembayaran Aman', style: TextStyle(fontSize: 11))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. LOGOUT SHEET
  void _showLogoutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Keluar dari Akun?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Anda harus masuk kembali untuk melihat riwayat pemesanan dan jadwal latihan aktif Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final appNavigator = Navigator.of(context);
                      final modalNavigator = Navigator.of(ctx);
                      final auth = Provider.of<AuthProvider>(context, listen: false);

                      modalNavigator.pop();
                      await auth.logout();
                      if (mounted) {
                        appNavigator.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile?['nama_lengkap'] ?? 'Dimitri Kurniawan';
    final userEmail = _userProfile?['email'] ?? 'thedimitris@email.com';
    final userPoints = (_userProfile?['poin_nada'] as num?)?.toInt() ?? 150;
    final totalBooking = (_userProfile?['total_booking'] as num?)?.toInt() ?? 0;
    final userRole = _userProfile?['role'] == 'admin' ? 'Administrator' : 'Musisi SENada';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Perbarui Data',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimaryColor),
            onPressed: _fetchProfile,
          ),
          IconButton(
            tooltip: 'Pengaturan Notifikasi',
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textPrimaryColor),
            onPressed: _showNotificationSettingsSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 1. HERO USER CARD
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5342E4), Color(0xFF7668F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.28),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Avatar dengan Edit Badge
                                GestureDetector(
                                  onTap: _showEditProfileSheet,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                        ),
                                        child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: const BoxDecoration(
                                            color: Colors.amber,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Icon(Icons.verified, color: Colors.amber, size: 18),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        userEmail,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          userRole,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Quick Stats Bar
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickStat(
                                    icon: Icons.calendar_month_outlined,
                                    label: 'Total Sesi',
                                    value: '$totalBooking Sesi',
                                    onTap: null,
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white24),
                                  _buildQuickStat(
                                    icon: Icons.stars_rounded,
                                    label: 'Poin Nada',
                                    value: '$userPoints Poin',
                                    onTap: () => _showPointsSheet(userPoints),
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white24),
                                  _buildQuickStat(
                                    icon: Icons.shield_outlined,
                                    label: 'Keanggotaan',
                                    value: 'Aktif',
                                    onTap: null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. BANNER INTERAKTIF POIN NADA
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade50, Colors.orange.shade50],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _showPointsSheet(userPoints),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade500,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.stars_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '$userPoints Poin Nada',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade600,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Reward',
                                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tukarkan poin dengan voucher potongan harga studio',
                                        style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.orange.shade800),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. MENU SECTION: AKUN
                    _buildModernSection(
                      title: 'Akun & Keamanan',
                      items: [
                        _buildModernTile(
                          title: 'Edit Profil',
                          subtitle: 'Ubah nama lengkap dan nomor kontak',
                          icon: Icons.person_outline_rounded,
                          iconBgColor: Colors.blue.shade50,
                          iconColor: Colors.blue.shade700,
                          onTap: _showEditProfileSheet,
                        ),
                        _buildModernTile(
                          title: 'Ubah Kata Sandi',
                          subtitle: 'Ganti password akun demi keamanan berkala',
                          icon: Icons.lock_outline_rounded,
                          iconBgColor: Colors.purple.shade50,
                          iconColor: Colors.purple.shade700,
                          onTap: _showChangePasswordSheet,
                        ),
                        _buildModernTile(
                          title: 'Pengaturan Notifikasi',
                          subtitle: 'Atur pengingat jadwal booking dan promo',
                          icon: Icons.notifications_active_outlined,
                          iconBgColor: Colors.amber.shade50,
                          iconColor: Colors.amber.shade800,
                          onTap: _showNotificationSettingsSheet,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 4. MENU SECTION: BANTUAN & INFO
                    _buildModernSection(
                      title: 'Bantuan & Lainnya',
                      items: [
                        _buildModernTile(
                          title: 'Pusat Bantuan & FAQ',
                          subtitle: 'Pertanyaan seputar booking dan kontak WhatsApp CS',
                          icon: Icons.help_outline_rounded,
                          iconBgColor: Colors.teal.shade50,
                          iconColor: Colors.teal.shade700,
                          onTap: _showHelpCenterSheet,
                        ),
                        _buildModernTile(
                          title: 'Tentang SENada',
                          subtitle: 'Informasi aplikasi, versi, dan lisensi',
                          icon: Icons.info_outline_rounded,
                          iconBgColor: Colors.indigo.shade50,
                          iconColor: Colors.indigo.shade700,
                          onTap: _showAboutSheet,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 5. MENU SECTION: LOGOUT
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showLogoutSheet,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(Icons.logout_rounded, color: Colors.red.shade600, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Keluar Akun',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Keluar dari sesi login saat ini',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: Colors.red.shade300),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text('SENada • Versi 1.0.0', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({required String title, required List<Widget> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildModernTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
