class CountryModel {
  const CountryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class StateModel {
  const StateModel({
    required this.id,
    required this.countryId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final int countryId;
  final String name;
  final double latitude;
  final double longitude;

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      id: json['id'] as int,
      countryId: json['country_id'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class WeatherModel {
  const WeatherModel({
    required this.stateId,
    required this.stateName,
    required this.countryName,
    required this.temperatureCelsius,
  });

  final int stateId;
  final String stateName;
  final String countryName;
  final double temperatureCelsius;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      stateId: json['state_id'] as int,
      stateName: json['state_name'] as String,
      countryName: json['country_name'] as String,
      temperatureCelsius: (json['temperature_celsius'] as num).toDouble(),
    );
  }
}
