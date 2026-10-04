import 'package:flutter/material.dart';

class SignAdjustmentsPopup extends StatelessWidget {
  const SignAdjustmentsPopup(
      {super.key,
      required this.title,
      required this.doneLabel,
      required this.child,
      required this.onDone});
  final String title;
  final String doneLabel;
  final Widget child;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            12, 12, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
        child: LayoutBuilder(builder: (context, constraints) {
          return Align(
            alignment: AlignmentDirectional.topEnd,
            child: SizedBox(
              width: 320,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight),
                child: Material(
                  key: const ValueKey('sign-adjustments-popup'),
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
                        child: Row(children: [
                          Expanded(
                              child: Text(title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          IconButton(
                              onPressed: onDone,
                              tooltip: MaterialLocalizations.of(context)
                                  .closeButtonTooltip,
                              icon: const Icon(Icons.close)),
                        ]),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: child,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            key: const ValueKey('editor-done'),
                            onPressed: onDone,
                            icon: const Icon(Icons.check),
                            label: Text(doneLabel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
