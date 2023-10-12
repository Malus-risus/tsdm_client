import 'package:flutter/material.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';

/// Show a dialog with given [title] and [message], with a ok button to navigate
/// back.
Future<void> showMessageSingleButtonDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        scrollable: true,
        title: Text(title),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(context.t.general.ok),
          )
        ],
      );
    },
  );
}
