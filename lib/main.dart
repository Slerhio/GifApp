import 'package:flutter/material.dart';

void main() 
{
  runApp(const GifSearchApp());
}

class GifSearchApp extends StatelessWidget 
{
  const GifSearchApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp(
      title: 'GIF Search',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GifSearchPage(),
    );
  }
}

class GifSearchPage extends StatefulWidget {
  const GifSearchPage({super.key});

  @override
  State<GifSearchPage> createState() => _GifSearchPageState();
}

class _GifSearchPageState extends State<GifSearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _lastQuery = '';

  @override
  void dispose() 
  {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchPressed() 
  {
    setState(() {
      _lastQuery = _controller.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIF Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Search GIFs',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _onSearchPressed,
              child: const Text('Search'),
            ),
            const SizedBox(height: 24),
            Text(
              _lastQuery.isEmpty
                  ? 'Nothing searched yet'
                  : 'Last query: $_lastQuery',
            ),
          ],
        ),
      ),
    );
  }
}
