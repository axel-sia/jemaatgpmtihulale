-- =====================================================================
-- DATABASE PORTAL JEMAAT GEREJA BETH EDEN - GPM TIHULALE
-- Dibuat dari struktur data website (Website_Tihulale_1.html)
-- Format: SQLite 3 (mudah dikonversi ke MySQL / PostgreSQL)
-- Catatan: tanggal = TEXT 'YYYY-MM-DD', uang = INTEGER (Rupiah),
--          foto & PDF disimpan sebagai path/URL file (bukan base64).
-- =====================================================================
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- A. MASTER
-- ---------------------------------------------------------------------
CREATE TABLE sektor (
  id    INTEGER PRIMARY KEY AUTOINCREMENT,
  nama  TEXT NOT NULL UNIQUE
);

CREATE TABLE peran (
  kode   TEXT PRIMARY KEY,
  label  TEXT NOT NULL
);

CREATE TABLE pengaturan (
  kunci  TEXT PRIMARY KEY,
  nilai  TEXT
);

CREATE TABLE profil_jemaat (
  kunci  TEXT PRIMARY KEY,          -- sejarah, visi, misi, alamat
  nilai  TEXT
);

CREATE TABLE pengurus (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  urutan   INTEGER NOT NULL,
  jabatan  TEXT NOT NULL,
  nama     TEXT
);

