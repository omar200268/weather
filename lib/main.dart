import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather/hourly.dart';
import 'package:weather/monthly.dart';
import 'package:weather/radar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const WeatherPage({super.key});

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
        if (currentWeatherData != null) {
          weatherForecasts.add(currentWeatherData);
        }

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

    if (currentWeatherData != null) {
      weatherForecasts.add(currentWeatherData);
    }
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight_round;
      case '02d':
      case '02n':
        return Icons.wb_cloudy;
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icons.cloud;
      case '09d':
      case '09n':
        return Icons.grain;
      case '10d':
      case '10n':
        return Icons.wb_cloudy;
      case '11d':
      case '11n':
        return Icons.bolt;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.filter_drama;
      default:
        return Icons.wb_sunny;
    }
  }

  void refreshWeatherData() {
    getWeatherData(cityName).then((weatherData) {
      setState(() {
        weatherForecasts.clear();
        parseWeatherData(weatherData);
        lastUpdatedTime = DateFormat('HH:mm').format(DateTime.now());
      });
    });
  }

  @override
  void initState() {
    super.initState();
    refreshWeatherData();
    lastUpdatedTime = DateFormat('HH:mm').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    String weatherCondition = '';
    double rainProbability = 0.0;

    if (weatherForecasts.isNotEmpty &&
        weatherForecasts[0].hourlyForecasts.isNotEmpty) {
      weatherCondition =
          weatherForecasts[0].hourlyForecasts[0].weatherCondition;
      rainProbability = weatherForecasts[0].rainProbability;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hava Durumu - $cityName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshWeatherData,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    'Bugünkü Hava Durumu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    weatherForecasts.isNotEmpty ? weatherForecasts[0].date : '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    weatherCondition,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Son Güncelleme: $lastUpdatedTime',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.thermostat_outlined, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            weatherForecasts.isNotEmpty
                                ? '${weatherForecasts[0].temperature.round()}°C'
                                : '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Text(
                            'Sıcaklık',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.air),
                          const SizedBox(height: 8),
                          Text(
                            weatherForecasts.isNotEmpty
                                ? '${weatherForecasts[0].windSpeed.toStringAsFixed(1)} m/s'
                                : '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Text(
                            'Rüzgar Hızı',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.water_drop, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            weatherForecasts.isNotEmpty
                                ? '${weatherForecasts[0].humidity}%'
                                : '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Text(
                            'Nem',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.cloud, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            weatherForecasts.isNotEmpty
                                ? '${rainProbability.toStringAsFixed(1)} mm'
                                : '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Text(
                            'Yağmur Olasılığı',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              child: ListView.builder(
                itemCount: weatherForecasts.length,
                itemBuilder: (BuildContext context, int index) {
                  final forecast = weatherForecasts[index];
                  return ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          forecast.date,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _getDayOfWeek(forecast.date),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        height: 150,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: forecast.hourlyForecasts.length,
                          itemBuilder: (BuildContext context, int index) {
                            final hourlyForecast =
                                forecast.hourlyForecasts[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(hourlyForecast.weatherIcon),
                                    Text(
                                      '${hourlyForecast.time.hour.toString().padLeft(2, '0')}:00',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      hourlyForecast.weatherCondition,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Yağmur Olasılığı: ${hourlyForecast.rainProbability.toStringAsFixed(1)} mm',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
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
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    );
                  },
                  icon: const Icon(Icons.schedule),
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

  String _getDayOfWeek(String date) {
    final DateTime dateTime = DateTime.parse(date);
    switch (dateTime.weekday) {
      case 1:
        return 'Pzt';
      case 2:
        return 'Sal';
      case 3:
        return 'Çar';
      case 4:
        return 'Per';
      case 5:
        return 'Cum';
      case 6:
        return 'Cmt';
      case 7:
        return 'Paz';
      default:
        return '';
    }
  }
}
