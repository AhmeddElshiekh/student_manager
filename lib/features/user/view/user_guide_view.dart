import 'package:flutter/material.dart';

class UserGuideView extends StatelessWidget {
  const UserGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('دليل الاستخدام'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'أهلاً بك في "مدير الطلاب"، رفيقك الأمثل لإدارة طلابك وفصولك. هذا الدليل سيساعدك على فهم جميع مميزات البرنامج، من الأساسيات إلى الخصائص المتقدمة.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          _GuideSection(
            title: '1. المميزات الأساسية',
            description: 'تعرف على كيفية إدارة الصفوف، المجموعات، الطلاب، والدفعات.',
            features: const [
              _FeatureCard(
                icon: Icons.school_outlined,
                title: 'إدارة الصفوف الدراسية',
                description: 'هي نقطة البداية لتنظيم طلابك. يمكنك عرض الصفوف، إضافة صفوف جاهزة، والبحث بسهولة. اضغط على (+) لإضافة طالب، أو على اسم الصف لعرض مجموعاته.',
              ),
              _FeatureCard(
                icon: Icons.groups_outlined,
                title: 'إدارة المجموعات',
                description: 'داخل كل صف، يمكنك تنظيم الطلاب في مجموعات. السحب لليسار يسمح لك بتعديل اسم المجموعة وسعرها، والسحب لليمين يتيح لك حذفها أو نسخها.',
              ),
              _FeatureCard(
                icon: Icons.person_outline,
                title: 'إدارة الطلاب',
                description: "لكل طالب رقم فريد. يمكنك إضافة طالب وتعديل بياناته أو نقله. السحب لليسار على اسم الطالب يتيح لك الاتصال بولي أمره، والسحب لليمين يتيح لك حذفه.",
              ),
              _FeatureCard(
                icon: Icons.qr_code_scanner,
                title: 'إدارة الدفعات',
                description: 'تتبع حالة دفع الطلاب بسهولة. استخدم ماسح QR Code الفريد لكل طالب لتسجيل دفعة جديدة بسرعة، أو لتفقد حالة دفعه الحالية.',
              ),
            ],
          ),

          _GuideSection(
            title: '2. لوحة التحكم',
            description: 'توفر لك رؤية شاملة لأهم الإحصائيات مع رسوم بيانية توضيحية.',
            features: const [
              _FeatureCard(
                icon: Icons.next_plan_outlined,
                title: 'المجموعات القادمة',
                description: 'عرض المجموعات المجدولة خلال الأسبوع القادم، مع تفاصيل الصف، التوقيت، وعدد الطلاب.',
              ),
              _FeatureCard(
                icon: Icons.bar_chart_outlined,
                title: 'إحصائيات الطلاب والإيرادات',
                description: 'اطلع على العدد الإجمالي للطلاب، وحالة الدفع. كما يمكنك متابعة إجمالي الإيرادات وإيرادات اليوم أو آخر 7 و 30 يومًا.',
              ),
              _FeatureCard(
                icon: Icons.pie_chart_outline,
                title: 'الرسوم البيانية',
                description: 'رسوم بيانية تفاعلية تعرض الإيرادات الشهرية، وتوزيع الطلاب حسب الصف أو المجموعة.',
              ),
            ],
          ),

          _GuideSection(
            title: '3. الملف الشخصي والإعدادات',
            description: 'تحتوي على بيانات حسابك وأدوات مهمة للتحكم في التطبيق.',
            features: const [
              _FeatureCard(
                icon: Icons.person_pin_outlined,
                title: 'بيانات الحساب',
                description: 'تعرض اسم المستخدم، البريد الإلكتروني، وتاريخ الانضمام. تظهر شارة خاصة إذا كان لديك صلاحيات مدير.',
              ),
              _FeatureCard(
                icon: Icons.cloud_upload_outlined,
                title: 'النسخ الاحتياطي',
                description: 'قم بعمل نسخة احتياطية سحابية (Firebase) أو محلية (JSON) لبياناتك، مع إمكانية الاستعادة والتصدير.',
              ),
              _FeatureCard(
                icon: Icons.sync_alt,
                title: 'المزامنة التلقائية بين الأجهزة',
                description: 'بياناتك تتزامن تلقائياً عبر جميع أجهزتك. عند تعديل أي بيانات، يتم رفعها للسحابة. لجلب آخر التحديثات على جهاز آخر، فقط ضع التطبيق في الخلفية ثم افتحه مجدداً.',
              ),
              _FeatureCard(
                icon: Icons.settings_outlined,
                title: 'الإعدادات المتقدمة',
                description: 'تحكم في وضع الثيم (داكن/فاتح)، أضف صفوفًا جاهزة، واستورد الطلاب من ملف CSV.',
              ),
              _FeatureCard(
                icon: Icons.logout,
                title: 'تسجيل الخروج',
                description: 'زر لتسجيل الخروج من الحساب بعد تأكيد العملية.',
              ),
            ],
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'نتمنى لك تجربة موفقة وفعالة!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.title,
    required this.description,
    required this.features,
  });

  final String title;
  final String description;
  final List<Widget> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...features,
          const Divider(height: 48),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 1,
      shadowColor: Colors.transparent,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
