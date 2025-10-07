/// Utility class to map rank order numbers to their corresponding image assets
class RankImageMapper {
  static const String _basePath = 'assets/ranks/';
  static const String _fileExtension = '.png';

  /// Maps a rank order (1-10) to its corresponding image asset path
  /// Returns the full asset path for the rank image
  static String getImagePath(int order) {
    if (order >= 1 && order <= 10) {
      return '$_basePath$order$_fileExtension';
    }
    // Default fallback to rank 1 image
    return '${_basePath}1$_fileExtension';
  }

  /// Gets all valid rank image paths (1-10)
  static List<String> getAllImagePaths() {
    return List.generate(10, (index) => getImagePath(index + 1));
  }

  /// Checks if a rank order is valid (1-10)
  static bool isValidOrder(int order) {
    return order >= 1 && order <= 10;
  }

  /// Gets the rank order from a rank image path
  /// Returns null if the path is not a valid rank image
  static int? getOrderFromPath(String imagePath) {
    if (!imagePath.startsWith(_basePath) ||
        !imagePath.endsWith(_fileExtension)) {
      return null;
    }

    final fileName = imagePath.substring(
      _basePath.length,
      imagePath.length - _fileExtension.length,
    );
    final order = int.tryParse(fileName);

    return isValidOrder(order ?? 0) ? order : null;
  }
}
