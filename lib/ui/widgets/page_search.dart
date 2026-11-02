import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../l10n/strings.dart';

/// The search state of one page: whether the field is open and what is typed.
/// Every page that can be searched owns one, so search always means "search
/// here" and the page decides what that filters.
class PageSearch extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final FocusNode focus = FocusNode();
  bool _open = false;

  bool get isOpen => _open;
  String get query => controller.text.trim();
  bool get isSearching => _open && query.isNotEmpty;

  void open() {
    _open = true;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  void close() {
    _open = false;
    controller.clear();
    focus.unfocus();
    notifyListeners();
  }

  void toggle() => _open ? close() : open();

  void changed() => notifyListeners();

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    super.dispose();
  }
}

/// The magnifier in a page header; it turns into a close button while the
/// field is open.
class PageSearchButton extends StatelessWidget {
  const PageSearchButton({super.key, required this.search});

  final PageSearch search;

  @override
  Widget build(BuildContext context) {
    final colors = context.mawjColors;
    final strings = context.strings;
    return ListenableBuilder(
      listenable: search,
      builder: (context, _) {
        return IconButton(
          tooltip: search.isOpen ? strings.clearSearch : strings.search,
          onPressed: search.toggle,
          icon: Icon(
            search.isOpen ? Icons.close_rounded : Icons.search_rounded,
            color: search.isOpen ? colors.accent : null,
          ),
        );
      },
    );
  }
}

/// The search field that slides open under a page header.
class PageSearchField extends StatelessWidget {
  const PageSearchField({super.key, required this.search, required this.hint});

  final PageSearch search;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: search,
      builder: (context, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: search.isOpen
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: CallbackShortcuts(
                    bindings: <ShortcutActivator, VoidCallback>{
                      const SingleActivator(LogicalKeyboardKey.escape):
                          search.close,
                    },
                    child: TextField(
                      controller: search.controller,
                      focusNode: search.focus,
                      autocorrect: false,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => search.changed(),
                      decoration: InputDecoration(
                        hintText: hint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.controller.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  search.controller.clear();
                                  search.changed();
                                },
                                icon: const Icon(Icons.backspace_outlined),
                              ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}
