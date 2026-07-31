import * as React from "react";
import { memo } from "react";
import { Platform, View } from "react-native";

import { COMPONENT_NAMES } from "../../constants";
import type { ILiquidGlassContainerProps } from "../../interfaces";
import { NativeLiquidGlassContainerView } from "../../views";

const LiquidGlassContainerBase: React.FC<ILiquidGlassContainerProps> = ({
  children,
  style,
  ...nativeProps
}: ILiquidGlassContainerProps): React.ReactNode & React.ReactElement => {
  if (Platform.OS !== "ios") {
    return <View style={style}>{children}</View>;
  }

  return (
    <NativeLiquidGlassContainerView {...nativeProps} style={style}>
      {children}
    </NativeLiquidGlassContainerView>
  );
};

LiquidGlassContainerBase.displayName = `${COMPONENT_NAMES.LIQUID_GLASS_CONTAINER}Base`;

const LiquidGlassContainer: React.NamedExoticComponent<ILiquidGlassContainerProps> =
  memo<ILiquidGlassContainerProps>(LiquidGlassContainerBase);

LiquidGlassContainer.displayName = COMPONENT_NAMES.LIQUID_GLASS_CONTAINER;

export { LiquidGlassContainer };
