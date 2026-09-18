import 'package:flutter/material.dart';

import '../models/date_key.dart';
import '../models/memo.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final palette = ThemeScope.of(context).palette;
        final textTheme = Theme.of(context).textTheme;
        final memos = controller.sortedMemos;
        final inset = MediaQuery.viewInsetsOf(context).bottom;

        return ListView(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 24 + inset),
          children: [
            Text('메모', style: textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(
              '떠오른 말을 짧게 남겨 두세요. 홈 화면 위젯에도 올릴 수 있어요.',
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _openEditor(context),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('메모 추가'),
            ),
            const SizedBox(height: 18),
            if (memos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Text(
                  '아직 메모가 없어요. 마음에 남는 한 줄을 적어 보세요.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final memo in memos) ...[
                AppCard(
                  onTap: () => _openEditor(context, memo: memo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              memo.title.trim().isEmpty ? '제목 없음' : memo.title,
                              style: textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: memo.pinned ? '위젯에서 내리기' : '위젯에 올리기',
                            onPressed: () => controller.toggleMemoPinned(memo.id),
                            icon: Icon(
                              memo.pinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 18,
                              color: memo.pinned
                                  ? palette.accent
                                  : palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (memo.body.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          memo.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        DateKey.from(memo.updatedAt),
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context, {Memo? memo}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MemoEditorScreen(
          controller: controller,
          memo: memo,
        ),
      ),
    );
  }
}

class MemoEditorScreen extends StatefulWidget {
  const MemoEditorScreen({
    super.key,
    required this.controller,
    this.memo,
  });

  final AppController controller;
  final Memo? memo;

  @override
  State<MemoEditorScreen> createState() => _MemoEditorScreenState();
}

class _MemoEditorScreenState extends State<MemoEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.memo?.title ?? '');
    _body = TextEditingController(text: widget.memo?.body ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.of(context).palette;
    final textTheme = Theme.of(context).textTheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.memo == null ? '새 메모' : '메모 수정'),
        actions: [
          if (widget.memo != null)
            IconButton(
              tooltip: '삭제',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(22, 8, 22, 24 + inset),
        children: [
          TextField(
            controller: _title,
            style: textTheme.titleLarge,
            decoration: const InputDecoration(
              hintText: '제목',
              border: InputBorder.none,
            ),
          ),
          TextField(
            controller: _body,
            minLines: 8,
            maxLines: null,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: '남겨 두고 싶은 말을 적어 보세요.',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.controller.upsertMemo(
      id: widget.memo?.id,
      title: _title.text,
      body: _body.text,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final memo = widget.memo;
    if (memo == null) {
      return;
    }
    await widget.controller.deleteMemo(memo.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
