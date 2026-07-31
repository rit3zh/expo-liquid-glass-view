import type { TGlassActiveRenderer } from "../types";
import type { ILiquidGlassViewProps } from "./liquid-glass-view.interface";

interface INativeLiquidGlassViewProps
  extends Omit<ILiquidGlassViewProps, "containerStyle" | "onRendererChange"> {
  onRendererChange?: (event: {
    nativeEvent: { renderer: TGlassActiveRenderer };
  }) => void;
}
export type { INativeLiquidGlassViewProps };
