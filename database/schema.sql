CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_lengkap VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  no_hp VARCHAR(50),
  poin_nada INT DEFAULT 0,
  role ENUM('user', 'admin') DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE studios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_studio VARCHAR(255) NOT NULL,
  lokasi VARCHAR(255) NOT NULL,
  jarak_statis DECIMAL(5,2),
  deskripsi TEXT,
  harga_per_jam DECIMAL(10,2) NOT NULL,
  rating DECIMAL(3,1) DEFAULT 0,
  foto_url VARCHAR(255),
  jam_buka TIME NOT NULL,
  jam_tutup TIME NOT NULL
);

CREATE TABLE studio_facilities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  studio_id INT NOT NULL,
  nama_fasilitas VARCHAR(100) NOT NULL,
  FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE
);

CREATE TABLE studio_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  studio_id INT NOT NULL,
  foto_url VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE
);


CREATE TABLE schedules (
  id INT AUTO_INCREMENT PRIMARY KEY,
  studio_id INT NOT NULL,
  tanggal DATE NOT NULL,
  jam_mulai TIME NOT NULL,
  status ENUM('Tersedia', 'Sudah dipesan') DEFAULT 'Tersedia',
  FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE
);

CREATE TABLE bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  studio_id INT NOT NULL,
  tanggal_booking DATE NOT NULL,
  jam_mulai TIME NOT NULL,
  jam_selesai TIME NOT NULL,
  durasi INT NOT NULL,
  metode_pembayaran ENUM('QRIS', 'E-Wallet', 'Transfer Bank') NOT NULL,
  total_harga DECIMAL(10,2) NOT NULL,
  status_pembayaran ENUM('Menunggu Konfirmasi', 'Lunas', 'Dibatalkan') DEFAULT 'Menunggu Konfirmasi',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (studio_id) REFERENCES studios(id) ON DELETE CASCADE
);

CREATE TABLE promos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  kode VARCHAR(50) NOT NULL UNIQUE,
  diskon_persen INT NOT NULL,
  aktif BOOLEAN DEFAULT TRUE
);
