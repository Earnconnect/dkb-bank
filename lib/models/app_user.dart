enum BenutzerStatus { aktiv, gesperrt, geschlossen }

class AppUser {
  final String id;
  final String name;
  final String kontonummer;
  String pin;
  final String email;
  final String adresse;
  BenutzerStatus status;
  final DateTime kundeSeit;

  AppUser({
    required this.id,
    required this.name,
    required this.kontonummer,
    required this.pin,
    required this.email,
    required this.adresse,
    this.status = BenutzerStatus.aktiv,
    required this.kundeSeit,
  });

  bool get isAktiv => status == BenutzerStatus.aktiv;

  String get initialen {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get statusLabel {
    switch (status) {
      case BenutzerStatus.aktiv:
        return 'Aktiv';
      case BenutzerStatus.gesperrt:
        return 'Gesperrt';
      case BenutzerStatus.geschlossen:
        return 'Geschlossen';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kontonummer': kontonummer,
        'pin': pin,
        'email': email,
        'adresse': adresse,
        'status': status.index,
        'kundeSeit': kundeSeit.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        name: json['name'],
        kontonummer: json['kontonummer'],
        pin: json['pin'],
        email: json['email'],
        adresse: json['adresse'],
        status: BenutzerStatus.values[json['status'] ?? 0],
        kundeSeit: DateTime.parse(json['kundeSeit']),
      );
}
