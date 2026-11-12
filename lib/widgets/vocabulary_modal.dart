import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';

class VocabularyModal extends StatelessWidget {
  const VocabularyModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        final discovered = user.userData.discoveredVocabulary;
        final count = discovered.length;

        // Milestones: 10, 25, 50, 100
        int nextMilestone = 10;
        if (count >= 10) nextMilestone = 25;
        if (count >= 25) nextMilestone = 50;
        if (count >= 50) nextMilestone = 100;
        if (count >= 100) nextMilestone = (count / 50).floor() * 50 + 50;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 380),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5).withValues(alpha: 0.82), // Soft bright translucent green glass
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD9A62E).withValues(alpha: 0.70), // Softer gold border
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VOCABULARY',
                          style: AppTheme.worldTitle.copyWith(
                            fontSize: 18,
                            letterSpacing: 2,
                            color: const Color(0xFF14532D), // Deep dark green title
                            shadows: const [
                              Shadow(color: Colors.white54, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF14532D).withValues(alpha: 0.12),
                              border: Border.all(
                                color: const Color(0xFF14532D).withValues(alpha: 0.25),
                                width: 1.0,
                              ),
                            ),
                            child: const Icon(Icons.close_rounded, color: Color(0xFF14532D), size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Milestone Progress Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5).withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.40)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'DISCOVERED: $count WORDS',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body.copyWith(
                                    color: const Color(0xFF065F46), // Dark green with strong readability
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'NEXT MILESTONE: $nextMilestone',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.smallSecondary.copyWith(
                                    color: const Color(0xFF15803D), // Darker muted green
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (count / nextMilestone).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFA7F3D0).withValues(alpha: 0.60),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'BONUS WORDS',
                        style: AppTheme.smallSecondary.copyWith(
                          color: const Color(0xFF047857), // Deep green accent
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Discovered Word List
                    Flexible(
                      fit: FlexFit.loose,
                      child: discovered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No bonus words discovered yet.\nSolve extra bonus words in gameplay to expand your vocabulary!',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body.copyWith(
                                    color: const Color(0xFF1F3A2B), // Dark green/charcoal contrast
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: discovered.map((word) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF065F46).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.35)),
                                    ),
                                    child: Text(
                                      word,
                                      style: AppTheme.worldTitle.copyWith(
                                        color: const Color(0xFF064E3B),
                                        fontSize: 13,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
