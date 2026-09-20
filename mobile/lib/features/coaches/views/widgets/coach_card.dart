import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/app_colors.dart';
import '../../models/coach_model.dart';
import '../../../../core/services/api_service.dart';
import 'coach_details_bottom_sheet.dart';

class CoachCard extends StatelessWidget {
  final CoachModel coach;

  const CoachCard({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    String? imageUrl = coach.profileImageUrl;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$imageUrl';
    }

    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          CoachDetailsBottomSheet(coach: coach),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.cardBackground,
                    child: const Icon(Icons.person, size: 100, color: Colors.white24),
                  ),
                )
              else
                Container(
                  color: AppColors.cardBackground,
                  child: const Icon(Icons.person, size: 100, color: Colors.white24),
                ),

              // Gradient Overlay for Text
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'متاح للتدريب',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      coach.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'اضغط لعرض الملف الشخصي والشهادات',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
