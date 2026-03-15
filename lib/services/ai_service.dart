import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../models/disease_prediction.dart';
import 'youtube_service.dart';

/// AI Service for Gemini-powered agricultural insights
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Gemini API configuration
  String _apiKey = 'AIzaSyDtr04mzTqzdCN0EMasaUo4L00pJue5jx4';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.0-flash';
  
  bool get isConfigured => _apiKey.isNotEmpty;

  /// Configure the API key
  void configure(String apiKey) {
    _apiKey = apiKey;
    YouTubeService().configure(apiKey);
  }

  /// Generate AI insights for crop health
  Future<AIInsight> getAgriculturalInsights({
    required SensorData sensorData,
    required Field field,
    required String languageCode,
    List<SensorData>? history,
  }) async {
    try {
      final plantingDate = field.plantingDate ?? field.createdAt ?? DateTime.now();
      final ageInDays = DateTime.now().difference(plantingDate).inDays;
      
      final prompt = _buildPrompt(
        sensorData: sensorData,
        cropType: field.cropType,
        fieldName: field.name,
        ageInDays: ageInDays,
        languageCode: languageCode,
        history: history,
      );
      
      final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';
      debugPrint('[AI] Requesting: $_baseUrl/models/$_model');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.25,
            'topP': 0.8,
            'topK': 32,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final parsedInsight = _parseAIResponse(text, languageCode);
        AIInsight insight = parsedInsight.copyWith(
          videoSearchQuery: _resolveVideoSearchQuery(
            parsedInsight: parsedInsight,
            cropType: field.cropType,
            languageCode: languageCode,
          ),
        );

        if (!_isInsightInRequestedLanguage(insight, languageCode)) {
          debugPrint('[AI] Response did not match requested language, using grounded fallback');
          return _getMockInsight(sensorData, field.cropType, field.name, languageCode, ageInDays);
        }
        
        // Fetch real YouTube video based on AI search query
        if (insight.videoSearchQuery.isNotEmpty) {
          try {
            debugPrint('[AI] Searching YouTube for: ${insight.videoSearchQuery}');
            final videos = await YouTubeService().searchVideos(
              query: insight.videoSearchQuery,
              languageCode: languageCode,
              maxResults: 1,
            );
            if (videos.isNotEmpty) {
              insight.video = videos.first;
              debugPrint('[AI] Found video: ${videos.first.title}');
            }
          } catch (e) {
            debugPrint('[AI] Video search failed: $e');
          }
        }
        
        return insight;
      } else {
        debugPrint('[AI] Error: ${response.statusCode} - ${response.body}');
        return _getMockInsight(sensorData, field.cropType, field.name, languageCode, ageInDays);
      }
    } catch (e) {
      debugPrint('[AI] Error getting insights: $e');
      return _getMockInsight(sensorData, field.cropType, field.name, languageCode, 0);
    }
  }

  String _buildPrompt({
    required SensorData sensorData,
    required String cropType,
    required String fieldName,
    required int ageInDays,
    required String languageCode,
    List<SensorData>? history,
  }) {
    final langName = languageCode == 'ta' ? 'Tamil' : (languageCode == 'hi' ? 'Hindi' : 'English');
    final agronomicContext = _buildAgronomicContext(sensorData, cropType);
    final likelyThreat = _inferLikelyThreat(sensorData, cropType);
    final estimatedRisk = _estimateRiskLevel(sensorData, cropType);
    
    String historyInfo = "No historical data available.";
    if (history != null && history.isNotEmpty) {
      historyInfo = "History (Last 3 records): " + 
          history.take(3).map((d) => "T:${d.temperature.toStringAsFixed(1)}°C, H:${d.humidity.toStringAsFixed(0)}%, M:${d.soilMoisture.toStringAsFixed(0)}%").join(" | ");
    }

    return '''
You are an expert agricultural scientist and crop pathologist specializing in disease prediction for $cropType crops in Indian farming conditions.
Your goal is to provide ACCURATE, PRACTICAL, and EASY TO UNDERSTAND advice to a farmer in their local language ($langName).

FIELD INFORMATION:
- Field Name: $fieldName
- Crop Type: $cropType
- Crop Age: $ageInDays days since planting

CURRENT ENVIRONMENTAL DATA:
- Soil Moisture: ${sensorData.soilMoisture.toStringAsFixed(1)}%
- Temperature: ${sensorData.temperature.toStringAsFixed(1)}°C  
- Air Humidity: ${sensorData.humidity.toStringAsFixed(1)}%

HISTORICAL TRENDS: $historyInfo
GROUNDED AGRONOMIC CONTEXT:
$agronomicContext

LIKELY ISSUE TO EVALUATE FIRST: $likelyThreat
ESTIMATED RISK FROM SENSOR DATA: $estimatedRisk

RULES:
1. Use ONLY the data above. Do not invent symptoms already seen in the field.
2. If the values indicate low risk, say the crop is currently healthy instead of forcing a disease prediction.
3. Connect every recommendation to the temperature, humidity, soil moisture, crop age, or recent trend.
4. Keep disease names in English only in the dedicated English-name field. All farmer-facing explanation must be in $langName.
5. Return STRICT JSON only. No markdown, no code fences, no extra text.

MUST COVER:
1. RISK ASSESSMENT: Identify the most significant disease, pest, or stress threat and explain the real risk level from the sensor values.
2. WHY NOW: Explain specifically how Temperature (${sensorData.temperature.toStringAsFixed(1)}°C), Humidity (${sensorData.humidity.toStringAsFixed(1)}%), Soil Moisture (${sensorData.soilMoisture.toStringAsFixed(1)}%), and crop age interact.
3. PRACTICAL STEPS: Give at least 4 clear prevention or treatment steps that match the risk level. Do not suggest unnecessary chemicals if risk is low.
4. YOUTUBE SEARCH: Produce a search query in $langName that includes the crop and the main issue, so YouTube can return videos in $langName.

FORMAT YOUR RESPONSE AS JSON:
{
  "riskLevel": "low|medium|high",
  "riskIntroduction": "A long, 3-4 paragraph detailed explanation about the current crop health and risks in $langName. Talk about the sensor data specifically. DO NOT USE ENGLISH HERE.",
  "predictedDisease": {
    "name": "Disease/stress name in English, or Healthy Crop if no significant threat",
    "localName": "Common name in $langName",
    "scientificName": "Scientific name or Optimal Conditions",
    "emoji": "🦠 or ✅"
  },
  "description": {
    "brief": "A detailed 4-5 sentence explanation of what this disease is and how it spreads. ALL TEXT IN $langName.",
    "forms": ["Detailed symptom 1 in $langName", "Detailed symptom 2 in $langName"]
  },
  "whyNow": {
    "temperature": "How ${sensorData.temperature}°C contributes in $langName.",
    "humidity": "How ${sensorData.humidity}% humidity contributes in $langName.",
    "soilMoisture": "How ${sensorData.soilMoisture}% moisture contributes in $langName."
  },
  "seasonalInfo": "Detailed seasonal context in $langName",
  "preventionSteps": [
    "Long step 1 in $langName",
    "Long step 2 in $langName",
    "Long step 3 in $langName",
    "Long step 4 in $langName"
  ],
  "chemicalControl": ["Spray 1 with dosage in $langName or 'Not needed now'"],
  "maintenanceTips": ["Tip 1 in $langName", "Tip 2 in $langName"],
  "videoSearchQuery": "YouTube search query in $langName for finding $langName videos about this disease management"
}

CRITICAL: All text fields except 'name' in 'predictedDisease' must be in $langName language. Be verbose and helpful.
''';
  }

  AIInsight _parseAIResponse(String text, String languageCode) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        
        // Try to parse new detailed format first
        if (json.containsKey('riskIntroduction') && json.containsKey('predictedDisease')) {
          // New detailed format
          final diseaseDetails = json['predictedDisease'] as Map<String, dynamic>?;
          final whyNow = json['whyNow'] as Map<String, dynamic>?;
          
          return AIInsight(
            summary: json['riskIntroduction'] ?? '',
            analysisPoints: whyNow != null 
                ? [
                    whyNow['temperature']?.toString() ?? '',
                    whyNow['humidity']?.toString() ?? '',
                    whyNow['soilMoisture']?.toString() ?? '',
                  ].where((s) => s.isNotEmpty).cast<String>().toList()
                : [],
            pestRiskLevel: _normalizeRiskLevel(
              json['riskLevel']?.toString(),
              diseaseDetails?['name']?.toString(),
            ),
            predictedDiseases: diseaseDetails != null 
                ? [diseaseDetails['localName'] ?? diseaseDetails['name'] ?? 'Unknown']
                : [],
            pestExplanation: json['description']?['brief'] ?? '',
            irrigationAdvice: (json['preventionSteps'] as List?)?.firstWhere(
              (step) => step.toString().toLowerCase().contains('water') || 
                       step.toString().toLowerCase().contains('irrigation'),
              orElse: () => json['preventionSteps']?[0] ?? ''
            ) ?? '',
            videoSearchQuery: json['videoSearchQuery'] ?? '',
            timestamp: DateTime.now(),
            languageCode: languageCode,
            // Enhanced fields
            riskIntroduction: json['riskIntroduction'],
            predictedDiseaseDetails: diseaseDetails,
            descriptionDetails: json['description'] as Map<String, dynamic>?,
            whyNowDetails: whyNow?.map((k, v) => MapEntry(k, v.toString())),
            seasonalInfo: json['seasonalInfo'],
            preventionSteps: (json['preventionSteps'] as List?)?.map((e) => e.toString()).toList(),
            chemicalControl: (json['chemicalControl'] as List?)?.map((e) => e.toString()).toList(),
            maintenanceTips: (json['maintenanceTips'] as List?)?.map((e) => e.toString()).toList(),
          );
        }
        
        // Fall back to old format
        return AIInsight(
          summary: json['summary'] ?? '',
          analysisPoints: List<String>.from(json['analysis'] ?? []),
          pestRiskLevel: json['pestRisk']?['level'] ?? 'low',
          predictedDiseases: List<String>.from(json['pestRisk']?['diseases'] ?? []),
          pestExplanation: json['pestRisk']?['explanation'] ?? '',
          irrigationAdvice: json['irrigationAdvice'] ?? '',
          videoSearchQuery: json['videoSearchQuery'] ?? '',
          timestamp: DateTime.now(),
          languageCode: languageCode,
        );
      }
    } catch (e) {
      debugPrint('[AI] Error parsing response: $e');
    }
    
    // Fallback to raw text
    return AIInsight(
      summary: text.split('\n').first,
      analysisPoints: [text],
      pestRiskLevel: 'unknown',
      predictedDiseases: [],
      pestExplanation: '',
      irrigationAdvice: '',
      videoSearchQuery: '',
      timestamp: DateTime.now(),
      languageCode: languageCode,
    );
  }

  AIInsight _getMockInsight(SensorData data, String cropType, String fieldName, String langCode, int ageInDays) {
    final isLowMoisture = data.soilMoisture < 40;
    final isMediumMoisture = data.soilMoisture >= 40 && data.soilMoisture < 60;
    final isHighTemp = data.temperature > 30;
    final isMediumTemp = data.temperature >= 25 && data.temperature <= 30;
    final isHighHumidity = data.humidity > 70;
    final isMediumHumidity = data.humidity >= 60 && data.humidity <= 70;
    
    // Determine most likely disease based on conditions
    String diseaseName = '';
    String diseaseLocalName = '';
    String scientificName = '';
    String emoji = '🌾';
    String riskLevel = 'low';
    
    if (isHighTemp && isMediumHumidity && cropType.toLowerCase().contains('paddy')) {
      diseaseName = 'Rice Blast';
      diseaseLocalName = langCode == 'ta' ? 'நெல் வெடிப்பு நோய்' : 
                         langCode == 'hi' ? 'चावल ब्लास्ट रोग' : 'Rice Blast';
      scientificName = 'Magnaporthe oryzae';
      emoji = '🦠';
      riskLevel = 'high';
    } else if (isHighHumidity) {
      diseaseName = 'Leaf Blight';
      diseaseLocalName = langCode == 'ta' ? 'இலைக்கருகல் நோய்' :
                         langCode == 'hi' ? 'पत्ती झुलसा' : 'Leaf Blight';
      scientificName = 'Xanthomonas oryzae';
      emoji = '🍂';
      riskLevel = 'medium';
    } else if (isLowMoisture && isHighTemp) {
      diseaseName = 'Drought Stress';
      diseaseLocalName = langCode == 'ta' ? 'வறட்சி அழுத்தம்' :
                         langCode == 'hi' ? 'सूखा तनाव' : 'Drought Stress';
      scientificName = '';
      emoji = '☀️';
      riskLevel = 'medium';
    }
    
    if (langCode == 'en') {
      // English detailed response
      if (riskLevel == 'high' && diseaseName == 'Rice Blast') {
        return AIInsight(
          summary: 'Based on your current field data (Temperature: ${data.temperature.toStringAsFixed(1)}°C, Humidity: ${data.humidity.toStringAsFixed(1)}%, Soil Moisture: ${data.soilMoisture.toStringAsFixed(1)}%) and historical trends for $cropType crops, the most significant risk to your plants is Rice Blast.',
          analysisPoints: [],
          pestRiskLevel: 'high',
          predictedDiseases: [diseaseLocalName],
          pestExplanation: 'While your current humidity (${data.humidity.toStringAsFixed(1)}%) is slightly lower than ideal for a massive outbreak, the temperature of ${data.temperature.toStringAsFixed(1)}°C is near optimum for fungus growth. If humidity rises during night or due to upcoming rain, the risk becomes critical.',
          irrigationAdvice: 'Maintain steady water level. Avoid complete drainage as drought stress triggers Blast.',
          videoSearchQuery: _buildLocalizedMockVideoQuery(
            cropType: cropType,
            languageCode: langCode,
            issueLocalName: diseaseLocalName,
          ),
          timestamp: DateTime.now(),
          languageCode: langCode,
          // Enhanced detailed fields
          riskIntroduction: 'Based on your current field data (Temperature: ${data.temperature.toStringAsFixed(1)}°C, Humidity: ${data.humidity.toStringAsFixed(1)}%, Soil Moisture: ${data.soilMoisture.toStringAsFixed(1)}%) and historical trends for $cropType crops, the most significant risk to your plants is Rice Blast.',
          predictedDiseaseDetails: {
            'name': diseaseName,
            'localName': diseaseLocalName,
            'scientificName': scientificName,
            'emoji': emoji,
          },
          descriptionDetails: {
            'brief': 'Rice Blast is one of the most destructive fungal diseases for paddy. It can attack the plant at all stages of growth and severely impact yield.',
            'forms': [
              'Leaf Blast: Spindle-shaped (diamond) spots with grey centers and brown borders',
              'Neck Blast: The most damaging form, where the neck of the grain-bearing head turns black and rots, causing head fall',
              'Node Blast: Black lesions on stem joints that cause the plant to snap'
            ],
          },
          whyNowDetails: {
            'temperature': 'Temperature (${data.temperature.toStringAsFixed(1)}°C): This is near the "sweet spot" for this fungus. Research shows 25-28°C is peak temperature for spore germination and lesion development.',
            'humidity': 'Humidity (${data.humidity.toStringAsFixed(1)}%): While the fungus prefers >90% humidity to spread rapidly, ${data.humidity.toStringAsFixed(1)}% is enough for survival. Evening dew or intermittent drizzles will double the risk.',
            'soilMoisture': 'Soil Moisture (${data.soilMoisture.toStringAsFixed(1)}%): Lower soil moisture (non-flooded conditions) can stress the plant, making it MORE susceptible to Blast than a fully submerged field.',
          },
          seasonalInfo: 'Most prevalent during Kharif (Monsoon/Wet) season or during transitions where nights are cool and days are warm. High nitrogen application during these months significantly increases risk.',
          preventionSteps: [
            'Water Management: Maintain a steady water level. Avoid letting field dry out completely.',
            'Nitrogen Control: Stop or reduce Urea application immediately if you see first tiny spots. Excess nitrogen makes plant tissues soft.',
            'Seed Treatment: For future crops, treat seeds with Pseudomonas fluorescens (10g/kg) or Carbendazim.',
            'Field Cleanliness: Remove weeds from bunds (edges), as fungus lives there before jumping to paddy.',
          ],
          chemicalControl: [
            'Tricyclazole 75 WP: Spray at 0.6 g per liter of water',
            'Carbendazim 50 WP: Spray at 1.0 g per liter of water',
            'Kasugamycin 3% SL: Apply at 2ml per liter for severe infections'
          ],
          maintenanceTips: [
            'Monitor field twice daily - early morning and evening',
            'Check for first signs of diamond-shaped spots',
            'Avoid overhead irrigation to reduce leaf wetness'
          ],
        );
      } else if (isHighHumidity) {
        return AIInsight(
          summary: 'Current conditions show elevated humidity (${data.humidity.toStringAsFixed(1)}%) creating favorable environment for Leaf Blight disease in your $cropType field.',
          analysisPoints: [],
          pestRiskLevel: 'medium',
          predictedDiseases: [diseaseLocalName],
          pestExplanation: 'High humidity combined with warm temperatures creates ideal conditions for fungal diseases to develop and spread.',
          irrigationAdvice: 'Reduce irrigation frequency. Water only in morning hours to allow leaves to dry before evening.',
          videoSearchQuery: _buildLocalizedMockVideoQuery(
            cropType: cropType,
            languageCode: langCode,
            issueLocalName: diseaseLocalName,
          ),
          timestamp: DateTime.now(),
          languageCode: langCode,
          riskIntroduction: 'Current environmental conditions (Temperature: ${data.temperature.toStringAsFixed(1)}°C, Humidity: ${data.humidity.toStringAsFixed(1)}%, Soil Moisture: ${data.soilMoisture.toStringAsFixed(1)}%) show elevated humidity creating favorable environment for Leaf Blight.',
          predictedDiseaseDetails: {
            'name': diseaseName,
            'localName': diseaseLocalName,
            'scientificName': scientificName,
            'emoji': emoji,
          },
          descriptionDetails: {
            'brief': 'Leaf Blight is a bacterial disease that causes brown spots and streaks on leaves, leading to reduced photosynthesis and poor grain filling.',
            'forms': [
              'Brown spots appearing on leaf tips and margins',
              'Yellow halos around brown lesions',
              'Complete leaf wilting in severe cases'
            ],
          },
          whyNowDetails: {
            'temperature': 'Temperature (${data.temperature.toStringAsFixed(1)}°C): Current temperature is in the optimal range for bacterial multiplication and spread.',
            'humidity': 'Humidity (${data.humidity.toStringAsFixed(1)}%): High humidity creates moisture on leaf surfaces, perfect for bacterial entry through stomata and wounds.',
            'soilMoisture': 'Soil Moisture (${data.soilMoisture.toStringAsFixed(1)}%): Current moisture level is acceptable, but when combined with high air humidity, disease pressure increases.',
          },
          seasonalInfo: 'Common during monsoon season and periods of high rainfall with poor drainage.',
          preventionSteps: [
            'Improve field drainage to prevent water logging',
            'Maintain proper plant spacing for air circulation',
            'Remove and destroy infected plant parts',
            'Apply balanced fertilizers - avoid excess nitrogen',
          ],
          chemicalControl: [
            'Copper Oxychloride 50% WP: 3g per liter of water',
            'Streptomycin Sulfate 90% + Tetracycline 10%: 1g per 10 liters',
          ],
          maintenanceTips: [
            'Inspect plants every 2-3 days for early symptoms',
            'Avoid working in wet fields to prevent disease spread',
          ],
        );
      } else {
        // Good conditions - still provide detailed fields for a premium UI experience
        return AIInsight(
          summary: 'Your $fieldName field is currently in excellent health with favorable environmental conditions (Temperature: ${data.temperature.toStringAsFixed(1)}°C, Humidity: ${data.humidity.toStringAsFixed(1)}%, Soil Moisture: ${data.soilMoisture.toStringAsFixed(1)}%).',
          analysisPoints: [
            'Temperature at ${data.temperature.toStringAsFixed(1)}°C - Optimal for healthy $cropType growth',
            'Air Humidity at ${data.humidity.toStringAsFixed(1)}% - Well within safe range',
            'Soil Moisture at ${data.soilMoisture.toStringAsFixed(1)}% - ${isMediumMoisture ? "Perfect hydration for root uptake" : "Current level is stable"}'
          ],
          pestRiskLevel: 'low',
          predictedDiseases: [],
          pestExplanation: 'Environmental parameters are stable. No significant pest or disease threats detected at this stage.',
          irrigationAdvice: 'Current moisture level is adequate. Continue current irrigation schedule. Next regular watering recommended in 2-3 days.',
          videoSearchQuery: _buildLocalizedMockVideoQuery(
            cropType: cropType,
            languageCode: langCode,
            issueLocalName: diseaseLocalName,
            healthyMode: true,
          ),
          timestamp: DateTime.now(),
          languageCode: langCode,
          // Enhanced detailed fields for "Good" status
          riskIntroduction: 'Excellent news! Your $fieldName field shows high vitality. Current environmental data (T: ${data.temperature.toStringAsFixed(1)}°C, H: ${data.humidity.toStringAsFixed(1)}%) indicates a very low risk of major infections.',
          predictedDiseaseDetails: {
            'name': 'Healthy Crop',
            'localName': langCode == 'ta' ? 'ஆரோக்கியமான பயிர்' : langCode == 'hi' ? 'स्वस्थ फसल' : 'Healthy Crop',
            'scientificName': 'Status: Optimal',
            'emoji': '✅',
          },
          descriptionDetails: {
            'brief': 'Your crop is currently thriving under standard conditions. All monitored vital signs are in the green zone.',
            'forms': [
              'Optimal Photosynthesis: Leaves are naturally green and healthy',
              'Strong Root Support: Soil moisture balance is ideal for nutrient absorption',
              'Low Stress: No signs of heat or moisture-induced stress'
            ],
          },
          whyNowDetails: {
            'temperature': 'Temperature (${data.temperature.toStringAsFixed(1)}°C) is perfect for $cropType. It prevents fungal sporulation and promotes steady growth.',
            'humidity': 'Current humidity (${data.humidity.toStringAsFixed(1)}%) allows the plant to breathe and transpire properly without the risk of mildew.',
            'soilMoisture': 'Soil Moisture (${data.soilMoisture.toStringAsFixed(1)}%) ensures the root zone remains aerobic while providing enough water for cellular turgidity.',
          },
          seasonalInfo: 'The $cropType crop is currently in a resilient growth phase for this season. Keep monitoring for any sudden weather shifts.',
          preventionSteps: [
            'Regular Scouting: Continue walking the field daily to check for early signs of stress.',
            'Balanced Nutrition: Maintain your planned fertilizer application to sustain this growth.',
            'Drainage Check: Ensure drains are clear in case of unexpected rain.',
            'Record Keeping: Log these optimal conditions as a benchmark for future cycles.',
          ],
          chemicalControl: [
            'No chemical intervention required at this time.',
            'Proactive use of bio-fertilizers can further enhance plant immunity.'
          ],
          maintenanceTips: [
            'Enjoy the healthy growth!',
            'Clean your equipment regularly to prevent cross-contamination from other areas.',
            'Stay updated with the local weather forecast.'
          ],
        );
      }
    }
    
    final localizedDiseaseName = diseaseLocalName.isNotEmpty
        ? diseaseLocalName
        : (langCode == 'ta'
            ? 'ஆரோக்கியமான பயிர்'
            : langCode == 'hi'
                ? 'स्वस्थ फसल'
                : 'Healthy Crop');
    final localizedSummary = langCode == 'ta'
        ? 'உங்கள் $fieldName வயலுக்கான AI மதிப்பீடு: வெப்பநிலை ${data.temperature.toStringAsFixed(1)}°C, ஈரப்பதம் ${data.humidity.toStringAsFixed(1)}%, மண் ஈரப்பதம் ${data.soilMoisture.toStringAsFixed(1)}% அடிப்படையில் ${riskLevel == 'low' ? 'பெரிய நோய் ஆபத்து தற்போது குறைவாக உள்ளது.' : '$localizedDiseaseName பாதிப்பு ஏற்படும் சாத்தியம் உள்ளது.'}'
        : langCode == 'hi'
            ? 'आपके $fieldName खेत के लिए AI विश्लेषण: तापमान ${data.temperature.toStringAsFixed(1)}°C, आर्द्रता ${data.humidity.toStringAsFixed(1)}%, मिट्टी नमी ${data.soilMoisture.toStringAsFixed(1)}% के आधार पर ${riskLevel == 'low' ? 'बड़े रोग का जोखिम अभी कम है।' : '$localizedDiseaseName का खतरा दिखाई दे रहा है।'}'
            : 'Your $fieldName field is in good condition';

    return AIInsight(
      summary: localizedSummary,
      analysisPoints: langCode == 'ta'
          ? [
              'வெப்பநிலை: ${data.temperature.toStringAsFixed(1)}°C',
              'காற்று ஈரப்பதம்: ${data.humidity.toStringAsFixed(1)}%',
              'மண் ஈரப்பதம்: ${data.soilMoisture.toStringAsFixed(1)}%'
            ]
          : langCode == 'hi'
              ? [
                  'तापमान: ${data.temperature.toStringAsFixed(1)}°C',
                  'वायु आर्द्रता: ${data.humidity.toStringAsFixed(1)}%',
                  'मिट्टी नमी: ${data.soilMoisture.toStringAsFixed(1)}%'
                ]
              : [
                  'Temperature: ${data.temperature.toStringAsFixed(1)}°C',
                  'Humidity: ${data.humidity.toStringAsFixed(1)}%',
                  'Soil Moisture: ${data.soilMoisture.toStringAsFixed(1)}%'
                ],
      pestRiskLevel: riskLevel,
      predictedDiseases: riskLevel == 'low' ? [] : [localizedDiseaseName],
      pestExplanation: langCode == 'ta'
          ? (riskLevel == 'low'
              ? 'தரவு நிலைகள் சீராக இருப்பதால் நோய் அழுத்தம் தற்போது குறைவாக உள்ளது.'
              : 'தற்போதைய காலநிலை மதிப்புகள் $localizedDiseaseName உருவாக ஏற்ற சூழலை உருவாக்குகின்றன.')
          : langCode == 'hi'
              ? (riskLevel == 'low'
                  ? 'डेटा मान संतुलित हैं, इसलिए रोग दबाव अभी कम है।'
                  : 'मौजूदा मौसम मान $localizedDiseaseName के लिए अनुकूल स्थिति बना रहे हैं।')
              : '',
      irrigationAdvice: langCode == 'ta'
          ? (isLowMoisture ? 'மண் ஈரப்பதம் குறைவாக உள்ளது. விரைவில் பாசனம் தேவை.' : 'அடுத்த 2 நாட்களுக்கு உடனடி பாசனம் தேவையில்லை.')
          : langCode == 'hi'
              ? (isLowMoisture ? 'मिट्टी नमी कम है। जल्दी सिंचाई करें।' : 'अगले 2 दिनों तक तत्काल सिंचाई आवश्यक नहीं है।')
              : (isLowMoisture ? 'Irrigation needed soon' : 'No irrigation needed for next 2 days'),
      videoSearchQuery: _buildLocalizedMockVideoQuery(
        cropType: cropType,
        languageCode: langCode,
        issueLocalName: localizedDiseaseName,
        healthyMode: riskLevel == 'low',
      ),
      timestamp: DateTime.now(),
      languageCode: langCode,
      riskIntroduction: langCode == 'ta'
          ? 'உங்கள் வயலில் இருந்து பெறப்பட்ட தரவுகளை வைத்து பயிர் நலநிலை மதிப்பீடு செய்யப்பட்டது. தற்போதைய அளவுகளில் வெப்பநிலை ${data.temperature.toStringAsFixed(1)}°C மற்றும் ஈரப்பதம் ${data.humidity.toStringAsFixed(1)}% உள்ளது. இந்த நிலை தொடர்ந்தால் ${riskLevel == 'low' ? 'பெரிய ஆபத்து குறைவு.' : '$localizedDiseaseName அபாயம் அதிகரிக்கலாம்.'}'
          : langCode == 'hi'
              ? 'आपके खेत के सेंसर डेटा के आधार पर फसल स्वास्थ्य का आकलन किया गया है। वर्तमान तापमान ${data.temperature.toStringAsFixed(1)}°C और आर्द्रता ${data.humidity.toStringAsFixed(1)}% है। यह स्थिति जारी रही तो ${riskLevel == 'low' ? 'बड़ा जोखिम कम रहेगा।' : '$localizedDiseaseName का खतरा बढ़ सकता है।'}'
              : null,
      predictedDiseaseDetails: {
        'name': diseaseName.isNotEmpty ? diseaseName : 'Healthy Crop',
        'localName': localizedDiseaseName,
        'scientificName': scientificName.isNotEmpty ? scientificName : 'Optimal Conditions',
        'emoji': riskLevel == 'low' ? '✅' : emoji,
      },
      descriptionDetails: {
        'brief': langCode == 'ta'
            ? (riskLevel == 'low'
                ? 'தற்போது பயிர் நல்ல நிலையில் உள்ளது. தொடர்ந்து கண்காணிப்பது போதுமானது.'
                : '$localizedDiseaseName ஆரம்ப அறிகுறிகளை விரைவாக கண்டறிந்து நடவடிக்கை எடுத்தால் இழப்பை குறைக்கலாம்.')
            : langCode == 'hi'
                ? (riskLevel == 'low'
                    ? 'फसल अभी अच्छी स्थिति में है। नियमित निगरानी पर्याप्त है।'
                    : '$localizedDiseaseName के शुरुआती लक्षण पहचानकर तुरंत कार्रवाई करने से नुकसान कम होगा।')
                : '',
        'forms': langCode == 'ta'
            ? [
                'இலை நிற மாற்றம் மற்றும் சிறு புள்ளிகளை தினமும் பார்வையிடுங்கள்',
                'மண் ஈரப்பதம் திடீர் மாற்றங்களை கவனியுங்கள்'
              ]
            : langCode == 'hi'
                ? [
                    'पत्ती के रंग और धब्बों को रोज जांचें',
                    'मिट्टी नमी में अचानक बदलाव पर ध्यान दें'
                  ]
                : [],
      },
      whyNowDetails: {
        'temperature': langCode == 'ta'
            ? 'வெப்பநிலை ${data.temperature.toStringAsFixed(1)}°C: இது நோய்/அழுத்த அபாயத்தை பாதிக்கும் முக்கிய காரணம்.'
            : langCode == 'hi'
                ? 'तापमान ${data.temperature.toStringAsFixed(1)}°C: यह रोग/तनाव जोखिम को प्रभावित करने वाला मुख्य कारक है।'
                : 'Temperature is a key risk factor.',
        'humidity': langCode == 'ta'
            ? 'ஈரப்பதம் ${data.humidity.toStringAsFixed(1)}%: அதிக ஈரப்பதம் இருந்தால் இலை நோய் அழுத்தம் கூடும்.'
            : langCode == 'hi'
                ? 'आर्द्रता ${data.humidity.toStringAsFixed(1)}%: अधिक आर्द्रता होने पर पत्ती रोग दबाव बढ़ता है।'
                : 'Humidity can increase foliar disease pressure.',
        'soilMoisture': langCode == 'ta'
            ? 'மண் ஈரப்பதம் ${data.soilMoisture.toStringAsFixed(1)}%: குறைவு/அதிகம் இரண்டும் பயிர் அழுத்தத்தை உண்டாக்கலாம்.'
            : langCode == 'hi'
                ? 'मिट्टी नमी ${data.soilMoisture.toStringAsFixed(1)}%: बहुत कम या बहुत अधिक दोनों तनाव बढ़ाते हैं।'
                : 'Soil moisture imbalance can stress the crop.',
      },
      seasonalInfo: langCode == 'ta'
          ? 'இது காலநிலை மாற்ற காலம் என்றால் கூடுதல் கண்காணிப்பு அவசியம்.'
          : langCode == 'hi'
              ? 'मौसम बदलने के समय अतिरिक्त निगरानी आवश्यक है।'
              : null,
      preventionSteps: langCode == 'ta'
          ? [
              'நாள்தோறும் இலை மற்றும் தண்டை பார்க்கவும்',
              'மண் ஈரப்பதத்தை சமநிலைப்படுத்தி பாசனம் செய்யவும்',
              'நீர் தேக்கம் தவிர்த்து வடிகால் சுத்தமாக வைத்திருக்கவும்',
              'ஆரம்ப அறிகுறி தெரிந்தவுடன் உள்ளூர் வேளாண்மை ஆலோசனை பெறவும்',
            ]
          : langCode == 'hi'
              ? [
                  'रोज पत्तियों और तने की जांच करें',
                  'मिट्टी नमी संतुलित रखते हुए सिंचाई करें',
                  'जलभराव रोकें और निकासी साफ रखें',
                  'शुरुआती लक्षण दिखते ही कृषि सलाह लें',
                ]
              : null,
      chemicalControl: langCode == 'ta'
          ? [
              riskLevel == 'low' ? 'இப்போது வேதியியல் தெளிப்பு தேவையில்லை.' : 'நோய் அறிகுறி தெளிவாக இருந்தால் பரிந்துரைக்கப்பட்ட மருந்தை மட்டும் பயன்படுத்தவும்.'
            ]
          : langCode == 'hi'
              ? [
                  riskLevel == 'low' ? 'अभी रासायनिक छिड़काव की आवश्यकता नहीं है।' : 'लक्षण स्पष्ट होने पर ही अनुशंसित दवा का उपयोग करें।'
                ]
              : null,
      maintenanceTips: langCode == 'ta'
          ? ['வாரத்திற்கு குறைந்தது 2 முறை வயல் ஆய்வு செய்யவும்', 'சென்சார் தரவை பதிவுசெய்து மாற்றங்களை ஒப்பிடவும்']
          : langCode == 'hi'
              ? ['सप्ताह में कम से कम 2 बार खेत निरीक्षण करें', 'सेंसर डेटा रिकॉर्ड करके बदलाव तुलना करें']
              : null,
    );
  }

  String _buildLocalizedMockVideoQuery({
    required String cropType,
    required String languageCode,
    required String issueLocalName,
    bool healthyMode = false,
  }) {
    final issue = issueLocalName.trim();

    if (languageCode == 'ta') {
      if (healthyMode || issue.isEmpty) {
        return '$cropType பயிர் பராமரிப்பு தமிழ் விவசாயம்';
      }
      return '$cropType $issue நோய் மேலாண்மை சிகிச்சை தமிழ்';
    }

    if (languageCode == 'hi') {
      if (healthyMode || issue.isEmpty) {
        return '$cropType फसल देखभाल खेती टिप्स हिंदी';
      }
      return '$cropType $issue रोग प्रबंधन उपचार हिंदी';
    }

    if (healthyMode || issue.isEmpty) {
      return '$cropType crop management best practices India';
    }
    return '$cropType $issue disease management prevention farming';
  }

  String _buildAgronomicContext(SensorData sensorData, String cropType) {
    return '''
- Crop stress status: ${sensorData.stressLevel.label}
- Temperature status: ${sensorData.temperatureStatus}
- Humidity status: ${sensorData.humidityStatus}
- Soil moisture status: ${sensorData.soilMoistureStatus}
- Irrigation need: ${sensorData.needsIrrigation ? 'Needs irrigation soon' : 'No immediate irrigation required'}
- Waterlogging risk: ${sensorData.isWaterlogged ? 'High' : 'Low'}
- Crop family context: ${cropType.toLowerCase().contains('paddy') || cropType.toLowerCase().contains('rice') ? 'Paddy crops are sensitive to blast and bacterial leaf issues under humid conditions.' : 'Focus on general foliar disease, root stress, and irrigation balance for this crop.'}
''';
  }

  String _inferLikelyThreat(SensorData sensorData, String cropType) {
    final normalizedCrop = cropType.toLowerCase();
    if ((normalizedCrop.contains('paddy') || normalizedCrop.contains('rice')) &&
        sensorData.temperature >= 24 &&
        sensorData.temperature <= 30 &&
        sensorData.humidity >= 70) {
      return 'Rice Blast or leaf disease pressure';
    }
    if (sensorData.humidity >= 80) {
      return 'Leaf blight or fungal leaf infection pressure';
    }
    if (sensorData.soilMoisture < 35 && sensorData.temperature > 32) {
      return 'Heat and drought stress';
    }
    return 'No major disease pressure, focus on preventive crop care';
  }

  String _estimateRiskLevel(SensorData sensorData, String cropType) {
    final normalizedCrop = cropType.toLowerCase();
    if ((normalizedCrop.contains('paddy') || normalizedCrop.contains('rice')) &&
        sensorData.temperature >= 24 &&
        sensorData.temperature <= 30 &&
        sensorData.humidity >= 75) {
      return 'high';
    }
    if (sensorData.humidity >= 80 || sensorData.soilMoisture < 35 || sensorData.temperature > 34) {
      return 'medium';
    }
    return 'low';
  }

  String _normalizeRiskLevel(String? riskLevel, String? diseaseName) {
    final normalized = riskLevel?.trim().toLowerCase();
    if (normalized == 'low' || normalized == 'medium' || normalized == 'high') {
      return normalized!;
    }

    final disease = diseaseName?.toLowerCase() ?? '';
    if (disease.contains('healthy')) {
      return 'low';
    }
    if (disease.isNotEmpty) {
      return 'medium';
    }
    return 'low';
  }

  String _resolveVideoSearchQuery({
    required AIInsight parsedInsight,
    required String cropType,
    required String languageCode,
  }) {
    final rawQuery = parsedInsight.videoSearchQuery.trim();
    if (rawQuery.isNotEmpty) {
      if (languageCode == 'ta' && !RegExp(r'[\u0B80-\u0BFF]').hasMatch(rawQuery)) {
        return '$rawQuery தமிழ் விவசாயம்';
      }
      if (languageCode == 'hi' && !RegExp(r'[\u0900-\u097F]').hasMatch(rawQuery)) {
        return '$rawQuery हिंदी खेती';
      }
      return rawQuery;
    }

    final focus = parsedInsight.diseaseLocalName.toLowerCase() == 'healthy crop'
        ? ''
        : parsedInsight.diseaseLocalName;

    switch (languageCode) {
      case 'ta':
        return '$cropType $focus விவசாய மேலாண்மை தமிழ்'.trim();
      case 'hi':
        return '$cropType $focus खेती प्रबंधन हिंदी'.trim();
      default:
        return '$cropType ${focus.isEmpty ? 'crop care' : focus} management India'.trim();
    }
  }

  bool _isInsightInRequestedLanguage(AIInsight insight, String languageCode) {
    if (languageCode == 'en') {
      return true;
    }

    final sample = [
      insight.summary,
      insight.riskIntroduction ?? '',
      insight.pestExplanation,
      insight.irrigationAdvice,
    ].join(' ');

    if (sample.trim().isEmpty) {
      return false;
    }

    final pattern = languageCode == 'ta'
        ? RegExp(r'[\u0B80-\u0BFF]')
        : RegExp(r'[\u0900-\u097F]');
    return pattern.hasMatch(sample);
  }

  /// Predict crop diseases based on field data and conditions
  Future<DiseasePredictionResult> predictDiseases({
    required SensorData sensorData,
    required Field field,
    required String languageCode,
    List<SensorData>? history,
  }) async {
    final plantingDate = field.plantingDate ?? field.createdAt ?? DateTime.now();
    final ageInDays = DateTime.now().difference(plantingDate).inDays;
    return _predictDiseasesLocally(
      sensorData: sensorData,
      field: field,
      languageCode: languageCode,
      history: history,
      ageInDays: ageInDays,
    );
  }

  DiseasePredictionResult _predictDiseasesLocally({
    required SensorData sensorData,
    required Field field,
    required String languageCode,
    required int ageInDays,
    List<SensorData>? history,
  }) {
    final all = <SensorData>[...(history ?? []), sensorData];
    final avgTemp = all.map((e) => e.temperature).reduce((a, b) => a + b) / all.length;
    final avgHum = all.map((e) => e.humidity).reduce((a, b) => a + b) / all.length;
    final avgMoist = all.map((e) => e.soilMoisture).reduce((a, b) => a + b) / all.length;
    final humTrend = all.length > 1 ? all.last.humidity - all.first.humidity : 0.0;
    final tempTrend = all.length > 1 ? all.last.temperature - all.first.temperature : 0.0;
    final moistTrend = all.length > 1 ? all.last.soilMoisture - all.first.soilMoisture : 0.0;

    final crop = field.cropType.toLowerCase();
    final candidates = <_LocalDiseaseCandidate>[];

    final riceBlastScore = _clamp01(
      (crop.contains('paddy') || crop.contains('rice') ? 0.25 : 0.0) +
          _bandScore(avgTemp, 24, 30, 27) * 0.30 +
          _bandScore(avgHum, 68, 92, 82) * 0.30 +
          _bandScore(ageInDays.toDouble(), 20, 95, 50) * 0.10 +
          (humTrend > 4 ? 0.10 : 0.0) -
          (avgMoist < 25 ? 0.08 : 0.0),
    );
    candidates.add(_buildLocalCandidate(
      score: riceBlastScore,
      levelHint: 'fungal',
      diseaseName: 'Rice Blast',
      scientificName: 'Magnaporthe oryzae',
      languageCode: languageCode,
      cropType: field.cropType,
    ));

    final leafBlightScore = _clamp01(
      _bandScore(avgHum, 70, 95, 85) * 0.40 +
          _bandScore(avgTemp, 25, 35, 30) * 0.30 +
          (humTrend > 3 ? 0.10 : 0.0) +
          (moistTrend > 5 ? 0.08 : 0.0) +
          (crop.contains('rice') || crop.contains('paddy') ? 0.08 : 0.0),
    );
    candidates.add(_buildLocalCandidate(
      score: leafBlightScore,
      levelHint: 'bacterial',
      diseaseName: 'Leaf Blight',
      scientificName: 'Xanthomonas oryzae',
      languageCode: languageCode,
      cropType: field.cropType,
    ));

    final droughtScore = _clamp01(
      _bandScore(100 - avgMoist, 30, 80, 55) * 0.45 +
          _bandScore(avgTemp, 30, 42, 36) * 0.30 +
          (moistTrend < -5 ? 0.15 : 0.0) +
          (tempTrend > 2 ? 0.08 : 0.0),
    );
    candidates.add(_buildLocalCandidate(
      score: droughtScore,
      levelHint: 'abiotic',
      diseaseName: 'Drought Stress',
      scientificName: 'Abiotic Stress',
      languageCode: languageCode,
      cropType: field.cropType,
    ));

    final rootRotScore = _clamp01(
      _bandScore(avgMoist, 75, 100, 90) * 0.45 +
          _bandScore(avgHum, 75, 98, 88) * 0.25 +
          _bandScore(avgTemp, 24, 34, 29) * 0.20 +
          (moistTrend > 6 ? 0.10 : 0.0),
    );
    candidates.add(_buildLocalCandidate(
      score: rootRotScore,
      levelHint: 'fungal',
      diseaseName: 'Root Rot',
      scientificName: 'Pythium spp.',
      languageCode: languageCode,
      cropType: field.cropType,
    ));

    final selected = candidates
        .where((c) => c.score >= 0.32)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final predictions = selected.take(3).map((c) => c.toPrediction()).toList();

    if (predictions.isEmpty) {
      predictions.add(_buildHealthyPrediction(field.cropType, languageCode));
    }

    return DiseasePredictionResult(
      predictions: predictions,
      overallAssessment: _buildOverallAssessment(
        predictions: predictions,
        languageCode: languageCode,
        cropType: field.cropType,
        avgTemp: avgTemp,
        avgHum: avgHum,
        avgMoist: avgMoist,
      ),
      fieldName: field.name,
      cropType: field.cropType,
      timestamp: DateTime.now(),
      languageCode: languageCode,
    );
  }

  _LocalDiseaseCandidate _buildLocalCandidate({
    required double score,
    required String levelHint,
    required String diseaseName,
    required String scientificName,
    required String languageCode,
    required String cropType,
  }) {
    final risk = score >= 0.70
        ? DiseaseRiskLevel.high
        : score >= 0.45
            ? DiseaseRiskLevel.medium
            : DiseaseRiskLevel.low;

    final diseaseLocalName = _localizeDiseaseName(diseaseName, languageCode);
    return _LocalDiseaseCandidate(
      score: score,
      prediction: DiseasePrediction(
        diseaseName: diseaseName,
        diseaseNameLocal: diseaseLocalName,
        riskLevel: risk,
        reason: _localizeReason(diseaseLocalName, score, languageCode),
        symptoms: _localizeSymptoms(diseaseName, languageCode),
        causes: _localizeCauses(levelHint, languageCode),
        prevention: _localizePrevention(levelHint, languageCode),
        treatment: _localizeTreatment(levelHint, languageCode),
        youtubeVideoId: '',
        youtubeSearchQuery: _buildLocalizedMockVideoQuery(
          cropType: cropType,
          languageCode: languageCode,
          issueLocalName: diseaseLocalName,
        ),
        timestamp: DateTime.now(),
        languageCode: languageCode,
      ),
    );
  }

  DiseasePrediction _buildHealthyPrediction(String cropType, String languageCode) {
    return DiseasePrediction(
      diseaseName: 'Healthy Crop',
      diseaseNameLocal: languageCode == 'ta'
          ? 'ஆரோக்கியமான பயிர்'
          : languageCode == 'hi'
              ? 'स्वस्थ फसल'
              : 'Healthy Crop',
      riskLevel: DiseaseRiskLevel.low,
      reason: languageCode == 'ta'
          ? 'தற்போதைய தரவுகள் பெரும் நோய் ஆபத்தை காட்டவில்லை.'
          : languageCode == 'hi'
              ? 'मौजूदा डेटा में गंभीर बीमारी का जोखिम कम है।'
              : 'Current field parameters show low immediate disease pressure.',
      symptoms: languageCode == 'ta'
          ? 'கண்கூடாக பாதிப்பு இல்லை. இலை நிறம் மற்றும் வளர்ச்சியை கண்காணிக்கவும்.'
          : languageCode == 'hi'
              ? 'कोई गंभीर लक्षण नहीं। पत्तियों का रंग और वृद्धि देखते रहें।'
              : 'No major visible symptoms. Continue monitoring leaf color and growth.',
      causes: languageCode == 'ta'
          ? 'சூழல் நிலைகள் தற்போது பயிர் வளர்ச்சிக்கு சாதகமாக உள்ளன.'
          : languageCode == 'hi'
              ? 'वातावरणीय स्थितियां अभी फसल के लिए अनुकूल हैं।'
              : 'Current environmental conditions are favorable for the crop.',
      prevention: languageCode == 'ta'
          ? 'தொடர்ந்து சென்சார் மதிப்புகளை கவனிக்கவும், அதிக நீர் தேக்கம் தவிர்க்கவும்.'
          : languageCode == 'hi'
              ? 'सेंसर मानों की नियमित निगरानी करें, पानी जमा न होने दें।'
              : 'Monitor sensors regularly and avoid sudden over-irrigation.',
      treatment: languageCode == 'ta'
          ? 'தற்போது சிகிச்சை தேவையில்லை.'
          : languageCode == 'hi'
              ? 'अभी उपचार की आवश्यकता नहीं है।'
              : 'No treatment required at this stage.',
      youtubeVideoId: '',
      youtubeSearchQuery: _buildLocalizedMockVideoQuery(
        cropType: cropType,
        languageCode: languageCode,
        issueLocalName: '',
        healthyMode: true,
      ),
      timestamp: DateTime.now(),
      languageCode: languageCode,
    );
  }

  double _bandScore(double value, double min, double max, double ideal) {
    if (value < min || value > max) return 0.0;
    final range = (max - min) / 2;
    final diff = (value - ideal).abs();
    return _clamp01(1 - (diff / range));
  }

  double _clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

  String _localizeDiseaseName(String name, String languageCode) {
    if (languageCode == 'ta') {
      switch (name) {
        case 'Rice Blast':
          return 'நெல் வெடிப்பு நோய்';
        case 'Leaf Blight':
          return 'இலைக்கருகல் நோய்';
        case 'Drought Stress':
          return 'வறட்சி அழுத்தம்';
        case 'Root Rot':
          return 'வேர் அழுகல்';
      }
    }
    if (languageCode == 'hi') {
      switch (name) {
        case 'Rice Blast':
          return 'चावल ब्लास्ट रोग';
        case 'Leaf Blight':
          return 'पत्ता झुलसा रोग';
        case 'Drought Stress':
          return 'सूखा तनाव';
        case 'Root Rot':
          return 'जड़ सड़न';
      }
    }
    return name;
  }

  String _localizeReason(String diseaseLocalName, double score, String languageCode) {
    final risk = (score * 100).round();
    if (languageCode == 'ta') {
      return 'தற்போதைய தரவுகள் அடிப்படையில் $diseaseLocalName ஏற்படும் வாய்ப்பு சுமார் $risk% உள்ளது.';
    }
    if (languageCode == 'hi') {
      return 'वर्तमान डेटा के आधार पर $diseaseLocalName का जोखिम लगभग $risk% है।';
    }
    return 'Based on current parameters, estimated risk of $diseaseLocalName is about $risk%.';
  }

  String _localizeSymptoms(String diseaseName, String languageCode) {
    if (languageCode == 'ta') {
      switch (diseaseName) {
        case 'Rice Blast':
          return 'இலைகளில் வைரம் போன்ற பழுப்பு புள்ளிகள், கழுத்து பகுதி கருமையாகுதல்.';
        case 'Leaf Blight':
          return 'இலை விளிம்பில் பழுப்பு/மஞ்சள் காய்ச்சல், இலை உலர்தல்.';
        case 'Drought Stress':
          return 'இலை சுருக்கு, வளர்ச்சி குறைவு, செடி வாடுதல்.';
        case 'Root Rot':
          return 'வேர் கருமை, வளர்ச்சி மந்தம், செடி திடீர் வாடுதல்.';
      }
    }
    if (languageCode == 'hi') {
      switch (diseaseName) {
        case 'Rice Blast':
          return 'पत्तियों पर हीरे जैसे धब्बे, गर्दन भाग काला पड़ना।';
        case 'Leaf Blight':
          return 'पत्तियों के किनारों पर पीला/भूरा झुलसा, पत्ती सूखना।';
        case 'Drought Stress':
          return 'पत्तियां मुड़ना, वृद्धि रुकना, पौधा मुरझाना।';
        case 'Root Rot':
          return 'जड़ों का काला होना, धीमी वृद्धि, अचानक मुरझाना।';
      }
    }
    switch (diseaseName) {
      case 'Rice Blast':
        return 'Diamond-like lesions on leaves and neck blackening in severe cases.';
      case 'Leaf Blight':
        return 'Yellow-brown streaking and drying from leaf edges.';
      case 'Drought Stress':
        return 'Leaf curling, wilting, and reduced growth rate.';
      case 'Root Rot':
        return 'Root darkening, stunted growth, and sudden wilting.';
      default:
        return 'Monitor crop symptoms closely.';
    }
  }

  String _localizeCauses(String levelHint, String languageCode) {
    if (languageCode == 'ta') {
      if (levelHint == 'fungal') return 'அதிக ஈரப்பதம் மற்றும் வெப்ப சூழல் பூஞ்சை வளர்ச்சியை அதிகரிக்கிறது.';
      if (levelHint == 'bacterial') return 'ஈரமான இலை மேற்பரப்பு மற்றும் நீர் தேக்கம் பாக்டீரியா பரவலை அதிகரிக்கிறது.';
      return 'வெப்பம், குறைந்த ஈரப்பதம் அல்லது நீர் குறைபாடு போன்ற சூழல் அழுத்தங்கள்.';
    }
    if (languageCode == 'hi') {
      if (levelHint == 'fungal') return 'उच्च नमी और तापमान फफूंद वृद्धि को बढ़ाते हैं।';
      if (levelHint == 'bacterial') return 'गीली पत्ती सतह और जलभराव बैक्टीरिया फैलाव बढ़ाते हैं।';
      return 'गर्मी, कम नमी या पानी की कमी जैसे पर्यावरणीय तनाव।';
    }
    if (levelHint == 'fungal') return 'High humidity and warm conditions increase fungal pressure.';
    if (levelHint == 'bacterial') return 'Wet leaf surfaces and standing water increase bacterial spread.';
    return 'Heat and water imbalance are causing abiotic stress.';
  }

  String _localizePrevention(String levelHint, String languageCode) {
    if (languageCode == 'ta') {
      if (levelHint == 'fungal' || levelHint == 'bacterial') {
        return 'வயலில் காற்றோட்டம் மேம்படுத்தவும், அதிக நீர் தேக்கம் தவிர்க்கவும், பாதித்த இலைகளை அகற்றவும்.';
      }
      return 'மல்ச்சிங் பயன்படுத்தவும், சீரான பாசனம் பின்பற்றவும், மதிய வெப்பத்தில் நீர் அழுத்தம் தவிர்க்கவும்.';
    }
    if (languageCode == 'hi') {
      if (levelHint == 'fungal' || levelHint == 'bacterial') {
        return 'खेत में हवा का प्रवाह बढ़ाएं, जलभराव रोकें, प्रभावित पत्तियां हटाएं।';
      }
      return 'मल्चिंग करें, सिंचाई संतुलित रखें, दोपहर की गर्मी में पौधे पर तनाव न आने दें।';
    }
    if (levelHint == 'fungal' || levelHint == 'bacterial') {
      return 'Improve field aeration, avoid waterlogging, and remove infected leaves early.';
    }
    return 'Use mulching and maintain balanced irrigation to avoid stress buildup.';
  }

  String _localizeTreatment(String levelHint, String languageCode) {
    if (languageCode == 'ta') {
      if (levelHint == 'fungal') return 'தேவையானபோது பூஞ்சைக்கொல்லி மருந்தை பரிந்துரைக்கப்பட்ட அளவில் தெளிக்கவும்.';
      if (levelHint == 'bacterial') return 'தாமிர அடிப்படையிலான கட்டுப்பாட்டு மருந்துகளை விவசாய ஆலோசனைப்படி பயன்படுத்தவும்.';
      return 'உடனடி பாசனம் மற்றும் உயிர்சத்து உரம் மூலம் செடியை மீட்டெடுக்கவும்.';
    }
    if (languageCode == 'hi') {
      if (levelHint == 'fungal') return 'आवश्यक होने पर अनुशंसित मात्रा में फफूंदनाशक का छिड़काव करें।';
      if (levelHint == 'bacterial') return 'कृषि सलाह के अनुसार तांबा आधारित नियंत्रण दवा का उपयोग करें।';
      return 'तुरंत सिंचाई करें और जैविक पोषण देकर पौधे की रिकवरी बढ़ाएं।';
    }
    if (levelHint == 'fungal') return 'Use a recommended fungicide dose only when symptoms appear.';
    if (levelHint == 'bacterial') return 'Use copper-based control measures based on local agri guidance.';
    return 'Restore moisture balance quickly and support recovery with organic nutrition.';
  }

  String _buildOverallAssessment({
    required List<DiseasePrediction> predictions,
    required String languageCode,
    required String cropType,
    required double avgTemp,
    required double avgHum,
    required double avgMoist,
  }) {
    final top = predictions.first;
    if (languageCode == 'ta') {
      return 'சராசரி T:${avgTemp.toStringAsFixed(1)}°C, H:${avgHum.toStringAsFixed(0)}%, M:${avgMoist.toStringAsFixed(0)}% அடிப்படையில், $cropType-க்கு ${top.diseaseNameLocal} முக்கிய ஆபத்தாக கணிக்கப்பட்டுள்ளது.';
    }
    if (languageCode == 'hi') {
      return 'औसत T:${avgTemp.toStringAsFixed(1)}°C, H:${avgHum.toStringAsFixed(0)}%, M:${avgMoist.toStringAsFixed(0)}% के आधार पर $cropType के लिए ${top.diseaseNameLocal} प्रमुख जोखिम है।';
    }
    return 'Based on avg T:${avgTemp.toStringAsFixed(1)}°C, H:${avgHum.toStringAsFixed(0)}%, M:${avgMoist.toStringAsFixed(0)}%, the key risk for $cropType is ${top.diseaseNameLocal}.';
  }

  String _buildDiseasePredictionPrompt({
    required SensorData sensorData,
    required String cropType,
    required String fieldName,
    required int ageInDays,
    required String languageCode,
    List<SensorData>? history,
  }) {
    final langName = languageCode == 'ta' ? 'Tamil' : (languageCode == 'hi' ? 'Hindi' : 'English');
    
    String historyInfo = "No historical data available.";
    if (history != null && history.isNotEmpty) {
      historyInfo = "History (Last 5 records): " + 
          history.take(5).map((d) => "T:${d.temperature.toStringAsFixed(1)}°C, H:${d.humidity.toStringAsFixed(0)}%, M:${d.soilMoisture.toStringAsFixed(0)}%").join(" | ");
    }

    return '''
You are an expert agricultural pathologist AI specialized in crop disease diagnosis for Indian farmers.
Analyze the environmental conditions and predict possible crop diseases.

FIELD INFO:
- Field Name: $fieldName
- Crop Type: $cropType
- Crop Age: $ageInDays days since planting

CURRENT ENVIRONMENTAL CONDITIONS:
- Soil Moisture: ${sensorData.soilMoisture.toStringAsFixed(1)}%
- Temperature: ${sensorData.temperature.toStringAsFixed(1)}°C
- Air Humidity: ${sensorData.humidity.toStringAsFixed(1)}%

HISTORICAL DATA: $historyInfo

IMPORTANT INSTRUCTIONS:
1. Predict 1-3 most likely diseases that could affect this $cropType crop under these conditions.
2. Use simple, farmer-friendly language that rural Indian farmers can easily understand.
3. ALL TEXT MUST BE IN $langName LANGUAGE ONLY.
4. For each disease, provide practical prevention and treatment advice.
5. Generate YouTube search queries in $langName to help farmers find relevant videos.

RESPOND STRICTLY IN THIS JSON FORMAT:
{
  "overallAssessment": "Brief overall crop health assessment in $langName using simple words",
  "diseases": [
    {
      "diseaseName": "Disease name in English",
      "diseaseNameLocal": "Disease name in $langName",
      "riskLevel": "low/medium/high",
      "reason": "Why this disease is a risk right now - simple explanation in $langName",
      "symptoms": "What the farmer should look for on the plant - in $langName",
      "causes": "What causes this disease - simple explanation in $langName",
      "prevention": "How to prevent this disease - practical steps in $langName",
      "treatment": "How to treat if the disease appears - in $langName",
      "youtubeSearchQuery": "Search query in $langName to find helpful video"
    }
  ]
}
''';
  }

  DiseasePredictionResult _parseDiseasePredictionResponse(
    String text, String fieldName, String cropType, String languageCode) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);
        
        final diseases = (json['diseases'] as List?)?.map((d) {
          return DiseasePrediction(
            diseaseName: d['diseaseName'] ?? 'Unknown Disease',
            diseaseNameLocal: d['diseaseNameLocal'] ?? d['diseaseName'] ?? 'Unknown',
            riskLevel: _parseRiskLevel(d['riskLevel']),
            reason: d['reason'] ?? '',
            symptoms: d['symptoms'] ?? '',
            causes: d['causes'] ?? '',
            prevention: d['prevention'] ?? '',
            treatment: d['treatment'] ?? '',
            youtubeVideoId: '', // Will be populated separately
            youtubeSearchQuery: d['youtubeSearchQuery'] ?? '$cropType disease $languageCode',
            timestamp: DateTime.now(),
            languageCode: languageCode,
          );
        }).toList() ?? [];

        return DiseasePredictionResult(
          predictions: diseases,
          overallAssessment: json['overallAssessment'] ?? '',
          fieldName: fieldName,
          cropType: cropType,
          timestamp: DateTime.now(),
          languageCode: languageCode,
        );
      }
    } catch (e) {
      debugPrint('[AI] Error parsing disease response: $e');
    }

    // Fallback
    return DiseasePredictionResult(
      predictions: [],
      overallAssessment: text.split('\n').first,
      fieldName: fieldName,
      cropType: cropType,
      timestamp: DateTime.now(),
      languageCode: languageCode,
    );
  }

  DiseaseRiskLevel _parseRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return DiseaseRiskLevel.high;
      case 'medium':
        return DiseaseRiskLevel.medium;
      default:
        return DiseaseRiskLevel.low;
    }
  }

  DiseasePredictionResult _getMockDiseasePrediction(
    SensorData data, Field field, String langCode, int ageInDays) {
    
    final isHighHumidity = data.humidity > 75;
    final isLowMoisture = data.soilMoisture < 40;
    final isHighTemp = data.temperature > 32;
    
    List<DiseasePrediction> diseases = [];

    if (langCode == 'ta') {
      // Tamil mock data
      if (isHighHumidity) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Leaf Blight',
          diseaseNameLocal: 'இலைக்கருகல் நோய்',
          riskLevel: DiseaseRiskLevel.high,
          reason: 'அதிக ஈரப்பதம் (${data.humidity.toStringAsFixed(0)}%) இருப்பதால் பூஞ்சை வளர ஏற்ற சூழ்நிலை உள்ளது.',
          symptoms: 'இலைகளில் பழுப்பு நிற புள்ளிகள், இலை விளிம்புகள் காய்ந்து போதல், மஞ்சள் நிற மாற்றம்.',
          causes: 'அதிக காற்று ஈரப்பதம், மழைக்காலம், நீர் தேங்குதல்.',
          prevention: 'செடிகளுக்கு இடையே இடைவெளி விடுங்கள். காலையில் தண்ணீர் ஊற்றுங்கள்.',
          treatment: 'பாதிக்கப்பட்ட இலைகளை அகற்றுங்கள். தாமிர பூஞ்சைக்கொல்லி தெளிக்கவும்.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} இலைக்கருகல் நோய் தடுப்பு தமிழ்',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }
      if (isHighTemp) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Heat Stress Wilting',
          diseaseNameLocal: 'வெப்ப அழுத்த வாடல்',
          riskLevel: DiseaseRiskLevel.medium,
          reason: 'வெப்பநிலை ${data.temperature.toStringAsFixed(0)}°C அதிகமாக உள்ளது.',
          symptoms: 'இலைகள் சுருங்குதல், வாடுதல், வளர்ச்சி குறைவு.',
          causes: 'அதிக சூரிய வெப்பம், போதுமான நீர் இல்லாமை.',
          prevention: 'மதியம் நிழல் ஏற்படுத்துங்கள். மல்ச்சிங் செய்யுங்கள்.',
          treatment: 'காலை மாலை நேரத்தில் நீர் பாய்ச்சுங்கள். தழை உரம் இடுங்கள்.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} வெப்ப பாதுகாப்பு விவசாயம் தமிழ்',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }

      return DiseasePredictionResult(
        predictions: diseases.isEmpty ? [DiseasePrediction(
          diseaseName: 'No Significant Risk',
          diseaseNameLocal: 'குறிப்பிடத்தக்க ஆபத்து இல்லை',
          riskLevel: DiseaseRiskLevel.low,
          reason: 'தற்போதைய சுற்றுச்சூழல் நிலைமைகள் சாதகமாக உள்ளன.',
          symptoms: 'எந்த அறிகுறியும் தெரியவில்லை.',
          causes: 'இல்லை',
          prevention: 'தொடர்ந்து கண்காணிக்கவும்.',
          treatment: 'தேவையில்லை.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} பயிர் பராமரிப்பு தமிழ்',
          timestamp: DateTime.now(),
          languageCode: langCode,
        )] : diseases,
        overallAssessment: diseases.isEmpty 
            ? 'உங்கள் ${field.name} வயல் நல்ல நிலையில் உள்ளது. தொடர்ந்து கவனமாக இருங்கள்.'
            : 'உங்கள் வயலில் சில ஆபத்துகள் உள்ளன. கவனமாக கண்காணிக்கவும்.',
        fieldName: field.name,
        cropType: field.cropType,
        timestamp: DateTime.now(),
        languageCode: langCode,
      );
    } else if (langCode == 'hi') {
      // Hindi mock data
      if (isHighHumidity) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Leaf Blight',
          diseaseNameLocal: 'पत्ता झुलसा रोग',
          riskLevel: DiseaseRiskLevel.high,
          reason: 'उच्च नमी (${data.humidity.toStringAsFixed(0)}%) के कारण फफूंद के लिए अनुकूल वातावरण है।',
          symptoms: 'पत्तियों पर भूरे धब्बे, पत्तियों का किनारा सूखना, पीला पड़ना।',
          causes: 'अधिक हवा की नमी, बारिश का मौसम, पानी का जमाव।',
          prevention: 'पौधों के बीच दूरी रखें। सुबह पानी दें।',
          treatment: 'प्रभावित पत्तियां हटाएं। तांबा फफूंदनाशक छिड़कें।',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} पत्ता झुलसा रोग उपचार हिंदी',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }
      if (isHighTemp) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Heat Stress Wilting',
          diseaseNameLocal: 'गर्मी का तनाव',
          riskLevel: DiseaseRiskLevel.medium,
          reason: 'तापमान ${data.temperature.toStringAsFixed(0)}°C बहुत अधिक है।',
          symptoms: 'पत्तियों का मुरझाना, सिकुड़ना, धीमी वृद्धि।',
          causes: 'तेज धूप, पानी की कमी।',
          prevention: 'दोपहर में छाया दें। मल्चिंग करें।',
          treatment: 'सुबह-शाम पानी दें। जैविक खाद डालें।',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} गर्मी से बचाव खेती हिंदी',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }

      return DiseasePredictionResult(
        predictions: diseases.isEmpty ? [DiseasePrediction(
          diseaseName: 'No Significant Risk',
          diseaseNameLocal: 'कोई महत्वपूर्ण खतरा नहीं',
          riskLevel: DiseaseRiskLevel.low,
          reason: 'वर्तमान पर्यावरणीय स्थितियां अनुकूल हैं।',
          symptoms: 'कोई लक्षण नहीं दिख रहे।',
          causes: 'कोई नहीं',
          prevention: 'निगरानी जारी रखें।',
          treatment: 'आवश्यक नहीं।',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} फसल देखभाल हिंदी',
          timestamp: DateTime.now(),
          languageCode: langCode,
        )] : diseases,
        overallAssessment: diseases.isEmpty 
            ? 'आपका ${field.name} खेत अच्छी स्थिति में है। सावधान रहें।'
            : 'आपके खेत में कुछ खतरे हैं। ध्यान से निगरानी करें।',
        fieldName: field.name,
        cropType: field.cropType,
        timestamp: DateTime.now(),
        languageCode: langCode,
      );
    } else {
      // English mock data
      if (isHighHumidity) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Leaf Blight',
          diseaseNameLocal: 'Leaf Blight',
          riskLevel: DiseaseRiskLevel.high,
          reason: 'High humidity (${data.humidity.toStringAsFixed(0)}%) creates favorable conditions for fungal growth.',
          symptoms: 'Brown spots on leaves, leaf edges drying up, yellowing of leaves.',
          causes: 'High air humidity, rainy weather, water logging.',
          prevention: 'Maintain spacing between plants. Water in the morning only.',
          treatment: 'Remove affected leaves. Spray copper-based fungicide.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} leaf blight disease treatment farming',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }
      if (isHighTemp) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Heat Stress Wilting',
          diseaseNameLocal: 'Heat Stress Wilting',
          riskLevel: DiseaseRiskLevel.medium,
          reason: 'Temperature at ${data.temperature.toStringAsFixed(0)}°C is too high for optimal growth.',
          symptoms: 'Leaves wilting, curling, reduced growth rate.',
          causes: 'Excessive sunlight, inadequate water supply.',
          prevention: 'Provide shade during peak hours. Apply mulching.',
          treatment: 'Water during cooler hours. Apply organic fertilizer.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} heat stress protection farming tips',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }
      if (isLowMoisture) {
        diseases.add(DiseasePrediction(
          diseaseName: 'Drought Stress',
          diseaseNameLocal: 'Drought Stress',
          riskLevel: DiseaseRiskLevel.medium,
          reason: 'Soil moisture at ${data.soilMoisture.toStringAsFixed(0)}% is below optimal level.',
          symptoms: 'Wilted leaves, stunted growth, dry and cracked soil.',
          causes: 'Insufficient irrigation, high evaporation rate.',
          prevention: 'Regular irrigation schedule. Use drip irrigation.',
          treatment: 'Irrigate immediately. Add organic mulch to retain moisture.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} drought stress water management',
          timestamp: DateTime.now(),
          languageCode: langCode,
        ));
      }

      return DiseasePredictionResult(
        predictions: diseases.isEmpty ? [DiseasePrediction(
          diseaseName: 'No Significant Risk',
          diseaseNameLocal: 'No Significant Risk',
          riskLevel: DiseaseRiskLevel.low,
          reason: 'Current environmental conditions are favorable for your crop.',
          symptoms: 'No visible symptoms.',
          causes: 'None',
          prevention: 'Continue regular monitoring.',
          treatment: 'Not required.',
          youtubeVideoId: '',
          youtubeSearchQuery: '${field.cropType} crop care farming tips',
          timestamp: DateTime.now(),
          languageCode: langCode,
        )] : diseases,
        overallAssessment: diseases.isEmpty 
            ? 'Your ${field.name} field is in good condition. Keep monitoring regularly.'
            : 'Some risks detected in your field. Monitor carefully and take preventive action.',
        fieldName: field.name,
        cropType: field.cropType,
        timestamp: DateTime.now(),
        languageCode: langCode,
      );
    }
  }

  // ============================================
  // AI Stress Prediction
  // ============================================

  /// Predict future crop stress using AI analysis of sensor trends
  Future<StressPrediction> predictStress({
    required SensorData sensorData,
    required Field field,
    required String languageCode,
    List<SensorData>? history,
  }) async {
    try {
      // Use local stress prediction so dashboard language always matches
      // selected app language and does not depend on external AI availability.
      return _getMockStressPrediction(sensorData, field, languageCode);
    } catch (e) {
      debugPrint('[AI] Stress prediction error: $e');
      return _getMockStressPrediction(sensorData, field, languageCode);
    }
  }

  String _buildStressPredictionPrompt({
    required SensorData sensorData,
    required String cropType,
    required String fieldName,
    required int ageInDays,
    required String languageCode,
    List<SensorData>? history,
  }) {
    String historyInfo = "No historical data available.";
    if (history != null && history.isNotEmpty) {
      historyInfo = "Recent readings (oldest first): " +
          history.take(10).map((d) => 
            "T:${d.temperature.toStringAsFixed(1)}°C, H:${d.humidity.toStringAsFixed(0)}%, M:${d.soilMoisture.toStringAsFixed(0)}%"
          ).join(" → ");
    }

    return '''
You are a crop stress prediction AI. Analyze the current and historical sensor data to predict future stress.

FIELD: $fieldName ($cropType, $ageInDays days old)
CURRENT: Temperature=${sensorData.temperature.toStringAsFixed(1)}°C, Humidity=${sensorData.humidity.toStringAsFixed(1)}%, SoilMoisture=${sensorData.soilMoisture.toStringAsFixed(1)}%
TREND: $historyInfo

Predict the most likely stress event in the next 24-48 hours.

RESPOND IN JSON ONLY:
{
  "overallRisk": "low|medium|high|critical",
  "predictedStressType": "The type of stress predicted, e.g. Drought Stress, Heat Stress, Waterlogging, Nutrient Deficiency",
  "confidence": 0.0 to 1.0,
  "timeToStress": "e.g. 6 hours, 12 hours, 2 days, not applicable",
  "recommendation": "One sentence actionable advice",
  "detailedAnalysis": "2-3 sentence detailed explanation of why this stress is predicted based on the data trends",
  "contributingFactors": [
    {
      "name": "Factor name",
      "description": "Why this factor contributes",
      "severity": 0.0 to 1.0,
      "currentValue": "The current reading",
      "optimalRange": "The optimal range for this crop"
    }
  ]
}
''';
  }

  StressPrediction _parseStressPredictionResponse(String text, String fieldName, String cropType) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!);

        final factorsList = (json['contributingFactors'] as List?)?.map((f) {
          return ContributingFactor(
            name: f['name'] ?? '',
            description: f['description'] ?? '',
            severity: (f['severity'] as num?)?.toDouble() ?? 0.5,
            currentValue: f['currentValue']?.toString() ?? '',
            optimalRange: f['optimalRange']?.toString() ?? '',
          );
        }).toList() ?? [];

        return StressPrediction(
          overallRisk: _parseStressRiskLevel(json['overallRisk']),
          predictedStressType: json['predictedStressType'] ?? 'Unknown',
          confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
          timeToStress: json['timeToStress'] ?? 'Unknown',
          recommendation: json['recommendation'] ?? '',
          detailedAnalysis: json['detailedAnalysis'] ?? '',
          contributingFactors: factorsList,
          timestamp: DateTime.now(),
          cropType: cropType,
          fieldName: fieldName,
        );
      }
    } catch (e) {
      debugPrint('[AI] Error parsing stress prediction: $e');
    }

    return _getMockStressPredictionFallback(fieldName, cropType);
  }

  StressRiskLevel _parseStressRiskLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'critical': return StressRiskLevel.critical;
      case 'high': return StressRiskLevel.high;
      case 'medium': return StressRiskLevel.medium;
      default: return StressRiskLevel.low;
    }
  }

  StressPrediction _getMockStressPrediction(
    SensorData data,
    Field field,
    String languageCode,
  ) {
    final isTamil = languageCode == 'ta';
    final isHindi = languageCode == 'hi';

    StressRiskLevel risk;
    String stressType;
    double confidence;
    String timeToStress;
    String recommendation;
    String analysis;
    List<ContributingFactor> factors = [];

    if (data.soilMoisture < 30) {
      risk = StressRiskLevel.high;
      stressType = isTamil
          ? 'வறட்சி அழுத்தம்'
          : (isHindi ? 'सूखा तनाव' : 'Drought Stress');
      confidence = 0.82;
      timeToStress = isTamil
          ? '6-12 மணி நேரம்'
          : (isHindi ? '6-12 घंटे' : '6-12 hours');
      recommendation = isTamil
          ? 'இலை வாடுதல் மற்றும் விளைச்சல் இழப்பைத் தவிர்க்க உடனே நீர்ப்பாசனம் செய்யுங்கள்.'
          : (isHindi
              ? 'मुरझाने और उपज हानि से बचने के लिए तुरंत सिंचाई करें।'
              : 'Irrigate immediately to prevent wilting and yield loss.');
      analysis = isTamil
          ? '${field.cropType} பயிருக்கு மண் ஈரப்பதம் ${data.soilMoisture.toStringAsFixed(1)}% ஆக மிகவும் குறைவாக உள்ளது. தற்போதைய ஆவியாதல் வேகத்தில் 6-12 மணி நேரத்துக்குள் ஈரப்பதம் உயிர்வாழ்வு வரம்பிற்கு கீழ் செல்லும்.'
          : (isHindi
              ? '${field.cropType} फसल के लिए मिट्टी की नमी ${data.soilMoisture.toStringAsFixed(1)}% पर अत्यधिक कम है। वर्तमान वाष्पीकरण दर के आधार पर 6-12 घंटों में नमी जीवित रहने की सीमा से नीचे जा सकती है।'
              : 'Soil moisture at ${data.soilMoisture.toStringAsFixed(1)}% is critically low for ${field.cropType}. Based on the current evaporation rate, moisture will drop below survival threshold within 6-12 hours.');
      factors = [
        ContributingFactor(
          name: isTamil
              ? 'மண் ஈரப்பதம்'
              : (isHindi ? 'मिट्टी की नमी' : 'Soil Moisture'),
          description: isTamil
              ? 'ஆரோக்கியமான வளர்ச்சிக்கான குறைந்தபட்ச வரம்புக்கு கீழ் உள்ளது'
              : (isHindi
                  ? 'स्वस्थ वृद्धि के न्यूनतम स्तर से नीचे'
                  : 'Below minimum threshold for healthy growth'),
          severity: 0.9,
          currentValue: '${data.soilMoisture.toStringAsFixed(1)}%',
          optimalRange: '45-70%',
        ),
        ContributingFactor(
          name: isTamil
              ? 'வெப்பநிலை'
              : (isHindi ? 'तापमान' : 'Temperature'),
          description: isTamil
              ? 'ஈரப்பத ஆவியாதலை வேகப்படுத்துகிறது'
              : (isHindi
                  ? 'नमी के वाष्पीकरण को तेज कर रहा है'
                  : 'Accelerating moisture evaporation'),
          severity: data.temperature > 30 ? 0.7 : 0.3,
          currentValue: '${data.temperature.toStringAsFixed(1)}°C',
          optimalRange: '22-30°C',
        ),
      ];
    } else if (data.temperature > 35) {
      risk = StressRiskLevel.high;
      stressType = isTamil
          ? 'வெப்ப அழுத்தம்'
          : (isHindi ? 'गर्मी तनाव' : 'Heat Stress');
      confidence = 0.78;
      timeToStress = isTamil
          ? '3-6 மணி நேரம்'
          : (isHindi ? '3-6 घंटे' : '3-6 hours');
      recommendation = isTamil
          ? 'மண்ணை குளிர்விக்க நிழல் ஏற்பாடு செய்யவும் அல்லது நீர்ப்பாசனத்தை அதிகரிக்கவும்.'
          : (isHindi
              ? 'मिट्टी को ठंडा करने के लिए छाया दें या सिंचाई बढ़ाएं।'
              : 'Provide shade or increase irrigation to cool the soil.');
      analysis = isTamil
          ? 'வெப்பநிலை ${data.temperature.toStringAsFixed(1)}°C ஆக இருந்து ${field.cropType} பயிரின் பாதுகாப்பான வரம்பை மீறுகிறது. நீண்ட நேரம் தொடர்ந்தால் ஒளிச்சேர்க்கை குறைவு மற்றும் செல்கள் சேதம் ஏற்படும்.'
          : (isHindi
              ? 'तापमान ${data.temperature.toStringAsFixed(1)}°C है, जो ${field.cropType} फसल की सुरक्षित सीमा से अधिक है। लंबे समय तक रहने पर प्रकाश संश्लेषण घटेगा और कोशिकीय क्षति हो सकती है।'
              : 'Temperature at ${data.temperature.toStringAsFixed(1)}°C exceeds the safe range for ${field.cropType}. Prolonged exposure will cause photosynthesis shutdown and cellular damage.');
      factors = [
        ContributingFactor(
          name: isTamil
              ? 'வெப்பநிலை'
              : (isHindi ? 'तापमान' : 'Temperature'),
          description: isTamil
              ? 'பயிரின் வெப்ப சகிப்புத்தன்மை வரம்பை மீறுகிறது'
              : (isHindi
                  ? 'फसल की गर्मी सहनशीलता सीमा से अधिक'
                  : 'Exceeds crop heat tolerance threshold'),
          severity: 0.85,
          currentValue: '${data.temperature.toStringAsFixed(1)}°C',
          optimalRange: '22-32°C',
        ),
        ContributingFactor(
          name: isTamil ? 'ஈரப்பதம்' : (isHindi ? 'नमी' : 'Humidity'),
          description: isTamil
              ? 'குறைந்த காற்று ஈரப்பதம் வெப்ப பாதிப்பை அதிகரிக்கிறது'
              : (isHindi
                  ? 'कम आर्द्रता गर्मी के प्रभाव को बढ़ाती है'
                  : 'Low humidity worsens heat impact'),
          severity: data.humidity < 40 ? 0.6 : 0.2,
          currentValue: '${data.humidity.toStringAsFixed(1)}%',
          optimalRange: '50-70%',
        ),
      ];
    } else if (data.soilMoisture > 85) {
      risk = StressRiskLevel.medium;
      stressType = isTamil
          ? 'நீர்தேக்கம் அபாயம்'
          : (isHindi ? 'जलभराव जोखिम' : 'Waterlogging Risk');
      confidence = 0.65;
      timeToStress = isTamil
          ? '24-48 மணி நேரம்'
          : (isHindi ? '24-48 घंटे' : '24-48 hours');
      recommendation = isTamil
          ? 'நீர் வடிகால் அமைப்பைச் சரிபார்த்து, நீர்ப்பாசன இடைவெளியை குறைக்கவும்.'
          : (isHindi
              ? 'निकासी व्यवस्था जांचें और सिंचाई की आवृत्ति घटाएं।'
              : 'Check drainage and reduce irrigation frequency.');
      analysis = isTamil
          ? 'மண் ஈரப்பதம் ${data.soilMoisture.toStringAsFixed(1)}% ஆக மிக அதிகமாக உள்ளது. நீர் வடிகால் போதாமை இருந்தால் 24-48 மணி நேரத்தில் வேர் ஆக்சிஜன் குறைபாடு தொடங்கலாம்.'
          : (isHindi
              ? 'मिट्टी की नमी ${data.soilMoisture.toStringAsFixed(1)}% पर बहुत अधिक है। निकासी पर्याप्त न होने पर 24-48 घंटों में जड़ों को ऑक्सीजन की कमी शुरू हो सकती है।'
              : 'Soil moisture at ${data.soilMoisture.toStringAsFixed(1)}% is excessively high. Root oxygen deprivation may begin within 24-48 hours if drainage is inadequate.');
      factors = [
        ContributingFactor(
          name: isTamil
              ? 'மண் ஈரப்பதம்'
              : (isHindi ? 'मिट्टी की नमी' : 'Soil Moisture'),
          description: isTamil
              ? 'அதிக ஈரப்பதம் வேர் காற்றோட்டத்தை குறைக்கிறது'
              : (isHindi
                  ? 'अत्यधिक नमी जड़ों के वायुसंचार को घटाती है'
                  : 'Excessive moisture reduces root aeration'),
          severity: 0.7,
          currentValue: '${data.soilMoisture.toStringAsFixed(1)}%',
          optimalRange: '45-70%',
        ),
      ];
    } else {
      risk = StressRiskLevel.low;
      stressType = isTamil
          ? 'அழுத்தம் எதிர்பார்க்கப்படவில்லை'
          : (isHindi ? 'तनाव की संभावना नहीं' : 'No Stress Expected');
      confidence = 0.90;
      timeToStress = isTamil
          ? 'பொருந்தாது'
          : (isHindi ? 'लागू नहीं' : 'Not applicable');
      recommendation = isTamil
          ? 'தற்போதைய பராமரிப்பு முறையைத் தொடருங்கள். அனைத்து அளவீடுகளும் சிறந்த வரம்பில் உள்ளன.'
          : (isHindi
              ? 'वर्तमान देखभाल जारी रखें। सभी मानक उचित सीमा में हैं।'
              : 'Continue current care routine. All parameters are within optimal range.');
      analysis = isTamil
          ? '${field.cropType} பயிருக்கான அனைத்து சூழல் அளவீடுகளும் நல்ல வரம்பில் உள்ளன. ${data.temperature.toStringAsFixed(1)}°C வெப்பநிலை மற்றும் ${data.soilMoisture.toStringAsFixed(1)}% மண் ஈரப்பதம் ஏற்றதாக உள்ளது.'
          : (isHindi
              ? '${field.cropType} फसल के लिए सभी पर्यावरणीय मानक स्वस्थ सीमा में हैं। ${data.temperature.toStringAsFixed(1)}°C तापमान और ${data.soilMoisture.toStringAsFixed(1)}% मिट्टी नमी उपयुक्त है।'
              : 'All environmental parameters are within healthy ranges for ${field.cropType}. Temperature at ${data.temperature.toStringAsFixed(1)}°C and soil moisture at ${data.soilMoisture.toStringAsFixed(1)}% are ideal.');
      factors = [
        ContributingFactor(
          name: isTamil
              ? 'வெப்பநிலை'
              : (isHindi ? 'तापमान' : 'Temperature'),
          description: isTamil
              ? 'சிறந்த வரம்பில் உள்ளது'
              : (isHindi ? 'उत्तम सीमा में' : 'Within optimal range'),
          severity: 0.1,
          currentValue: '${data.temperature.toStringAsFixed(1)}°C',
          optimalRange: '22-32°C',
        ),
        ContributingFactor(
          name: isTamil
              ? 'மண் ஈரப்பதம்'
              : (isHindi ? 'मिट्टी की नमी' : 'Soil Moisture'),
          description: isTamil
              ? 'போதுமான ஈரப்பதம்'
              : (isHindi ? 'पर्याप्त नमी' : 'Adequate hydration'),
          severity: 0.1,
          currentValue: '${data.soilMoisture.toStringAsFixed(1)}%',
          optimalRange: '45-70%',
        ),
        ContributingFactor(
          name: isTamil ? 'ஈரப்பதம்' : (isHindi ? 'नमी' : 'Humidity'),
          description: isTamil
              ? 'சாதாரண வளிமண்டல நிலை'
              : (isHindi ? 'सामान्य वायुमंडलीय स्थिति' : 'Normal atmospheric conditions'),
          severity: 0.1,
          currentValue: '${data.humidity.toStringAsFixed(1)}%',
          optimalRange: '50-70%',
        ),
      ];
    }

    return StressPrediction(
      overallRisk: risk,
      predictedStressType: stressType,
      confidence: confidence,
      timeToStress: timeToStress,
      recommendation: recommendation,
      detailedAnalysis: analysis,
      contributingFactors: factors,
      timestamp: DateTime.now(),
      cropType: field.cropType,
      fieldName: field.name,
    );
  }

  StressPrediction _getMockStressPredictionFallback(String fieldName, String cropType) {
    return StressPrediction(
      overallRisk: StressRiskLevel.low,
      predictedStressType: 'No Stress Expected',
      confidence: 0.75,
      timeToStress: 'Not applicable',
      recommendation: 'Continue monitoring. Conditions appear stable.',
      detailedAnalysis: 'Unable to fully analyze trends, but current snapshot suggests stable conditions.',
      contributingFactors: [],
      timestamp: DateTime.now(),
      cropType: cropType,
      fieldName: fieldName,
    );
  }
}

