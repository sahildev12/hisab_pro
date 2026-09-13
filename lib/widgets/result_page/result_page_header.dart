import 'package:flutter/material.dart';

import '../hisab_page_header.dart';

class ResultPageHeader extends StatelessWidget {
  const ResultPageHeader({
    super.key,
    required this.onBack,
    required this.onShare,
    this.onViewHistory,
    this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback? onViewHistory;
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    return HisabPageHeader(
      title: 'Result',
      onBack: onBack,
      actions: [
        HisabHeaderIconButton(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onPressed: onShare,
        ),
        Builder(
          builder: (buttonContext) {
            return HisabHeaderIconButton(
              icon: Icons.more_vert,
              tooltip: 'More',
              onPressed: () => _openMenu(buttonContext),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openMenu(BuildContext buttonContext) async {
    final items = <HisabMenuItem>[];
    if (onViewHistory != null) {
      items.add(
        HisabMenuItem(
          value: 'history',
          label: 'View History',
          icon: Icons.history_outlined,
          onTap: onViewHistory!,
        ),
      );
    }
    if (onDelete != null) {
      items.add(
        HisabMenuItem(
          value: 'delete',
          label: 'Delete Calculation',
          icon: Icons.delete_outline,
          onTap: () => onDelete!(),
          destructive: true,
        ),
      );
    }
    if (items.isEmpty) return;

    final box = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);

    await showHisabHeaderMenu(
      context: buttonContext,
      position: RelativeRect.fromRect(
        Rect.fromPoints(topLeft, bottomRight),
        Offset.zero & overlay.size,
      ),
      items: items,
    );
  }
}
