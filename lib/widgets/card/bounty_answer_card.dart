import 'package:flutter/material.dart';
import 'package:tsdm_client/constants/layout.dart';
import 'package:tsdm_client/constants/url.dart';
import 'package:tsdm_client/extensions/build_context.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';
import 'package:tsdm_client/widgets/cached_image/cached_image_provider.dart';

/// Widget to show the answer of a bounty in thread.
class BountyAnswerCard extends StatelessWidget {
  /// Constructor.
  const BountyAnswerCard({
    required this.username,
    required this.userSpaceUrl,
    required this.userAvatarUrl,
    required this.answer,
    super.key,
  });

  /// User name of the answer.
  final String username;

  /// Profile url of the answer's user.
  final String userSpaceUrl;

  /// Avatar url of the answer's user.
  final String userAvatarUrl;

  /// Answer content.
  final String answer;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: edgeInsetsL15T15R15B15,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, size: 28, color: secondaryColor),
                sizedBoxW10H10,
                Text(
                  context.t.bountyAnswerCard.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: secondaryColor,
                      ),
                ),
              ],
            ),
            sizedBoxW10H10,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: () async => context.dispatchAsUrl(userSpaceUrl),
                child: CircleAvatar(
                  backgroundImage: CachedImageProvider(
                    userAvatarUrl,
                    fallbackImageUrl: noAvatarUrl,
                    context,
                  ),
                ),
              ),
              title: GestureDetector(
                onTap: () async => context.dispatchAsUrl(userSpaceUrl),
                child: Text(username),
              ),
            ),
            Text(answer),
          ],
        ),
      ),
    );
  }
}
