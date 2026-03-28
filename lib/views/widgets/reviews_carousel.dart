// import 'package:flutter/material.dart';

// class ReviewsCarousel extends StatelessWidget {
//   final List<(String, String, String)> reviews;
//   const ReviewsCarousel({super.key, required this.reviews});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text('تقييمات العملاء', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 10),
//         SizedBox(
//           height: 140,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 2),
//             itemBuilder: (_, i) => _card(reviews[i]),
//             separatorBuilder: (_, __) => const SizedBox(width: 12),
//             itemCount: reviews.length,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _card((String, String, String) r) {
//     final (name, time, text) = r;
//     return Container(
//       width: 240,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(.06),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Row(
//             children: [
//               const CircleAvatar(
//                 radius: 18,
//                 backgroundImage: NetworkImage(
//                   'https://i.pravatar.cc/100?img=5',
//                 ),
//               ),
//               const Spacer(),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     name,
//                     style: const TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                   Text(
//                     time,
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             text,
//             textAlign: TextAlign.right,
//             maxLines: 3,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
// }
