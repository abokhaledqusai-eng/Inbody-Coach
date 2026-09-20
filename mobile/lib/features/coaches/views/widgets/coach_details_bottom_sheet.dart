import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/app_colors.dart';
import '../../models/coach_model.dart';
import '../../controllers/coaches_controller.dart';
import '../../../../core/services/api_service.dart';

class CoachDetailsBottomSheet extends StatelessWidget {
  final CoachModel coach;

  const CoachDetailsBottomSheet({super.key, required this.coach});

  String _cleanHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').replaceAll('&nbsp;', ' ').trim();
  }

  String _parseBio(String? bio) {
    if (bio == null || bio.isEmpty) return 'لا توجد نبذة.';
    
    final trimmed = bio.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = json.decode(trimmed);
        return _extractTextFromJson(decoded);
      } catch (e) {
        // Fallback to HTML stripping if JSON decode fails
      }
    }
    
    return _cleanHtml(bio);
  }

  String _extractTextFromJson(dynamic node) {
    if (node == null) return '';
    if (node is Map) {
      if (node['type'] == 'text') {
        return node['text'] ?? '';
      }
      if (node['content'] != null) {
        return _extractTextFromJson(node['content']);
      }
    } else if (node is List) {
      return node.map((item) => _extractTextFromJson(item)).join(' ').trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CoachesController>();
    
    String? imageUrl = coach.profileImageUrl;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imageUrl';
    }

    return Container(
      height: Get.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Image + Name + Basic Info)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.cardBackground,
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        child: imageUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white24) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach.name,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              coach.gender == 'female' ? 'مدربة (أنثى)' : 'مدرب (ذكر)',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Bio Section
                  const Text(
                    'نبذة عني',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _parseBio(coach.bio),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Certificates Section
                  if (coach.certificates != null && coach.certificates!.isNotEmpty) ...[
                    const Text(
                      'الشهادات والاعتمادات',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: coach.certificates!.length,
                        itemBuilder: (context, index) {
                          String certUrl = coach.certificates![index];
                          if (!certUrl.startsWith('http')) {
                            certUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$certUrl';
                          }
                          return Container(
                            margin: const EdgeInsets.only(left: 12),
                            width: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white12),
                              image: DecorationImage(
                                image: NetworkImage(certUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom CTA Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Obx(() => ElevatedButton(
              onPressed: controller.isSelecting.value 
                  ? null 
                  : () {
                      Get.back(); // close bottom sheet
                      controller.selectCoach(coach.id);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: controller.isSelecting.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'ابدأ رحلتك مع المدرب ${coach.name.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            )),
          ),
        ],
      ),
    );
  }
}
