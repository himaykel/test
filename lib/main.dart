import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter API Endpoint',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProgressScreen(apiEndpoint: _controller.text)),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  final String apiEndpoint;

  ProgressScreen({required this.apiEndpoint});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  AnimationController? _animationController;
  Animation<double>? _animation;
  List<dynamic> _responseData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController!);
    _submitRequest();
  }

  void _submitRequest() async {
    try {
      _animationController!.reset();
      _animationController!.forward();

      final response = await http.get(Uri.parse(widget.apiEndpoint));

      if (response.statusCode == 200) {
        setState(() {
          _responseData = json.decode(response.body)['data'];
        });

        await Future.delayed(const Duration(seconds: 2)); // Simulate a delay
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e);
      // Handle error appropriately
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!_isLoading && _responseData.isNotEmpty)
                      const Text(
                        'All calculations have finished, you can send your results to the server.',
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 60),
                    Transform.scale(
                      scale: 3.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        value: _animation!.value,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      '${(_animation!.value * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    if (!_isLoading && _responseData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ResultsScreen(data: _responseData)),
                              );
                            },
                            child: const Text('Proceed to Results'),
                          ),
                        ],
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

class ResultsScreen extends StatelessWidget {
  final List<dynamic> data;

  ResultsScreen({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            Map item = data[index];

            List field = item['field'];
            Map<String, dynamic> startCell = item['start'];
            Map<String, dynamic> endCell = item['end'];

            return Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GridScreen(field: field, startCell: startCell, endCell: endCell)),
                  ),
                  child: ListTile(
                    title: Text(
                      '(${startCell["x"]}, ${startCell["y"]}) -> (${endCell["x"]}, ${endCell["y"]})',
                      textAlign: TextAlign.center,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 16.0),
                  ),
                ),
                if (index < data.length - 1) // Add divider after each item except the last one
                  const Divider(
                    color: Colors.grey,
                    thickness: 0.5,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class GridScreen extends StatelessWidget {
  final List<dynamic> field;
  final Map<String, dynamic> startCell;
  final Map<String, dynamic> endCell;

  GridScreen({required this.field, required this.startCell, required this.endCell});

  @override
  Widget build(BuildContext context) {
    Color getColorBasedOnCell(String cell, int col, int row, Map<String, dynamic> startCell, Map<String, dynamic> endCell) {
      if (col == startCell["x"] && row == startCell["y"]) {
        return Colors.lightBlue;
      } else if (col == endCell["x"] && row == endCell["y"]) {
        return Colors.green;
      } else if (cell == '.') {
        return Colors.white;
      } else {
        return Color(0xFF000000); // Default color
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Screen'),
      ),
      body: Center(
        child: GridView.builder(
          itemCount: (field.length * field[0].length).toInt(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: field.isNotEmpty ? field[0].length : 1,
          ),
          itemBuilder: (context, index) {
            int col = (index % field[0].length).toInt(); // x
            int row = index ~/ field[0].length; // y
            String cell = field[row][col];

            return Container(
              decoration: BoxDecoration(
                color: getColorBasedOnCell(cell, col, row, startCell, endCell),
                border: Border.all(color: Colors.black),
              ),
              child: Center(
                child: Text(
                  '($col,$row)',
                  style: TextStyle(fontSize: 16, color: cell == 'X' ? Colors.white : Colors.black),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void showGridScreen(BuildContext context, List<String> field, Map<String, dynamic> startCell, Map<String, dynamic> endCell) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GridScreen(
        field: field,
        startCell: startCell,
        endCell: endCell,
      ),
    ),
  );
}
