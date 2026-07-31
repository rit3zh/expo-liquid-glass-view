import * as React from "react";
import { memo, useCallback } from "react";
import { View } from "react-native";

import { COMPONENT_NAMES } from "../../constants";
import type { ILiquidGlassViewProps } from "../../interfaces";
import type { TGlassActiveRenderer } from "../../types";
import { NativeLiquidGlassView } from "../../views";

const LiquidGlassViewBase: React.FC<ILiquidGlassViewProps> = ({
  children,
  containerStyle,
  style,
  onRendererChange,
  ...nativeProps
}: ILiquidGlassViewProps): React.ReactNode & React.ReactElement => {
  const handleRendererChange = useCallback(
    (event: { nativeEvent: { renderer: TGlassActiveRenderer } }): void =>
      onRendererChange?.(event.nativeEvent.renderer),
    [onRendererChange],
  );

  return (
    <NativeLiquidGlassView
      {...nativeProps}
      style={style}
      onRendererChange={onRendererChange ? handleRendererChange : undefined}
    >
      {}
      {children ? (
        <View pointerEvents="box-none" style={containerStyle}>
          {children}
        </View>
      ) : null}
    </NativeLiquidGlassView>
  );
};
LiquidGlassViewBase.displayName = `${COMPONENT_NAMES.LIQUID_GLASS_VIEW}Base`;
const LiquidGlassView: React.NamedExoticComponent<ILiquidGlassViewProps> =
  memo<ILiquidGlassViewProps>(LiquidGlassViewBase);

LiquidGlassView.displayName = COMPONENT_NAMES.LIQUID_GLASS_VIEW;

export { LiquidGlassView };
