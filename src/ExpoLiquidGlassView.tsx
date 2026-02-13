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
  const { children, containerStyle, style, ...nativeProps } = props;

  return (
    <NativeView
      {...nativeProps}
      style={[styles.wrapper, style]}
    >
      {children ? (
        <View style={[styles.container, containerStyle]}>{children}</View>
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
