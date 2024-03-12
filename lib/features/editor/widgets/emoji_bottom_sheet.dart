import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsdm_client/constants/layout.dart';
import 'package:tsdm_client/features/editor/bloc/emoji_bloc.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';
import 'package:tsdm_client/utils/retry_button.dart';

/// Show a bottom sheet that provides emojis in editor.
Future<void> showEmojiBottomSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: _EmojiBottomSheet.new,
  );
}

/// Widget to show all available emojis can use in editor.
class _EmojiBottomSheet extends StatefulWidget {
  /// Constructor.
  const _EmojiBottomSheet(this.context);

  final BuildContext context;

  @override
  State<_EmojiBottomSheet> createState() => _EmojiBottomSheetState();
}

class _EmojiBottomSheetState extends State<_EmojiBottomSheet> {
  Widget _buildBody(BuildContext context, EmojiState state) {
    return const Column(
      children: [
        SizedBox(height: 50, child: Center(child: Text('emoji'))),
        sizedBoxW10H10,
        Expanded(
          child: Text('all emoji'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmojiBloc(
        editRepository: RepositoryProvider.of(context),
      )..add(EmojiFetchFromCacheEvent()),
      child: BlocBuilder<EmojiBloc, EmojiState>(
        builder: (context, state) {
          final body = switch (state.status) {
            EmojiStatus.initial || EmojiStatus.loading => Center(
                child: Padding(
                  padding: edgeInsetsL20R20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      sizedBoxW10H10,
                      Expanded(
                        child: Text(
                          context.t.bbcodeEditor.emoji.downloading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            EmojiStatus.failed => buildRetryButton(context, () {
                context.read<EmojiBloc>().add(EmojiFetchFromServerEvent());
              }),
            EmojiStatus.success => _buildBody(context, state),
          };

          return Scaffold(
            body: Padding(
              padding: edgeInsetsL15T15R15B15,
              child: body,
            ),
          );
        },
      ),
    );
  }
}
