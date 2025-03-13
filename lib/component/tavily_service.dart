import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TavilyService {
  static const String _baseUrl = 'https://api.tavily.com/search';
  
  // Get the API key from shared preferences
  Future<String> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('search_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      throw Exception('Tavily API key not configured. Please add your API key in Search Configuration settings.');
    }
    
    return apiKey;
  }

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final apiKey = await _getApiKey();
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': apiKey,
        },
        body: json.encode({
          'query': query,
          'search_depth': 'advanced',
          'include_answer': true,
          'include_images': false,
          'include_raw_content': false,
          'max_results': 5,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to perform search: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in TavilyService: $e');
      throw Exception('Error performing search: $e');
    }
  }
}