-- DATA AWAL (diambil dari bawaan website)
INSERT INTO sektor(nama) VALUES ('Sektor Sion'),('Sektor Galelia'),('Sektor Ebenhaezer'),('Sektor Getsemany'),('Sektor Tiberias'),('Sektor Betlehem');

INSERT INTO peran(kode,label) VALUES
 ('admin','Admin'),('adminsektor','Admin Sektor'),('ketua','Ketua Majelis Jemaat'),
 ('sekretaris','Sekretaris'),('bendahara','Bendahara');

INSERT INTO profil_jemaat(kunci,nilai) VALUES
 ('sejarah','Jemaat Gereja Beth Eden berdiri sejak tahun 1935 dan berada di Desa Tihulale, Kecamatan Amalatu, Kabupaten Seram Bagian Barat, Provinsi Maluku, sebagai bagian dari Gereja Protestan Maluku (GPM).

Sejak awal berdirinya, jemaat terus bertumbuh dalam ibadah, pelayanan, perayaan hari besar gerejawi, dan pembangunan fasilitas jemaat.'),
 ('visi','Menjadi jemaat yang hidup dalam kasih Kristus, bersekutu, bersaksi, dan melayani.'),
 ('misi','Menyelenggarakan ibadah dan pembinaan iman warga jemaat.
Memperkuat persekutuan antarwarga dan antarsektor.
Melayani sesama dan masyarakat sekitar dengan kasih.
Menyelesaikan pembangunan gedung gereja baru secara gotong royong.'),
 ('alamat','Desa Tihulale, Kecamatan Amalatu, Kabupaten Seram Bagian Barat, Provinsi Maluku.');

INSERT INTO pengurus(urutan,jabatan,nama) VALUES
 (1,'Ketua Majelis Jemaat',NULL),(2,'Wakil Ketua',NULL),(3,'Sekretaris',NULL),(4,'Bendahara',NULL),
 (5,'Seksi Ibadah',NULL),(6,'Seksi Diakonia',NULL),(7,'Seksi Pembangunan',NULL),(8,'Seksi Pemuda',NULL);

INSERT INTO pengaturan(kunci,nilai) VALUES
 ('sentral_persen_kas','75'),('sentral_persen_sinode','25');

INSERT INTO rekening_pembangunan(id,bank,no,an) VALUES
 (1,'Bank Rakyat Indonesia (BRI)','0000000000000000','Panitia Pembangunan Gereja Beth Eden');

INSERT INTO agenda_jemaat(judul,kategori,waktu,deskripsi) VALUES
 ('Ibadah Raya Minggu','Jadwal Ibadah','Setiap Minggu, 09.00 WIT','Ibadah raya jemaat setiap hari Minggu. Seluruh warga jemaat diundang hadir.'),
 ('Perayaan Natal Jemaat','Hari Besar','25 Desember','Persiapan ibadah dan perayaan Natal bersama seluruh sektor pelayanan.'),
 ('Kerja Bakti Gedung Gereja','Pembangunan','Sabtu, Pukul 08.00','Gotong royong seluruh warga untuk menunjang pembangunan gedung gereja baru.'),
 ('Latihan Paduan Suara','Pelayanan','Setiap Kamis, 19.00 WIT','Latihan rutin paduan suara jemaat. Terbuka bagi pemuda dan orang dewasa.');

INSERT INTO renungan(tanggal,judul,ayat,teks,isi,doa,penulis) VALUES
 (date('now'),'Tuhan adalah Gembalaku','Mazmur 23:1','TUHAN adalah gembalaku, takkan kekurangan aku.',
 'Seorang gembala mengenal setiap dombanya, menuntun ke padang rumput yang hijau dan menjaga dari bahaya.

Dalam setiap musim hidup, entah penuh sukacita atau penuh pergumulan, kita tidak berjalan sendirian. Tuhan setia menuntun dan mencukupkan kebutuhan kita.

Hari ini, percayakan langkah Anda kepada Gembala yang baik.',
 'Tuhan Yesus, terima kasih sebab Engkau menuntun dan mencukupkan kami. Ajar kami percaya sepenuhnya kepada-Mu. Amin.',
 'Majelis Jemaat Gereja Beth Eden');
