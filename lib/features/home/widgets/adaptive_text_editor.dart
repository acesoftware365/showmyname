import 'package:flutter/material.dart';

/// One editing task with persistent completion and a preview beside the form
/// only when both panes have enough space. The form keeps its identity on resize.
class AdaptiveTextEditor extends StatelessWidget {
  const AdaptiveTextEditor({
    super.key,
    required this.title,
    required this.doneLabel,
    required this.previewLabel,
    required this.preview,
    required this.form,
    required this.onDone,
  });

  final String title;
  final String doneLabel;
  final String previewLabel;
  final Widget Function(double height) preview;
  final Widget form;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: availableHeight * 0.94,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(children: [
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: onDone,
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760 &&
                    constraints.maxHeight >= 300 &&
                    media.textScaler.scale(14) < 21;
                Widget previewPanel(double height) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previewLabel,
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 10),
                        preview(height),
                      ],
                    );
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: previewPanel(
                                (constraints.maxHeight - 76).clamp(120, 320))),
                        const SizedBox(width: 24),
                        Expanded(child: SingleChildScrollView(child: form)),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      form,
                      const SizedBox(height: 20),
                      previewPanel(
                          (constraints.maxHeight * .32).clamp(96, 180)),
                    ],
                  ),
                );
              }),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 160, maxWidth: 360),
                    child: FilledButton.icon(
                      key: const ValueKey('editor-done'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                      onPressed: onDone,
                      icon: const Icon(Icons.check),
                      label: Text(doneLabel),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeComposition extends StatelessWidget {
  const HomeComposition(
      {super.key, required this.preview, required this.children});
  final Widget preview;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760 &&
          MediaQuery.textScalerOf(context).scale(14) < 21;
      final controls = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: preview),
            const SizedBox(width: 24),
            SizedBox(width: 320, child: controls),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [preview, const SizedBox(height: 16), controls],
      );
    });
  }
}
