import * as React from "react";
import type { StyleProp, ViewStyle } from "react-native";

export enum CornerStyle {
  Continuous = "continuous",
  Circular = "circular",
}

export enum LiquidGlassType {
  Clear = "clear",
  Tint = "tint",
  Regular = "regular",
  Interactive = "interactive",
  Identity = "identity",
}

export interface ExpoLiquidGlassViewProps {
  type?: LiquidGlassType;
  tint?: string;
  cornerRadius?: number;
  isInteractive?: boolean;
  cornerStyle?: CornerStyle;
  style?: StyleProp<ViewStyle>;
  children?: React.ReactNode;
}
