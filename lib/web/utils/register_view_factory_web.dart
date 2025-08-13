import 'dart:ui' as ui;

typedef ViewFactory = dynamic Function(int viewId);

void registerViewFactory(String viewType, ViewFactory viewFactory) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, viewFactory);
}
