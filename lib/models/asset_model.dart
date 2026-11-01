class AssetModel {
  final int? id;
  final String nama;
  final String kategori;
  final String tanggalBeli;
  final double hargaBeli;
  final String? catatan;

  AssetModel({
    this.id,
    required this.nama,
    required this.kategori,
    required this.tanggalBeli,
    required this.hargaBeli,
    this.catatan,
  });

  // Mengubah dari Object Flutter ke Map (format yang dipahami SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'tanggalBeli': tanggalBeli,
      'hargaBeli': hargaBeli,
      'catatan': catatan,
    };
  }

  // Mengubah dari Map SQLite kembali menjadi Object Flutter
  factory AssetModel.fromMap(Map<String, dynamic> map) {
    return AssetModel(
      id: map['id'],
      nama: map['nama'],
      kategori: map['kategori'],
      tanggalBeli: map['tanggalBeli'],
      hargaBeli: map['hargaBeli'],
      catatan: map['catatan'],
    );
  }
}