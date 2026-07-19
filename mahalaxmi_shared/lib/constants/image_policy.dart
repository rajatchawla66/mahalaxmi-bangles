class ImagePolicy {
  // Product/item images
  static const double productAspectRatio = 4 / 5; // 4:5 portrait
  static const int productOutputWidth = 1080;
  static const int productOutputHeight = 1350;
  static const int productMinAcceptWidth = 800;
  static const int productMinAcceptHeight = 1000;
  static const int productJpegQuality = 90; // 88–92% quality range

  // Category cover images
  static const double categoryAspectRatio = 3 / 4; // 3:4 portrait
  static const int categoryOutputWidth = 900;
  static const int categoryOutputHeight = 1200;
  static const int categoryMinAcceptWidth = 750;
  static const int categoryMinAcceptHeight = 1000;
  static const int categoryJpegQuality = 87; // 87% quality
}
