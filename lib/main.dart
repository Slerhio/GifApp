import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GifSearchApp());
}

class GifSearchApp extends StatelessWidget {
  const GifSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
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

class GifDetailsPage extends StatelessWidget {
  final Map<String, dynamic> gif;

  const GifDetailsPage({super.key, required this.gif});

  @override
  Widget build(BuildContext context) {
    final images = gif['images'] as Map<String, dynamic>?;
    final original = images?['original'] as Map<String, dynamic>?;
    final url = original?['url'] as String?;

    final title = (gif['title'] as String?)?.trim();
    final username = (gif['username'] as String?)?.trim();
    final rating = (gif['rating'] as String?)?.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(title?.isEmpty ?? true ? 'GIF details' : title!),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (url != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(url, fit: BoxFit.contain),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(child: Text('No preview available')),
                ),
              const SizedBox(height: 16),
              if (title != null && title.isNotEmpty)
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (username != null && username.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Author: $username',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (rating != null && rating.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Rating: $rating',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
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
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  String _lastQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _resultsCount = 0;

  final int _pageSize = 10;
  int _offset = 0;
  int _totalAvailable = 0;
  bool _hasMore = true;

  List<Map<String, dynamic>> _gifs = [];

  static const _apiKey = 'Vpz8GxsT7tvlrIIawsOkZNW8sV8Z35jq';

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onSearchPressed() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    if (_isLoading || _isLoadingMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _lastQuery = query;

      _offset = 0;
      _hasMore = true;
      _gifs = [];
      _resultsCount = 0;
      _totalAvailable = 0;
    });

    try {
      final url = Uri.https(
        'api.giphy.com',
        '/v1/gifs/search',
        <String, String>{
          'api_key': _apiKey,
          'q': query,
          'limit': '$_pageSize',
          'offset': '$_offset',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

        final totalCount = (pagination['total_count'] ?? 0) as int;

        setState(() {
          _gifs = data.cast<Map<String, dynamic>>();
          _resultsCount = _gifs.length;
          _totalAvailable = totalCount;
          _offset = _gifs.length;
          _hasMore = _offset < _totalAvailable;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_lastQuery.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
      _error = null;
    });

    try {
      final url = Uri.https(
        'api.giphy.com',
        '/v1/gifs/search',
        <String, String>{
          'api_key': _apiKey,
          'q': _lastQuery,
          'limit': '$_pageSize',
          'offset': '$_offset',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;
        final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

        final totalCount =
            (pagination['total_count'] ?? _totalAvailable) as int;

        setState(() {
          final newItems = data.cast<Map<String, dynamic>>();
          _gifs.addAll(newItems);
          _resultsCount = _gifs.length;
          _totalAvailable = totalCount;
          _offset = _gifs.length;
          _hasMore = _offset < _totalAvailable;
        });
      } else {
        setState(() {
          _error = 'HTTP error (load more): ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error (load more): $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
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
        _hasMore = true;
        _offset = 0;
        _totalAvailable = 0;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _onSearchPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GIF Search')),
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
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_isLoading && _error == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _lastQuery.isEmpty
                      ? 'Nothing searched yet'
                      : '$_resultsCount / $_totalAvailable GIFs for "$_lastQuery"',
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid()),
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
      return const Center(child: Text('No GIFs yet'));
    }
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width >= 600) {
      crossAxisCount = 3;
    }
    if (width >= 900) {
      crossAxisCount = 4;
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _gifs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _gifs.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final gif = _gifs[index];
        final images = gif['images'] as Map<String, dynamic>?;

        final preview = images?['fixed_width_small'] ?? images?['fixed_width'];
        final url = (preview as Map?)?['url'] as String?;

        if (url == null) {
          return const ColoredBox(color: Colors.black12);
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => GifDetailsPage(gif: gif)));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
