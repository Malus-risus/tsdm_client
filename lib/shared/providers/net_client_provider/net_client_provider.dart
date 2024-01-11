import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:tsdm_client/instance.dart';
import 'package:tsdm_client/shared/providers/cookie_provider/cookie_provider.dart';
import 'package:tsdm_client/shared/providers/cookie_provider/models/cookie_data.dart';
import 'package:tsdm_client/shared/providers/settings_provider/settings_provider.dart';
import 'package:tsdm_client/utils/debug.dart';

extension _WithFormExt<T> on Dio {
  Future<Response<T>> postWithForm(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
  }
}

/// A http client to do web request.
///
/// With optional [CookieData] use in requests.
///
/// Also a wrapper of [Dio] instance.
///
/// Instance should be unique when making requests.
class NetClientProvider {
  NetClientProvider({Dio? dio, String? username, bool disableCookie = false})
      : _dio = dio ?? _buildDefaultDio() {
    if (disableCookie) {
      _dio.interceptors.add(_ErrorHandler());
    } else {
      final u = username ?? _getLoggedUsername();
      final cookie = getIt.get<CookieProvider>().build(username: u);
      final cookieJar = PersistCookieJar(
        ignoreExpires: true,
        storage: cookie,
      );
      _dio.interceptors
        ..add(CookieManager(cookieJar))
        ..add(_ErrorHandler());
    }
  }

  final Dio _dio;

  /// Build a default dio.
  static Dio _buildDefaultDio() {
    final settings = getIt.get<SettingsProvider>();

    return Dio()
      ..options = BaseOptions(
        headers: <String, String>{
          'Accept': settings.getNetClientAccept(),
          'Accept-Encoding': settings.getNetClientAcceptEncoding(),
          'Accept-Language': settings.getNetClientAcceptLanguage(),
          'User-Agent': settings.getNetClientUserAgent(),
        },
      );
  }

  static String? _getLoggedUsername() {
    final loggedUser = getIt.get<SettingsProvider>().getLoginInfo();
    return loggedUser.$1;
  }

  /// Make a GET request to [path].
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = await _dio.get(path, queryParameters: queryParameters);
    return resp;
  }

  /// Make a GET request to [path], with options set to image types.
  Future<Response<dynamic>> getImage(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'Accept': 'image/avif,image/webp,*/*'},
      ),
    );
    return resp;
  }

  /// Post [data] to [path] with [queryParameters].
  ///
  /// When post a form data, use [postForm] instead.
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp = _dio.post(path, data: data, queryParameters: queryParameters);
    return resp;
  }

  /// Post a form [data] to url [path] with [queryParameters].
  ///
  /// Automatically set `Content-Type` to `application/x-www-form-urlencoded`.
  Future<Response<dynamic>> postForm(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final resp =
        _dio.postWithForm(path, data: data, queryParameters: queryParameters);
    return resp;
  }

  Future<void> download(
    String path,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    final resp = _dio.download(
      path,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: data,
      options: options,
    );
  }
}

/// Handle exceptions during web request.
class _ErrorHandler extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    debug('${err.type}: ${err.message}');

    if (err.type == DioExceptionType.badResponse) {
      // Till now we can do nothing if encounter a bad response.
    }

    // TODO: Retry if we need this error kind.
    if (err.type == DioExceptionType.unknown &&
        err.error.runtimeType == HandshakeException) {
      // Likely we have an error in SSL handshake.
      // debug(err);
      // TODO: Avoid this status code.
      handler.resolve(
        Response(requestOptions: RequestOptions(), statusCode: 999),
      );
      return;
    }

    // Do not block error handling.
    handler.next(err);
  }
}