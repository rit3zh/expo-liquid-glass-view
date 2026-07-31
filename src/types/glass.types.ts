import type {
  COMPONENT_NAMES,
  GLASS_ACTIVE_RENDERERS,
  GLASS_CORNER_STYLES,
  GLASS_RENDERERS,
  GLASS_VARIANTS,
  NATIVE_VIEW_NAMES,
} from "../constants";

type TGlassVariant = (typeof GLASS_VARIANTS)[number];
type TGlassRenderer = (typeof GLASS_RENDERERS)[number];
type TGlassActiveRenderer = (typeof GLASS_ACTIVE_RENDERERS)[number];
type TGlassCornerStyle = (typeof GLASS_CORNER_STYLES)[number];
type TNativeViewName =
  (typeof NATIVE_VIEW_NAMES)[keyof typeof NATIVE_VIEW_NAMES];
type TComponentName = (typeof COMPONENT_NAMES)[keyof typeof COMPONENT_NAMES];

export type {
  TGlassVariant,
  TGlassRenderer,
  TGlassActiveRenderer,
  TGlassCornerStyle,
  TNativeViewName,
  TComponentName,
};
