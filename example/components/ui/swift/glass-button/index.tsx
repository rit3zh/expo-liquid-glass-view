import { LiquidGlassView } from "expo-liquid-glass-view";
import React, { memo } from "react";
import { Pressable, StyleProp, StyleSheet, ViewStyle } from "react-native";
import Animated, { LinearTransition } from "react-native-reanimated";
const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

export const GlassButton: React.FC<
  React.PropsWithChildren<{
    onPress?: () => void;
    style?: StyleProp<ViewStyle>;
  }>
> = memo(
  ({
    children,
    onPress,
    style,
  }: React.PropsWithChildren<{
    onPress?: () => void;
    style?: StyleProp<ViewStyle>;
  }>): React.ReactNode & React.JSX.Element => {
    return (
      <AnimatedPressable onPress={onPress} layout={LinearTransition}>
        <LiquidGlassView
          style={styles.pressable}
          tint={"#111111"}
          cornerRadius={99}
          interactive
        >
          {children}
        </LiquidGlassView>
      </AnimatedPressable>
    );
  },
);

const styles = StyleSheet.create({
  container: {},
  pressable: {
    alignSelf: "flex-start",
    marginTop: 6,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 99,
  },
});
