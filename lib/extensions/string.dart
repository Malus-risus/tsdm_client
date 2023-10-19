import 'package:tsdm_client/routes/app_routes.dart';
import 'package:tsdm_client/routes/screen_paths.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

extension ParseUrl on String {
  /// Try parse string to [AppRoute] with arguments.
  (String, Map<String, String>)? parseUrlToRoute() {
    final fidRe = RegExp(r'fid=(?<Fid>\d+)');
    final fidMatch = fidRe.firstMatch(this);
    if (fidMatch != null) {
      return (ScreenPaths.forum, {'fid': "${fidMatch.namedGroup('Fid')}"});
    }

    final tidRe = RegExp(r'tid=(?<Tid>\d+)');
    final tidMatch = tidRe.firstMatch(this);
    if (tidMatch != null) {
      return (ScreenPaths.thread, {'tid': "${tidMatch.namedGroup('Tid')}"});
    }

    return null;
  }
}

extension ImageCacheFileName on String {
  String fileNameV5() {
    return _uuid.v5(Namespace.URL, this);
  }
}