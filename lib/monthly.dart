import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MonthlyPage());
}

class MonthlyPage extends StatefulWidget {
  const MonthlyPage({super.key});

  @override
  _MonthlyPageState createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  String apiKey = 'f62affb5257db99e981a28bff419d8db';
  String cityName = 'Istanbul';
  String temperature = '';
  String weatherCondition = '';

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    final response = await http.get(
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric'
            as Uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        temperature = data['main']['temp'].toString();
        weatherCondition = data['weather'][0]['main'];
      });
    } else {
      throw Exception('Failed to fetch weather data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Weather App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/$weatherCondition.svg',
                height: 100,
              ),
              const SizedBox(height: 16),
              Text(
                '$temperature°C',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchWeatherData,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
