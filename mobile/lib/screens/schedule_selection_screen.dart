import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'booking_payment_screen.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> studio;

  const ScheduleSelectionScreen({super.key, required this.studio});

  @override
  State<ScheduleSelectionScreen> createState() => _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _selectedTimes = [];

  final ApiService _api = ApiService();
  bool _isLoadingSchedules = false;
  List<dynamic> _schedules = [];

  final List<String> _timeSlots = [
    '10:00', '11:00', '12:00', '13:00', '14:00', '15:00',
    '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSchedules(_selectedDay!);
  }

  Future<void> _fetchSchedules(DateTime date) async {
    setState(() => _isLoadingSchedules = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await _api.dio.get('/studios/${widget.studio['id']}/schedules', queryParameters: {'tanggal': dateStr});
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _schedules = response.data['data'];
            _isLoadingSchedules = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  bool _isSlotAvailable(String time) {
    final schedule = _schedules.firstWhere((s) => s['jam_mulai'].toString().startsWith(time), orElse: () => null);
    if (schedule != null && schedule['status'] != 'Tersedia') {
      return false;
    }
    return true;
  }

  void _toggleTimeSlot(String time) {
    setState(() {
      if (_selectedTimes.contains(time)) {
        _selectedTimes.remove(time);
      } else {
        _selectedTimes.add(time);
      }
      _selectedTimes.sort((a, b) => _timeSlots.indexOf(a).compareTo(_timeSlots.indexOf(b)));
      
      // Validate continuity
      if (_selectedTimes.length > 1) {
        bool isValid = true;
        for (int i = 0; i < _selectedTimes.length - 1; i++) {
          int currentIndex = _timeSlots.indexOf(_selectedTimes[i]);
          int nextIndex = _timeSlots.indexOf(_selectedTimes[i+1]);
          if (nextIndex - currentIndex != 1) {
            isValid = false;
            break;
          }
        }
        if (!isValid) {
          // If not contiguous, reset to only the newly selected time
          _selectedTimes = [time];
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilihan jam harus berurutan (misal: 10:00 dan 11:00)')),
          );
        }
      }
    });
  }

  void _proceedToPayment() {
    if (_selectedDay == null || _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal dan minimal satu jam jadwal')),
      );
      return;
    }

    final double harga = double.parse(widget.studio['harga_per_jam'].toString());
    final int durasi = _selectedTimes.length;
    final double totalHarga = harga * durasi;
    final String jamMulai = _selectedTimes.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingPaymentScreen(
          studio: widget.studio,
          tanggalBooking: DateFormat('yyyy-MM-dd').format(_selectedDay!),
          jamMulai: '$jamMulai:00',
          durasi: durasi,
          totalHarga: totalHarga,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Pilih Jadwal', style: TextStyle(color: AppTheme.textPrimaryColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 16),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTimes.clear(); // reset time selection when date changes
                  });
                  _fetchSchedules(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('Waktu Mulai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoadingSchedules
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _timeSlots.map((time) {
                        final isAvailable = _isSlotAvailable(time);
                        final isSelected = _selectedTimes.contains(time);
                        return InkWell(
                          onTap: isAvailable ? () => _toggleTimeSlot(time) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : (isAvailable ? Colors.white : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : (isAvailable ? Colors.grey[300]! : Colors.grey[400]!),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isAvailable ? AppTheme.textPrimaryColor : Colors.grey[500]),
                                fontWeight: FontWeight.bold,
                                decoration: isAvailable ? null : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 32),
            if (_selectedTimes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Durasi otomatis dihitung: ${_selectedTimes.length} Jam\nDimulai dari ${_selectedTimes.first} hingga ${_timeSlots[_timeSlots.indexOf(_selectedTimes.last) + 1]}',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 100),
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
        child: ElevatedButton(
          onPressed: _proceedToPayment,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Lanjut ke Pembayaran'),
        ),
      ),
    );
  }
}
