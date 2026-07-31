// Learn more https://docs.expo.io/guides/customizing-metro
const { getDefaultConfig } = require("expo/metro-config");
const path = require("path");

const config = getDefaultConfig(__dirname);

const root = path.resolve(__dirname, "..");

// npm v7+ will install ../node_modules/react and ../node_modules/react-native because of peerDependencies.
// To prevent the incompatible react-native between ./node_modules/react-native and ../node_modules/react-native,
// excludes the one from the parent folder when bundling.
config.resolver.blockList = [
  ...Array.from(config.resolver.blockList ?? []),
  new RegExp(path.resolve(root, "node_modules", "react").replace(/\\/g, "\\\\")),
  new RegExp(
    path.resolve(root, "node_modules", "react-native").replace(/\\/g, "\\\\")
  ),
  // The compiled output is a second copy of everything in `src`. Because the
  // repo root is a watch folder, Metro can otherwise reach the same component
  // through both `build/` and `src/` and end up with two module instances —
  // which throws "Tried to register two views with the same name" from
  // `requireNativeView`, and "Cannot assign to property 'exports'" when the two
  // copies disagree about ESM/CJS interop. The example always uses source.
  new RegExp(`^${path.resolve(root, "build").replace(/\\/g, "\\\\")}/.*$`),
];

config.resolver.nodeModulesPaths = [
  path.resolve(__dirname, "./node_modules"),
  path.resolve(root, "node_modules"),
];

// Must match the package name exactly, and must agree with the `paths` entry in
// example/tsconfig.json. The previous value was `expo-liquid-glass` — missing
// the `-view` — so imports never matched it and fell through to a different
// resolver, producing the duplicate-module errors above.
config.resolver.extraNodeModules = {
  "expo-liquid-glass-view": path.resolve(root, "src"),
};

config.watchFolders = [root];

// NOTE: no `transformer.getTransformOptions` override here. The old template
// forced `experimentalImportSupport: false`, which contradicts what
// babel-preset-expo emits on SDK 56 and is the direct cause of
// "Cannot assign to property 'exports' which has only a getter" when Fast
// Refresh re-evaluates a module. Metro's defaults are correct.

module.exports = config;
