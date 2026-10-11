import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/studio_card.dart';

class StudioTab extends StatefulWidget {
  final String? initialSearchQuery;
  final String? initialCategory;

  const StudioTab({super.key, this.initialSearchQuery, this.initialCategory});

  @override
  State<StudioTab> createState() => _StudioTabState();
}

class _StudioTabState extends State<StudioTab> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _studios = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _hargaMin = '';
  String _hargaMax = '';
  String _rating = '';
  String _category = '';
  String _lokasi = '';
  String _fasilitas = '';

  List<String> _availableLocations = [];
  List<String> _availableFacilities = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
    _fetchFilters();
    _fetchStudios();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _fetchStudios();
    });
  }

  Future<void> _fetchFilters() async {
    try {
      final response = await _api.dio.get('/studios/filters');
      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _availableLocations = List<String>.from(response.data['data']['locations'] ?? []);
            _availableFacilities = List<String>.from(response.data['data']['facilities'] ?? []);
          });
        }
      }
    } catch (_) {
      // Fallback: will be extracted from studios list in _fetchStudios
    }
  }

  Future<void> _fetchStudios() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.dio.get('/studios', queryParameters: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_category.isNotEmpty) 'kategori': _category,
        if (_hargaMin.isNotEmpty) 'harga_min': _hargaMin,
        if (_hargaMax.isNotEmpty) 'harga_max': _hargaMax,
        if (_lokasi.isNotEmpty) 'lokasi': _lokasi,
        if (_fasilitas.isNotEmpty) 'fasilitas': _fasilitas,
      });

      if (response.statusCode == 200 && response.data['success']) {
        if (mounted) {
          setState(() {
            _studios = response.data['data'];
            
            // Client-side rating filter
            if (_rating.isNotEmpty) {
              double minRating = double.parse(_rating);
              _studios = _studios.where((s) => double.parse(s['rating'].toString()) >= minRating).toList();
            }

            // Extract dynamic locations & facilities fallback
            if (_availableLocations.isEmpty && _studios.isNotEmpty) {
              final locSet = <String>{};
              final facSet = <String>{};
              for (final s in _studios) {
                if (s['lokasi'] != null) {
                  final parts = s['lokasi'].toString().split(',');
                  for (final p in parts) {
                    final clean = p.trim();
                    if (clean.isNotEmpty) locSet.add(clean);
                  }
                }
                if (s['fasilitas'] != null && s['fasilitas'] is List) {
                  for (final f in s['fasilitas']) {
                    final clean = f.toString().trim();
                    if (clean.isNotEmpty) facSet.add(clean);
                  }
                }
              }
              _availableLocations = locSet.toList()..sort();
              _availableFacilities = facSet.toList()..sort();
            }

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

  void _showFilterModal(String filterType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pilih $filterType', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          if (filterType == 'Lokasi') _applyFilter('lokasi', '');
                          if (filterType == 'Fasilitas') _applyFilter('fasilitas', '');
                          if (filterType == 'Harga') { _applyFilter('harga_min', ''); _applyFilter('harga_max', ''); }
                          if (filterType == 'Rating') _applyFilter('rating', '');
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (filterType == 'Lokasi') ...[
                          ListTile(
                            leading: const Icon(Icons.public, color: AppTheme.primaryColor),
                            title: const Text('Semua Lokasi'),
                            trailing: _lokasi.isEmpty ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('lokasi', '');
                              Navigator.pop(context);
                            },
                          ),
                          if (_availableLocations.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Memuat daftar lokasi studio...', style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ..._availableLocations.map((loc) {
                              final isSelected = _lokasi == loc;
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined, size: 20),
                                title: Text(loc),
                                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                                selected: isSelected,
                                onTap: () {
                                  _applyFilter('lokasi', loc);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                        ] else if (filterType == 'Fasilitas') ...[
                          ListTile(
                            leading: const Icon(Icons.all_inclusive, color: AppTheme.primaryColor),
                            title: const Text('Semua Fasilitas'),
                            trailing: _fasilitas.isEmpty ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('fasilitas', '');
                              Navigator.pop(context);
                            },
                          ),
                          if (_availableFacilities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Memuat daftar fasilitas studio...', style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ..._availableFacilities.map((fac) {
                              final isSelected = _fasilitas == fac;
                              return ListTile(
                                leading: const Icon(Icons.music_note_outlined, size: 20),
                                title: Text(fac),
                                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                                selected: isSelected,
                                onTap: () {
                                  _applyFilter('fasilitas', fac);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                        ] else if (filterType == 'Harga') ...[
                          ListTile(
                            title: const Text('Semua Harga'),
                            trailing: (_hargaMin.isEmpty && _hargaMax.isEmpty) ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('harga_min', '');
                              _applyFilter('harga_max', '');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Di bawah Rp 100.000'),
                            trailing: _hargaMax == '100000' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('harga_max', '100000');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Di atas Rp 100.000'),
                            trailing: _hargaMin == '100000' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('harga_min', '100000');
                              Navigator.pop(context);
                            },
                          ),
                        ] else if (filterType == 'Rating') ...[
                          ListTile(
                            title: const Text('Semua Rating'),
                            trailing: _rating.isEmpty ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('rating', '');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text('Bintang 4.5 ke atas'),
                            trailing: _rating == '4.5' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                            onTap: () {
                              _applyFilter('rating', '4.5');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilter(String key, String value) {
    setState(() {
      if (key == 'harga_max') {
        _hargaMax = value;
        if (value.isNotEmpty) _hargaMin = '';
      } else if (key == 'harga_min') {
        _hargaMin = value;
        if (value.isNotEmpty) _hargaMax = '';
      } else if (key == 'rating') {
        _rating = value;
      } else if (key == 'lokasi') {
        _lokasi = value;
      } else if (key == 'fasilitas') {
        _fasilitas = value;
      }
    });
    _fetchStudios();
  }

  void _resetAllFilters() {
    setState(() {
      _lokasi = '';
      _fasilitas = '';
      _hargaMin = '';
      _hargaMax = '';
      _rating = '';
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchStudios();
  }

  Widget _buildFilterChip(String label, IconData icon) {
    bool isActive = false;
    String displayLabel = label;

    if (label == 'Lokasi') {
      isActive = _lokasi.isNotEmpty;
      if (isActive) displayLabel = _lokasi;
    } else if (label == 'Fasilitas') {
      isActive = _fasilitas.isNotEmpty;
      if (isActive) displayLabel = _fasilitas;
    } else if (label == 'Harga') {
      isActive = _hargaMin.isNotEmpty || _hargaMax.isNotEmpty;
      if (isActive) {
        displayLabel = _hargaMax.isNotEmpty ? '< 100rb' : '> 100rb';
      }
    } else if (label == 'Rating') {
      isActive = _rating.isNotEmpty;
      if (isActive) displayLabel = '⭐ $_rating+';
    }

    return InkWell(
      onTap: () => _showFilterModal(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          border: Border.all(color: isActive ? AppTheme.primaryColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : AppTheme.textSecondaryColor),
            const SizedBox(width: 6),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  if (label == 'Lokasi') _applyFilter('lokasi', '');
                  if (label == 'Fasilitas') _applyFilter('fasilitas', '');
                  if (label == 'Harga') { _applyFilter('harga_min', ''); _applyFilter('harga_max', ''); }
                  if (label == 'Rating') _applyFilter('rating', '');
                },
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = _lokasi.isNotEmpty || _fasilitas.isNotEmpty || _hargaMin.isNotEmpty || _hargaMax.isNotEmpty || _rating.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jelajahi Studio', style: TextStyle(color: AppTheme.textPrimaryColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppTheme.textPrimaryColor),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama studio atau daerah...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildFilterChip('Lokasi', Icons.location_on_outlined),
                _buildFilterChip('Fasilitas', Icons.music_note_outlined),
                _buildFilterChip('Harga', Icons.attach_money),
                _buildFilterChip('Rating', Icons.star_outline),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menampilkan ${_studios.length} studio', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (hasActiveFilter)
                  GestureDetector(
                    onTap: _resetAllFilters,
                    child: const Text('Reset Filter', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                  )
                else
                  const Row(
                    children: [
                      Text('Rekomendasi', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _studios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada studio yang sesuai filter',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            if (hasActiveFilter)
                              ElevatedButton(
                                onPressed: _resetAllFilters,
                                child: const Text('Hapus Semua Filter'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _fetchFilters();
                          await _fetchStudios();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _studios.length,
                          itemBuilder: (context, index) {
                            return StudioCard(studio: _studios[index], isHorizontal: false);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
