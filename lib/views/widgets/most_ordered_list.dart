import 'package:flutter/material.dart';

class MostOrderedList extends StatelessWidget {
  final int period; // 0: شهر, 1: أسبوع, 2: يوم, 3: الكل
  final ValueChanged<int> onChange;

  /// العناصر: (الترتيب, الاسم, العدد كنص, آخر تاريخ, رابط الصورة)
  final List<(int, String, String, String, String)> items;

  const MostOrderedList({
    super.key,
    required this.period,
    required this.onChange,
    required this.items,
  });

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: _card(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TabsBar(period: period, onChange: onChange),
            const SizedBox(height: 10),

            // عنوان القسم
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الأكثر طلبًا',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: primary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 6),

            // القائمة
            if (items.isEmpty)
              const _EmptyState()
            else
              ...List.generate(items.length, (i) => _RowItem(data: items[i])),

            const SizedBox(height: 8),

            // زر عرض المزيد (هوك)
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: TextButton(
            //     onPressed: items.isEmpty ? null : () {},
            //     child: const Text('عرض المزيد'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /* ---------------- Styles ---------------- */
  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 10,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/* ================= Tabs (مع مؤشر متحرك) ================= */

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.period, required this.onChange});

  final int period;
  final ValueChanged<int> onChange;

  static const primary = Color(0xFFB85A1B);

  @override
  Widget build(BuildContext context) {
    final labels = const ['شهر', 'أسبوع', 'يوم', 'الكل'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E1DA)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: List.generate(4, (i) {
          final selected = i == period;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChange(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: TextStyle(
                        color: selected ? primary : Colors.black87,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                      child: Text(labels[i]),
                    ),
                    const SizedBox(height: 6),
                    // مؤشر أسفل التبويب
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 3,
                      width: selected ? 24 : 0,
                      decoration: BoxDecoration(
                        color: selected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: primary.withOpacity(.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/* ================= Row item ================= */

class _RowItem extends StatelessWidget {
  const _RowItem({required this.data});
  final (int, String, String, String, String) data;

  @override
  Widget build(BuildContext context) {
    final (rank, name, countStr, date, img) = data;
    final int count = int.tryParse(countStr.trim()) ?? 0;
    _arabicCountLabel(count);
    final medal = _medal(rank);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          // الصورة + شارة الترتيب فوقها
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _NetImage(url: img, size: 52),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: _RankBadge(rank: rank, medal: medal),
              ),
            ],
          ),
          title: Text(
            name,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            date,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // العدّاد كشارة صغيرة
          // trailing: Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          //   decoration: BoxDecoration(
          //     color: primary.withOpacity(.08),
          //     border: Border.all(color: primary.withOpacity(.18)),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     // children: [
          //     //   // Text(
          //     //   //   '$count',
          //     //   //   style: const TextStyle(
          //     //   //     fontWeight: FontWeight.w900,
          //     //   //     fontSize: 16,
          //     //   //     height: 1.0,
          //     //   //   ),
          //     //   // ),
          //     //   const SizedBox(height: 2),
          //     //   // Text(
          //     //   //   countLabel,
          //     //   //   style: const TextStyle(
          //     //   //     color: Colors.black54,
          //     //   //     fontSize: 11,
          //     //   //     height: 1.0,
          //     //   //   ),
          //     //   // ),
          //     // ],
          //   ),
          // ),
        ),
        const Divider(height: 8),
      ],
    );
  }

  String _arabicCountLabel(int n) {
    if (n == 0) return 'لا طلبات';
    if (n == 1) return 'طلب';
    if (n == 2) return 'طلبان';
    if (n >= 3 && n <= 10) return 'طلبات';
    return 'طلبًا';
  }

  _Medal? _medal(int rank) {
    switch (rank) {
      case 1:
        return _Medal('🥇', const Color(0xFFFFD700));
      case 2:
        return _Medal('🥈', const Color(0xFFC0C0C0));
      case 3:
        return _Medal('🥉', const Color(0xFFCD7F32));
      default:
        return null;
    }
  }
}

/* ================= Helpers Widgets ================= */

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'لا توجد بيانات للفترة المحددة',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.medal});
  final int rank;
  final _Medal? medal;

  @override
  Widget build(BuildContext context) {
    final hasMedal = medal != null;
    final bg = hasMedal ? medal!.color.withOpacity(.18) : Colors.black12;
    final fg = hasMedal ? medal!.color : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: hasMedal
          ? Text(medal!.emoji, style: const TextStyle(fontSize: 16))
          : Text(
              '#$rank',
              style: TextStyle(fontWeight: FontWeight.w900, color: fg),
            ),
    );
  }
}

class _NetImage extends StatelessWidget {
  const _NetImage({required this.url, required this.size});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;
    if (!hasUrl) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFFF1EFEA),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 22),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: const Color(0xFFF1EFEA),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, size: 22),
      ),
    );
  }
}

class _Medal {
  final String emoji;
  final Color color;
  const _Medal(this.emoji, this.color);
}