/// AI Insight model with comprehensive disease information
class AIInsight {
  final String summary;
  final List<String> analysisPoints;
  final String pestRiskLevel;
  final List<String> predictedDiseases;
  final String pestExplanation;
  final String irrigationAdvice;
  final String videoSearchQuery;
  final DateTime timestamp;
  final String languageCode;
  
  // Enhanced fields for rich disease information
  final String? riskIntroduction;
  final Map<String, dynamic>? predictedDiseaseDetails;
  final Map<String, dynamic>? descriptionDetails;
  final Map<String, String>? whyNowDetails;
  final String? seasonalInfo;
  final List<String>? preventionSteps;
  final List<String>? chemicalControl;
  final List<String>? maintenanceTips;
  YouTubeVideo? video;
  
  AIInsight({
    required this.summary,
    required this.analysisPoints,
    required this.pestRiskLevel,
    required this.predictedDiseases,
    required this.pestExplanation,
    required this.irrigationAdvice,
    required this.videoSearchQuery,
    required this.timestamp,
    required this.languageCode,
    this.riskIntroduction,
    this.predictedDiseaseDetails,
    this.descriptionDetails,
    this.whyNowDetails,
    this.seasonalInfo,
    this.preventionSteps,
    this.chemicalControl,
    this.maintenanceTips,
  });

