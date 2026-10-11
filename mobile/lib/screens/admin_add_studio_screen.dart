import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminAddStudioScreen extends StatefulWidget {
  final Map<String, dynamic>? studioToEdit;

  const AdminAddStudioScreen({super.key, this.studioToEdit});

  @override
  State<AdminAddStudioScreen> createState() => _AdminAddStudioScreenState();
}

class _AdminAddStudioScreenState extends State<AdminAddStudioScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _customFacilityController = TextEditingController();
  final TextEditingController _customUrlController = TextEditingController();

  TimeOfDay _jamBuka = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _jamTutup = const TimeOfDay(hour: 23, minute: 0);

  final List<String> _popularFacilities = [
    'AC',
    'Drum',
    'Ampli Gitar',
    'Ampli Bass',
    'Mixer',
    'Wi-Fi',
    'Mic Vokal',
    'Keyboard',
    'Peredam Suara',
    'Podcast',
  ];

  List<String> _selectedFacilities = ['AC', 'Drum', 'Ampli Gitar', 'Wi-Fi'];

  // Photos management: local files picked from device
  final List<XFile> _pickedImages = [];

  // Existing photo URLs (used in edit mode or manually added via URL)
  final List<String> _existingPhotoUrls = [];

  bool _isLoading = false;
  String _loadingMessage = 'Menyimpan data...';
  bool _showUrlInput = false;

  bool get _isEditMode => widget.studioToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.studioToEdit!;
      _nameController.text = s['nama_studio']?.toString() ?? '';
      _locationController.text = s['lokasi']?.toString() ?? '';
      _descriptionController.text = s['deskripsi']?.toString() ?? '';
      if (s['harga_per_jam'] != null) {
        _priceController.text = s['harga_per_jam'].toString().replaceAll(RegExp(r'\.00$'), '');
      }

      if (s['jam_buka'] != null) {
        final parts = s['jam_buka'].toString().split(':');
        if (parts.length >= 2) {
          _jamBuka = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
        }
      }

      if (s['jam_tutup'] != null) {
        final parts = s['jam_tutup'].toString().split(':');
        if (parts.length >= 2) {
          _jamTutup = TimeOfDay(hour: int.tryParse(parts[0]) ?? 23, minute: int.tryParse(parts[1]) ?? 0);
        }
      }

      if (s['fasilitas'] != null && s['fasilitas'] is List) {
        _selectedFacilities = (s['fasilitas'] as List).map((f) => f.toString()).toList();
      }

      // Load existing photos
      if (s['foto_urls'] != null && s['foto_urls'] is List && (s['foto_urls'] as List).isNotEmpty) {
        _existingPhotoUrls.addAll((s['foto_urls'] as List).map((u) => u.toString()));
      } else if (s['foto_url'] != null && s['foto_url'].toString().isNotEmpty) {
        _existingPhotoUrls.add(s['foto_url'].toString());
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customFacilityController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String _displayTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(bool isJamBuka) async {
    final initial = isJamBuka ? _jamBuka : _jamTutup;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isJamBuka) {
          _jamBuka = picked;
        } else {
          _jamTutup = picked;
        }
      });
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar dari galeri: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _pickedImages.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto dari kamera: $e')),
        );
      }
    }
  }

  void _addManualUrl() {
    final text = _customUrlController.text.trim();
    if (text.isNotEmpty) {
      if (!_existingPhotoUrls.contains(text)) {
        setState(() {
          _existingPhotoUrls.add(text);
          _customUrlController.clear();
          _showUrlInput = false;
        });
      } else {
        _customUrlController.clear();
      }
    }
  }

  void _addCustomFacility() {
    final text = _customFacilityController.text.trim();
    if (text.isNotEmpty) {
      if (!_selectedFacilities.contains(text)) {
        setState(() {
          _selectedFacilities.add(text);
          _customFacilityController.clear();
        });
      } else {
        _customFacilityController.clear();
      }
    }
  }

  Future<void> _submitStudio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFacilities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau tambahkan minimal 1 fasilitas studio')),
      );
      return;
    }

    final int totalPhotos = _existingPhotoUrls.length + _pickedImages.length;
    if (totalPhotos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 foto studio')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = _pickedImages.isNotEmpty ? 'Mengunggah foto studio...' : 'Menyimpan data...';
    });

    try {
      final List<String> finalPhotoUrls = List.from(_existingPhotoUrls);

      // 1. Upload local images to backend if any
      if (_pickedImages.isNotEmpty) {
        final formData = FormData();
        for (final xfile in _pickedImages) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(xfile.path, filename: xfile.name),
          ));
        }

        final uploadResponse = await _api.dio.post('/studios/upload', data: formData);
        if (uploadResponse.statusCode == 200 && uploadResponse.data['success']) {
          final List newUrls = uploadResponse.data['data']['urls'] ?? [];
          for (final u in newUrls) {
            finalPhotoUrls.add(u.toString());
          }
        } else {
          throw Exception(uploadResponse.data['message'] ?? 'Gagal mengunggah foto');
        }
      }

      setState(() {
        _loadingMessage = 'Menyimpan data studio...';
      });

      final double price = double.tryParse(_priceController.text.trim()) ?? 0;
      final String primaryPhoto = finalPhotoUrls.isNotEmpty ? finalPhotoUrls.first : '';

      final data = {
        'nama_studio': _nameController.text.trim(),
        'lokasi': _locationController.text.trim(),
        'jarak_statis': widget.studioToEdit?['jarak_statis'] ?? 2.5,
        'deskripsi': _descriptionController.text.trim(),
        'harga_per_jam': price,
        'rating': widget.studioToEdit?['rating'] ?? 5.0,
        'foto_url': primaryPhoto,
        'foto_urls': finalPhotoUrls,
        'jam_buka': _formatTimeOfDay(_jamBuka),
        'jam_tutup': _formatTimeOfDay(_jamTutup),
        'fasilitas': _selectedFacilities,
      };

      final response = _isEditMode
          ? await _api.dio.put('/studios/${widget.studioToEdit!['id']}', data: data)
          : await _api.dio.post('/studios', data: data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode ? 'Studio berhasil diperbarui!' : 'Studio berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Gagal menyimpan data studio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPhotoTile({
    required Widget imageWidget,
    required bool isFirst,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 140,
      height: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
        border: Border.all(
          color: isFirst ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isFirst ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 140,
              height: 140,
              child: imageWidget,
            ),
          ),
          if (isFirst)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Utama',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPhotos = _existingPhotoUrls.length + _pickedImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Studio' : 'Tambah Studio Baru'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION: FOTO STUDIO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Foto Studio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  Text(
                    '$totalPhotos Foto dipilih',
                    style: TextStyle(
                      fontSize: 13,
                      color: totalPhotos > 0 ? AppTheme.primaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Unggah foto studio dari galeri atau kamera (foto pertama akan dijadikan sampul utama):',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),

              // Action Buttons: Galeri & Kamera
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImagesFromGallery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 20),
                      label: const Text('Pilih Foto (Banyak)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImageFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text('Kamera'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Photos Preview Horizontal List
              if (totalPhotos > 0)
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Render existing photos from server / URL
                      ..._existingPhotoUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        final isFirst = index == 0;
                        return _buildPhotoTile(
                          isFirst: isFirst,
                          imageWidget: Image.network(
                            ApiService.getFullImageUrl(url),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                          onRemove: () {
                            setState(() {
                              _existingPhotoUrls.removeAt(index);
                            });
                          },
                        );
                      }),

                      // Render newly picked local photos from device
                      ..._pickedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final xfile = entry.value;
                        final isFirst = _existingPhotoUrls.isEmpty && index == 0;
                        return _buildPhotoTile(
                          isFirst: isFirst,
                          imageWidget: Image.file(
                            File(xfile.path),
                            fit: BoxFit.cover,
                          ),
                          onRemove: () {
                            setState(() {
                              _pickedImages.removeAt(index);
                            });
                          },
                        );
                      }),

                      // Quick Add Button inside the list
                      Container(
                        width: 100,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                          color: Colors.grey[50],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _pickImagesFromGallery,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primaryColor, size: 32),
                              SizedBox(height: 4),
                              Text('+ Tambah', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        const Text(
                          'Belum ada foto yang dipilih\nKlik tombol di atas untuk memilih foto studio',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Optional: Add URL accordion for flexibility
              TextButton.icon(
                onPressed: () => setState(() => _showUrlInput = !_showUrlInput),
                icon: Icon(_showUrlInput ? Icons.keyboard_arrow_up : Icons.link, size: 18),
                label: Text(
                  _showUrlInput ? 'Sembunyikan input URL' : 'Atau masukkan foto lewat link URL web',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              if (_showUrlInput) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: const Icon(Icons.link),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _addManualUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addManualUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Text('Tambah URL'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 24),

              // SECTION: INFORMASI UTAMA
              const Text(
                'Informasi Studio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Studio *',
                  hintText: 'Contoh: Senada Band Studio',
                  prefixIcon: const Icon(Icons.storefront_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama studio tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lokasi Studio *',
                  hintText: 'Contoh: Kemang, Jl. Puri Mutiara Raya No. 6',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga per Jam *',
                  hintText: 'Contoh: 75000',
                  prefixText: 'Rp ',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Harga per jam tidak boleh kosong';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Harga harus berupa angka valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Tentang Studio (Deskripsi)',
                  hintText: 'Deskripsikan ruang studio, akustik, kualitas alat, serta kenyamanan yang ditawarkan...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // SECTION: JAM OPERASIONAL
              const Text(
                'Jam Operasional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Jam Buka', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${_displayTimeOfDay(_jamBuka)} WIB',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Jam Tutup', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${_displayTimeOfDay(_jamTutup)} WIB',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SECTION: FASILITAS STUDIO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fasilitas Studio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  Text(
                    '${_selectedFacilities.length} dipilih',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih fasilitas yang tersedia di studio:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 10),

              // Preset facility choices
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _popularFacilities.map((fac) {
                  final isSelected = _selectedFacilities.contains(fac);
                  return FilterChip(
                    label: Text(fac),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.add(fac);
                        } else {
                          _selectedFacilities.remove(fac);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Custom facility input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customFacilityController,
                      decoration: InputDecoration(
                        hintText: 'Tambah fasilitas lain...',
                        prefixIcon: const Icon(Icons.add_circle_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _addCustomFacility(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomFacility,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Tambah'),
                  ),
                ],
              ),

              if (_selectedFacilities.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Fasilitas terpilih:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedFacilities.map((fac) {
                    return Chip(
                      label: Text(fac, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: AppTheme.primaryColor,
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onDeleted: () {
                        setState(() {
                          _selectedFacilities.remove(fac);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitStudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _loadingMessage,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Simpan Studio',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
