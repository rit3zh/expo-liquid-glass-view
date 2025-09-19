import { requireNativeView } from "expo";
import * as React from "react";
import { StyleSheet, View } from "react-native";
import type { ExpoLiquidGlassViewProps } from "./ExpoLiquidGlassView.types";

const NativeView: React.ComponentType<ExpoLiquidGlassViewProps> =
  requireNativeView<ExpoLiquidGlassViewProps>(
    "ExpoLiquidGlass",
    "ExpoLiquidGlassView"
  );

export function ExpoLiquidGlassView(props: ExpoLiquidGlassViewProps) {
  return (
    <NativeView
      {...props}
      style={[styles.wrapper, props.style]}
      key={Math.random().toString()}
    >
      {props.children ? (
        <View style={styles.container}>{props.children}</View>
      ) : null}
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
