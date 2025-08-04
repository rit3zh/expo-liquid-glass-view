import { requireNativeView } from "expo";
import * as React from "react";
import type { ExpoLiquidGlassViewProps } from "./ExpoLiquidGlassView.types";
import { StyleSheet, View } from "react-native";

const NativeView: React.ComponentType<ExpoLiquidGlassViewProps> =
  requireNativeView("ExpoLiquidGlass", "ExpoLiquidGlassView");

export function ExpoLiquidGlassView(props: ExpoLiquidGlassViewProps) {
  return (
    <NativeView {...props} style={[styles.wrapper, props.style]}>
      <View style={styles.container}>{props.children}</View>
    </NativeView>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignSelf: "flex-start",
  },
  container: {
    alignSelf: "flex-start",
    flexShrink: 1,
  },
});
