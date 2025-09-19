import { requireNativeView } from "expo";
import * as React from "react";
import { StyleProp, StyleSheet, View, ViewStyle } from "react-native";

interface ExpoLiquidGlassContainerProps {
  morph?: number;
  style?: StyleProp<ViewStyle>;
  children?: React.ReactNode;
}

const NativeView: React.ComponentType<any> = requireNativeView<any>(
  "ExpoLiquidGlass",
  "ExpoLiquidGlassContainer"
);
export function ExpoLiquidGlassContainer(props: ExpoLiquidGlassContainerProps) {
  return (
    <NativeView
      {...props}
      spacing={props.morph ?? 200}
      style={[styles.wrapper, props.style]}
      key={Math.random().toString()}
    >
      <View style={styles.container}>{props.children}</View>
    </NativeView>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    // alignSelf: "flex-start",
  },
  container: {
    alignSelf: "flex-start",
    flexShrink: 1,
  },
});
