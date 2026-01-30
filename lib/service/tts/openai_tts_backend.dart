import 'dart:convert';
import 'dart:typed_data';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/tts/models/tts_voice.dart';
import 'package:anx_reader/service/tts/online_tts_backend.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class OpenaiTtsBackend extends OnlineTtsBackend {
  static final OpenaiTtsBackend _instance = OpenaiTtsBackend._internal();

  factory OpenaiTtsBackend() {
    return _instance;
  }

  OpenaiTtsBackend._internal();

  @override
  String get serviceId => 'openai';

  @override
  String get name => 'OpenAI TTS';

  @override
  String helpText(BuildContext context) =>
      'Use OpenAI Speech API or any compatible endpoint. Configure API URL and API Key below.';

  @override
  String get helpLink =>
      'https://platform.openai.com/docs/guides/text-to-speech';

  @override
  List<String> get configFields => ['api_url', 'api_key', 'model', 'models_url', 'voices_url'];

  @override
  Future<Uint8List> speak(
      String text, String voice, double rate, double pitch) async {
    AnxLog.info('OpenAI TTS: Starting speak request');
    AnxLog.info('OpenAI TTS: Text: $text');
    AnxLog.info('OpenAI TTS: Voice: $voice');
    
    // Get TTS-specific config
    final config = Prefs().getOnlineTtsConfig(serviceId);
    String? apiUrl = config['api_url'];
    String? apiKey = config['api_key'];
    String? model = config['model'];

    AnxLog.info('OpenAI TTS: Config - API URL: $apiUrl');
    AnxLog.info('OpenAI TTS: Config - Model: $model');

    // Default to OpenAI official endpoint if not configured
    if (apiUrl == null || apiUrl.isEmpty) {
      apiUrl = 'https://api.openai.com/v1/audio/speech';
      AnxLog.info('OpenAI TTS: Using default OpenAI endpoint');
    }

    // Fallback to AI config if TTS config doesn't have API key
    if (apiKey == null || apiKey.isEmpty) {
      final aiConfig = Prefs().getAiConfig('openai');
      apiKey = aiConfig['api_key'];
      AnxLog.info('OpenAI TTS: Using API key from AI config');
    }

    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      AnxLog.severe('OpenAI TTS: ERROR: API key not configured');
      throw Exception(
          'OpenAI API key not configured. Please configure API Key in TTS settings or AI settings.');
    }

    final requestBody = {
      'model': model?.isNotEmpty == true ? model : 'tts-1',
      'input': text,
      'voice': voice,
      'response_format': 'mp3',
    };

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    AnxLog.info('OpenAI TTS: ========== REQUEST ==========');
    AnxLog.info('OpenAI TTS: Method: POST');
    AnxLog.info('OpenAI TTS: URL: $apiUrl');
    AnxLog.info('OpenAI TTS: Headers: ${jsonEncode(headers)}');
    AnxLog.info('OpenAI TTS: Body: ${jsonEncode(requestBody)}');
    AnxLog.info('OpenAI TTS: ================================');

    // Note: OpenAI TTS API does not support rate or pitch parameters
    // These parameters are ignored by the API
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    AnxLog.info('OpenAI TTS: Response status: ${response.statusCode}');
    AnxLog.info('OpenAI TTS: Response length: ${response.bodyBytes.length} bytes');

    if (response.statusCode == 200) {
      AnxLog.info('OpenAI TTS: Success!');
      return response.bodyBytes;
    } else {
      AnxLog.severe('OpenAI TTS: ERROR: ${response.statusCode} - ${response.body}');
      throw Exception(
          'OpenAI TTS API error: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get available TTS models from API endpoint
  Future<List<String>> getModels() async {
    final config = Prefs().getOnlineTtsConfig(serviceId);
    String? apiUrl = config['api_url'];
    String? apiKey = config['api_key'];

    // Fallback to AI config
    if (apiKey == null || apiKey.isEmpty) {
      final aiConfig = Prefs().getAiConfig('openai');
      apiKey = aiConfig['api_key'];
    }

    if (apiKey == null || apiKey.isEmpty) {
      return ['tts-1', 'tts-1-hd']; // Default OpenAI models
    }

    // Build models endpoint URL
    String modelsUrl;
    // Check if custom models_url is configured
    String? customModelsUrl = config['models_url'];
    if (customModelsUrl != null && customModelsUrl.isNotEmpty) {
      modelsUrl = customModelsUrl;
    } else if (apiUrl != null && apiUrl.isNotEmpty) {
      // Replace /v1/audio/speech with /v1/audio/models
      modelsUrl = apiUrl.replaceAll('/v1/audio/speech', '/v1/audio/models');
    } else {
      modelsUrl = 'https://api.openai.com/v1/audio/models';
    }

    try {
      final response = await http.get(
        Uri.parse(modelsUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is List) {
          return (data['data'] as List)
              .map((m) => m['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      // Fallback to defaults on error
    }

    return ['tts-1', 'tts-1-hd'];
  }

  @override
  Future<List<TtsVoice>> getVoices() async {
    AnxLog.info('OpenAI TTS: Getting voices list');

    final config = Prefs().getOnlineTtsConfig(serviceId);
    String? apiUrl = config['api_url'];
    String? apiKey = config['api_key'];

    // Fallback to AI config
    if (apiKey == null || apiKey.isEmpty) {
      final aiConfig = Prefs().getAiConfig('openai');
      apiKey = aiConfig['api_key'];
    }

    if (apiKey == null || apiKey.isEmpty) {
      AnxLog.info('OpenAI TTS: No API key, returning default voices');
      // Return default OpenAI voices if not configured
      return const [
        TtsVoice(shortName: 'alloy', name: 'Alloy', locale: 'en-US'),
        TtsVoice(shortName: 'echo', name: 'Echo', locale: 'en-US'),
        TtsVoice(shortName: 'fable', name: 'Fable', locale: 'en-US'),
        TtsVoice(shortName: 'onyx', name: 'Onyx', locale: 'en-US'),
        TtsVoice(shortName: 'nova', name: 'Nova', locale: 'en-US'),
        TtsVoice(shortName: 'shimmer', name: 'Shimmer', locale: 'en-US'),
      ];
    }

    // Build voices endpoint URL
    String voicesUrl;
    // Check if custom voices_url is configured
    String? customVoicesUrl = config['voices_url'];
    if (customVoicesUrl != null && customVoicesUrl.isNotEmpty) {
      voicesUrl = customVoicesUrl;
    } else if (apiUrl != null && apiUrl.isNotEmpty) {
      // Replace /v1/audio/speech with /v1/audio/voices
      voicesUrl = apiUrl.replaceAll('/v1/audio/speech', '/v1/audio/voices');
    } else {
      voicesUrl = 'https://api.openai.com/v1/audio/voices';
    }

    AnxLog.info('OpenAI TTS: Fetching voices from: $voicesUrl');

    try {
      final response = await http.get(
        Uri.parse(voicesUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      AnxLog.info('OpenAI TTS: Voices API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Support multiple API response formats
        List<dynamic>? voicesList;
        if (data['data'] is List) {
          voicesList = data['data'] as List;
        } else if (data['voices'] is List) {
          voicesList = data['voices'] as List;
        }
        
        if (voicesList != null && voicesList.isNotEmpty) {
          final voices = voicesList.map((v) {
            // Support different field names for voice ID
            // Prefer 'voice' field as it's usually the API parameter (without extension)
            String voiceId = v['voice']?.toString() ?? 
                            v['id']?.toString() ?? 
                            v['name']?.toString() ?? '';
            String voiceName = v['name']?.toString() ?? 
                              v['id']?.toString() ?? 
                              v['voice']?.toString() ?? 
                              'Unknown';
            String voiceLocale = v['locale']?.toString() ?? 
                                v['language']?.toString() ?? 
                                v['lang']?.toString() ?? 
                                'zh-CN'; // Default to Chinese for custom service
            
            return TtsVoice(
              shortName: voiceId,
              name: voiceName,
              locale: voiceLocale,
              gender: v['gender']?.toString() ?? v['mode']?.toString() ?? '',
              rawData: v,
            );
          }).where((voice) => voice.shortName.isNotEmpty).toList();

          AnxLog.info('OpenAI TTS: Loaded ${voices.length} voices');
          return voices;
        } else {
          AnxLog.warning('OpenAI TTS: No voices list in response');
        }
      } else {
        AnxLog.severe('OpenAI TTS: Voices API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AnxLog.severe('OpenAI TTS: Failed to fetch voices: $e');
    }

    // Return default OpenAI voices as fallback
    AnxLog.info('OpenAI TTS: Returning default fallback voices');
    return const [
      TtsVoice(shortName: 'alloy', name: 'Alloy', locale: 'en-US'),
      TtsVoice(shortName: 'echo', name: 'Echo', locale: 'en-US'),
      TtsVoice(shortName: 'fable', name: 'Fable', locale: 'en-US'),
      TtsVoice(shortName: 'onyx', name: 'Onyx', locale: 'en-US'),
      TtsVoice(shortName: 'nova', name: 'Nova', locale: 'en-US'),
      TtsVoice(shortName: 'shimmer', name: 'Shimmer', locale: 'en-US'),
    ];
  }

  @override
  TtsVoice convertVoiceModel(dynamic voiceData) {
    // OpenAI voice data is simple, just return TtsVoice
    return TtsVoice(
      shortName: voiceData['shortName'],
      name: voiceData['name'],
      locale: voiceData['locale'],
      rawData: voiceData,
    );
  }
}
