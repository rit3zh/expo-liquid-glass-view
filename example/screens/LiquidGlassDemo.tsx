import { View, StyleSheet, Text } from "react-native";
import { useCallback, useMemo, useState } from "react";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  WithSpringConfig,
  WithTimingConfig,
} from "react-native-reanimated";
import {
  LiquidGlassView,
  GlassMetalOptions,
  GlassVariant,
  GlassRenderer,
} from "expo-liquid-glass-view";
import { GlassButton } from "../components/ui/swift/glass-button";
import { MatchedText } from "../components/ui/swift/matched-text/swiftui+text";
import { useFonts } from "expo-font";

const SPRING: WithSpringConfig = {
  damping: 14,
  stiffness: 180,
  mass: 0.5,
} as const;

const FADE: WithTimingConfig = {
  duration: 320,
} as const;

const _METAL_OPTIONS: GlassMetalOptions = {
  refraction: {
    depth: 1,
    height: 40,
    amount: 40,
    width: 25,
  },
  noise: 0.5,
  saturation: -5,
};

export default function LiquidGlassDemo() {
  const [fontLoaded] = useFonts({
    SfProBold: require("../assets/fonts/sf-pro-rounded/bold.otf"),
    SfProMedium: require("../assets/fonts/sf-pro-rounded/medium.otf"),
    SfProRegular: require("../assets/fonts/sf-pro-rounded/regular.otf"),
  });

  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const scale = useSharedValue(1);
  const startX = useSharedValue(0);
  const startY = useSharedValue(0);
  const opacity = useSharedValue(1);

  const [visible, setVisible] = useState(true);

  const toggleGlass = useCallback(() => {
    setIndex((prev) => (prev + 1) % 2);
    setVisible((current) => {
      const next = !current;
      opacity.value = withTiming(next ? 1 : 0, FADE);
      return next;
    });
  }, [opacity]);

  const pan = useMemo(
    () =>
      Gesture.Pan()
        .enabled(visible)

        .onBegin(() => {
          startX.value = translateX.value;
          startY.value = translateY.value;
          scale.value = withSpring(1.06, SPRING);
        })
        .onUpdate((event) => {
          translateX.value = startX.value + event.translationX;
          translateY.value = startY.value + event.translationY;
        })

        .onFinalize(() => {
          scale.value = withSpring(1, SPRING);
        }),
    [translateX, translateY, scale, startX, startY, visible],
  );

  const glassStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));
  const [index, setIndex] = useState<number>(0);

  return (
    <View style={styles.container}>
      <View style={styles.article}>
        <Text style={styles.eyebrow}>Framework Preview</Text>

        <Text
          style={[
            styles.heading,
            {
              fontFamily: fontLoaded ? "SfProBold" : undefined,
            },
          ]}
        >
          Liquid Glass
        </Text>

        <Text style={[styles.body]}>
          Liquid Glass recreates Apple's new translucent material using Metal,
          combining live blur, refraction, soft highlights, and dynamic edge
          distortion into a single native view. The effect reacts naturally to
          the content behind it, producing depth and subtle movement while
          maintaining excellent performance.
        </Text>

        <Text style={[styles.body]}>
          Drag the glass around the screen to see how the material bends light,
          samples the background, and continuously updates in real time. Every
          frame is rendered natively on the GPU for a smooth, responsive
          experience.
        </Text>

        <GlassButton onPress={toggleGlass}>
          <MatchedText texts={["Hide glass", "Show glass"]} index={index} />
        </GlassButton>
      </View>
      <GestureDetector gesture={pan}>
        <Animated.View
          pointerEvents={visible ? "auto" : "none"}
          style={[styles.glassWrapper, glassStyle]}
        >
          <LiquidGlassView
            style={styles.glassEffect}
            variant={GlassVariant.Clear}
            renderer={GlassRenderer.Metal}
            metal={_METAL_OPTIONS}
            cornerRadius={99}
          >
            <View style={styles.glassContent} />
          </LiquidGlassView>
        </Animated.View>
      </GestureDetector>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#F5F5F7",
    justifyContent: "center",
    paddingHorizontal: 28,
  },

  article: {
    gap: 18,
  },

  eyebrow: {
    fontSize: 15,
    fontWeight: "600",
    color: "#8E8E93",
    letterSpacing: -0.2,
    textTransform: "uppercase",
  },

  heading: {
    fontSize: 40,
    fontWeight: "700",
    letterSpacing: -1.4,
    color: "#111111",
  },

  body: {
    fontSize: 19,
    lineHeight: 31,
    fontWeight: "400",
    letterSpacing: -0.45,
    color: "#3A3A3C",
  },
  toggle: {
    alignSelf: "flex-start",
    marginTop: 6,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 99,
    backgroundColor: "#111111",
  },
  pressed: {
    opacity: 0.7,
  },
  toggleLabel: {
    fontSize: 16,
    fontWeight: "600",
    letterSpacing: -0.3,
    color: "#FFFFFF",
  },
  glassWrapper: {
    position: "absolute",
  },
  glassEffect: {
    width: 120,
    height: 120,
  },
  glassContent: {
    width: 120,
    height: 120,
  },
});
