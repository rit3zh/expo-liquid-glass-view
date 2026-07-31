import type { ComponentType } from "react";

import { NATIVE_MODULE_NAME, NATIVE_VIEW_NAMES } from "../constants";
import type { ILiquidGlassContainerProps } from "../interfaces";
import { requireNativeViewOnce } from "../utils";

const NativeLiquidGlassContainerView: ComponentType<ILiquidGlassContainerProps> =
  requireNativeViewOnce<ILiquidGlassContainerProps>(
    NATIVE_MODULE_NAME,
    NATIVE_VIEW_NAMES.LIQUID_GLASS_CONTAINER_VIEW
  );

export { NativeLiquidGlassContainerView };
