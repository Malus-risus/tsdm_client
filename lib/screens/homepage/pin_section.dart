import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tsdm_client/providers/root_content_provider.dart';
import 'package:tsdm_client/utils/debug.dart';
import 'package:tsdm_client/utils/parse_route.dart';
import 'package:tsdm_client/widgets/single_line_text.dart';

class PinSection extends ConsumerWidget {
  const PinSection({super.key});

  /// Build a list of [ThreadAuthorPair] to a list of [ListTile] and
  /// wrap in a [Card].
  /// All [ThreadAuthorPair] inside [threads] should guarantee not null.
  Widget _buildSectionThreads(
    BuildContext context,
    List<ThreadAuthorPair?> threads,
  ) {
    final listTileList = threads
        .map(
          (e) => ListTile(
            title: SingleLineText(
              e!.threadTitle,
            ),
            trailing: SingleLineText(
              e.authorName,
            ),
            onTap: () {
              final target = e.threadUrl.parseUrlToRoute();
              if (target == null) {
                debug('invalid pinned thread url: ${e.threadUrl}');
                return;
              }
              context.pushNamed(target.$1, pathParameters: target.$2);
            },
          ),
        )
        .toList();

    return Column(children: listTileList);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.read(rootContentProvider.notifier).cache;
    final navNameList = cache.navNameList;
    final navThreadList = cache.sectionAllThreadPairList;
    if (navNameList == null || navNameList.length != navThreadList.length) {
      final errorText =
          'failed to build homepage pin section: navName length: ${navNameList?.length}, navShowList length: ${navThreadList.length}';
      debug(errorText);
      return Text(errorText);
    }

    if (navNameList.isEmpty || navThreadList.isEmpty) {
      return const Center(
        child: Text('Need to login to see recent pinned threads in homepage'),
      );
    }

    final ret = <Widget>[];

    final count = navNameList.length;
    debug('nav thread section count: $count');

    for (var i = 0; i < count; i++) {
      final sectionName = navNameList[i];
      final sectionAllThreadPair = navThreadList[i];

      final threadWidgetList =
          _buildSectionThreads(context, sectionAllThreadPair);

      ret.add(Card(
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              Text(
                sectionName ?? '',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 10, height: 10),
              threadWidgetList,
            ],
          ),
        ),
      ));
    }

    return GridView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      // TODO: Not hardcode these Extent sizes.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 800,
        // Set to at least 552 to ensure not overflow when scaling window size down.
        mainAxisSpacing: 20,
        mainAxisExtent: 552,
        crossAxisSpacing: 20,
      ),
      children: ret,
    );
  }
}
