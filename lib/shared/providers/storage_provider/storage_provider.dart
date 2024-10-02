import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:tsdm_client/exceptions/exceptions.dart';
import 'package:tsdm_client/shared/models/models.dart';
import 'package:tsdm_client/shared/providers/storage_provider/models/database/dao/dao.dart';
import 'package:tsdm_client/shared/providers/storage_provider/models/database/database.dart';
import 'package:tsdm_client/utils/logger.dart';

/// Load all cookie info from database without any dependency except [db].
///
/// Only use this function to preload cookie before initializing
/// [StorageProvider].
Future<Map<UserLoginInfo, Cookie>> preloadCookie(AppDatabase db) async {
  final allCookie = await CookieDao(db).selectAll();
  final mappedCookie = allCookie.map(
    (e) => MapEntry(
      UserLoginInfo(
        username: e.username,
        uid: e.uid,
        email: e.email,
      ),
      jsonDecode(e.cookie) as Map<String, dynamic>,
    ),
  );

  return Map.fromEntries(mappedCookie);
}

/// Load all image cache info from database without any dependency except [db].
///
/// Only use this function to preload cookie before initializing
/// [StorageProvider].
Future<Map<String, ImageCacheEntity>> preloadImageCache(AppDatabase db) async {
  final allImageCache = await ImageCacheDao(db).selectAll();
  final mappedImageCache = allImageCache.map((e) => MapEntry(e.url, e));
  return Map.fromEntries(mappedImageCache);
}

/// [StorageProvider] should be used by other providers.
class StorageProvider with LoggerMixin {
  /// Constructor.
  const StorageProvider(this._db, this._cookieCache, this._imageCache);

  /// Injected database
  final AppDatabase _db;

  /// All cookie cached in memory.
  ///
  /// Read cache to avoid disk IO and make it synchronous.
  ///
  /// MUST update during cookie setter calls.
  final Map<UserLoginInfo, Cookie> _cookieCache;

  /// All image cache cached in memory.
  ///
  /// Access this field to avoid disk IO and make it synchronous.
  ///
  /// MUST update during image cache setter calls.
  final Map<String, ImageCacheEntity> _imageCache;

  /*             cookie             */

  /// Get [Cookie] with [uid] from cookie cached saved in memory.
  ///
  /// Return null if not found.
  ///
  /// Generally the cookie cache is synced with database cookie values.
  /// So may not need to use the async version API to retry to read.
  Cookie? getCookieByUidSync(int uid) {
    return _cookieCache.entries
        .firstWhereOrNull((e) => e.key.uid == uid)
        ?.value;
  }

  /// Get [Cookie] with [username] from cookie cached saved in memory.
  ///
  /// Return null if not found.
  ///
  /// Generally the cookie cache is synced with database cookie values.
  /// So may not need to use the async version API to retry to read.
  Cookie? getCookieByUsernameSync(String username) {
    return _cookieCache.entries
        .firstWhereOrNull((e) => e.key.username == username)
        ?.value;
  }

  /// Get [Cookie] with [email] from cookie cached saved in memory.
  ///
  /// Return null if not found.
  ///
  /// Generally the cookie cache is synced with database cookie values.
  /// So may not need to use the async version API to retry to read.
  Cookie? getCookieByEmailSync(String email) {
    return _cookieCache.entries
        .firstWhereOrNull((e) => e.key.email == email)
        ?.value;
  }

  /// Save cookie with completed user info.
  ///
  /// Required full user info and save by [uid] so that we handled some extreme
  /// situation when username or email changed.
  Future<void> saveCookie({
    required String username,
    required int uid,
    required String email,
    required Cookie cookie,
  }) async {
    final allCookie = getCookieByUidSync(uid) ?? <String, dynamic>{};

    // Combine two map together, do not directly use [cookie].
    // ignore: cascade_invocations
    allCookie.addAll(Map.castFrom<String, dynamic, String, String>(cookie));

    // Update cookie cache.
    final userInfo = UserLoginInfo(username: username, uid: uid, email: email);
    _cookieCache[userInfo] = allCookie;

    if (!allCookie.toString().contains('s_gkr8_682f_auth')) {
      // Only save cookie when cookie is authed.
      info('refuse to save not authed cookie');
      return;
    }

    await CookieDao(_db).upsertCookie(
      CookieCompanion(
        username: Value(username),
        uid: Value(uid),
        email: Value(email),
        cookie: Value(jsonEncode(allCookie)),
      ),
    );
  }

  /// Delete cookie for [uid].
  Future<bool> deleteCookieByUid(int uid) async {
    // Update cookie cache.
    _cookieCache.removeWhere((e, _) => e.uid == uid);
    final affectedRows = await CookieDao(_db).deleteCookieByUid(uid);
    return affectedRows != 0;
  }

  /// Delete stored cookie with [userInfo].
  ///
  /// uid > username > email.
  Future<bool> deleteCookieByUserInfo(UserLoginInfo userInfo) async {
    final username = userInfo.username;
    final uid = userInfo.uid;
    final email = userInfo.email;
    final int affectedRows;
    if (uid != null) {
      _cookieCache.removeWhere((e, _) => e.uid == uid);
      affectedRows = await CookieDao(_db).deleteCookieByUid(uid);
    } else if (username != null) {
      _cookieCache.removeWhere((e, _) => e.username == username);
      affectedRows = await CookieDao(_db).deleteCookieByUsername(username);
    } else if (email != null) {
      _cookieCache.removeWhere((e, _) => e.email == email);
      affectedRows = await CookieDao(_db).deleteCookieByEmail(email);
    } else {
      error('intend to delete cookie with empty user info');
      affectedRows = 0;
    }
    return affectedRows != 0;
  }

