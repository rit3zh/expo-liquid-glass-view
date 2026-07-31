import { requireOptionalNativeModule } from "expo";

import { NATIVE_MODULE_NAME } from "../constants";

interface IExpoLiquidGlassModule {
  supportsNativeGlass: boolean;
}

const ExpoLiquidGlassModule =
  requireOptionalNativeModule<IExpoLiquidGlassModule>(NATIVE_MODULE_NAME);

export { ExpoLiquidGlassModule };
export type { IExpoLiquidGlassModule };
