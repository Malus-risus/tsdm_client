import 'package:tsdm_client/extensions/string.dart';
import 'package:tsdm_client/extensions/universal_html.dart';
import 'package:tsdm_client/utils/debug.dart';
import 'package:universal_html/html.dart' as uh;

// TODO: Refactor with sealed class.
enum NoticeType {
  reply,
  score,
}

class _NoticeInfo {
  _NoticeInfo({
    required this.userAvatarUrl,
    required this.username,
    required this.userSpaceUrl,
    required this.noticeTime,
    required this.noticeTimeString,
    required this.noticeThreadUrl,
    required this.noticeThreadTitle,
    required this.redirectUrl,
    required this.ignoreCount,
    required this.noticeType,
    required this.score,
    required this.scoreComment,
  });

  /// User avatar.
  ///
  /// User is who triggered this notice.
  /// Following "user"s are the same.
  final String? userAvatarUrl;

  /// Username.
  final String? username;

  /// Link to that user's user space.
  final String? userSpaceUrl;

  /// [DateTime] format notice time.
  ///
  /// Use this instead of [noticeTimeString].
  final DateTime? noticeTime;

  /// String format notice time.
  ///
  /// May not be used, better to use [noticeTime];
  final String noticeTimeString;

  /// Url to the thread that contains this notice's reply.
  /// Following "thread"'s are the same.
  final String? noticeThreadUrl;

  /// Thread title.
  final String? noticeThreadTitle;

  /// Link directly to the notice related reply in thread.
  ///
  /// This is helpful when redirecting to the related post in thread, though
  /// not used yet.
  final String? redirectUrl;

  /// Number of ignored same notice.
  ///
  /// Will be null when there is no ignored notice.
  final int? ignoreCount;

  /// Type of current notice.
  final NoticeType noticeType;

  /// Score received.
  final String? score;

  /// Comment when scoring.
  final String? scoreComment;
}

class Notice {
  /// Build a [Notice] from html node [element] :
  /// div#ct > div.mn > div.bm.bw0 > div.xld.xlda > div.nts > div.cl (notice=xxx)
  ///
  /// This css selector may work in all web page styles.
  Notice.fromClNode(uh.Element element) : _info = _buildPostFromClNode(element);

  final _NoticeInfo _info;

  String? get userAvatarUrl => _info.userAvatarUrl;

  String? get username => _info.username;

  String? get userSpaceUrl => _info.userSpaceUrl;

  DateTime? get noticeTime => _info.noticeTime;

  String? get noticeTimeString => _info.noticeTimeString;

  String? get noticeThreadUrl => _info.noticeThreadUrl;

  String? get noticeThreadTitle => _info.noticeThreadTitle;

  String? get redirectUrl => _info.redirectUrl;

  int? get ignoreCount => _info.ignoreCount;

  NoticeType get noticeType => _info.noticeType;

  String? get score => _info.score;

  String? get scoreComment => _info.scoreComment;

  /// [element] :
  /// div#ct > div.mn > div.bm.bw0 > div.xld.xlda > div.nts > div.cl (notice=xxx)
  static _NoticeInfo _buildPostFromClNode(uh.Element element) {
    final userAvatarUrl = element.querySelector('dd.avt > a > img')?.imageUrl();

    final noticeNode = element.querySelector('dt > span > span');
    final noticeTime = noticeNode?.attributes['title']?.parseToDateTimeUtc8();
    final noticeTimeString = noticeNode?.firstEndDeepText();

    String? score;
    String? scoreComment;

    final quoteNode = element.querySelector('dd.ntc_body > div.quote');
    late final NoticeType noticeType;
    if (quoteNode == null) {
      noticeType = NoticeType.reply;
    } else {
      final n = element.querySelector('dd.ntc_body');
      noticeType = NoticeType.score;
      score = n?.nodes[n.nodes.length - 2].text?.trim().replaceFirst('评分 ', '');
      scoreComment = quoteNode.innerText;
    }

    String? username;
    String? userSpaceUrl;
    String? noticeThreadUrl;
    String? noticeThreadTitle;
    String? redirectUrl;

    final a1Node = element.querySelector('dd.ntc_body > a:nth-child(1)');
    final a2Node = element.querySelector('dd.ntc_body > a:nth-child(2)');
    if (noticeType == NoticeType.reply) {
      username = a1Node?.firstEndDeepText();
      userSpaceUrl = a1Node?.firstHref();
      noticeThreadUrl = a2Node?.firstHref();
      noticeThreadTitle = a2Node?.firstEndDeepText();
      redirectUrl = element
          .querySelector('dd.ntc_body > a:nth-child(3)')
          ?.firstHref()
          ?.prependHost();
    } else {
      noticeThreadTitle = a1Node?.firstEndDeepText();
      redirectUrl = a1Node?.firstHref()?.prependHost();
      userSpaceUrl = a2Node?.firstHref();
      username = a2Node?.firstEndDeepText();
    }

    final ignoreCount = element
        .querySelector('dd.xg1.xw0')
        ?.firstEndDeepText()
        ?.split(' ')
        .elementAtOrNull(1)
        ?.parseToInt();

    return _NoticeInfo(
      userAvatarUrl: userAvatarUrl,
      noticeTime: noticeTime,
      noticeTimeString: noticeTimeString ?? '',
      userSpaceUrl: userSpaceUrl,
      username: username,
      noticeThreadUrl: noticeThreadUrl,
      noticeThreadTitle: noticeThreadTitle,
      redirectUrl: redirectUrl,
      ignoreCount: ignoreCount,
      noticeType: noticeType,
      score: score,
      scoreComment: scoreComment,
    );
  }

  bool isValid() {
    if (username == null ||
        userSpaceUrl == null ||
        noticeTime == null ||
        noticeThreadTitle == null ||
        redirectUrl == null) {
      debug(
          'failed to parse notice: $username, $userSpaceUrl, $noticeTime, $noticeThreadUrl, $noticeThreadTitle, $redirectUrl');
      return false;
    }

    return true;
  }
}
