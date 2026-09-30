class Barber {
  const Barber({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.specialty,
    required this.isAvailable,
    this.rating = 5.0,
  });

  final String id;
  final String name;
  final String photoUrl;
  final String specialty;
  final bool isAvailable;
  final double rating;

  factory Barber.fromJson(Map<String, dynamic> json) {
    final specialties = json['especialidades'];
    var specialty = 'Barbeiro';
    if (specialties is List && specialties.isNotEmpty) {
      specialty = specialties.first.toString();
    }

    return Barber(
      id: json['id']?.toString() ?? '',
      name: json['nome'] as String,
      photoUrl: json['foto_url'] as String? ?? '',
      specialty: specialty,
      isAvailable: json['disponivel'] as bool? ?? true,
    );
  }
}
