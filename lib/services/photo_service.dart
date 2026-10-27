import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Finds a photo for a dish on Wikipedia, by dish name.
///
/// Returns null when Wikipedia has no usable photo, and the UI then shows a
/// styled fallback card. Found URLs are cached on the device. Misses are
/// cached for a week. Network errors are never cached, so they retry later.
class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  static const _missTtl = Duration(days: 7);
  static const _userAgent = 'FridgeChef/1.0 (student recipe app; Flutter)';

  SharedPreferences? _prefs;
  final Map<String, Future<String?>> _inflight = {};

  Future<String?> photoFor(Recipe recipe) =>
      _inflight.putIfAbsent(recipe.id, () => _resolve(recipe));

  Future<String?> _resolve(Recipe recipe) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final key = 'photo_v1_${recipe.id}';
    final now = DateTime.now().millisecondsSinceEpoch;

    final cached = prefs.getString(key);
    if (cached != null) {
      if (cached.startsWith('http')) return cached;
      if (cached.startsWith('none:')) {
        final at = int.tryParse(cached.substring(5)) ?? 0;
        if (now - at < _missTtl.inMilliseconds) return null;
      }
    }

    var hadError = false;
    for (final title in recipe.photoTitles) {
      try {
        final url = await _thumbnailFor(title);
        if (url != null) {
          await prefs.setString(key, url);
          return url;
        }
      } catch (_) {
        hadError = true;
      }
    }

    if (hadError) {
      // Do not remember a miss that may just be a bad connection.
      _inflight.remove(recipe.id);
      return null;
    }
    await prefs.setString(key, 'none:$now');
    return null;
  }

  Future<String?> _thumbnailFor(String title) async {
    final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'formatversion': '2',
      'redirects': '1',
      'titles': title,
      'prop': 'pageimages|pageprops',
      'piprop': 'thumbnail',
      'pithumbsize': '900',
      'ppprop': 'disambiguation',
    });
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw HttpException('Wikipedia answered ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final pages = (data['query'] as Map<String, dynamic>?)?['pages'] as List?;
    if (pages == null || pages.isEmpty) return null;
    final page = pages.first as Map<String, dynamic>;
    if (page['missing'] == true) return null;
    final props = page['pageprops'] as Map<String, dynamic>?;
    if (props != null && props.containsKey('disambiguation')) return null;
    final thumb = page['thumbnail'] as Map<String, dynamic>?;
    return thumb?['source'] as String?;
  }
}
