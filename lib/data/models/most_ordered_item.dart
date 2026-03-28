class MostOrderedItem {
  final int rank; // الترتيب (محسوب في الكلاينت)
  final int itemId;
  final String name;
  final int ordersCount; // عدد الطلبات/الوحدات المباعة
  final String lastDate; // آخر تاريخ ظهر فيه
  final String imageUrl;

  const MostOrderedItem({
    required this.rank,
    required this.itemId,
    required this.name,
    required this.ordersCount,
    required this.lastDate,
    required this.imageUrl,
  });

  factory MostOrderedItem.fromJson(Map<String, dynamic> j, {int rank = 0}) {
    return MostOrderedItem(
      rank: rank,
      itemId: int.tryParse('${j['item_id'] ?? 0}') ?? 0,
      name: (j['name'] ?? j['title'] ?? '').toString(),
      ordersCount: int.tryParse('${j['orders_count'] ?? j['count'] ?? 0}') ?? 0,
      lastDate: (j['last_date'] ?? '').toString(),
      imageUrl: (j['image_url'] ?? j['image'] ?? '').toString(),
    );
  }

  MostOrderedItem withRank(int r) => MostOrderedItem(
    rank: r,
    itemId: itemId,
    name: name,
    ordersCount: ordersCount,
    lastDate: lastDate,
    imageUrl: imageUrl,
  );
}
