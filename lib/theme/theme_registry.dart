class ThemeInfo {
  final String id;
  final String assetPath;
  final List<String> swatchKeys;

  const ThemeInfo({
    required this.id,
    required this.assetPath,
    required this.swatchKeys,
  });
}

const kThemeRegistry = [
  ThemeInfo(
    id: "vampire", 
    assetPath: "assets/themes/vampire.json",
    swatchKeys: ["background", "red", "yellow", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "gruvbox-dark", 
    assetPath: "assets/themes/gruvbox-dark.json",
    swatchKeys: ["background", "red", "green", "yellow", "blue"],
  ),
  ThemeInfo(
    id: "gruvbox-light", 
    assetPath: "assets/themes/gruvbox-light.json",
    swatchKeys: ["background", "red", "green", "yellow", "blue"],
  ),
  ThemeInfo(
    id: "solarized-dark", 
    assetPath: "assets/themes/solarized-dark.json",
    swatchKeys: ["background", "blue", "cyan", "green", "magenta"],
  ),
  ThemeInfo(
    id: "solarized-light", 
    assetPath: "assets/themes/solarized-light.json",
    swatchKeys: ["background", "blue", "cyan", "green", "magenta"],
  ),
  ThemeInfo(
    id: "dracula", 
    assetPath: "assets/themes/dracula.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "nord", 
    assetPath: "assets/themes/nord.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "monokai", 
    assetPath: "assets/themes/monokai.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "one-dark", 
    assetPath: "assets/themes/one-dark.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "tokyo-night-storm", 
    assetPath: "assets/themes/tokyo-night-storm.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  ThemeInfo(
    id: "catppuccin-mocha", 
    assetPath: "assets/themes/catppuccin-mocha.json",
    swatchKeys: ["background", "red", "green", "blue", "magenta"],
  ),
  // Keep existing themes for compatibility
  ThemeInfo(
    id: "default", 
    assetPath: "assets/themes/default.json",
    swatchKeys: ["background", "primary", "secondary", "accent", "error"],
  ),
  ThemeInfo(
    id: "light", 
    assetPath: "assets/themes/light.json",
    swatchKeys: ["background", "primary", "secondary", "accent", "error"],
  ),
  ThemeInfo(
    id: "dark", 
    assetPath: "assets/themes/dark.json",
    swatchKeys: ["background", "primary", "secondary", "accent", "error"],
  ),
];