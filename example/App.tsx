import { StyleSheet } from "react-native";
import { useState } from "react";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import LiquidGlassDemo from "./screens/LiquidGlassDemo";
import ScrollDemo from "./screens/ScrollDemo";
import FlatListDemo from "./screens/FlatListDemo";
import { KeyboardProvider } from "react-native-keyboard-controller";
import {
  configureReanimatedLogger,
  ReanimatedLogLevel,
} from "react-native-reanimated";

configureReanimatedLogger({
  level: ReanimatedLogLevel.warn,
  strict: false,
});

const DEMOS = {
  scroll: ScrollDemo,
  drag: LiquidGlassDemo,
  flatlist: FlatListDemo,
} as const;

type DemoKey = keyof typeof DEMOS;

export default function App() {
  const [demo] = useState<DemoKey>("drag");
  const Current = DEMOS[demo];

  return (
    <KeyboardProvider enabled>
      <GestureHandlerRootView style={styles.container}>
        <Current />
      </GestureHandlerRootView>
    </KeyboardProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: "#0d0d0d",
    flex: 1,
  },
  switcher: {
    position: "absolute",
    top: 60,
    right: 16,
    flexDirection: "row",
    gap: 6,
    backgroundColor: "#00000066",
    borderRadius: 10,
    padding: 4,
  },
  tab: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 7 },
  tabActive: { backgroundColor: "#ffffff2e" },
  tabText: { color: "#c7cedb", fontSize: 12 },
  tabTextActive: { color: "#fff", fontWeight: "700" },
});
