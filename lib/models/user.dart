class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  UserProfile copyWith({String? name, String? phone, String? avatarUrl}) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['telefone'] as String? ?? json['whatsapp'] as String?,
      avatarUrl: json['foto_url'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nome': name,
      if (phone != null) 'telefone': phone,
      if (avatarUrl != null) 'foto_url': avatarUrl,
    };
  }
}
