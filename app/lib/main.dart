import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MoviePredictorApp());
}

class MoviePredictorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MoviePredictorScreen(),
    );
  }
}

class MoviePredictorScreen extends StatefulWidget {
  @override
  _MoviePredictorScreenState createState() => _MoviePredictorScreenState();
}

class _MoviePredictorScreenState extends State<MoviePredictorScreen> {
  final TextEditingController popularityController = TextEditingController();
  final TextEditingController voteCountController = TextEditingController();
  final TextEditingController voteAverageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String predictionResult = '';
  bool isLoading = false;

  Future<void> predictHitOrFlop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://127.0.0.1:8000/predict');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'popularity': double.parse(popularityController.text),
          'vote_count': int.parse(voteCountController.text),
          'vote_average': double.parse(voteAverageController.text),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictionResult = data['prediction'];
        });
      } else {
        setState(() {
          predictionResult = 'Error predicting movie status';
        });
      }
    } catch (e) {
      setState(() {
        predictionResult = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildInputField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          if (double.tryParse(value) == null) {
            return '$label must be a valid number';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Movie Hit/Flop Predictor', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildInputField(popularityController, 'Popularity'),
              buildInputField(voteCountController, 'Vote Count'),
              buildInputField(voteAverageController, 'Vote Average'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : predictHitOrFlop,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Predict', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 30),
              if (predictionResult.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  color: predictionResult == 'Hit' ? Colors.green[100] : Colors.red[100],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Prediction: $predictionResult',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
