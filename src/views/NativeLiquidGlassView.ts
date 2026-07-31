import type { ComponentType } from "react";

import { NATIVE_MODULE_NAME, NATIVE_VIEW_NAMES } from "../constants";
import type { INativeLiquidGlassViewProps } from "../interfaces";
import { requireNativeViewOnce } from "../utils";

const NativeLiquidGlassView: ComponentType<INativeLiquidGlassViewProps> =
  requireNativeViewOnce<INativeLiquidGlassViewProps>(
    NATIVE_MODULE_NAME,
    NATIVE_VIEW_NAMES.LIQUID_GLASS_VIEW
  );

export { NativeLiquidGlassView };
