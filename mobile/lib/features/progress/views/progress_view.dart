import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/app_colors.dart';
import '../controllers/progress_controller.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  final ProgressController _controller = Get.put(ProgressController());
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];

  final _weightController = TextEditingController();
  final _fatController = TextEditingController();
  final _muscleController = TextEditingController();
  final _bmiController = TextEditingController();

  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _armController = TextEditingController();
  final _thighController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _fatController.dispose();
    _muscleController.dispose();
    _bmiController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _armController.dispose();
    _thighController.dispose();
    super.dispose();
  }

  void _openAddReportSheet() {
    setState(() {
      _selectedDate = DateTime.now();
      _selectedImages.clear();
      _weightController.clear();
      _fatController.clear();
      _muscleController.clear();
      _bmiController.clear();
      _chestController.clear();
      _waistController.clear();
      _armController.clear();
      _thighController.clear();
    });

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'إضافة تقرير تطور جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تاريخ القياس:',
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month, color: AppColors.primary),
                        label: Text(
                          intl.DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),

                  // Body composition inputs
                  Text(
                    'تكوين الجسم (Body Composition)',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _weightController,
                          label: 'الوزن (كجم)',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _fatController,
                          label: 'نسبة الدهون (%)',
                          icon: Icons.percent_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _muscleController,
                          label: 'العضلات (كجم)',
                          icon: Icons.fitness_center_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _bmiController,
                          label: 'الـ BMI (اختياري)',
                          icon: Icons.speed_outlined,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Circumferences inputs
                  Text(
                    'محيطات الجسم (Circumferences)',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _chestController,
                          label: 'الصدر (سم)',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _waistController,
                          label: 'الخصر (سم)',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _armController,
                          label: 'الذراع (سم)',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSheetTextField(
                          controller: _thighController,
                          label: 'الفخذ (سم)',
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Inbody image attachments
                  Text(
                    'InBody مرفقات فحص',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final images = await _picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setSheetState(() {
                          _selectedImages.addAll(images);
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط هنا لرفع صور فحص الـ InBody',
                            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected Images Preview Grid
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Submit Button
                  Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _controller.isSubmitting.value
                          ? null
                          : () async {
                              final success = await _controller.addMeasurement(
                                date: _selectedDate,
                                weight: double.tryParse(_weightController.text),
                                fat: double.tryParse(_fatController.text),
                                muscle: double.tryParse(_muscleController.text),
                                bmi: double.tryParse(_bmiController.text),
                                chest: double.tryParse(_chestController.text),
                                waist: double.tryParse(_waistController.text),
                                arm: double.tryParse(_armController.text),
                                thigh: double.tryParse(_thighController.text),
                                inbodyFiles: _selectedImages,
                              );
                              if (success) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                Get.back();
                                Get.snackbar(
                                  'نجاح',
                                  'تم حفظ التقرير الجديد',
                                  backgroundColor: Colors.green.shade600,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.TOP,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _controller.isSubmitting.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ التقرير الجديد',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: GoogleFonts.cairo(fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'التقدم والتطور',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => _controller.fetchMeasurements(),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddReportSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'تقرير جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.measurements.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Toggle Pills
              _buildPeriodToggle(),
              const SizedBox(height: 20),

              // Weight Goal Progression Card
              _buildGoalProgressionCard(),
              const SizedBox(height: 24),

              // Progression Line Chart
              _buildProgressionChart(),
              const SizedBox(height: 24),

              // Main Stats Grid
              _buildMainStatsGrid(),
              const SizedBox(height: 24),

              // Circumferences logs
              _buildCircumferencesCard(),
              const SizedBox(height: 100), // Spacing for floating action button
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد تقارير قياسات بعد',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر (تقرير جديد) بالأسفل لإدخال أول قياساتك!',
            style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTogglePill('weekly', 'أسبوعي'),
          _buildTogglePill('monthly', 'شهري'),
          _buildTogglePill('yearly', 'سنوي'),
        ],
      ),
    );
  }

  Widget _buildTogglePill(String period, String label) {
    return Expanded(
      child: InkWell(
        onTap: () => _controller.selectedPeriod.value = period,
        borderRadius: BorderRadius.circular(12),
        child: Obx(() {
          final isSelected = _controller.selectedPeriod.value == period;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalProgressionCard() {
    final cur = _controller.currentWeight.value;
    final target = _controller.targetWeight.value;
    final diff = (cur - target).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'هدف الوزن',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cur > target ? 'تحت التخفيض 📉' : 'بناء كتلة 📈',
                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                cur.toStringAsFixed(1),
                style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Text(
                'كجم حلياً',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
              ),
              const Spacer(),
              Text(
                'المتبقي: ${diff.toStringAsFixed(1)} كجم',
                style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: cur == 0 ? 0 : (target / cur).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الحالي: ${cur.toStringAsFixed(1)} كجم',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70),
              ),
              Text(
                'الهدف: ${target.toStringAsFixed(1)} كجم',
                style: GoogleFonts.cairo(fontSize: 11, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionChart() {
    final filtered = _controller.getFilteredMeasurements();
    if (filtered.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    for (int i = 0; i < filtered.length; i++) {
      final w = double.tryParse(filtered[i]['weight']?.toString() ?? '0') ?? 0.0;
      if (w > 0) {
        spots.add(FlSpot(i.toDouble(), w));
      }
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'منحنى تغير الوزن',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[100]!, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < filtered.length) {
                          final dateStr = filtered[idx]['log_date'] ?? '';
                          if (dateStr.isNotEmpty) {
                            final parsed = DateTime.tryParse(dateStr);
                            if (parsed != null) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  intl.DateFormat('MM-dd').format(parsed),
                                  style: GoogleFonts.cairo(fontSize: 8, color: AppColors.textLight),
                                ),
                              );
                            }
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.cairo(fontSize: 8, color: AppColors.textLight),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    final latest = _controller.measurements.isNotEmpty ? _controller.measurements.first : {};
    final weight = double.tryParse(latest['weight']?.toString() ?? '0') ?? 0.0;
    final muscle = double.tryParse(latest['muscle_mass']?.toString() ?? '0') ?? 0.0;
    final fat = double.tryParse(latest['fat_percentage']?.toString() ?? '0') ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildStatCard(
          label: 'الوزن الحالي',
          value: weight > 0 ? '${weight.toStringAsFixed(1)}' : '-',
          unit: 'كجم',
          icon: Icons.monitor_weight_outlined,
          color: AppColors.primary,
        ),
        _buildStatCard(
          label: 'العضلات',
          value: muscle > 0 ? '${muscle.toStringAsFixed(1)}' : '-',
          unit: 'كجم',
          icon: Icons.fitness_center_outlined,
          color: Colors.orange,
        ),
        _buildStatCard(
          label: 'نسبة الدهون',
          value: fat > 0 ? '${fat.toStringAsFixed(1)}' : '-',
          unit: '%',
          icon: Icons.percent_outlined,
          color: Colors.redAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textLight),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircumferencesCard() {
    final latest = _controller.measurements.isNotEmpty ? _controller.measurements.first : {};
    final chest = double.tryParse(latest['chest']?.toString() ?? '0') ?? 0.0;
    final waist = double.tryParse(latest['waist']?.toString() ?? '0') ?? 0.0;
    final arm = double.tryParse(latest['arm']?.toString() ?? '0') ?? 0.0;
    final thigh = double.tryParse(latest['thigh']?.toString() ?? '0') ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'محيطات القياس الحالية',
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircumferenceItem('الصدر', chest, 'سم'),
              _buildCircumferenceItem('الخصر', waist, 'سم'),
              _buildCircumferenceItem('الذراع', arm, 'سم'),
              _buildCircumferenceItem('الفخذ', thigh, 'سم'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircumferenceItem(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 4),
        Text(
          value > 0 ? '${value.toStringAsFixed(1)} $unit' : '-',
          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
      ],
    );
  }
}
