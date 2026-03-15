/// Trilingual dictionary for AgroSmart
/// Supports English, Tamil (தமிழ்), and Hindi (हिन्दी)

class AppLocalizations {
  static const Map<String, Map<String, String>> _translations = {
    // App General
    'app_name': {
      'en': 'AgroSmart',
      'ta': 'அக்ரோஸ்மார்ட்',
      'hi': 'एग्रोस्मार्ट',
    },
    'dashboard': {
      'en': 'Dashboard',
      'ta': 'டாஷ்போர்டு',
      'hi': 'डैशबोर्ड',
    },
    'fields': {
      'en': 'My Fields',
      'ta': 'என் வயல்கள்',
      'hi': 'मेरे खेत',
    },
    'alerts': {
      'en': 'Alerts',
      'ta': 'விழிப்பூட்டல்கள்',
      'hi': 'अलर्ट',
    },
    'settings': {
      'en': 'Settings',
      'ta': 'அமைப்புகள்',
      'hi': 'सेटिंग्स',
    },
    
    // Sensor Labels
    'temperature': {
      'en': 'Temperature',
      'ta': 'வெப்பநிலை',
      'hi': 'तापमान',
    },
    'humidity': {
      'en': 'Humidity',
      'ta': 'ஈரப்பதம்',
      'hi': 'नमी',
    },
    'soil_moisture': {
      'en': 'Soil Moisture',
      'ta': 'மண் ஈரப்பதம்',
      'hi': 'मिट्टी की नमी',
    },
    
    // Status Labels
    'healthy': {
      'en': 'Healthy',
      'ta': 'ஆரோக்கியமான',
      'hi': 'स्वस्थ',
    },
    'warning': {
      'en': 'Warning',
      'ta': 'எச்சரிக்கை',
      'hi': 'चेतावनी',
    },
    'critical': {
      'en': 'Critical',
      'ta': 'அவசரம்',
      'hi': 'गंभीर',
    },
    'optimal': {
      'en': 'Optimal',
      'ta': 'சிறப்பான',
      'hi': 'उत्तम',
    },
    
    // Crop Types
    'paddy': {
      'en': 'Paddy',
      'ta': 'நெல்',
      'hi': 'धान',
    },
    'wheat': {
      'en': 'Wheat',
      'ta': 'கோதுமை',
      'hi': 'गेहूं',
    },
    'groundnut': {
      'en': 'Groundnut',
      'ta': 'நிலக்கடலை',
      'hi': 'मूंगफली',
    },
    'cotton': {
      'en': 'Cotton',
      'ta': 'பருத்தி',
      'hi': 'कपास',
    },
    'sugarcane': {
      'en': 'Sugarcane',
      'ta': 'கரும்பு',
      'hi': 'गन्ना',
    },
    'maize': {
      'en': 'Maize',
      'ta': 'மக்காச்சோளம்',
      'hi': 'मक्का',
    },
    'tomato': {
      'en': 'Tomato',
      'ta': 'தக்காளி',
      'hi': 'टमाटर',
    },
    'potato': {
      'en': 'Potato',
      'ta': 'உருளைக்கிழங்கு',
      'hi': 'आलू',
    },
    'onion': {
      'en': 'Onion',
      'ta': 'வெங்காயம்',
      'hi': 'प्याज',
    },
    'chili': {
      'en': 'Chili',
      'ta': 'மிளகாய்',
      'hi': 'मिर्च',
    },
    
    // Actions
    'ai_insights': {
      'en': 'AI Insights',
      'ta': 'AI பகுப்பாய்வு',
      'hi': 'AI विश्लेषण',
    },
    'start_motor': {
      'en': 'Start Motor',
      'ta': 'மோட்டார் தொடங்கு',
      'hi': 'मोटर चालू करें',
    },
    'stop_motor': {
      'en': 'Stop Motor',
      'ta': 'மோட்டார் நிறுத்து',
      'hi': 'मोटर बंद करें',
    },
    'irrigation_on': {
      'en': 'Irrigation ON',
      'ta': 'நீர்ப்பாசனம் இயக்கம்',
      'hi': 'सिंचाई चालू',
    },
    'irrigation_off': {
      'en': 'Irrigation OFF',
      'ta': 'நீர்ப்பாசனம் நிறுத்தம்',
      'hi': 'सिंचाई बंद',
    },
    
    // Alerts
    'irrigation_needed': {
      'en': 'Irrigation needed now!',
      'ta': 'உடனடி நீர்ப்பாசனம் தேவை!',
      'hi': 'अभी सिंचाई की जरूरत है!',
    },
    'high_temp_alert': {
      'en': 'High temperature warning',
      'ta': 'அதிக வெப்பநிலை எச்சரிக்கை',
      'hi': 'उच्च तापमान चेतावनी',
    },
    'low_moisture_alert': {
      'en': 'Low moisture - Water required',
      'ta': 'குறைந்த ஈரப்பதம் - நீர் தேவை',
      'hi': 'कम नमी - पानी चाहिए',
    },
    
    // AI Analysis
    'analyzing': {
      'en': 'Analyzing...',
      'ta': 'பகுப்பாய்வு செய்கிறது...',
      'hi': 'विश्लेषण हो रहा है...',
    },
    'preparing_voice': {
      'en': 'Preparing voice...',
      'ta': 'குரல் தயாராகிறது...',
      'hi': 'आवाज तैयार हो रही है...',
    },
    'expert_summary': {
      'en': 'Expert Summary',
      'ta': 'நிபுணர் சுருக்கம்',
      'hi': 'विशेषज्ञ सारांश',
    },
    'detailed_analysis': {
      'en': 'Detailed Analysis',
      'ta': 'விரிவான பகுப்பாய்வு',
      'hi': 'विस्तृत विश्लेषण',
    },
    'pest_prediction': {
      'en': 'Pest & Disease Prediction',
      'ta': 'பூச்சி & நோய் கணிப்பு',
      'hi': 'कीट और रोग पूर्वानुमान',
    },
    'watch_video': {
      'en': 'Watch Prevention Video',
      'ta': 'தடுப்பு வீடியோ பாருங்கள்',
      'hi': 'रोकथाम वीडियो देखें',
    },
    
    // Connection Status
    'online': {
      'en': 'Online',
      'ta': 'இணைப்பில்',
      'hi': 'ऑनलाइन',
    },
    'offline': {
      'en': 'Offline',
      'ta': 'இணைப்பில்லை',
      'hi': 'ऑफलाइन',
    },
    
    // Time
    'last_updated': {
      'en': 'Last Updated',
      'ta': 'கடைசி புதுப்பிப்பு',
      'hi': 'अंतिम अपडेट',
    },
    'weekly_trend': {
      'en': 'Weekly Trend',
      'ta': 'வாராந்திர போக்கு',
      'hi': 'साप्ताहिक रुझान',
    },
    
    // Settings
    'language': {
      'en': 'Language',
      'ta': 'மொழி',
      'hi': 'भाषा',
    },
    'dark_mode': {
      'en': 'Dark Mode',
      'ta': 'இருட்டு பயன்முறை',
      'hi': 'डार्क मोड',
    },
    'notifications': {
      'en': 'Notifications',
      'ta': 'அறிவிப்புகள்',
      'hi': 'सूचनाएं',
    },
    
    // Common
    'loading': {
      'en': 'Loading...',
      'ta': 'ஏற்றுகிறது...',
      'hi': 'लोड हो रहा है...',
    },
    'error': {
      'en': 'Error',
      'ta': 'பிழை',
      'hi': 'त्रुटि',
    },
    'retry': {
      'en': 'Retry',
      'ta': 'மீண்டும் முயற்சி',
      'hi': 'पुनः प्रयास करें',
    },
    'cancel': {
      'en': 'Cancel',
      'ta': 'ரத்து',
      'hi': 'रद्द करें',
    },
    'save': {
      'en': 'Save',
      'ta': 'சேமி',
      'hi': 'सहेजें',
    },
    'add': {
      'en': 'Add',
      'ta': 'சேர்',
      'hi': 'जोड़ें',
    },
    'delete': {
      'en': 'Delete',
      'ta': 'நீக்கு',
      'hi': 'हटाएं',
    },
    'edit': {
      'en': 'Edit',
      'ta': 'திருத்து',
      'hi': 'संपादित करें',
    },
    'back': {
      'en': 'Back',
      'ta': 'பின்செல்',
      'hi': 'वापस',
    },
    'crop': {
      'en': 'Crop',
      'ta': 'பயிர்',
      'hi': 'फसल',
    },
    'fields_registered': {
      'en': 'fields registered',
      'ta': 'வயல்கள் பதிவு செய்யப்பட்டுள்ளன',
      'hi': 'खेत पंजीकृत हैं',
    },
    // Field Management
    'add_field': {
      'en': 'Add Field',
      'ta': 'வயல் சேர்க்க',
      'hi': 'खेत जोड़ें',
    },
    'edit_field': {
      'en': 'Edit Field',
      'ta': 'வயல் திருத்தம்',
      'hi': 'खेत संपादित करें',
    },
    'no_fields': {
      'en': 'No fields added yet',
      'ta': 'வயல்கள் எதுவும் இல்லை',
      'hi': 'अभी तक कोई खेत नहीं',
    },
    
    // Time Ranges for Graph
    '24 Hours': {
      'en': '24 Hours',
      'ta': '24 மணிநேரம்',
      'hi': '24 घंटे',
    },
    '7 Days': {
      'en': '7 Days',
      'ta': '7 நாட்கள்',
      'hi': '7 दिन',
    },
    '30 Days': {
      'en': '30 Days',
      'ta': '30 நாட்கள்',
      'hi': '30 दिन',
    },
    'historical_data': {
      'en': 'Historical Data',
      'ta': 'வரலாற்று தரவு',
      'hi': 'ऐतिहासिक डेटा',
    },
    'daily_averages': {
      'en': 'Daily Averages',
      'ta': 'தினசரி சராசரி',
      'hi': 'दैनिक औसत',
    },
    'points': {
      'en': 'points',
      'ta': 'புள்ளிகள்',
      'hi': 'अंक',
    },
    'days': {
      'en': 'days',
      'ta': 'நாட்கள்',
      'hi': 'दिन',
    },
    'statistics': {
      'en': 'Statistics',
      'ta': 'புள்ளிவிவரங்கள்',
      'hi': 'आंकड़े',
    },

    // Stress Prediction
    'stress_prediction': {
      'en': 'Stress Prediction',
      'ta': 'அழுத்தம் கணிப்பு',
      'hi': 'तनाव पूर्वानुमान',
    },
    'ai_stress_prediction': {
      'en': 'AI Stress Prediction',
      'ta': 'AI அழுத்தம் கணிப்பு',
      'hi': 'AI तनाव पूर्वानुमान',
    },
    'analyzing_stress_levels': {
      'en': 'Analyzing stress levels...',
      'ta': 'அழுத்த நிலைகள் பகுப்பாய்வு செய்யப்படுகிறது...',
      'hi': 'तनाव स्तरों का विश्लेषण हो रहा है...',
    },
    'tap_run_stress_prediction': {
      'en': 'Tap to run AI stress prediction',
      'ta': 'AI அழுத்தம் கணிப்பை இயக்க தட்டவும்',
      'hi': 'AI तनाव पूर्वानुमान चलाने के लिए टैप करें',
    },
    'tap_for_details': {
      'en': 'Tap for details',
      'ta': 'விவரங்களுக்கு தட்டவும்',
      'hi': 'विवरण के लिए टैप करें',
    },
    'recommendation': {
      'en': 'Recommendation',
      'ta': 'பரிந்துரை',
      'hi': 'सिफारिश',
    },
    'contributing_factors': {
      'en': 'Contributing Factors',
      'ta': 'பங்களிக்கும் காரணிகள்',
      'hi': 'योगदान करने वाले कारक',
    },
    'confidence': {
      'en': 'Confidence',
      'ta': 'நம்பகத்தன்மை',
      'hi': 'विश्वसनीयता',
    },
    'time_to_stress': {
      'en': 'Time to Stress',
      'ta': 'அழுத்தம் வரும்வரை நேரம்',
      'hi': 'तनाव आने का समय',
    },
    'speak_prediction': {
      'en': 'Speak prediction',
      'ta': 'கணிப்பை குரலில் வாசிக்க',
      'hi': 'पूर्वानुमान बोलें',
    },
    'low_risk': {
      'en': 'Low Risk',
      'ta': 'குறைந்த ஆபத்து',
      'hi': 'कम जोखिम',
    },
    'medium_risk': {
      'en': 'Medium Risk',
      'ta': 'மிதமான ஆபத்து',
      'hi': 'मध्यम जोखिम',
    },
    'high_risk': {
      'en': 'High Risk',
      'ta': 'அதிக ஆபத்து',
      'hi': 'उच्च जोखिम',
    },
    'critical_risk': {
      'en': 'Critical Risk',
      'ta': 'அவசர ஆபத்து',
      'hi': 'गंभीर जोखिम',
    },
    'current': {
      'en': 'Current',
      'ta': 'தற்போதைய',
      'hi': 'वर्तमान',
    },
    'min': {
      'en': 'Min',
      'ta': 'குறைந்த',
      'hi': 'न्यूनतम',
    },
    'max': {
      'en': 'Max',
      'ta': 'அதிக',
      'hi': 'अधिकतम',
    },
    'average': {
      'en': 'Average',
      'ta': 'சராசரி',
      'hi': 'औसत',
    },
    'confirm_delete': {
      'en': 'Delete Field?',
      'ta': 'வயலை நீக்கவா?',
      'hi': 'खेत हटाएं?',
    },
    'delete_message': {
      'en': 'Are you sure you want to delete this field?',
      'ta': 'இந்த வயலை நிச்சயமாக நீக்க விரும்புகிறீர்களா?',
      'hi': 'क्या आप वाकई इस खेत को हटाना चाहते हैं?',
    },
    'field_name': {
      'en': 'Field Name',
      'ta': 'வயல் பெயர்',
      'hi': 'खेत का नाम',
    },
    'crop_type': {
      'en': 'Crop Type',
      'ta': 'பயிர் வகை',
      'hi': 'फसल का प्रकार',
    },
    'location': {
      'en': 'Location',
      'ta': 'இடம்',
      'hi': 'स्थान',
    },
    'field_settings': {
      'en': 'Field Settings',
      'ta': 'வயல் அமைப்புகள்',
      'hi': 'खेत की सेटिंग्स',
    },
    'min_moisture': {
      'en': 'Minimum Soil Moisture',
      'ta': 'குறைந்தபட்ச மண் ஈரப்பதம்',
      'hi': 'न्यूनतम मिट्टी की नमी',
    },
    'max_moisture': {
      'en': 'Maximum Soil Moisture',
      'ta': 'அதிகபட்ச மண் ஈரப்பதம்',
      'hi': 'अधिकतम मिट्टी की नमी',
    },
    'max_temp': {
      'en': 'Maximum Temperature',
      'ta': 'அதிகபட்ச வெப்பநிலை',
      'hi': 'अधिकतम तापमान',
    },
    'add_new_field': {
      'en': 'Add New Field',
      'ta': 'புதிய வயல் சேர்க்க',
      'hi': 'नया खेत जोड़ें',
    },
    'save_changes': {
      'en': 'Save Changes',
      'ta': 'மாற்றங்களை சேமி',
      'hi': 'परिवर्तन सहेजें',
    },
    'save_settings': {
      'en': 'Save Settings',
      'ta': 'அமைப்புகளை சேமி',
      'hi': 'सेटिंग्स सहेजें',
    },
    'no_fields_yet': {
      'en': 'No Fields Yet',
      'ta': 'வயல்கள் எதுவும் இல்லை',
      'hi': 'अभी तक कोई खेत नहीं',
    },
    'add_first_field_msg': {
      'en': 'Add your first field to start monitoring',
      'ta': 'கண்காணிக்க உங்கள் முதல் வயலைச் சேர்க்கவும்',
      'hi': 'निगरानी शुरू करने के लिए अपना पहला खेत जोड़ें',
    },
    'add_first_field_btn': {
      'en': 'Add Your First Field',
      'ta': 'உங்கள் முதல் வயலைச் சேர்க்கவும்',
      'hi': 'अपना पहला खेत जोड़ें',
    },
    'field_name_hint': {
      'en': 'e.g., North Paddy Field',
      'ta': 'உ.தா., வடக்கு நெல் வயல்',
      'hi': 'उदा., उत्तर धान का खेत',
    },
    'location_hint': {
      'en': 'e.g., Block A, Village Farm',
      'ta': 'உ.தா., பிளாக் ஏ, கிராமப் பண்ணை',
      'hi': 'उदा., ब्लॉक ए, ग्राम फार्म',
    },
    'error_field_name': {
      'en': 'Please enter a field name',
      'ta': 'தயவுசெய்து வயலின் பெயரை உள்ளிடவும்',
      'hi': 'कृपया खेत का नाम दर्ज करें',
    },
    'success_field_added': {
      'en': 'Field added successfully!',
      'ta': 'வயல் வெற்றிகரமாக சேர்க்கப்பட்டது!',
      'hi': 'खेत सफलतापूर्वक जोड़ा गया!',
    },
    'error_field_add_failed': {
      'en': 'Failed to add field',
      'ta': 'வயலைச் சேர்க்க முடியவில்லை',
      'hi': 'खेत जोड़ने में विफल',
    },
    // Alerts Screen
    'alert_center': {
      'en': 'Alert Center',
      'ta': 'எச்சரிக்கை மையம்',
      'hi': 'चेतावनी केंद्र',
    },
    'critical_alerts': {
      'en': 'Critical Alerts!',
      'ta': 'அவசர எச்சரிக்கைகள்!',
      'hi': 'गंभीर चेतावनी!',
    },
    'unread_alerts': {
      'en': 'unread alerts',
      'ta': 'படிக்காத எச்சரிக்கைகள்',
      'hi': 'अपठित चेतावनी',
    },
    'mark_all_read': {
      'en': 'Mark all read',
      'ta': 'அனைத்தையும் படித்ததாக குறி',
      'hi': 'सभी को पढ़ा हुआ चिह्नित करें',
    },
    'all_clear': {
      'en': 'All Clear!',
      'ta': 'எல்லாம் தெளிவு!',
      'hi': 'सब ठीक है!',
    },
    'no_alerts_moment': {
      'en': 'No alerts at the moment.',
      'ta': 'தற்போது எச்சரிக்கைகள் ஏதுமில்லை.',
      'hi': 'फिलहाल कोई चेतावनी नहीं।',
    },
    'mark_resolved': {
      'en': 'Mark Resolved',
      'ta': 'தீர்க்கப்பட்டது',
      'hi': 'हल किया गया',
    },
    'view_field': {
      'en': 'View Field',
      'ta': 'வயலைப் பார்',
      'hi': 'खेत देखें',
    },
    'threshold': {
      'en': 'Threshold',
      'ta': 'வரம்பு',
      'hi': 'सीमा',
    },
    'all': {
      'en': 'All',
      'ta': 'அனைத்தும்',
      'hi': 'सभी',
    },
    'unread': {
      'en': 'Unread',
      'ta': 'படிக்காதவை',
      'hi': 'अपठित',
    },
    // Settings Screen
    'appearance': {
      'en': 'Appearance',
      'ta': 'தோற்றம்',
      'hi': 'दिखावट',
    },
    // dark_mode defined above
    // notifications defined above
    'push_notifications': {
      'en': 'Push Notifications',
      'ta': 'புஷ் அறிவிப்புகள்',
      'hi': 'पुश सूचनाएं',
    },
    'hardware_status': {
      'en': 'Hardware Status',
      'ta': 'வன்பொருள் நிலை',
      'hi': 'हार्डवेयर स्थिति',
    },
    'units_preferences': {
      'en': 'Units & Preferences',
      'ta': 'அலகுகள் மற்றும் விருப்பங்கள்',
      'hi': 'इकाइयाँ और प्राथमिकताएँ',
    },
    'temperature_unit': {
      'en': 'Temperature Unit',
      'ta': 'வெப்பநிலை அலகு',
      'hi': 'तापमान इकाई',
    },
    'refresh_interval': {
      'en': 'Data Refresh Interval',
      'ta': 'தரவு புதுப்பிப்பு இடைவெளி',
      'hi': 'डेटा ताज़ा अंतराल',
    },
    'about': {
      'en': 'About',
      'ta': 'பற்றி',
      'hi': 'के बारे में',
    },
    'reset_settings': {
      'en': 'Reset Settings',
      'ta': 'அமைப்புகளை மீட்டமை',
      'hi': 'सेटिंग्स रीसेट करें',
    },
    'restore_defaults': {
      'en': 'Restore default settings',
      'ta': 'இயல்புநிலை அமைப்புகளை மீட்டமை',
      'hi': 'डिफ़ॉल्ट सेटिंग्स बहाल करें',
    },
    // Offline Banner
    'offline_mode': {
      'en': 'Offline Mode',
      'ta': 'ஆஃப்லைன் பயன்முறை',
      'hi': 'ऑफ़लाइन स्थिति',
    },
    'offline_desc': {
      'en': 'Offline: Showing last known data. Check connection.',
      'ta': 'இணைப்பு இல்லை: கடைசி தரவு காட்டப்படுகிறது.',
      'hi': 'ऑफ़लाइन: पिछला डेटा दिखाया जा रहा है।',
    },
    
    // Disease Prediction
    'disease_prediction': {
      'en': 'Disease Prediction',
      'ta': 'நோய் கணிப்பு',
      'hi': 'रोग अनुमान',
    },
    'predict_diseases': {
      'en': 'Predict Diseases',
      'ta': 'நோய்களை கணிக்க',
      'hi': 'रोगों का अनुमान लगाएं',
    },
    'analyzing_field': {
      'en': 'Analyzing Your Field...',
      'ta': 'உங்கள் வயலை பகுப்பாய்வு செய்கிறது...',
      'hi': 'आपके खेत का विश्लेषण हो रहा है...',
    },
    'ai_analyzing': {
      'en': 'AI is analyzing environmental conditions',
      'ta': 'AI சுற்றுச்சூழல் நிலைமைகளை பகுப்பாய்வு செய்கிறது',
      'hi': 'AI पर्यावरणीय स्थितियों का विश्लेषण कर रहा है',
    },
    'predicted_diseases': {
      'en': 'Predicted Diseases',
      'ta': 'கணிக்கப்பட்ட நோய்கள்',
      'hi': 'अनुमानित रोग',
    },
    'no_predictions': {
      'en': 'No predictions available',
      'ta': 'கணிப்புகள் இல்லை',
      'hi': 'कोई पूर्वानुमान उपलब्ध नहीं',
    },
    'reason': {
      'en': 'Reason',
      'ta': 'காரணம்',
      'hi': 'कारण',
    },
    'symptoms': {
      'en': 'Symptoms',
      'ta': 'அறிகுறிகள்',
      'hi': 'लक्षण',
    },
    'causes': {
      'en': 'Causes',
      'ta': 'காரணங்கள்',
      'hi': 'कारण',
    },
    'prevention': {
      'en': 'Prevention',
      'ta': 'தடுப்பு',
      'hi': 'बचाव',
    },
    'treatment': {
      'en': 'Treatment',
      'ta': 'சிகிச்சை',
      'hi': 'उपचार',
    },
    'watch_disease_video': {
      'en': 'Watch Video on YouTube',
      'ta': 'YouTube-ல் வீடியோ பார்க்க',
      'hi': 'YouTube पर वीडियो देखें',
    },
    'error_occurred': {
      'en': 'Error Occurred',
      'ta': 'பிழை ஏற்பட்டது',
      'hi': 'त्रुटि हुई',
    },
    'try_again': {
      'en': 'Try Again',
      'ta': 'மீண்டும் முயற்சிக்கவும்',
      'hi': 'पुन: प्रयास करें',
    },
    
    // Connection Status
    'poor_connection': {
      'en': 'Poor Connection',
      'ta': 'மோசமான இணைப்பு',
      'hi': 'खराब कनेक्शन',
    },
    'poor_connection_msg': {
      'en': 'Some features may be limited',
      'ta': 'சில அம்சங்கள் வரையறுக்கப்படலாம்',
      'hi': 'कुछ सुविधाएँ सीमित हो सकती हैं',
    },
    'no_connection': {
      'en': 'No Internet Connection',
      'ta': 'இணைய இணைப்பு இல்லை',
      'hi': 'इंटरनेट कनेक्शन नहीं',
    },
    'no_connection_msg': {
      'en': 'Please check your internet connection and try again',
      'ta': 'உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்',
      'hi': 'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें',
    },
    'connection_tip_1': {
      'en': 'Check your mobile data or WiFi signal',
      'ta': 'உங்கள் மொபைல் டேட்டா அல்லது WiFi சிக்னலை சரிபார்க்கவும்',
      'hi': 'अपना मोबाइल डेटा या WiFi सिग्नल जांचें',
    },
    'connection_tip_2': {
      'en': 'Try moving to an area with better coverage',
      'ta': 'சிறந்த கவரேஜ் உள்ள பகுதிக்கு செல்ல முயற்சிக்கவும்',
      'hi': 'बेहतर कवरेज वाले क्षेत्र में जाने का प्रयास करें',
    },
    'connection_tip_3': {
      'en': 'Make sure airplane mode is turned off',
      'ta': 'விமான பயன்முறை ஆஃப் செய்யப்பட்டுள்ளதை உறுதிப்படுத்தவும்',
      'hi': 'सुनिश्चित करें कि हवाई जहाज मोड बंद है',
    },
    'predicted_disease': {
      'en': 'Predicted Disease',
      'ta': 'கணிக்கப்பட்ட நோய்',
      'hi': 'अनुमानित रोग',
    },
    'expert_video': {
      'en': 'Expert Video Advice',
      'ta': 'நிபுணர் வீடியோ ஆலோசனை',
      'hi': 'विशेषज्ञ वीडियो सलाह',
    },
    'why_now': {
      'en': 'Why it affects your crop now?',
      'ta': 'இது ஏன் இப்போது உங்கள் பயிரைப் பாதிக்கிறது?',
      'hi': 'यह अब आपकी फसल को क्यों प्रभावित करता है?',
    },
    'description': {
      'en': 'Description',
      'ta': 'விளக்கம்',
      'hi': 'विवरण',
    },
    'prevention_title': {
      'en': 'How to Prevent',
      'ta': 'எவ்வாறு தடுப்பது',
      'hi': 'कैसे रोकें',
    },
    'chemical_control': {
      'en': 'Chemical Control',
      'ta': 'பரிந்துரைக்கப்படும் மருந்துகள்',
      'hi': 'रासायनिक नियंत्रण',
    },
    'tips': {
      'en': 'Expert Tips',
      'ta': 'நிபுணர் குறிப்புகள்',
      'hi': 'विशेषज्ञ सुझाव',
    },
    'management_video': {
      'en': 'Management tips & prevention guide',
      'ta': 'மேலாண்மை குறிப்புகள் மற்றும் தடுப்பு வழிகாட்டி',
      'hi': 'प्रबंधन सुझाव और रोकथाम गाइड',
    },

    // Graph Charts
    'real_time_trend': {
      'en': 'Real-Time Trend',
      'ta': 'நிகழ்நேர போக்கு',
      'hi': 'रियल-टाइम ट्रेंड',
    },
    'hourly_distribution': {
      'en': 'Hourly Distribution',
      'ta': 'மணிநேர விநியோகம்',
      'hi': 'प्रति घंटा वितरण',
    },
    'daily_range': {
      'en': 'Daily Range',
      'ta': 'தினசரி வரம்பு',
      'hi': 'दैनिक सीमा',
    },
    'monthly_trend': {
      'en': 'Monthly Trend',
      'ta': 'மாதாந்திர போக்கு',
      'hi': 'मासिक रुझान',
    },
    'monthly_range': {
      'en': 'Monthly Range',
      'ta': 'மாதாந்திர வரம்பு',
      'hi': 'मासिक सीमा',
    },
    'live_gauge': {
      'en': 'Live Gauge',
      'ta': 'நிகழ்நேர அளவி',
      'hi': 'लाइव गेज',
    },
    'range': {
      'en': 'Range',
      'ta': 'வீச்சு',
      'hi': 'सीमा',
    },
    'soilmoisture': {
      'en': 'Soil Moisture',
      'ta': 'மண் ஈரப்பதம்',
      'hi': 'मिट्टी की नमी',
    },
  };

  static String get(String key, String languageCode) {
    final translation = _translations[key];
    if (translation == null) return key;
    return translation[languageCode] ?? translation['en'] ?? key;
  }

  static String getCropName(String cropType, String languageCode) {
    final key = cropType.toLowerCase();
    return get(key, languageCode);
  }
  
  static Map<String, String> getAllForLanguage(String languageCode) {
    final result = <String, String>{};
    for (var entry in _translations.entries) {
      result[entry.key] = entry.value[languageCode] ?? entry.value['en'] ?? entry.key;
    }
    return result;
  }
}

/// Language codes supported
class SupportedLanguages {
  static const String english = 'en';
  static const String tamil = 'ta';
  static const String hindi = 'hi';
  
  static const List<Map<String, String>> all = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
  ];
}
