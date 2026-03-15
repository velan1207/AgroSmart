import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ThresholdSettingsScreen extends StatefulWidget {
  const ThresholdSettingsScreen({super.key});

  @override
  State<ThresholdSettingsScreen> createState() => _ThresholdSettingsScreenState();
}

class _ThresholdSettingsScreenState extends State<ThresholdSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _minMoistureController;
  late TextEditingController _maxMoistureController;
  late TextEditingController _minTempController;
  late TextEditingController _maxTempController;
  late TextEditingController _minHumidityController;
  late TextEditingController _maxHumidityController;
  
  bool _isSaving = false;
  late bool _autoIrrigation;

  @override
  void initState() {
    super.initState();
    final field = context.read<FieldProvider>().selectedField;
    final settings = field?.settings ?? FieldSettings();
    _autoIrrigation = settings.autoIrrigation;
    
    _minMoistureController = TextEditingController(text: settings.minMoisture.toString());
    _maxMoistureController = TextEditingController(text: settings.maxMoisture.toString());
    _minTempController = TextEditingController(text: settings.minTemperature.toString());
    _maxTempController = TextEditingController(text: settings.maxTemperature.toString());
    _minHumidityController = TextEditingController(text: settings.minHumidity.toString());
    _maxHumidityController = TextEditingController(text: settings.maxHumidity.toString());
  }

  void _resetToDefaults() {
    final field = context.read<FieldProvider>().selectedField;
    if (field == null) return;
    
    final defaults = FieldSettings.getDefaultSettings(field.cropType);
    
    setState(() {
      _minMoistureController.text = defaults.minMoisture.toString();
      _maxMoistureController.text = defaults.maxMoisture.toString();
      _minTempController.text = defaults.minTemperature.toString();
      _maxTempController.text = defaults.maxTemperature.toString();
      _minHumidityController.text = defaults.minHumidity.toString();
      _maxHumidityController.text = defaults.maxHumidity.toString();
    });

    final lang = context.read<SettingsProvider>().languageCode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang == 'ta' 
          ? '${field.cropType} க்கான இயல்புநிலை மதிப்புகள் மீட்டெடுக்கப்பட்டன' 
          : 'Restored defaults for ${field.cropType}'),
        backgroundColor: AppTheme.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _minMoistureController.dispose();
    _maxMoistureController.dispose();
    _minTempController.dispose();
    _maxTempController.dispose();
    _minHumidityController.dispose();
    _maxHumidityController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final fieldProvider = context.read<FieldProvider>();
    final field = fieldProvider.selectedField;
    final settingsProvider = context.read<SettingsProvider>();
    
    if (field == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No field selected')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final newSettings = FieldSettings(
      minMoisture: double.parse(_minMoistureController.text),
      maxMoisture: double.parse(_maxMoistureController.text),
      minTemperature: double.parse(_minTempController.text),
      maxTemperature: double.parse(_maxTempController.text),
      minHumidity: double.parse(_minHumidityController.text),
      maxHumidity: double.parse(_maxHumidityController.text),
      samplingIntervalMinutes: field.settings.samplingIntervalMinutes,
      autoIrrigation: _autoIrrigation,
    );

    final success = await fieldProvider.updateFieldSettings(field.id, newSettings);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settingsProvider.languageCode == 'ta' ? 'அளவீடுகள் புதுப்பிக்கப்பட்டன' : 'Thresholds updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update thresholds'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final lang = settingsProvider.languageCode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'ta' ? 'பயிர் அளவீடுகள்' : 'Crop Thresholds'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _resetToDefaults,
            child: Text(
              lang == 'ta' ? 'இயல்புநிலை' : 'DEFAULT',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Auto Irrigation Toggle ──
              _buildAutoIrrigationToggle(context, isDark, lang),
              const SizedBox(height: 28),

              Text(
                lang == 'ta' ? 'பாதுகாப்பு அளவீடுகள்' : 'Safety Thresholds',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lang == 'ta' 
                  ? 'விவசாயக் கருவி இந்த மதிப்புகளைப் பயன்படுத்தி எச்சரிக்கைகளை வழங்கும்.' 
                  : 'Microcontroller will use these values for alerts and irrigation logic.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle(
                lang == 'ta' ? 'மண் ஈரப்பதம் (%)' : 'Soil Moisture (%)', 
                Icons.water_drop, 
                AppTheme.soilMoistureColor
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(_minMoistureController, lang == 'ta' ? 'குறைந்தபட்சம் (%)' : 'Min (%)')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_maxMoistureController, lang == 'ta' ? 'அதிகபட்சம் (%)' : 'Max (%)')),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(
                lang == 'ta' ? 'வெப்பநிலை (°C)' : 'Temperature (°C)', 
                Icons.thermostat, 
                AppTheme.temperatureColor
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(_minTempController, lang == 'ta' ? 'குறைந்தபட்சம் (°C)' : 'Min (°C)')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_maxTempController, lang == 'ta' ? 'அதிகபட்சம் (°C)' : 'Max (°C)')),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(
                lang == 'ta' ? 'காற்று ஈரப்பதம் (%)' : 'Air Humidity (%)', 
                Icons.cloud_outlined, 
                AppTheme.humidityColor
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(_minHumidityController, lang == 'ta' ? 'குறைந்தபட்சம் (%)' : 'Min (%)')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_maxHumidityController, lang == 'ta' ? 'அதிகபட்சம் (%)' : 'Max (%)')),
                ],
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          lang == 'ta' ? 'அளவீடுகளைச் சேமி' : 'SAVE THRESHOLDS', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoIrrigationToggle(BuildContext context, bool isDark, String lang) {
    final activeColor = _autoIrrigation ? AppTheme.primaryGreen : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _autoIrrigation
            ? LinearGradient(
                colors: [AppTheme.primaryGreen.withOpacity(0.15), AppTheme.primaryGreen.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _autoIrrigation ? null : (isDark ? AppTheme.cardDark : AppTheme.cardLight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _autoIrrigation ? AppTheme.primaryGreen.withOpacity(0.4) : (isDark ? Colors.white12 : Colors.grey.shade200),
          width: _autoIrrigation ? 2 : 1,
        ),
        boxShadow: _autoIrrigation
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _autoIrrigation ? Icons.water_drop : Icons.water_drop_outlined,
                  color: _autoIrrigation ? AppTheme.primaryGreen : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang == 'ta'
                          ? 'தானியங்கி நீர்ப்பாசனம்'
                          : lang == 'hi'
                              ? 'ऑटो सिंचाई'
                              : 'Auto Irrigation',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _autoIrrigation
                          ? (lang == 'ta'
                              ? 'மண் வறண்டால் தானாக பம்ப் இயங்கும்'
                              : lang == 'hi'
                                  ? 'मिट्टी सूखने पर पंप अपने आप चलेगा'
                                  : 'Pump will activate automatically when soil is dry')
                          : (lang == 'ta'
                              ? 'பம்ப் கைமுறையாக கட்டுப்படுத்தப்படும்'
                              : lang == 'hi'
                                  ? 'पंप मैन्युअल रूप से नियंत्रित होगा'
                                  : 'Pump is controlled manually from dashboard'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _autoIrrigation
                            ? AppTheme.primaryGreen.withOpacity(0.8)
                            : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle Switch
              Transform.scale(
                scale: 1.1,
                child: Switch.adaptive(
                  value: _autoIrrigation,
                  activeColor: AppTheme.primaryGreen,
                  activeTrackColor: AppTheme.primaryGreen.withOpacity(0.4),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  onChanged: (val) {
                    setState(() => _autoIrrigation = val);
                  },
                ),
              ),
            ],
          ),
          // Info row when enabled
          if (_autoIrrigation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primaryGreen.withOpacity(0.7)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang == 'ta'
                          ? 'மண் ஈரப்பதம் குறைந்தபட்சத்தை விட குறைந்தால் பம்ப் இயங்கும், அதிகபட்சத்தை அடைந்ததும் நிற்கும்.'
                          : lang == 'hi'
                              ? 'जब नमी न्यूनतम से कम हो तो पंप चालू होगा, अधिकतम पहुँचने पर बंद होगा।'
                              : 'Pump turns ON when moisture drops below Min threshold, and OFF when it reaches Max threshold.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.black.withOpacity(0.02),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (double.tryParse(v) == null) return 'Invalid';
        return null;
      },
    );
  }
}
