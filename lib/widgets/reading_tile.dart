import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/models/reading_record.dart';

class ReadingTile extends StatelessWidget {
  const ReadingTile({
    super.key,
    required this.record,
    required this.onTap,
  });

  final ReadingRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = record.kind == ReadingKind.meihua ? '梅花' : '六爻';
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cinnabar.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  kind.substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.cinnabar,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$kind · ${record.summary}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoment(record.createdAt),
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
