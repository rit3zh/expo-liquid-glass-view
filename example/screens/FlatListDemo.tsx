import React from "react";
import {
  FlatList,
  Image,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from "react-native";
import { LiquidGlassView } from "expo-liquid-glass-view";

const BACKGROUND =
  "https://i.pinimg.com/736x/53/19/87/531987c992d8058ee7f9837f40dae12c.jpg";

type Track = {
  id: string;
  title: string;
  artist: string;
  duration: string;
  accent: string;
};

const TRACKS: Track[] = [
  {
    id: "1",
    title: "Slow Burn",
    artist: "Kacey Musgraves",
    duration: "4:01",
    accent: "#ff2d55",
  },
  {
    id: "2",
    title: "Nightcall",
    artist: "Kavinsky",
    duration: "4:18",
    accent: "#0a84ff",
  },
  {
    id: "3",
    title: "Rêverie",
    artist: "Debussy",
    duration: "5:12",
    accent: "#af52de",
  },
  {
    id: "4",
    title: "Redbone",
    artist: "Childish Gambino",
    duration: "5:26",
    accent: "#ff9f0a",
  },
  {
    id: "5",
    title: "Weird Fishes",
    artist: "Radiohead",
    duration: "5:18",
    accent: "#34c759",
  },
  {
    id: "6",
    title: "Motion Picture",
    artist: "Grizzly Bear",
    duration: "3:44",
    accent: "#ffcc00",
  },
  {
    id: "7",
    title: "Glassworks",
    artist: "Philip Glass",
    duration: "6:20",
    accent: "#5ac8fa",
  },
  {
    id: "8",
    title: "An Ending",
    artist: "Brian Eno",
    duration: "4:32",
    accent: "#ff375f",
  },
  {
    id: "9",
    title: "Teardrop",
    artist: "Massive Attack",
    duration: "5:29",
    accent: "#64d2ff",
  },
  {
    id: "10",
    title: "Avril 14th",
    artist: "Aphex Twin",
    duration: "2:05",
    accent: "#bf5af2",
  },
  {
    id: "11",
    title: "Svefn-g-englar",
    artist: "Sigur Rós",
    duration: "10:04",
    accent: "#30d158",
  },
  {
    id: "12",
    title: "Nuvole Bianche",
    artist: "Ludovico Einaudi",
    duration: "5:57",
    accent: "#ff6482",
  },
];

function TrackRow({ track, index }: { track: Track; index: number }) {
  return (
    <LiquidGlassView
      renderer="metal"
      variant="regular"
      cornerRadius={22}
      style={styles.row}
      containerStyle={styles.rowContent}
      metal={{
        blurRadius: 6,
        frost: 0.28,
        saturation: 1.7,
        refraction: { amount: 70, width: 22, height: 22, depth: 0.8 },
        dispersion: { amount: 6 },
        highlight: { intensity: 0.28, angle: 135 },
        border: { width: 1, opacity: 0.28 },
      }}
    >
      <View style={[styles.artwork, { backgroundColor: track.accent }]}>
        <Text style={styles.artworkText}>{index + 1}</Text>
      </View>

      <View style={styles.rowText}>
        <Text style={styles.rowTitle} numberOfLines={1}>
          {track.title}
        </Text>
        <Text style={styles.rowSubtitle} numberOfLines={1}>
          {track.artist}
        </Text>
      </View>

      <Text style={styles.rowDuration}>{track.duration}</Text>
    </LiquidGlassView>
  );
}

export default function FlatListDemo() {
  const { width, height } = useWindowDimensions();

  return (
    <View style={styles.root}>
      <Image
        source={{ uri: BACKGROUND }}
        style={[styles.background, { width, height }]}
        resizeMode="cover"
      />

      <FlatList
        data={TRACKS}
        keyExtractor={(item) => item.id}
        renderItem={({ item, index }) => (
          <TrackRow track={item} index={index} />
        )}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        ListHeaderComponent={
          <View style={styles.header}>
            <Text style={styles.title}>Liquid Glass</Text>
            <Text style={styles.subtitle}>FlatList · Metal renderer</Text>
          </View>
        }
      />

      <LiquidGlassView
        renderer="native"
        variant="clear"
        cornerRadius={28}
        style={styles.tabBar}
        containerStyle={styles.tabBarContent}
        metal={{
          blurRadius: 8,
          frost: 0.18,
          saturation: 1.9,
          refraction: { amount: 90, width: 26, height: 26, depth: 1 },
          dispersion: { amount: 8 },
          highlight: { intensity: 0.32, angle: 135 },
          border: { width: 1, opacity: 0.32 },
        }}
      >
        {["Library", "Search", "Radio"].map((label, i) => (
          <Text key={label} style={[styles.tab, i === 0 && styles.tabActive]}>
            {label}
          </Text>
        ))}
      </LiquidGlassView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#0b0d12" },

  background: { position: "absolute", top: 0, left: 0 },

  list: { paddingTop: 90, paddingBottom: 160, paddingHorizontal: 18, gap: 14 },

  header: { marginBottom: 20 },
  title: { color: "#fff", fontSize: 34, fontWeight: "800" },
  subtitle: { color: "#d7dbe4cc", fontSize: 14, marginTop: 4 },

  row: { height: 78 },
  rowContent: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 14,
    gap: 14,
  },

  artwork: {
    width: 50,
    height: 50,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  artworkText: { color: "#fff", fontSize: 16, fontWeight: "800" },

  rowText: { flex: 1, gap: 3 },
  rowTitle: { color: "#fff", fontSize: 16, fontWeight: "700" },
  rowSubtitle: { color: "#ffffffb3", fontSize: 13 },
  rowDuration: {
    color: "#ffffff8c",
    fontSize: 13,
    fontVariant: ["tabular-nums"],
  },

  tabBar: { position: "absolute", left: 20, right: 20, bottom: 44, height: 68 },
  tabBarContent: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-around",
  },
  tab: { color: "#ffffff99", fontSize: 14, fontWeight: "600" },
  tabActive: { color: "#fff", fontWeight: "800" },
});
