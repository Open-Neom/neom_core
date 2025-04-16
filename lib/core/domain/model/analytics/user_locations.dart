class UserLocations {

  String dateId;
  int totalUsers;
  int totalLocations;
  Map<String, int>? locationCounts;

  UserLocations({
    this.dateId = '',
    this.totalUsers = 0,
    this.totalLocations = 0,
    this.locationCounts,
  });

  factory UserLocations.fromJSON(json) {
    // Convertir los valores de totalUsers y totalLocations a int,
    // en caso de que vengan como String.
    int totalUsers = int.tryParse(json['totalUsers'].toString()) ?? 0;
    int totalLocations = int.tryParse(json['totalLocations'].toString()) ?? 0;

    // Clonar el mapa para separar los campos de conteo de ubicaciones.
    final Map<String, dynamic> countsJson = Map<String, dynamic>.from(json);
    countsJson.remove('totalUsers');
    countsJson.remove('totalLocations');

    // Convertir cada valor a int.
    Map<String, int> locationCounts = countsJson.map((key, value) =>
        MapEntry(key, int.tryParse(value.toString()) ?? 0));

    return UserLocations(
      totalUsers: totalUsers,
      totalLocations: totalLocations,
      locationCounts: locationCounts,
    );
  }

  Map<String, dynamic> toJSON() {
    final Map<String, dynamic> data = {
      'totalUsers': totalUsers.toString(),
      'totalLocations': totalLocations.toString(),
    };

    // Se agregan los conteos de cada ubicación.
    locationCounts?.forEach((key, value) {
      data[key] = value.toString();
    });
    return data;
  }
}
