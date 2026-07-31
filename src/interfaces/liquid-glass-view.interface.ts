import type { ColorValue, StyleProp, ViewStyle } from "react-native";

import type {
  TGlassActiveRenderer,
  TGlassCornerStyle,
  TGlassRenderer,
  TGlassVariant,
} from "../types";
import type { IGlassMetalOptions } from "./glass-metal.interface";
import type { IGlassSurfaceProps } from "./glass-surface.interface";

interface IGlassCornerRadii {
  topLeft?: number;
  topRight?: number;
  bottomRight?: number;
  bottomLeft?: number;
}

type TGlassCornerRadius = number | IGlassCornerRadii;

interface ILiquidGlassViewProps extends IGlassSurfaceProps {
  containerStyle?: StyleProp<ViewStyle>;

  variant?: TGlassVariant;
  renderer?: TGlassRenderer;
  cornerRadius?: TGlassCornerRadius;
  cornerStyle?: TGlassCornerStyle;
  tint?: ColorValue;
  interactive?: boolean;
  metal?: IGlassMetalOptions;
  onRendererChange?: (renderer: TGlassActiveRenderer) => void;
}
export type { ILiquidGlassViewProps, IGlassCornerRadii, TGlassCornerRadius };
