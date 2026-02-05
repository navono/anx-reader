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
  List<String> get configFields => ['api_url', 'api_key', 'model', 'models_url', 'voices_url', 'instruct'];

  @override
  Future<Uint8List> speak(
      String text, String voice, double rate, double pitch) async {
    // Get TTS-specific config first
    final config = Prefs().getOnlineTtsConfig(serviceId);
    String? apiUrl = config['api_url']?.trim();
    String? apiKey = config['api_key']?.trim();
    String? model = config['model']?.trim();
    String? instruct = config['instruct']?.trim();

    AnxLog.info('OpenAI TTS: ========== CONFIG ==========');
    AnxLog.info('OpenAI TTS: API URL: $apiUrl');
    AnxLog.info('OpenAI TTS: API Key: ${apiKey?.substring(0, 8)}...');
    AnxLog.info('OpenAI TTS: Model: $model');
    AnxLog.info('OpenAI TTS: Voice: $voice');
    if (instruct != null && instruct.isNotEmpty) {
      AnxLog.info('OpenAI TTS: Instruct: $instruct');
    }
    AnxLog.info('OpenAI TTS: Text: $text');
    AnxLog.info('OpenAI TTS: ================================');

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
    };

    // Add instruct parameter if configured
    if (instruct != null && instruct.isNotEmpty) {
      requestBody['instruct'] = instruct;
    }
    
    // Note: response_format is optional and not all services support it
    // Removed to maximize compatibility with custom TTS backends

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    AnxLog.info('OpenAI TTS: ========== SENDING REQUEST ==========');
    AnxLog.info('OpenAI TTS: URL: $apiUrl');
    AnxLog.info('OpenAI TTS: Headers: ${jsonEncode(headers)}');
    AnxLog.info('OpenAI TTS: Body: ${jsonEncode(requestBody)}');
    AnxLog.info('OpenAI TTS: ======================================');

    // Note: OpenAI TTS API does not support rate or pitch parameters
    // These parameters are ignored by the API

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: jsonEncode(requestBody),
    );

    AnxLog.info('OpenAI TTS: ========== RESPONSE ==========');
    AnxLog.info('OpenAI TTS: Status: ${response.statusCode}');
    AnxLog.info('OpenAI TTS: Headers: ${response.headers}');
    AnxLog.info('OpenAI TTS: Body length: ${response.bodyBytes.length} bytes');
    
    if (response.statusCode == 200) {
      AnxLog.info('OpenAI TTS: Success! Audio size: ${response.bodyBytes.length} bytes');
      AnxLog.info('OpenAI TTS: ======================================');
      return response.bodyBytes;
    } else {
      // Try to decode response body for error details
      String errorBody = response.body;
      try {
        if (response.bodyBytes.isNotEmpty) {
          errorBody = utf8.decode(response.bodyBytes);
        }
      } catch (e) {
        errorBody = 'Unable to decode response body: ${response.bodyBytes.length} bytes';
      }
      
      AnxLog.severe('OpenAI TTS: ========== ERROR ==========');
      AnxLog.severe('OpenAI TTS: Status: ${response.statusCode}');
      AnxLog.severe('OpenAI TTS: Error body: $errorBody');
      AnxLog.severe('OpenAI TTS: Request was: ${jsonEncode(requestBody)}');
      AnxLog.severe('OpenAI TTS: ======================================');
      
      throw Exception(
          'OpenAI TTS API error: ${response.statusCode} - $errorBody');
    }
  }

  /// Get available TTS models from API endpoint
  Future<List<String>> getModels() async {
    final config = Prefs().getOnlineTtsConfig(serviceId);
    String? apiUrl = config['api_url']?.trim();
    String? apiKey = config['api_key']?.trim();

    // Fallback to AI config
    if (apiKey == null || apiKey.isEmpty) {
      final aiConfig = Prefs().getAiConfig('openai');
      apiKey = aiConfig['api_key']?.trim();
    }

    if (apiKey == null || apiKey.isEmpty) {
      return ['tts-1', 'tts-1-hd']; // Default OpenAI models
    }

    // Build models endpoint URL
    String modelsUrl;
    // Check if custom models_url is configured
    String? customModelsUrl = config['models_url']?.trim();
    if (customModelsUrl != null && customModelsUrl.isNotEmpty) {
      modelsUrl = customModelsUrl;
    } else if (apiUrl != null && apiUrl.isNotEmpty) {
      // Try /v1/models first (some services use this endpoint)
      modelsUrl = apiUrl.replaceAll(RegExp(r'/v1/audio/speech|/v1/audio/speech$'), '/v1/models');
      // If no match, try replacing /v1/audio/speech with /v1/audio/models
      if (modelsUrl == apiUrl) {
        modelsUrl = apiUrl.replaceAll('/v1/audio/speech', '/v1/audio/models');
      }
    } else {
      modelsUrl = 'https://api.openai.com/v1/models';
    }

    // Try multiple endpoints for model discovery
    final endpointsToTry = <String>[
      modelsUrl,
      // Fallback to /v1/audio/models if /v1/models doesn't work
      if (apiUrl != null && apiUrl.isNotEmpty)
        apiUrl.replaceAll('/v1/audio/speech', '/v1/audio/models'),
      'https://api.openai.com/v1/models',
    ];

    for (final url in endpointsToTry) {
      try {
        AnxLog.info('OpenAI TTS: Trying models endpoint: $url');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        AnxLog.info('OpenAI TTS: Models endpoint response: ${response.statusCode}');
        if (response.statusCode == 200) {
          AnxLog.info('OpenAI TTS: Models response body: ${response.body}');
          final data = jsonDecode(response.body);
          // Support multiple response formats
          List<dynamic>? modelsList;
          if (data['data'] is List) {
            modelsList = data['data'] as List;
          } else if (data['models'] is List) {
            modelsList = data['models'] as List;
          }

          if (modelsList != null && modelsList.isNotEmpty) {
            final models = modelsList
                .map((m) => m['id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
            if (models.isNotEmpty) {
              AnxLog.info('OpenAI TTS: Found ${models.length} models from $url: $models');
              return models;
            }
          }
        }
      } catch (e) {
        AnxLog.warning('OpenAI TTS: Failed to get models from $url: $e');
        continue;
      }
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
