import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../utils/localization.dart';

/// AI Insights Card Widget
class AIInsightsCard extends StatefulWidget {
  final AIInsight? insight;
  final bool isLoading;
  final bool isPlayingAudio;
  final VoidCallback onRequestInsight;
  final VoidCallback? onPlayAudio;
  final String languageCode;

  const AIInsightsCard({
    super.key,
    this.insight,
    this.isLoading = false,
    this.isPlayingAudio = false,
    required this.onRequestInsight,
    this.onPlayAudio,
    this.languageCode = 'en',
  });

  @override
  State<AIInsightsCard> createState() => _AIInsightsCardState();
}

class _AIInsightsCardState extends State<AIInsightsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.insight == null && !widget.isLoading) {
      return _buildRequestButton(context);
    }

    if (widget.isLoading) {
      return _buildLoadingState(context);
    }

    return _buildInsightCard(context, widget.insight!);
  }

  Widget _buildRequestButton(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.get('ai_insights', widget.languageCode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.languageCode == 'ta'
                          ? 'AI விவசாய நிபுணரிடம் ஆலோசனை பெறுங்கள்'
                          : widget.languageCode == 'hi'
                              ? 'AI कृषि विशेषज्ञ से सलाह लें'
                              : 'Get advice from AI Agri-Scientist',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onRequestInsight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                AppLocalizations.get('ai_insights', widget.languageCode),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.cardDark
            : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF667eea),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.get('analyzing', widget.languageCode),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: const Color(0xFF667eea).withOpacity(0.3));
  }

  Widget _buildInsightCard(BuildContext context, AIInsight insight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: isDark ? null : AppTheme.cardShadow,
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.1),
                  const Color(0xFF764ba2).withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF667eea),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.get('ai_insights', widget.languageCode),
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onPlayAudio != null)
                  IconButton(
                    onPressed: widget.onPlayAudio,
                    icon: Icon(
                      widget.isPlayingAudio ? Icons.volume_up : Icons.volume_off,
                      color: const Color(0xFF667eea),
                    ),
                    tooltip: widget.isPlayingAudio ? 'Stop' : 'Listen',
                  ),
                IconButton(
                  onPressed: widget.onRequestInsight,
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF667eea),
                  ),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          
          // Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.get('expert_summary', widget.languageCode),
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight.summary,
                  style: TextStyle(
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          // Expandable details
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.get('detailed_analysis', widget.languageCode),
                    style: TextStyle(
                      color: const Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF667eea),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (_isExpanded) ...[ 
            // Check if we have detailed info to show
            if (insight.hasDetailedInfo) ...[
              _buildDetailedDiseaseInfo(context, insight, isDark),
            ] else ...[
              // Fallback to simple analysis
              _buildSimpleAnalysis(context, insight, isDark),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
  
  Widget _buildDetailedDiseaseInfo(BuildContext context, AIInsight insight, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predicted Disease Header
          if (insight.predictedDiseaseDetails != null) ...[ 
            Row(
              children: [
                Text(
                  insight.predictedDiseaseDetails!['emoji'] ?? '🌾',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.languageCode != 'en' ? AppLocalizations.get('predicted_disease', widget.languageCode) : 'Predicted Disease'}',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight.diseaseLocalName,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (insight.predictedDiseaseDetails!['scientificName'] != null) ...[ 
                        Text(
                          '(${insight.predictedDiseaseDetails!['scientificName']})',
                          style: TextStyle(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Description
          if (insight.descriptionDetails != null) ...[
            _buildSection(
              title: widget.languageCode != 'en' ? AppLocalizations.get('description', widget.languageCode) : 'Description',
              icon: Icons.info_outline,
              color: const Color(0xFF667eea),
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.descriptionDetails!['brief'] ?? '',
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      height: 1.5,
                    ),
                  ),
                  if (insight.descriptionDetails!['forms'] != null) ...[ 
                    const SizedBox(height: 12),
                    ...(insight.descriptionDetails!['forms'] as List).map((form) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              form.toString(),
                              style: TextStyle(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Why Now
          if (insight.whyNowDetails != null) ...[
            _buildSection(
              title: widget.languageCode != 'en' ? AppLocalizations.get('why_now', widget.languageCode) : 'Why it affects your crop now?',
              icon: Icons.warning_amber_rounded,
              color: AppTheme.warning,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insight.whyNowDetails!.entries.map((entry) {
                  IconData icon = Icons.thermostat;
                  if (entry.key == 'humidity') icon = Icons.water_drop;
                  if (entry.key == 'soilMoisture') icon = Icons.grass;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 18, color: AppTheme.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Seasonal Info
          if (insight.seasonalInfo != null && insight.seasonalInfo!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight.seasonalInfo!,
                      style: TextStyle(
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Prevention Steps
          if (insight.preventionSteps != null && insight.preventionSteps!.isNotEmpty) ...[
            _buildSection(
              title: widget.languageCode != 'en' ? AppLocalizations.get('prevention', widget.languageCode) : '🛡️ How to Prevent',
              icon: Icons.shield_outlined,
              color: AppTheme.success,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insight.preventionSteps!.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Chemical Control
          if (insight.chemicalControl != null && insight.chemicalControl!.isNotEmpty) ...[
            _buildSection(
              title: widget.languageCode != 'en' ? AppLocalizations.get('chemical_control', widget.languageCode) : '🧪 Chemical Control',
              icon: Icons.science_outlined,
              color: Colors.purple,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: insight.chemicalControl!.map((chemical) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medication, size: 16, color: Colors.purple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            chemical,
                            style: TextStyle(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Maintenance Tips
          if (insight.maintenanceTips != null && insight.maintenanceTips!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: AppTheme.info, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.languageCode != 'en' ? AppLocalizations.get('tips', widget.languageCode) : '💡 Tips',
                        style: TextStyle(
                          color: AppTheme.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...insight.maintenanceTips!.map((tip) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Video link
          if (insight.videoSearchQuery.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _openVideoSearch(insight.youtubeSearchUrl),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.languageCode != 'en' 
                                ? AppLocalizations.get('watch_video', widget.languageCode)
                                : '📺 Watch Educational Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.languageCode != 'en'
                                ? AppLocalizations.get('management_video', widget.languageCode)
                                : 'Management tips & prevention guide',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
  
  Widget _buildSimpleAnalysis(BuildContext context, AIInsight insight, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis points
          ...insight.analysisPoints.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          
          // Pest risk
          if (insight.predictedDiseases.isNotEmpty) ...[
            _buildRiskBadge(insight),
            const SizedBox(height: 8),
            Text(
              insight.pestExplanation,
              style: TextStyle(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Irrigation advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: AppTheme.info, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.irrigationAdvice,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Video link
          if (insight.videoSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openVideoSearch(insight.youtubeSearchUrl),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.get('watch_video', widget.languageCode),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.red, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskBadge(AIInsight insight) {
    final color = insight.hasHighPestRisk
        ? AppTheme.error
        : insight.hasMediumPestRisk
            ? AppTheme.warning
            : AppTheme.success;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.get('pest_prediction', widget.languageCode),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ...insight.predictedDiseases.take(2).map((disease) => Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            disease,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _openVideoSearch(String url) async {
    final uri = Uri.parse(url);
    try {
      // Force external application to bypass internal webview issues
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AI] Could not launch video search: $e');
    }
  }
}

/// Connection Status Badge
class ConnectionBadge extends StatelessWidget {
  final bool isOnline;
  final String languageCode;

  const ConnectionBadge({
    super.key,
    required this.isOnline,
    this.languageCode = 'en',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isOnline ? AppTheme.success : AppTheme.error).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.success : AppTheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.get(isOnline ? 'online' : 'offline', languageCode),
            style: TextStyle(
              color: isOnline ? AppTheme.success : AppTheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
