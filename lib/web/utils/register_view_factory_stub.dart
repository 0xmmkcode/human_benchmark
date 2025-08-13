typedef ViewFactory = dynamic Function(int viewId);

void registerViewFactory(String viewType, ViewFactory viewFactory) {
  // No-op on non-web platforms
}