  /*            image cache           */

  /// Get the image cache for image from [url].
  ImageCacheEntity? getImageCacheSync(String url) =>
      _imageCache.entries.firstWhereOrNull((e) => e.key == url)?.value;

  /// Insert or update cache info, update all info.
  Future<void> updateImageCache(
    String url, {
    required String fileName,
    DateTime? lastCacheTime,
    DateTime? lastUsedTime,
  }) async {
    final now = DateTime.now();
    _imageCache[url] = ImageCacheEntity(
      url: url,
      fileName: fileName,
      lastCachedTime: lastCacheTime ?? now,
      lastUsedTime: lastUsedTime ?? now,
    );
    await ImageCacheDao(_db).upsertImageCache(
      ImageCacheCompanion(
        url: Value(url),
        fileName: Value(fileName),
        lastCachedTime:
            lastCacheTime != null ? Value(lastCacheTime) : Value(now),
        lastUsedTime: lastUsedTime != null ? Value(lastUsedTime) : Value(now),
      ),
    );
  }

  /// Insert or update cache info, only update last used time.
  Future<void> updateImageCacheUsedTime(String url) async {
    final now = DateTime.now();
    if (_imageCache.containsKey(url)) {
      _imageCache[url] = _imageCache[url]!.copyWith(lastUsedTime: now);
    }
    await ImageCacheDao(_db).upsertImageCache(
      ImageCacheCompanion(url: Value(url), lastUsedTime: Value(now)),
    );
  }

  /// Clear all image cache in database.
  Future<void> clearImageCache() async {
    _imageCache.clear();
    await ImageCacheDao(_db).deleteAll();
  }

  /*             settings             */

  /// Load all saved settings.
  Future<List<SettingsEntity>> getAllSettings() async {
    return SettingsDao(_db).getAll();
  }

  /// Remove a settings with given [name].
  Future<bool> removeByKey(String name) async {
    final affectedRows = await SettingsDao(_db).deleteByName(name);
    return affectedRows != 0;
  }

  /// Get string type value of specified key.
  Future<String?> getString(String key) async =>
      SettingsDao(_db).getValueByName<String>(key);

  /// Save string type value of specified key.
  Future<void> saveString(String key, String value) async {
    await SettingsDao(_db).setValue<String>(key, value);
  }

  /// Get int type value of specified key.
  Future<int?> getInt(String key) async =>
      SettingsDao(_db).getValueByName<int>(key);

  /// Sae int type value of specified key.
  Future<void> saveInt(String key, int value) async {
    await SettingsDao(_db).setValue<int>(key, value);
  }

  /// Get bool type value of specified key.
  Future<bool?> getBool(String key) async =>
      SettingsDao(_db).getValueByName<bool>(key);

  /// Save bool type value of specified value.
  Future<void> saveBool(String key, {required bool value}) async {
    await SettingsDao(_db).setValue<bool>(key, value);
  }

  /// Get double type value of specified key.
  Future<double?> getDouble(String key) async =>
      SettingsDao(_db).getValueByName<double>(key);

  /// Save double type value of specified key.
  Future<void> saveDouble(String key, double value) async {
    await SettingsDao(_db).setValue<double>(key, value);
  }

  /// Delete the given record from database.
  Future<void> deleteKey(String key) async {
    await SettingsDao(_db).deleteByName(key);
  }

  /*        thread visit history        */

  /// Fetch all thread visit history for all users and all threads..
  AsyncEither<List<ThreadVisitHistoryEntity>> fetchAllThreadVisitHistory() =>
      AsyncEither(() async {
        final history = await ThreadVisitHistoryDao(_db).selectAll();
        return Right(history);
      });

  /// Fetch all thread visit history for user [uid].
  AsyncEither<List<ThreadVisitHistoryEntity>> fetchThreadVisitHistoryByUid(
    int uid,
  ) =>
      AsyncEither(
        () async => Right(await ThreadVisitHistoryDao(_db).selectByUid(uid)),
      );

  /// Delete a history record specified by [uid] and [tid].
  AsyncVoidEither deleteByUidAndTid({
    required int uid,
    required int tid,
  }) =>
      AsyncVoidEither(() async {
        await ThreadVisitHistoryDao(_db).deleteByUidOrTid(uid: uid, tid: tid);
        return rightVoid();
      });

  /// Save thread visit history.
  Future<void> updateThreadVisitHistory({
    required int uid,
    required int tid,
    required int fid,
    required String username,
    required String threadTitle,
    required String forumName,
    required DateTime visitTime,
  }) async =>
      ThreadVisitHistoryDao(_db).upsertVisitHistory(
        ThreadVisitHistoryCompanion(
          uid: Value(uid),
          tid: Value(tid),
          fid: Value(fid),
          username: Value(username),
          threadTitle: Value(threadTitle),
          forumName: Value(forumName),
          visitTime: Value(visitTime),
        ),
      );

  /// Delete thread visit history with [uid] and [tid].
  Future<void> deleteThreadVisitHistory({
    int? uid,
    int? tid,
  }) async =>
      ThreadVisitHistoryDao(_db).deleteByUidOrTid(
        uid: uid,
        tid: tid,
      );

  /// Delete all thread visit history.
  AsyncVoidEither deleteAllThreadVisitHistory() => AsyncVoidEither(() async {
        await ThreadVisitHistoryDao(_db).deleteAll();
        return rightVoid();
      });
}