  AIInsight copyWith({
    String? summary,
    List<String>? analysisPoints,
    String? pestRiskLevel,
    List<String>? predictedDiseases,
    String? pestExplanation,
    String? irrigationAdvice,
    String? videoSearchQuery,
    DateTime? timestamp,
    String? languageCode,
    String? riskIntroduction,
    Map<String, dynamic>? predictedDiseaseDetails,
    Map<String, dynamic>? descriptionDetails,
    Map<String, String>? whyNowDetails,
    String? seasonalInfo,
    List<String>? preventionSteps,
    List<String>? chemicalControl,
    List<String>? maintenanceTips,
    YouTubeVideo? video,
  }) {
    return AIInsight(
      summary: summary ?? this.summary,
      analysisPoints: analysisPoints ?? this.analysisPoints,
      pestRiskLevel: pestRiskLevel ?? this.pestRiskLevel,
      predictedDiseases: predictedDiseases ?? this.predictedDiseases,
      pestExplanation: pestExplanation ?? this.pestExplanation,
      irrigationAdvice: irrigationAdvice ?? this.irrigationAdvice,
      videoSearchQuery: videoSearchQuery ?? this.videoSearchQuery,
      timestamp: timestamp ?? this.timestamp,
      languageCode: languageCode ?? this.languageCode,
      riskIntroduction: riskIntroduction ?? this.riskIntroduction,
      predictedDiseaseDetails: predictedDiseaseDetails ?? this.predictedDiseaseDetails,
      descriptionDetails: descriptionDetails ?? this.descriptionDetails,
      whyNowDetails: whyNowDetails ?? this.whyNowDetails,
      seasonalInfo: seasonalInfo ?? this.seasonalInfo,
      preventionSteps: preventionSteps ?? this.preventionSteps,
      chemicalControl: chemicalControl ?? this.chemicalControl,
      maintenanceTips: maintenanceTips ?? this.maintenanceTips,
    )..video = video ?? this.video;
  }
  
