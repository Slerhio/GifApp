import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
  bool _isLoading = false;
  String? _error;
  int _resultsCount = 0;
  Timer? _debounce;

  List<Map<String, dynamic>> _gifs = [];

  static const _apiKey = 'Vpz8GxsT7tvlrIIawsOkZNW8sV8Z35jq';

 @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

Future<void> _onSearchPressed() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _resultsCount = 0;
      _gifs = [];
      _lastQuery = query;
    });

    try {
      final url = Uri.https(
        'api.giphy.com',
        '/v1/gifs/search',
        <String, String>{
          'api_key': _apiKey,
          'q': query,
          'limit': '25',
          'offset': '0',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;

        setState(() {
          _gifs = data.cast<Map<String, dynamic>>();
          _resultsCount = _gifs.length;
        });
      } else {
        setState(() {
          _error = 'HTTP error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _lastQuery = '';
        _gifs = [];
        _resultsCount = 0;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onSearchPressed();
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
              onChanged: _onQueryChanged,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _onSearchPressed,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const LinearProgressIndicator(),
            if (!_isLoading && _error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _lastQuery.isEmpty
                      ? 'Nothing searched yet'
                      : '$_resultsCount GIFs found for "$_lastQuery"',
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGrid() {
    if (_isLoading && _gifs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _gifs.isEmpty) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_gifs.isEmpty) {
      return const Center(
        child: Text('No GIFs yet'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _gifs.length,
      itemBuilder: (context, index) {
        final gif = _gifs[index];
        final images = gif['images'] as Map<String, dynamic>?;

        final preview =
            images?['fixed_width_small'] ?? images?['fixed_width'];
        final url = (preview as Map?)?['url'] as String?;

        if (url == null) {
          return const ColoredBox(color: Colors.black12);
        }

        return GestureDetector(
          onTap: () {
            // сюда позже добавим переход на экран деталей
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
