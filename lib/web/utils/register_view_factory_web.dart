import 'dart:ui_web' as ui;

typedef ViewFactory = dynamic Function(int viewId);

void registerViewFactory(String viewType, ViewFactory viewFactory) {
  ui.platformViewRegistry.registerViewFactory(viewType, viewFactory);
}
