-- Seed Studios
INSERT INTO studios (nama_studio, lokasi, jarak_statis, deskripsi, harga_per_jam, rating, foto_url, jam_buka, jam_tutup) VALUES
('Sonic Space Studio', 'Kemang, Jakarta Selatan', 1.2, 'Ruang latihan kedap suara dengan perangkat profesional, cocok untuk band, rekaman demo, dan latihan rutin.', 120000.00, 4.9, 'studio1.jpg', '09:00:00', '23:00:00'),
('Echo Room Records', 'Cilandak, Jakarta Selatan', 2.4, 'Studio rekaman terbaik untuk vokal dan instrumen akustik.', 150000.00, 4.8, 'studio2.jpg', '10:00:00', '22:00:00'),
('Groove Lab', 'Tebet, Jakarta Selatan', 3.1, 'Tempat asik buat nge-jam bareng teman. Piano akustik tersedia.', 100000.00, 4.7, 'studio3.jpg', '08:00:00', '00:00:00'),
('Pulse Creative Studio', 'Pancoran, Jakarta Selatan', 4.5, 'Sangat cocok untuk podcast dan rekaman vokal solo.', 90000.00, 4.5, 'studio4.jpg', '09:00:00', '21:00:00'),
('Zyn Room Records', 'Kuningan, Jakarta Selatan', 5.2, 'Ruang luas untuk latihan band besar dengan akustik ruangan memukau.', 180000.00, 4.9, 'studio5.jpg', '11:00:00', '23:00:00'),
('Rexa Studio', 'Mampang, Jakarta Selatan', 2.8, 'Pilihan hemat untuk latihan reguler.', 80000.00, 4.3, 'studio6.jpg', '10:00:00', '20:00:00');

-- Seed Facilities
INSERT INTO studio_facilities (studio_id, nama_fasilitas) VALUES
(1, 'Drum'), (1, 'Ampli'), (1, 'Mixer'), (1, 'AC'), (1, 'Wi-Fi'),
(2, 'Vokal'), (2, 'Mixer'), (2, 'Mic'), (2, 'AC'),
(3, 'Piano'), (3, 'Drum'), (3, 'Wi-Fi'), (3, 'AC'),
(4, 'Podcast'), (4, 'Mic'), (4, 'Wi-Fi'),
(5, 'Drum'), (5, 'Ampli'), (5, 'Mixer'), (5, 'AC'),
(6, 'Drum'), (6, 'Ampli');

-- Seed Promo
INSERT INTO promos (kode, diskon_persen, aktif) VALUES
('NADABARU', 25, TRUE);

-- Seed Schedules (example for Sonic Space Studio for the next few days)
INSERT INTO schedules (studio_id, tanggal, jam_mulai, status) VALUES
(1, CURDATE(), '13:00:00', 'Tersedia'),
(1, CURDATE(), '14:00:00', 'Tersedia'),
(1, CURDATE(), '15:00:00', 'Tersedia'),
(1, CURDATE(), '16:00:00', 'Tersedia'),
(2, CURDATE(), '10:00:00', 'Tersedia'),
(2, CURDATE(), '11:00:00', 'Tersedia');
