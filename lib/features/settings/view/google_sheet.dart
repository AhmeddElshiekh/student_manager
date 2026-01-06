import 'package:flutter/material.dart';

class GoogleSheetGuide extends StatelessWidget {
  const GoogleSheetGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildStep({
      required int number,
      String? description,
      String? imagePath,
    }) {
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.primaryColor,
                child: Text(
                  "$number",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
              if (imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(imagePath),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📘 دليل إنشاء ملف الطلاب (Google Sheet)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '👋 أهلاً بك في برنامج "مدير الطلاب"، رفيقك الأمثل لإدارة طلابك وفصولك ومجموعاتك بفعالية وسهولة.\n\n'
            'هذا الدليل يوضح لك خطوة بخطوة كيفية إنشاء Google Form وربطه مع Google Sheet للحصول على بيانات الطلاب وتصديرها في ملف CSV.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.justify,
          ),
          const Divider(height: 32),
          Text(
            '📍 اتبع الخطوات بالترتيب:',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          buildStep(number: 1, imagePath: 'assets/images/1.jpg'),
          buildStep(number: 2, imagePath: 'assets/images/2.jpg'),
          buildStep(number: 3, imagePath: 'assets/images/3.jpg'),
          buildStep(number: 4, imagePath: 'assets/images/4.jpg'),
          buildStep(
            number: 5,
            description:
                'فى أسفل الصفحة ستجد خانة المجموعة. يمكنك تعديل أسماء المجموعات ولكن بنفس الصيغة مثل: (الجمعة ٦:٠٠ م).',
            imagePath: 'assets/images/5.jpg',
          ),
          buildStep(
            number: 6,
            description: 'قم بحفظ النموذج النهائي.',
            imagePath: 'assets/images/6.jpg',
          ),
          buildStep(
            number: 7,
            description: 'انسخ رابط النموذج لإرساله إلى الطلاب.',
            imagePath: 'assets/images/7.jpg',
          ),
          buildStep(
            number: 8,
            description: 'تأكد من تنزيل تطبيق (جداول بيانات Google) على هاتفك.',
            imagePath: 'assets/images/8.jpg',
          ),
          buildStep(
            number: 9,
            description: 'بعد انتهاء تسجيل الطلاب، اذهب إلى تبويب "الردود".',
            imagePath: 'assets/images/9.jpg',
          ),
          buildStep(number: 10, imagePath: 'assets/images/10.jpg'),
          buildStep(number: 11, imagePath: 'assets/images/11.jpg'),
          buildStep(number: 12, imagePath: 'assets/images/12.jpg'),
          buildStep(number: 13, imagePath: 'assets/images/13.jpg'),
          buildStep(number: 14, imagePath: 'assets/images/14.jpg'),
          buildStep(number: 15, imagePath: 'assets/images/15.jpg'),
          buildStep(number: 16, imagePath: 'assets/images/16.jpg'),
          buildStep(number: 17, imagePath: 'assets/images/17.jpg'),
          buildStep(number: 18, imagePath: 'assets/images/18.jpg'),
          buildStep(number: 19, imagePath: 'assets/images/19.jpg'),
          buildStep(number: 20, imagePath: 'assets/images/20.jpg'),
          buildStep(number: 21, imagePath: 'assets/images/21.jpg'),
          const SizedBox(height: 24),
          Center(
            child: Text(
              "✅ الآن يمكنك استيراد ملف CSV إلى برنامج مدير الطلاب.",
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
