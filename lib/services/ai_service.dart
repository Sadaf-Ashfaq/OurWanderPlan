import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static Future<String> generateItinerary(String destination, int days, double budget) async {
    try {
      if (_apiKey.isEmpty) {
        return 'API key not configured. Please add GROQ_API_KEY to .env file.';
      }

      final prompt =
          '''Create a detailed $days-day travel itinerary for $destination with a total budget of USD $budget.

Format strictly as:

## Day 1: [Theme Title]
**Morning:** activity (~USD cost)
**Afternoon:** activity (~USD cost)
**Evening:** activity (~USD cost)
*Estimated day cost: USD X*

Repeat for each day. End with:

## Budget Summary
List total estimated costs per category.''';

      final url = 'https://api.groq.com/openai/v1/chat/completions';

      final requestBody = {
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 4096,
        'temperature': 0.7,
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? 'No itinerary generated.';
        return text;
      } else {
        print('Groq API Error: ${response.statusCode}');
        print('Response: ${response.body}');
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return 'API Error: $errorMessage';
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      return 'Network error. Please check your connection.';
    } catch (e) {
      print('Exception: $e');
      return 'Failed to generate itinerary. Try again.';
    }
  }
}
