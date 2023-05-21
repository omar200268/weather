import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather/main.dart';
import 'package:weather/monthly.dart';
import 'package:weather/radar.dart';

void main() => runApp(const HourlyPage());

class HourlyPage extends StatelessWidget {
  const HourlyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hava Durumu',
      theme: ThemeData(
        brightness: Brightness.dark, // Dark Mode
        primarySwatch: Colors.blue,
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherData {
  final String date;
  final double temperature;
  final String weatherCondition;
  final double windSpeed;
  final int humidity;
  final double rainProbability;
  final List<WeatherForecast> hourlyForecasts;

  WeatherData({
    required this.date,
    required this.temperature,
    required this.weatherCondition,
    required this.windSpeed,
    required this.humidity,
    required this.rainProbability,
    required this.hourlyForecasts,
  });
}

class WeatherForecast {
  final DateTime time;
  final String weatherCondition;
  final IconData weatherIcon;
  final double rainProbability;

  WeatherForecast({
    required this.time,
    required this.weatherCondition,
    required this.weatherIcon,
    required this.rainProbability,
  });
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String cityName = 'Istanbul';
  List<WeatherData> weatherForecasts = [];
  late String lastUpdatedTime;

  Future<Map<String, dynamic>> getWeatherData(String cityName) async {
    const String apiKey = 'f62affb5257db99e981a28bff419d8db';
    final String apiUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$apiKey&lang=tr&units=metric';

    final response = await http.get(Uri.parse(apiUrl));
    return json.decode(response.body);
  }

  void parseWeatherData(Map<String, dynamic> weatherData) {
    final List<dynamic> forecasts = weatherData['list'];

    String currentDate = '';
    WeatherData? currentWeatherData;
    List<WeatherForecast> hourlyForecasts = [];

    for (var forecast in forecasts) {
      final DateTime time =
          DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final String date = time.toString().substring(0, 10);
      final String weatherCondition = forecast['weather'][0]['description'];
      final IconData weatherIcon =
          _getWeatherIcon(forecast['weather'][0]['icon']);
      final double rainProbability =
          forecast.containsKey('rain') ? forecast['rain']['3h'].toDouble() : 0;

      // Günlük hava durumu verileri
      if (currentDate.isEmpty) {
        currentDate = date;
        currentWeatherData = WeatherData(
          date: currentDate,
          temperature: forecast['main']['temp'].toDouble(),
          weatherCondition: weatherCondition,
          windSpeed: forecast['wind']['speed'].toDouble(),
          humidity: forecast['main']['humidity'],
          rainProbability: rainProbability,
          hourlyForecasts: hourlyForecasts,
        );
      }

      // Saatlik hava tahminleri
      if (currentDate == date) {
        hourlyForecasts.add(
          WeatherForecast(
            time: time,
            weatherCondition: weatherCondition,
            weatherIcon: weatherIcon,
            rainProbability: rainProbability,
          ),
        );
      } else {
        // Yeni bir güne geçtiğimizde, önceki günlük veriyi ekle ve yeni güne başla
        weatherForecasts.add(currentWeatherData!);
        currentDate = date;
        hourlyForecasts = [
          WeatherForecast(
            time: time,
            weatherCondition: weatherCondition,
            weatherIcon: weatherIcon,
            rainProbability: rainProbability,
          ),
        ];
        currentWeatherData = WeatherData(
          date: currentDate,
          temperature: forecast['main']['temp'].toDouble(),
          weatherCondition: weatherCondition,
          windSpeed: forecast['wind']['speed'].toDouble(),
          humidity: forecast['main']['humidity'],
          rainProbability: rainProbability,
          hourlyForecasts: hourlyForecasts,
        );
      }
    }

    // Son günlük hava durumu verisini ekle
    if (currentWeatherData != null) {
      weatherForecasts.add(currentWeatherData);
    }

    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm');
    lastUpdatedTime = formatter.format(now);
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
      case '02n':
      case '03d':
      case '03n':
        return Icons.wb_cloudy;
      case '04d':
      case '04n':
        return Icons.cloud;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.beach_access;
      case '11d':
      case '11n':
        return Icons.bolt;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.cloud_circle;
      default:
        return Icons.help_outline;
    }
  }

  void refreshWeatherData(String cityName) async {
    final Map<String, dynamic> weatherData = await getWeatherData(cityName);
    setState(() {
      weatherForecasts = [];
      parseWeatherData(weatherData);
    });
  }

  @override
  void initState() {
    super.initState();
    refreshWeatherData(cityName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hava Durumu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final cityName = await showSearch(
                context: context,
                delegate: CitySearchDelegate(),
              );
              if (cityName != null) {
                refreshWeatherData(cityName);
              }
            },
          ),
        ],
      ),
      body: weatherForecasts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        lastUpdatedTime,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: weatherForecasts.length,
                    itemBuilder: (context, index) {
                      final weatherData = weatherForecasts[index];
                      return WeatherCard(weatherData: weatherData);
                    },
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MyApp()),
                          );
                        },
                        icon: const Icon(Icons.today),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HourlyPage()),
                          );
                        },
                        icon: const Icon(Icons.schedule),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MonthlyPage()),
                          );
                        },
                        icon: const Icon(Icons.calendar_today),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RadarPage()),
                          );
                        },
                        icon: const Icon(Icons.radar),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class WeatherCard extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherCard({Key? key, required this.weatherData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              weatherData.date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Icon(
                      weatherData.hourlyForecasts[0].weatherIcon,
                      size: 48,
                    ),
                    Text(
                      weatherData.weatherCondition,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${weatherData.temperature.toStringAsFixed(1)} °C',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Wind: ${weatherData.windSpeed.toStringAsFixed(1)} m/s',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Humidity: ${weatherData.humidity}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rain: ${weatherData.rainProbability.toStringAsFixed(1)} mm',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: weatherData.hourlyForecasts.length,
              itemBuilder: (context, index) {
                final forecast = weatherData.hourlyForecasts[index];
                return Column(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(forecast.time),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Icon(forecast.weatherIcon),
                    Text(
                      '${forecast.rainProbability.toStringAsFixed(1)} mm',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CitySearchDelegate extends SearchDelegate<String> {
  final List<String> cities = [
    'Istanbul',
    'Ankara',
    'Sivas',
    'kayseri',
    'Tokat',
    'Berlin',
  ];

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white70,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final cityName = cities[index];
        return ListTile(
          title: Text(cityName),
          onTap: () {
            close(context, cityName);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestionList = query.isEmpty
        ? cities
        : cities
            .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
            .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        final cityName = suggestionList[index];
        return ListTile(
          title: Text(cityName),
          onTap: () {
            close(context, cityName);
          },
        );
      },
    );
  }
}
