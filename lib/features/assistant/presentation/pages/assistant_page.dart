import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/widgets/zohal_card.dart';

class AssistantPage extends StatelessWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دستیار زحل')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.yellow, size: 34),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دستیار زحل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'اینجا محل ورود دستیار هوشمند زحل است.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const ZohalCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.construction_outlined),
                title: Text('دستیار در حال آماده‌سازی است'),
                subtitle: Text(
                  'قابلیت‌های هوشمند بعد از تثبیت هسته عملیاتی به این بخش اضافه می‌شوند.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
