import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum SearchProvider {
  tavily,
  google,
  searper,
  brave
}

extension SearchProviderExtension on SearchProvider {
  String get displayName {
    switch (this) {
      case SearchProvider.tavily:
        return 'Tavily';
      case SearchProvider.google:
        return 'Google';
      case SearchProvider.searper:
        return 'Searper';
      case SearchProvider.brave:
        return 'Brave';
    }
  }
  
  IconData get icon {
    switch (this) {
      case SearchProvider.tavily:
        return Icons.search;
      case SearchProvider.google:
        return Icons.search;
      case SearchProvider.searper:
        return Icons.search;
      case SearchProvider.brave:
        return Icons.search;
    }
  }
}

class SearchConfig {
  final String id;
  final String name;
  final SearchProvider provider;
  final String baseUrl;
  final String apiKey;
  
  SearchConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
  });
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.toString().split('.').last,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
    };
  }
  
  // Create from JSON
  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    return SearchConfig(
      id: json['id'],
      name: json['name'],
      provider: SearchProvider.values.firstWhere(
        (e) => e.toString().split('.').last == json['provider'],
        orElse: () => SearchProvider.tavily,
      ),
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'],
    );
  }
}

class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final DateTime? publishedDate;
  
  SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.publishedDate,
  });
}

class SearchService {
  static const String _configsKey = 'search_configs';
  static const String _selectedConfigKey = 'selected_search_config';
  
  // Default URLs for providers
  static String getDefaultUrlForProvider(SearchProvider provider) {
    switch (provider) {
      case SearchProvider.tavily:
        return 'https://api.tavily.com/search';
      case SearchProvider.google:
        return 'https://www.googleapis.com/customsearch/v1';
      case SearchProvider.searper:
        return 'https://api.searper.com/search';
      case SearchProvider.brave:
        return 'https://api.search.brave.com/res/v1/web/search';
    }
  }
  
  // Get all search configurations
  static Future<List<SearchConfig>> getSearchConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final configsJson = prefs.getStringList(_configsKey) ?? [];
    
    return configsJson
        .map((json) => SearchConfig.fromJson(jsonDecode(json)))
        .toList();
  }
  
  // Save a search configuration
  static Future<void> saveSearchConfig(SearchConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getSearchConfigs();
    
    // Check if config already exists
    final existingIndex = configs.indexWhere((c) => c.id == config.id);
    
    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    
    // Save updated configs
    await prefs.setStringList(
      _configsKey,
      configs.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
  
  // Delete a search configuration
  static Future<void> deleteSearchConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final configs = await getSearchConfigs();
    
    configs.removeWhere((c) => c.id == id);
    
    // Save updated configs
    await prefs.setStringList(
      _configsKey,
      configs.map((c) => jsonEncode(c.toJson())).toList(),
    );
    
    // If the deleted config was selected, clear the selection
    final selectedId = prefs.getString(_selectedConfigKey);
    if (selectedId == id) {
      await prefs.remove(_selectedConfigKey);
    }
  }
  
  // Get the selected search configuration
  static Future<String?> getSelectedSearchConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedConfigKey);
  }
  
  // Set the selected search configuration
  static Future<void> setSelectedSearchConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedConfigKey, id);
  }
  
  // Clear the selected search configuration
  static Future<void> clearSelectedSearchConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedConfigKey);
  }
  
  // Test connection to a search provider
  static Future<bool> testConnection(SearchConfig config) async {
    try {
      switch (config.provider) {
        case SearchProvider.tavily:
          return await _testTavilyConnection(config);
        case SearchProvider.google:
          return await _testGoogleConnection(config);
        case SearchProvider.searper:
          return await _testSearperConnection(config);
        case SearchProvider.brave:
          return await _testBraveConnection(config);
      }
    } catch (e) {
      debugPrint('Error testing connection: $e');
      return false;
    }
  }
  
  // Test connection to Tavily
  static Future<bool> _testTavilyConnection(SearchConfig config) async {
    try {
      final response = await http.post(
        Uri.parse(config.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'query': 'test',
          'include_answer': true,
          'max_results': 1,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing Tavily connection: $e');
      return false;
    }
  }
  
  // Test connection to Google
  static Future<bool> _testGoogleConnection(SearchConfig config) async {
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}?q=test&key=${config.apiKey}&cx=YOUR_CUSTOM_SEARCH_ENGINE_ID'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing Google connection: $e');
      return false;
    }
  }
  
  // Test connection to Searper
  static Future<bool> _testSearperConnection(SearchConfig config) async {
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}?q=test&api_key=${config.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing Searper connection: $e');
      return false;
    }
  }
  
  // Test connection to Brave
  static Future<bool> _testBraveConnection(SearchConfig config) async {
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}?q=test'),
        headers: {
          'Content-Type': 'application/json',
          'X-Subscription-Token': config.apiKey,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing Brave connection: $e');
      return false;
    }
  }
  
  // Search using the selected provider
  static Future<List<SearchResult>> search(String query) async {
    try {
      final selectedId = await getSelectedSearchConfig();
      if (selectedId == null) {
        throw Exception('No search provider selected');
      }
      
      final configs = await getSearchConfigs();
      final config = configs.firstWhere(
        (c) => c.id == selectedId,
        orElse: () => throw Exception('Selected search provider not found'),
      );
      
      switch (config.provider) {
        case SearchProvider.tavily:
          return await _searchWithTavily(config, query);
        case SearchProvider.google:
          return await _searchWithGoogle(config, query);
        case SearchProvider.searper:
          return await _searchWithSearper(config, query);
        case SearchProvider.brave:
          return await _searchWithBrave(config, query);
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      throw Exception('Error searching: $e');
    }
  }
  
  // Search with Tavily
  static Future<List<SearchResult>> _searchWithTavily(SearchConfig config, String query) async {
    try {
      final response = await http.post(
        Uri.parse(config.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode({
          'query': query,
          'include_answer': true,
          'max_results': 5,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = <SearchResult>[];
        
        if (data['results'] != null) {
          for (final result in data['results']) {
            results.add(SearchResult(
              title: result['title'] ?? 'No title',
              url: result['url'] ?? '',
              snippet: result['content'] ?? '',
              publishedDate: result['published_date'] != null 
                  ? DateTime.parse(result['published_date']) 
                  : null,
            ));
          }
        }
        
        return results;
      } else {
        throw Exception('Failed to search with Tavily: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching with Tavily: $e');
      throw Exception('Error searching with Tavily: $e');
    }
  }
  
  // Search with Google
  static Future<List<SearchResult>> _searchWithGoogle(SearchConfig config, String query) async {
    // Implement Google search
    return [];
  }
  
  // Search with Searper
  static Future<List<SearchResult>> _searchWithSearper(SearchConfig config, String query) async {
    // Implement Searper search
    return [];
  }
  
  // Search with Brave
  static Future<List<SearchResult>> _searchWithBrave(SearchConfig config, String query) async {
    // Implement Brave search
    return [];
  }
} 