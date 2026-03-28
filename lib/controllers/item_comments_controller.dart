import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ✅ للكاش

import '../core/services/api_service.dart';
import '../core/config/env.dart';

class CommentModel {
  final int id;
  final int userId;
  final String userName;
  final String comment;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id: int.tryParse('${j['id'] ?? 0}') ?? 0,
        userId: int.tryParse('${j['user_id'] ?? 0}') ?? 0,
        userName: (j['user_name'] ??
                j['username'] ??
                j['phone'] ??
                'مستخدم')
            .toString(),
        comment: (j['comment'] ?? '').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'user_name': userName,
        'comment': comment,
        'created_at': createdAt,
      };
}

class ItemCommentsController extends GetxController {
  final int itemId;
  ItemCommentsController(this.itemId);

  final _api = ApiService();

  /// كاش
  final _box = GetStorage('item_comments_box');

  final loading = false.obs;
  final comments = <CommentModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    // ✅ أولاً: نحاول نقرأ من الكاش
    _loadFromCache();

    // ثم نجلب من السيرفر
    fetchComments();
  }

  String get _cacheKey => 'item_comments_$itemId';

  void _loadFromCache() {
    try {
      final cached = _box.read(_cacheKey);
      if (cached is List) {
        final list = cached
            .map(
              (e) => CommentModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        if (list.isNotEmpty) {
          comments.assignAll(list);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('loadFromCache error: $e');
      }
    }
  }

  void _saveToCache(List<CommentModel> list) {
    try {
      final jsonList = list.map((e) => e.toJson()).toList();
      _box.write(_cacheKey, jsonList);
    } catch (e) {
      if (kDebugMode) {
        print('saveToCache error: $e');
      }
    }
  }

  Future<void> fetchComments({bool force = false}) async {
    try {
      loading.value = true;

      // ✅ لو itemId > 0 نرسل item_id، لو 0 نطلع كل التعليقات
      final Map<String, String> query = {
        't': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      if (itemId > 0) {
        query['item_id'] = '$itemId';
      }

      final res = await _api.get(
        Env.itemComments,
        query: query,
      );

      dynamic root = res;
      if (res is String) {
        try {
          root = jsonDecode(res);
        } catch (e) {
          if (kDebugMode) {
            print('itemComments decode error: $e');
            print('raw: $res');
          }
        }
      }

      List listRaw;

      if (root is Map && root['comments'] is List) {
        listRaw = root['comments'] as List;
      } else if (root is List) {
        listRaw = root;
      } else {
        listRaw = const <dynamic>[];
      }

      final list = listRaw
          .map(
            (e) => CommentModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      comments.assignAll(list);

      // ✅ خزّن في الكاش بعد جلب ناجح
      _saveToCache(list);
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر جلب التعليقات');
      if (kDebugMode) print('fetchComments error: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<bool> deleteComment({
    required int commentId,
    required int userId,
  }) async {
    try {
      final res = await _api.postForm(
        Env.adminDeleteComment,
        {
          'comment_id': '$commentId',
          'user_id': '$userId',
        },
      );

      final ok =
          (res is Map && (res['ok'] == true || res['status'] == 'success'));
      if (ok) {
        comments.removeWhere((c) => c.id == commentId);

        // ✅ حدّث الكاش بعد الحذف
        _saveToCache(comments.toList());

        Get.snackbar('تم', 'تم حذف التعليق',
            snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        final msg = (res is Map)
            ? (res['error'] ?? res['message'] ?? res.toString())
            : res.toString();
        Get.snackbar('خطأ', msg.toString());
        return false;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الاتصال في حذف التعليق');
      if (kDebugMode) print('deleteComment error: $e');
      return false;
    }
  }
}