-- ---------------------------------------------------------------------
-- B. PENGGUNA & KEAMANAN
-- ---------------------------------------------------------------------
CREATE TABLE pengguna (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  nama               TEXT NOT NULL,
  username           TEXT NOT NULL UNIQUE,
  email              TEXT NOT NULL UNIQUE,
  peran              TEXT NOT NULL REFERENCES peran(kode),
  sektor_id          INTEGER REFERENCES sektor(id),      -- untuk Admin Sektor
  status             TEXT NOT NULL DEFAULT 'menunggu'
                     CHECK (status IN ('menunggu','aktif','nonaktif')),
  akses_keuangan     INTEGER NOT NULL DEFAULT 0 CHECK (akses_keuangan IN (0,1)),  -- khusus Ketua
  password_hash      TEXT NOT NULL,                      -- PBKDF2-SHA256
  salt               TEXT NOT NULL,
  pertanyaan_keamanan TEXT,
  jawaban_hash       TEXT,
  dibuat_pada        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE audit_log (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  waktu    TEXT NOT NULL DEFAULT (datetime('now')),
  user_id  INTEGER REFERENCES pengguna(id) ON DELETE SET NULL,
  user_label TEXT,                                       -- "Nama (Peran)" saat kejadian
  aksi     TEXT NOT NULL,
  modul    TEXT NOT NULL,
  detail   TEXT
);

-- ---------------------------------------------------------------------
-- C. DATA WARGA, MUTASI & REGISTER SAKRAMEN
-- ---------------------------------------------------------------------
CREATE TABLE warga (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  nama           TEXT NOT NULL,
  sektor_id      INTEGER NOT NULL REFERENCES sektor(id),
  kategori       TEXT NOT NULL DEFAULT 'Kepala Keluarga'
                 CHECK (kategori IN ('Kepala Keluarga','Istri','Janda','Duda','Pemuda','Anak')),
  status         TEXT NOT NULL DEFAULT 'Aktif'
                 CHECK (status IN ('Aktif','Pindah','Meninggal')),
  tanggal_lahir  TEXT,
  telepon        TEXT,
  alamat         TEXT,
  persetujuan    TEXT NOT NULL DEFAULT 'Disetujui'
                 CHECK (persetujuan IN ('Menunggu','Disetujui','Ditolak')),
  dibuat_oleh    INTEGER REFERENCES pengguna(id) ON DELETE SET NULL,
  dibuat_pada    TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX idx_warga_sektor ON warga(sektor_id, status);

CREATE TABLE pengajuan_pindah_sektor (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  warga_id        INTEGER NOT NULL REFERENCES warga(id) ON DELETE CASCADE,
  dari_sektor_id  INTEGER NOT NULL REFERENCES sektor(id),
  tujuan_sektor_id INTEGER NOT NULL REFERENCES sektor(id),
  alasan          TEXT,
  diajukan_oleh   INTEGER REFERENCES pengguna(id) ON DELETE SET NULL,
  tanggal         TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'Menunggu'
                  CHECK (status IN ('Menunggu','Disetujui','Ditolak'))
);

CREATE TABLE mutasi_jemaat (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  warga_id  INTEGER REFERENCES warga(id) ON DELETE SET NULL,
  nama      TEXT NOT NULL,
  jenis     TEXT NOT NULL CHECK (jenis IN ('Pindah Masuk','Pindah Keluar')),
  sektor_id INTEGER REFERENCES sektor(id),
  asal_tujuan TEXT,                                      -- jemaat asal / tujuan
  alasan    TEXT
);

CREATE TABLE register_sakramen (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  jenis           TEXT NOT NULL CHECK (jenis IN ('Baptis','Sidi','Pernikahan','Kematian')),
  nomor_register  TEXT NOT NULL UNIQUE,                  -- BAP/SID/NIK/KMT-...
  nama            TEXT NOT NULL,                         -- yg dibaptis / sidi / mempelai pria / almarhum
  nama_pasangan   TEXT,                                  -- mempelai wanita (Pernikahan)
  tanggal_lahir   TEXT,                                  -- Baptis
  nama_ayah       TEXT,                                  -- ayah / ayah mempelai pria
  nama_ibu        TEXT,                                  -- ibu / ibu mempelai pria
  nama_ayah_pasangan TEXT,                               -- ayah mempelai wanita
  nama_ibu_pasangan  TEXT,                               -- ibu mempelai wanita
  tanggal         TEXT NOT NULL,                         -- tgl baptis/sidi/nikah/meninggal
  tempat          TEXT,
  pelayan         TEXT,
  usia            INTEGER,                               -- Kematian
  keterangan      TEXT,                                  -- sebab/keterangan
  warga_id        INTEGER REFERENCES warga(id) ON DELETE SET NULL
);
CREATE INDEX idx_register_jenis ON register_sakramen(jenis, tanggal);

CREATE TABLE register_saksi (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  register_id INTEGER NOT NULL REFERENCES register_sakramen(id) ON DELETE CASCADE,
  pihak       TEXT NOT NULL DEFAULT 'Umum' CHECK (pihak IN ('Umum','Pria','Wanita')),
  urutan      INTEGER NOT NULL DEFAULT 1,
  nama        TEXT NOT NULL
);

CREATE TABLE catatan_pastoral (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal     TEXT NOT NULL,
  sektor_id   INTEGER REFERENCES sektor(id),
  warga_id    INTEGER REFERENCES warga(id) ON DELETE SET NULL,
  nama        TEXT NOT NULL,
  jenis       TEXT NOT NULL,   -- Kunjungan Rumah, Kunjungan Sakit, Kedukaan, Konseling / Penggembalaan, Doa & Ibadah Keluarga, dst.
  catatan     TEXT,
  tindak_lanjut TEXT,
  status      TEXT NOT NULL DEFAULT 'Perlu Tindak Lanjut'
              CHECK (status IN ('Perlu Tindak Lanjut','Dalam Pendampingan','Selesai')),
  dibuat_oleh INTEGER REFERENCES pengguna(id) ON DELETE SET NULL,
  dibuat_pada TEXT NOT NULL DEFAULT (date('now'))
);

CREATE TABLE radar_sektor (
  sektor_id    INTEGER PRIMARY KEY REFERENCES sektor(id),
  kondisi      TEXT NOT NULL CHECK (kondisi IN ('Kondusif','Butuh Pendampingan','Intervensi Ketua Majelis Jemaat')),
  isu          TEXT,
  tanggal      TEXT,
  status       TEXT NOT NULL DEFAULT 'Menunggu' CHECK (status IN ('Menunggu','Disetujui','Ditolak')),
  diajukan_oleh INTEGER REFERENCES pengguna(id) ON DELETE SET NULL
);

-- Jurnal inputan Admin Sektor -> dilaporkan ke Sekretaris
CREATE TABLE laporan_sektor (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  sektor_id INTEGER NOT NULL REFERENCES sektor(id),
  oleh      INTEGER REFERENCES pengguna(id) ON DELETE SET NULL,
  tanggal   TEXT NOT NULL,
  catatan   TEXT,
  status    TEXT NOT NULL DEFAULT 'Terkirim',
  dibuat_pada TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE jurnal_sektor (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  sektor_id  INTEGER NOT NULL REFERENCES sektor(id),
  tanggal    TEXT NOT NULL,
  aksi       TEXT NOT NULL,                              -- mis. Tambah Warga, Pindah Sektor
  nama       TEXT,
  lawan      TEXT,                                       -- sektor asal/tujuan bila ada
  warga_id   INTEGER REFERENCES warga(id) ON DELETE SET NULL,
  laporan_id INTEGER REFERENCES laporan_sektor(id) ON DELETE SET NULL  -- NULL = belum dilaporkan
);

-- ---------------------------------------------------------------------
-- D. ADMINISTRASI: SURAT, SK, NOTULEN, PROGRAM
-- ---------------------------------------------------------------------
CREATE TABLE surat (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  nomor         TEXT NOT NULL,
  nomor_jenis   TEXT,                                    -- kode penomoran otomatis
  nomor_tahun   INTEGER,
  nomor_urut    INTEGER,
  tanggal       TEXT NOT NULL,
  jenis         TEXT NOT NULL CHECK (jenis IN ('Surat Masuk','Surat Keluar')),
  kategori      TEXT,        -- Undangan, Pemberitahuan, Permohonan, Laporan, Keuangan, Pelayanan & Pastoral, Edaran, ...
  pihak         TEXT,        -- pengirim (masuk) / tujuan (keluar)
  diterima_oleh TEXT,
  perihal       TEXT NOT NULL,
  lampiran      TEXT,
  isi           TEXT,
  keterangan    TEXT,
  berkas_pdf    TEXT,                                    -- path/URL (maks. 2 MB)
  status        TEXT NOT NULL DEFAULT 'Menunggu' CHECK (status IN ('Menunggu','Disetujui','Ditolak')),
  disetujui_oleh TEXT,
  tgl_setuju    TEXT,
  dibuat_oleh   INTEGER REFERENCES pengguna(id) ON DELETE SET NULL
);
CREATE INDEX idx_surat_tanggal ON surat(tanggal);

CREATE TABLE disposisi_surat (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  surat_id    INTEGER NOT NULL REFERENCES surat(id) ON DELETE CASCADE,
  tujuan      TEXT NOT NULL,       -- Ketua, Sekretaris, Bendahara, Seksi ..., dst.
  instruksi   TEXT,
  tenggat     TEXT,
  status      TEXT NOT NULL DEFAULT 'Baru'
);

CREATE TABLE sk (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  nomor        TEXT NOT NULL,
  nomor_jenis  TEXT,
  nomor_tahun  INTEGER,
  nomor_urut   INTEGER,
  jenis        TEXT NOT NULL DEFAULT 'Pengangkatan Panitia',   -- atau Pengangkatan Pelayan
  nama         TEXT NOT NULL,
  tanggal      TEXT NOT NULL,
  tempat       TEXT DEFAULT 'Tihulale',
  menimbang    TEXT,
  mengingat    TEXT,
  masa         TEXT,
  sekretaris   TEXT,
  status       TEXT NOT NULL DEFAULT 'Diterbitkan',
  diterbitkan_oleh TEXT,
  tgl_terbit   TEXT
);

CREATE TABLE sk_anggota (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  sk_id    INTEGER NOT NULL REFERENCES sk(id) ON DELETE CASCADE,
  urutan   INTEGER NOT NULL,
  jabatan  TEXT NOT NULL,
  nama     TEXT NOT NULL
);

CREATE TABLE notulen (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  jenis     TEXT NOT NULL CHECK (jenis IN ('Sidang Jemaat','Rapat Majelis Jemaat','Rapat Ketua Majelis Jemaat')),
  judul     TEXT NOT NULL,
  tanggal   TEXT NOT NULL,
  tempat    TEXT,
  pimpinan  TEXT,
  notulis   TEXT,
  peserta   TEXT,
  agenda    TEXT,
  isi       TEXT
);

CREATE TABLE keputusan_rapat (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  notulen_id  INTEGER NOT NULL REFERENCES notulen(id) ON DELETE CASCADE,
  teks        TEXT NOT NULL,
  penanggung_jawab TEXT,
  target      TEXT,
  status      TEXT NOT NULL DEFAULT 'Belum' CHECK (status IN ('Belum','Berjalan','Selesai'))
);

CREATE TABLE program_pelayanan (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tahun     INTEGER NOT NULL,
  unit      TEXT NOT NULL,
  nama      TEXT NOT NULL,
  target    TEXT,
  capaian   INTEGER NOT NULL DEFAULT 0 CHECK (capaian BETWEEN 0 AND 100),
  status    TEXT NOT NULL DEFAULT 'Direncanakan'
            CHECK (status IN ('Direncanakan','Berjalan','Selesai','Tertunda')),
  anggaran  INTEGER,
  hasil     TEXT
);

CREATE TABLE pelkes_meta (
  tahun        INTEGER PRIMARY KEY,
  pendahuluan  TEXT,
  evaluasi     TEXT,
  ketua        TEXT,
  sekretaris   TEXT
);

-- ---------------------------------------------------------------------
-- E. KEUANGAN
-- ---------------------------------------------------------------------
CREATE TABLE kas_umum (                    -- buku kas sederhana (menu Keuangan lama)
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal    TEXT NOT NULL,
  uraian     TEXT NOT NULL,
  jenis      TEXT NOT NULL CHECK (jenis IN ('Pemasukan','Pengeluaran')),
  jumlah     INTEGER NOT NULL CHECK (jumlah >= 0),
  program_id INTEGER REFERENCES program_pelayanan(id) ON DELETE SET NULL
);

CREATE TABLE penerimaan_ibadah (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal  TEXT NOT NULL,
  uraian   TEXT NOT NULL,
  metode   TEXT CHECK (metode IN ('Tunai','Transfer Bank')),
  jumlah   INTEGER NOT NULL CHECK (jumlah >= 0)
);

CREATE TABLE persepuluhan (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  sektor_id INTEGER NOT NULL REFERENCES sektor(id),
  jumlah    INTEGER NOT NULL CHECK (jumlah >= 0)
);

CREATE TABLE pengeluaran (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  seksi     TEXT NOT NULL,     -- Seksi Ibadah, Seksi Diakonia, Seksi Pembangunan, AMGPM, Wadah Perempuan, Koinonia, Operasional...
  kategori  TEXT NOT NULL CHECK (kategori IN ('Insentif Pelayan','Operasional Gedung Gereja','Belanja Inventaris','Kegiatan Seksi','Lainnya')),
  uraian    TEXT NOT NULL,
  jumlah    INTEGER NOT NULL CHECK (jumlah >= 0)
);
CREATE INDEX idx_pengeluaran_seksi ON pengeluaran(seksi, tanggal);

CREATE TABLE pagu_apbj (
  tahun   INTEGER NOT NULL,
  seksi   TEXT NOT NULL,
  jumlah  INTEGER NOT NULL DEFAULT 0 CHECK (jumlah >= 0),
  PRIMARY KEY (tahun, seksi)
);

CREATE TABLE disposisi_dana (               -- E-Disposisi pengajuan dana
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  seksi     TEXT NOT NULL,
  kegiatan  TEXT NOT NULL,
  pengaju   TEXT,
  jumlah    INTEGER NOT NULL CHECK (jumlah >= 0),
  status    TEXT NOT NULL DEFAULT 'Menunggu',    -- Menunggu / Disetujui / Ditolak / Dicairkan
  pengeluaran_id INTEGER REFERENCES pengeluaran(id) ON DELETE SET NULL
);

CREATE TABLE setoran_sentral (              -- setoran ke Sinode GPM
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  periode   TEXT NOT NULL,
  bank      TEXT NOT NULL DEFAULT 'Rekening Sinode GPM',
  jumlah    INTEGER NOT NULL CHECK (jumlah >= 0),
  bukti     TEXT                                     -- path/URL foto bukti transfer
);

CREATE TABLE dana_darurat (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal   TEXT NOT NULL,
  jenis     TEXT NOT NULL CHECK (jenis IN ('Diakonia','Kedukaan','Penanggulangan Bencana','Bantuan Kemanusiaan')),
  penerima  TEXT NOT NULL,
  jumlah    INTEGER NOT NULL CHECK (jumlah >= 0),
  keterangan TEXT
);

CREATE TABLE rekening_pembangunan (
  id    INTEGER PRIMARY KEY CHECK (id = 1),          -- hanya 1 rekening aktif
  bank  TEXT NOT NULL,
  no    TEXT NOT NULL,
  an    TEXT NOT NULL
);

CREATE TABLE saldo_publik (                 -- kartu saldo yang tampil di beranda publik
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  tipe        TEXT NOT NULL CHECK (tipe IN ('minggu','bulan','tahun')),
  label       TEXT NOT NULL,
  tanggal     TEXT NOT NULL,
  masuk       INTEGER NOT NULL DEFAULT 0,
  keluar      INTEGER NOT NULL DEFAULT 0,
  selisih     INTEGER NOT NULL DEFAULT 0,
  saldo_akhir INTEGER NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------
-- F. KONTEN PUBLIK (BERANDA)
-- ---------------------------------------------------------------------
CREATE TABLE agenda_jemaat (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  judul      TEXT NOT NULL,
  kategori   TEXT NOT NULL CHECK (kategori IN ('Jadwal Ibadah','Hari Besar','Pembangunan','Pelayanan','Pengumuman')),
  waktu      TEXT NOT NULL,
  deskripsi  TEXT,
  foto       TEXT
);

CREATE TABLE agenda_sektor (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  sektor_id   INTEGER NOT NULL REFERENCES sektor(id),
  judul       TEXT NOT NULL,
  kategori    TEXT NOT NULL CHECK (kategori IN ('Jadwal Ibadah','Pelayanan','Pengumuman','Hari Besar','Pembangunan')),
  waktu       TEXT NOT NULL,
  deskripsi   TEXT,
  foto        TEXT,
  tayang      TEXT NOT NULL DEFAULT 'Ya' CHECK (tayang IN ('Ya','Tidak')),
  status      TEXT NOT NULL DEFAULT 'Menunggu' CHECK (status IN ('Menunggu','Disetujui','Ditolak')),
  diajukan_oleh INTEGER REFERENCES pengguna(id) ON DELETE SET NULL
);

CREATE TABLE jadwal_ibadah (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal     TEXT NOT NULL,
  jam         TEXT,                                  -- WIT
  tempat      TEXT,                                  -- Gedung Gereja Beth Eden / Sektor / Rumah Jemaat / Lainnya
  tempat_lain TEXT,
  jenis       TEXT NOT NULL,
  unit        TEXT,
  tema        TEXT,
  pelayan     TEXT,
  keterangan  TEXT
);
CREATE INDEX idx_ibadah_tanggal ON jadwal_ibadah(tanggal);

CREATE TABLE renungan (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal  TEXT NOT NULL,
  judul    TEXT NOT NULL,
  ayat     TEXT NOT NULL,
  teks     TEXT,
  isi      TEXT,
  doa      TEXT,
  penulis  TEXT
);

CREATE TABLE warta (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  tanggal     TEXT NOT NULL,
  judul       TEXT NOT NULL,
  bacaan      TEXT,
  ibadah      TEXT,
  pengumuman  TEXT,
  syukur      TEXT,
  kolekte     INTEGER,
  penulis     TEXT
);

CREATE TABLE buletin (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  edisi      TEXT NOT NULL,
  deskripsi  TEXT,
  status     TEXT NOT NULL DEFAULT 'Terbit' CHECK (status IN ('Terbit','Draf')),
  berkas_pdf TEXT NOT NULL,
  nama_berkas TEXT
);

CREATE TABLE panitia_pembangunan (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  urutan   INTEGER NOT NULL DEFAULT 0,
  jabatan  TEXT NOT NULL,
  nama     TEXT NOT NULL
);

CREATE TABLE foto_beranda (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  foto       TEXT NOT NULL,
  keterangan TEXT
);

CREATE TABLE foto_pembangunan (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  foto       TEXT NOT NULL,
  keterangan TEXT
);

-- ---------------------------------------------------------------------
-- G. VIEW LAPORAN
-- ---------------------------------------------------------------------
CREATE VIEW v_warga_per_sektor AS
SELECT s.nama AS sektor,
       COALESCE(SUM(w.status = 'Aktif'),0)     AS aktif,
       COALESCE(SUM(w.status = 'Pindah'),0)    AS pindah,
       COALESCE(SUM(w.status = 'Meninggal'),0) AS meninggal,
       COUNT(w.id)                 AS total
FROM sektor s LEFT JOIN warga w ON w.sektor_id = s.id
GROUP BY s.id;

CREATE VIEW v_kas_tahunan AS
SELECT t AS tahun,
       SUM(masuk) AS total_masuk, SUM(keluar) AS total_keluar,
       SUM(masuk) - SUM(keluar) AS saldo
FROM (
  SELECT substr(tanggal,1,4) AS t, jumlah AS masuk, 0 AS keluar FROM penerimaan_ibadah
  UNION ALL SELECT substr(tanggal,1,4), jumlah, 0 FROM persepuluhan
  UNION ALL SELECT substr(tanggal,1,4), 0, jumlah FROM pengeluaran
  UNION ALL SELECT substr(tanggal,1,4), 0, jumlah FROM setoran_sentral
  UNION ALL SELECT substr(tanggal,1,4), 0, jumlah FROM dana_darurat
) GROUP BY t;

CREATE VIEW v_sisa_pagu AS
SELECT p.tahun, p.seksi, p.jumlah AS pagu,
       COALESCE((SELECT SUM(e.jumlah) FROM pengeluaran e
                 WHERE e.seksi = p.seksi AND substr(e.tanggal,1,4) = CAST(p.tahun AS TEXT)),0) AS terpakai,
       p.jumlah - COALESCE((SELECT SUM(e.jumlah) FROM pengeluaran e
                 WHERE e.seksi = p.seksi AND substr(e.tanggal,1,4) = CAST(p.tahun AS TEXT)),0) AS sisa
FROM pagu_apbj p;

CREATE VIEW v_realisasi_program AS
SELECT g.id, g.tahun, g.unit, g.nama, g.anggaran,
       COALESCE(SUM(k.jumlah),0) AS realisasi,
       CASE WHEN COALESCE(SUM(k.jumlah),0) = 0 THEN 'Belum ada realisasi'
            WHEN g.anggaran IS NOT NULL AND SUM(k.jumlah) > g.anggaran THEN 'Melebihi anggaran'
            ELSE 'Sesuai anggaran' END AS keterangan
FROM program_pelayanan g
LEFT JOIN kas_umum k ON k.program_id = g.id AND k.jenis = 'Pengeluaran'
GROUP BY g.id;

CREATE VIEW v_keputusan_terlambat AS
SELECT n.tanggal, n.jenis AS rapat, n.judul, k.teks, k.penanggung_jawab, k.target, k.status
FROM keputusan_rapat k JOIN notulen n ON n.id = k.notulen_id
WHERE k.status <> 'Selesai' AND k.target IS NOT NULL AND k.target < date('now');
