import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tsdm_client/features/jump_page/cubit/jump_page_cubit.dart';
import 'package:tsdm_client/features/jump_page/widgets/jump_page_dialog.dart';
import 'package:tsdm_client/generated/i18n/strings.g.dart';

/// App bar actions.
enum MenuActions {
  /// Refresh current page.
  refresh,

  /// Copy the url of current page to clipboard.
  copyUrl,

  /// Open the url of current page in external  browser.
  openInBrowser,

  /// Go back to top of the page.
  backToTop,
}

/// A app bar contains list and provides features including:
///
/// * Jump to the global search page.
/// * Specified title.
/// * Jump page.
class ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Constructor.
  const ListAppBar({
    required this.onSearch,
    this.title,
    this.bottom,
    this.onSelected,
    this.onJumpPage,
    super.key,
  });

  /// Callback that should navigate to global search page.
  final FutureOr<void> Function() onSearch;

  /// Jump to another page in the list.
  ///
  /// Parameter is the page number.
  final FutureOr<void> Function(int)? onJumpPage;

  /// Widget title.
  final String? title;

  /// Callback when app bar actions selected.
  final PopupMenuItemSelected<MenuActions>? onSelected;

  /// Extra bottom widget.
  final PreferredSizeWidget? bottom;

  Future<void> _jumpPage(
    BuildContext context,
    int currentPage,
    int totalPages,
  ) async {
    if (currentPage <= 0 && currentPage > totalPages) {
      return;
    }
    final page = await showDialog<int>(
      context: context,
      builder: (context) => JumpPageDialog(
        min: 1,
        current: currentPage,
        max: totalPages,
      ),
    );
    if (page == null || page == currentPage) {
      return;
    }
    await onJumpPage?.call(page);
  }

  @override
  Widget build(BuildContext context) {
    var currentPage = 0;
    var totalPages = 0;
    var canJumpPage = false;
    if (onJumpPage != null) {
      final jumpPageState = context.read<JumpPageCubit>().state;
      currentPage = jumpPageState.currentPage;
      totalPages = jumpPageState.totalPages;
      canJumpPage = jumpPageState.canJumpPage;
    }
    return AppBar(
      title: title == null ? null : Text(title!),
      bottom: bottom,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_outlined),
          onPressed: onSearch,
        ),
        if (onJumpPage != null)
          TextButton(
            onPressed: canJumpPage
                ? () async => _jumpPage(context, currentPage, totalPages)
                : null,
            child: Text('${canJumpPage ? currentPage : "-"}'),
          ),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: MenuActions.refresh,
              child: Row(
                children: [
                  const Icon(Icons.refresh_outlined),
                  Text(context.t.networkList.actionRefresh),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuActions.copyUrl,
              child: Row(
                children: [
                  const Icon(Icons.copy_outlined),
                  Text(context.t.networkList.actionCopyUrl),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuActions.openInBrowser,
              child: Row(
                children: [
                  const Icon(Icons.launch_outlined),
                  Text(context.t.networkList.actionOpenInBrowser),
                ],
              ),
            ),
            PopupMenuItem(
              value: MenuActions.backToTop,
              child: Row(
                children: [
                  const Icon(Icons.vertical_align_top_outlined),
                  Text(context.t.networkList.actionBackToTop),
                ],
              ),
            ),
          ],
          onSelected: onSelected,
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
