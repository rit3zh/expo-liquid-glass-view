import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  ImageBackground,
} from "react-native";
import React, { useState, useEffect } from "react";

import { ExpoLiquidGlassView } from "expo-liquid-glass-view";

const WIDTH: number = 300;
const HEIGHT: number = 300;
const BORDER_RADIUS: number = 999;

const App = () => {
  const [videoLoaded, setVideoLoaded] = useState(false);
  const [forceUpdate, setForceUpdate] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => {
      setForceUpdate((prev) => prev + 1);
    }, 100);
    return () => clearTimeout(timer);
  }, [videoLoaded]);

  useEffect(() => {
    const interval = setInterval(() => {
      setForceUpdate((prev) => prev + 1);
    }, 1000);

    const cleanup = setTimeout(() => {
      clearInterval(interval);
    }, 3000);

    return () => {
      clearInterval(interval);
      clearTimeout(cleanup);
    };
  }, []);

  return (
    <ImageBackground
      style={styles.container}
      source={{
        uri: "https://i.pinimg.com/736x/eb/b4/68/ebb4685cc02c29730294e9c6ecdbec9f.jpg",
      }}
    >
      <View>
        <ExpoLiquidGlassView style={{ borderRadius: 100 }} cornerRadius={300}>
          <View
            style={{
              width: 400,
              height: 400,
              justifyContent: "center",
              alignItems: "center",
              borderRadius: 100,
            }}
          >
            <Text style={{ color: "black" }}>Hello, from liquid glass!</Text>
          </View>
        </ExpoLiquidGlassView>
      </View>
    </ImageBackground>
  );
};

export default App;

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "black",
    justifyContent: "center",
    alignItems: "center",
  },
  overlay: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  videoContainer: {
    position: "relative",
    width: WIDTH,
    height: HEIGHT,
    borderRadius: BORDER_RADIUS,
    overflow: "hidden",
    bottom: 100,
  },
  video: {
    width: WIDTH,
    height: HEIGHT,
    position: "absolute",
    top: 0,
    left: 0,
  },
  glassOverlay: {
    height: HEIGHT,
    width: WIDTH,
  },
  glassContent: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  innerView: {
    overflow: "hidden",
    width: WIDTH,
    height: HEIGHT,
    borderRadius: BORDER_RADIUS,
  },
  bottomContent: {
    width: "90%",
    alignItems: "center",
    justifyContent: "flex-end",
    height: "90%",
    position: "absolute",
  },
  statsCard: {
    width: "80%",
    height: 80,
    marginBottom: 40,
  },
  statsContent: {
    flex: 1,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-around",
    paddingHorizontal: 20,
  },
  statItem: {
    alignItems: "center",
  },
  statValue: {
    fontSize: 20,
    fontWeight: "600",
    color: "#ffffff",
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: "#888888",
    fontWeight: "400",
  },
  statDivider: {
    width: 1,
    height: 40,
    backgroundColor: "#333333",
  },
  controls: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    gap: 40,
    marginBottom: 40,
  },
  controlButton: {
    alignItems: "center",
  },
  controlGlass: {
    width: 50,
    height: 50,
    marginBottom: 12,
  },
  controlContent: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
  },
  controlIcon: {
    fontSize: 20,
  },
  controlText: {
    fontSize: 14,
    color: "#cccccc",
    fontWeight: "400",
  },
});
