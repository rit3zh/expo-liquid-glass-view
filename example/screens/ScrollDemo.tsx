import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { LiquidGlassView } from "expo-liquid-glass-view";

const SHAPES = [
  { color: "#ff2d55", size: 96, radius: 48 },
  { color: "#ffcc00", size: 120, radius: 24 },
  { color: "#34c759", size: 80, radius: 8 },
  { color: "#0a84ff", size: 140, radius: 70 },
  { color: "#af52de", size: 100, radius: 32 },
  { color: "#ff9f0a", size: 110, radius: 55 },
];

const PARAGRAPHS = [
  "Scroll the content underneath the bars. The glass samples whatever is behind it, so the colours and edges shift as the shapes pass through.",
  "The pinned bars never move, which means the backdrop capture keeps running and you are seeing content change rather than the glass change.",
  "Refraction is strongest at the rim, where the sample coordinate contracts toward the centre. Watch a shape's edge distort as it crosses the boundary.",
  "Everything below iOS 26 is drawn by the custom Metal pipeline. On iOS 26 the same component uses UIGlassEffect instead.",
];

export default function ScrollDemo() {
  return (
    <View style={styles.root}>
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.title}>Liquid Glass</Text>
        <Text style={styles.subtitle}>over scrolling content</Text>

        {PARAGRAPHS.map((text, i) => (
          <View key={i} style={styles.block}>
            <View style={styles.shapeRow}>
              {SHAPES.slice(i % 3, (i % 3) + 3).map((shape, j) => (
                <View
                  key={j}
                  style={{
                    width: shape.size,
                    height: shape.size,
                    borderRadius: shape.radius,
                    backgroundColor: shape.color,
                  }}
                />
              ))}
            </View>

            <Text style={styles.heading}>Section {i + 1}</Text>
            <Text style={styles.body}>{text}</Text>
          </View>
        ))}

        <View style={styles.stripes}>
          {Array.from({ length: 24 }).map((_, i) => (
            <View
              key={i}
              style={[
                styles.stripe,
                { backgroundColor: i % 2 ? "#ffffff" : "#111318" },
              ]}
            />
          ))}
        </View>
        <Text style={styles.footer}>End of content</Text>
      </ScrollView>

      <LiquidGlassView
        style={styles.navBar}
        containerStyle={styles.barContent}
        variant="regular"
        renderer="native"
      >
        <Text style={styles.barText}>Nav bar</Text>
      </LiquidGlassView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0b0d12" },
  scroll: { flex: 1 },
  content: {
    paddingTop: 130,
    paddingBottom: 180,
    paddingHorizontal: 20,
    gap: 34,
  },

  title: { color: "#fff", fontSize: 34, fontWeight: "800" },
  subtitle: { color: "#8e98a8", fontSize: 15, marginTop: -26 },

  block: { gap: 12 },
  shapeRow: { flexDirection: "row", gap: 14, alignItems: "center" },
  heading: { color: "#fff", fontSize: 20, fontWeight: "700", marginTop: 6 },
  body: { color: "#aab3c0", fontSize: 15, lineHeight: 22 },

  stripes: { borderRadius: 16, overflow: "hidden" },
  stripe: { height: 12 },

  footer: {
    color: "#5c6675",
    fontSize: 13,
    textAlign: "center",
    marginTop: 10,
  },

  navBar: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 110,
  },
  tabBar: {
    position: "absolute",
    bottom: 40,
    left: 20,
    right: 20,
    height: 72,
  },
  barContent: {
    alignItems: "center",
    justifyContent: "flex-end",
    paddingBottom: 14,
  },
  barText: { color: "#fff", fontSize: 15, fontWeight: "600" },
});
