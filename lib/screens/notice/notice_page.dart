import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tsdm_client/constants/layout.dart';
import 'package:tsdm_client/constants/url.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';
import 'package:tsdm_client/models/notice.dart';
import 'package:tsdm_client/providers/net_client_provider.dart';
import 'package:tsdm_client/utils/debug.dart';
import 'package:tsdm_client/utils/show_toast.dart';
import 'package:tsdm_client/widgets/notice_card.dart';
import 'package:universal_html/html.dart' as uh;
import 'package:universal_html/parsing.dart';

/// Notice page, shows [Notice] and PrivateMessage of current user.
class NoticePage extends ConsumerStatefulWidget {
  const NoticePage({super.key});

  @override
  ConsumerState<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends ConsumerState<NoticePage> {
  Future<List<Notice>> _fetchNotice(String url) async {
    late final uh.Document document;

    while (true) {
      final resp = await ref.read(netClientProvider()).get(url);
      if (resp.statusCode == HttpStatus.ok) {
        document = parseHtmlDocument(resp.data as String);
        break;
      }

      if (!context.mounted) {
        return [];
      }

      await showRetryToast(context);
    }

    // Check if empty
    final emptyNode =
        document.querySelector('div#ct > div.mn > div.bm.bw0 > div.emp');
    if (emptyNode != null) {
      debug('empty notice');
      // No notice here.
      return [];
    }

    final noticeList = document
        .querySelectorAll(
            'div#ct div.mn > div.bm.bw0 > div.xld.xlda > div.nts > dl.cl')
        .map(Notice.fromClNode)
        .where((e) => e.isValid())
        .toList();
    return noticeList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.noticePage.title),
      ),
      body: FutureBuilder(
        future:
            Future.wait([_fetchNotice(noticeUrl), _fetchNotice(readNoticeUrl)]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          }
          if (snapshot.hasData) {
            // Here d1 is unread notices and d2 is read notices.
            // When fetching data, we use Futures.wait() to run the two futures in parallel so we need to combine them
            // together while filter duplicate messages when server side get d1 request before d2.
            final d1 = snapshot.data![0];
            final d2 = snapshot.data![1];
            d2.addAll(d1.where((x) => !d2.any((y) =>
                (y.redirectUrl == x.redirectUrl) ||
                (y.noticeTime != x.noticeTime))));
            return Padding(
              padding: edgeInsetsL10T5R10B20,
              child: ListView.separated(
                itemCount: d2.length,
                itemBuilder: (context, index) {
                  return NoticeCard(notice: d2[index]);
                },
                separatorBuilder: (context, index) => sizedBoxW5H5,
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
