import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to search YouTube for crop disease management videos
class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  // API Keys (Primary from Gemini, fallback from Google Services)
  String _apiKey = 'AIzaSyDtr04mzTqzdCN0EMasaUo4L00pJue5jx4';
  static const String _fallbackKey = 'AIzaSyC3XheBH60x7s2tlnmho2oDAIUD2WJsTMY';
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Configure the API key (used by AIService to sync keys)
  void configure(String key) {
    if (key.isNotEmpty) _apiKey = key;
  }

  /// Search YouTube for disease management videos in the given language
  /// Returns a list of video results with id, title, thumbnail, and channel
  Future<List<YouTubeVideo>> searchVideos({
    required String query,
    required String languageCode,
    int maxResults = 5,
  }) async {
    try {
      final relevanceLang = _getYouTubeLanguage(languageCode);
      for (final candidateQuery in _buildSearchCandidates(query, languageCode)) {
        final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
          'part': 'snippet',
          'q': candidateQuery,
          'type': 'video',
          'maxResults': maxResults.toString(),
          'relevanceLanguage': relevanceLang,
          'regionCode': 'IN',
          'safeSearch': 'moderate',
          'order': 'relevance',
          'key': _apiKey,
        });

        debugPrint('[YouTube] Searching: $candidateQuery (lang: $relevanceLang)');

        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final videos = _parseSearchResponse(response.body);
          if (videos.isNotEmpty) {
            return videos;
          }
        } else if (response.statusCode == 403 || response.statusCode == 400) {
          debugPrint('[YouTube] Primary key failed (${response.statusCode}), trying fallback...');
          final fallbackUri = uri.replace(queryParameters: {
            ...uri.queryParameters,
            'key': _fallbackKey,
          });
          final fallbackResponse = await http.get(fallbackUri).timeout(const Duration(seconds: 10));
          if (fallbackResponse.statusCode == 200) {
            final videos = _parseSearchResponse(fallbackResponse.body);
            if (videos.isNotEmpty) {
              return videos;
            }
          }
        } else {
          debugPrint('[YouTube] API Error: ${response.statusCode} - ${response.body}');
        }
      }

      return [];
    } catch (e) {
      debugPrint('[YouTube] Search error: $e');
      return [];
    }
  }

  String buildSearchUrl({
    required String query,
    required String languageCode,
  }) {
    final uri = Uri.https('www.youtube.com', '/results', {
      'search_query': query,
      'hl': _getYouTubeLanguage(languageCode),
      'persist_hl': '1',
      'gl': 'IN',
    });
    return uri.toString();
  }

  String buildWatchUrl({
    required String videoId,
    required String languageCode,
  }) {
    final uri = Uri.https('www.youtube.com', '/watch', {
      'v': videoId,
      'hl': _getYouTubeLanguage(languageCode),
      'gl': 'IN',
    });
    return uri.toString();
  }

  List<YouTubeVideo> _parseSearchResponse(String body) {
    final data = jsonDecode(body);
    final items = data['items'] as List? ?? [];

    final videos = items.map<YouTubeVideo>((item) {
      final snippet = item['snippet'] ?? {};
      return YouTubeVideo(
        videoId: item['id']?['videoId'] ?? '',
        title: snippet['title'] ?? '',
        channelTitle: snippet['channelTitle'] ?? '',
        thumbnailUrl: snippet['thumbnails']?['high']?['url'] ??
            snippet['thumbnails']?['medium']?['url'] ??
            snippet['thumbnails']?['default']?['url'] ?? '',
        description: snippet['description'] ?? '',
        publishedAt: snippet['publishedAt'] ?? '',
      );
    }).where((v) => v.videoId.isNotEmpty).toList();

    debugPrint('[YouTube] Found ${videos.length} videos');
    return videos;
  }

  String _getYouTubeLanguage(String langCode) {
    switch (langCode) {
      case 'ta': return 'ta';
      case 'hi': return 'hi';
      default: return 'en';
    }
  }

  List<String> _buildSearchCandidates(String query, String languageCode) {
    final normalizedQuery = query.trim();
    final candidates = <String>[];

    if (normalizedQuery.isNotEmpty) {
      candidates.add(normalizedQuery);
    }

    for (final suffix in _languageSearchSuffixes(languageCode)) {
      final candidate = '$normalizedQuery $suffix'.trim();
      if (candidate.isNotEmpty && !candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    return candidates;
  }

  List<String> _languageSearchSuffixes(String langCode) {
    switch (langCode) {
      case 'ta':
        return const ['தமிழ்', 'Tamil', 'India'];
      case 'hi':
        return const ['हिंदी', 'Hindi', 'India'];
      default:
        return const ['India'];
    }
  }
}

/// Represents a YouTube video result
class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String description;
  final String publishedAt;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.description,
    required this.publishedAt,
  });

  String get watchUrl => 'https://www.youtube.com/watch?v=$videoId';
  String get embedUrl => 'https://www.youtube.com/embed/$videoId?autoplay=0&rel=0';
  String get shortThumbnailUrl => 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}