  String get youtubeSearchUrl => youtubeSearchUrlForLanguage(languageCode);

  String youtubeSearchUrlForLanguage(String activeLanguageCode) {
    return YouTubeService().buildSearchUrl(
      query: videoSearchQuery,
      languageCode: activeLanguageCode,
    );
  }

  String? videoWatchUrlForLanguage(String activeLanguageCode) {
    if (video == null) {
      return null;
    }

    return YouTubeService().buildWatchUrl(
      videoId: video!.videoId,
      languageCode: activeLanguageCode,
    );
  }
  
  bool get hasHighPestRisk => pestRiskLevel == 'high';
  bool get hasMediumPestRisk => pestRiskLevel == 'medium';
  
  // Helper to get disease name
  String get diseaseName => predictedDiseaseDetails?['name'] ?? 
      (predictedDiseases.isNotEmpty ? predictedDiseases.first : 'Unknown');
  
  // Helper to get local disease name
  String get diseaseLocalName => predictedDiseaseDetails?['localName'] ?? diseaseName;
  
  // Check if has detailed information
  bool get hasDetailedInfo => riskIntroduction != null && 
      predictedDiseaseDetails != null &&
      preventionSteps != null;
}

class _LocalDiseaseCandidate {
  final double score;
  final DiseasePrediction prediction;

  const _LocalDiseaseCandidate({
    required this.score,
    required this.prediction,
  });

  DiseasePrediction toPrediction() => prediction;
}
