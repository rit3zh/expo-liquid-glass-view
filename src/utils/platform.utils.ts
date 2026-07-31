import { Platform } from "react-native";

import { ExpoLiquidGlassModule } from "../modules";

const supportsNativeGlass: boolean =
  Platform.OS === "ios" && ExpoLiquidGlassModule?.supportsNativeGlass === true;

export { supportsNativeGlass };
