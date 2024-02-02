import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tsdm_client/constants/layout.dart';
import 'package:tsdm_client/constants/url.dart';
import 'package:tsdm_client/extensions/build_context.dart';
import 'package:tsdm_client/extensions/date_time.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';
import 'package:tsdm_client/packages/html_muncher/lib/html_muncher.dart';
import 'package:tsdm_client/routes/screen_paths.dart';
import 'package:tsdm_client/shared/models/post.dart';
import 'package:tsdm_client/shared/models/user.dart';
import 'package:tsdm_client/widgets/cached_image//cached_image_provider.dart';
import 'package:tsdm_client/widgets/card/lock_card/locked_card.dart';
import 'package:tsdm_client/widgets/card/packet_card.dart';
import 'package:tsdm_client/widgets/card/rate_card.dart';
import 'package:universal_html/parsing.dart';

enum _PostCardActions {
  reply,
  rate,
}

/// Card for a [Post] model.
///
/// Usually inside a ThreadPage.
class PostCard extends StatefulWidget {
  /// Constructor.
  const PostCard(this.post, {this.replyCallback, super.key});

  /// [Post] model to show.
  final Post post;

  /// A callback function that will be called every time when user try to
  /// reply to the post.
  final FutureOr<void> Function(User user, int? postFloor, String? replyAction)?
      replyCallback;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with AutomaticKeepAliveClientMixin {
  Future<void> _rateCallback() async {
    await context.pushNamed(
      ScreenPaths.ratePost,
      pathParameters: <String, String>{
        'username': widget.post.author.name,
        'pid': widget.post.postID,
        'floor': '${widget.post.postFloor}',
        'rateAction': widget.post.rateAction!,
      },
    );
  }

  // TODO: Handle better.
  // FIXME: Fix rebuild when interacting with widgets inside.
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      child: Padding(
        padding: edgeInsetsL10R10B10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: GestureDetector(
                onTap: () async =>
                    context.dispatchAsUrl(widget.post.author.url),
                child: CircleAvatar(
                  backgroundImage: CachedImageProvider(
                    widget.post.author.avatarUrl!,
                    context,
                    fallbackImageUrl: noAvatarUrl,
                  ),
                ),
              ),
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () async =>
                        context.dispatchAsUrl(widget.post.author.url),
                    child: Text(widget.post.author.name),
                  ),
                  Expanded(child: Container()),
                ],
              ),
              subtitle: Text('${widget.post.publishTime?.elapsedTillNow()}'),
              trailing: widget.post.postFloor == null
                  ? null
                  : Text('#${widget.post.postFloor}'),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await widget.replyCallback?.call(
                  widget.post.author,
                  widget.post.postFloor,
                  widget.post.replyAction,
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: edgeInsetsL15R15B10,
                      child: munchElement(
                        context,
                        parseHtmlDocument(widget.post.data).body!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.post.locked.isNotEmpty)
              ...widget.post.locked
                  .where((e) => e.isValid())
                  .map(LockedCard.new),
            if (widget.post.packetUrl != null) ...[
              PacketCard(widget.post.packetUrl!),
              sizedBoxW10H10,
            ],
            if (widget.post.rate != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 712),
                child: RateCard(widget.post.rate!),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _PostCardActions.reply,
                      child: Row(
                        children: [
                          const Icon(Icons.reply_outlined),
                          Text(context.t.postCard.reply),
                        ],
                      ),
                    ),
                    if (widget.post.rateAction != null)
                      PopupMenuItem(
                        value: _PostCardActions.rate,
                        child: Row(
                          children: [
                            const Icon(Icons.rate_review_outlined),
                            Text(context.t.postCard.rate),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case _PostCardActions.reply:
                        await widget.replyCallback?.call(
                          widget.post.author,
                          widget.post.postFloor,
                          widget.post.replyAction,
                        );
                      case _PostCardActions.rate:
                        if (widget.post.rateAction != null) {
                          await _rateCallback.call();
                        }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add mixin and return true to avoid post list shaking when scrolling.
  @override
  bool get wantKeepAlive => true;
}
