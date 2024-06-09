import 'dart:async';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:tsdm_client/features/cache/models/models.dart';
import 'package:tsdm_client/shared/providers/image_cache_provider/image_cache_provider.dart';
import 'package:tsdm_client/shared/providers/net_client_provider/net_client_provider.dart';

/// Repository of global image cache.
final class ImageCacheRepository {
  /// Constructor.
  ImageCacheRepository(this._imageCacheProvider, this._netClientProvider);

  final ImageCacheProvider _imageCacheProvider;
  final NetClientProvider _netClientProvider;

  /// Provide a stream of [ImageCacheResponse].
  final _controller = BehaviorSubject<ImageCacheResponse>();

  /// [ImageCacheResponse] stream.
  ///
  /// Contains a series of responses to image caching requests.
  ///
  /// Latest image cache state also is here.
  Stream<ImageCacheResponse> get response => _controller.asBroadcastStream();

  /// Record all currently loading images.
  ///
  /// Use this list to avoid duplicate requests.
  final List<String> _loadingImages = [];

  /// Dispose the repository.
  void dispose() {
    _controller.close();
  }

  /// Update caches.
  ///
  /// When [force] is true, always ignore local cache and fetch image from url.
  FutureOr<void> updateImageCache(String url, {bool force = false}) async {
    // Use cache if intended to.
    if (!force) {
      final cacheInfo = _imageCacheProvider.getCacheInfo(url);
      if (cacheInfo != null) {
        final imageData = await _imageCacheProvider.getCache(url);
        _controller.add(ImageCacheSuccessResponse(url, imageData));
        return;
      }
    }

    if (_loadingImages.contains(url)) {
      // If already loading, do nothing.
      return;
    }

    // Enter loading state.
    _loadingImages.add(url);
    _controller.add(ImageCacheLoadingResponse(url));

    try {
      final resp = await _netClientProvider.getImage(url);
      final imageData = resp.data as List<int>;
      await _imageCacheProvider.updateCache(url, imageData);
      _controller
          .add(ImageCacheSuccessResponse(url, Uint8List.fromList(imageData)));
    } catch (e) {
      _controller.add(ImageCacheFailedResponse(url));
    }
    // Leave loading state.
    _loadingImages.remove(url);
  }

  /// Get the cached file of emoji with specified [groupId] and [id].
  Uint8List? getEmojiCacheSync(String groupId, String id) {
    return _imageCacheProvider.getEmojiCacheSync(groupId, id);
  }

  /// Get emoji cache data form emoji bbcode [code].
  Future<Uint8List?> getEmojiCacheFromRawCode(String code) async {
    return _imageCacheProvider.getEmojiCacheFromRawCode(code);
  }
}
