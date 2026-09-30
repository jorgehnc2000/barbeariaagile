class Service {
  const Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String? imageUrl;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString() ?? '',
      name: json['nome'] as String,
      description: json['descricao'] as String? ?? '',
      price: (json['preco'] as num).toDouble(),
      durationMinutes: json['duracao_minutos'] as int,
      imageUrl: json['imagem_url'] as String?,
    );
  }
}
