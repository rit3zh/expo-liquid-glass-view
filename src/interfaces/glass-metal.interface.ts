interface IGlassRefractionCurve {
  power?: number;
  bias?: number;
}
interface IGlassRefraction {
  amount?: number;
  width?: number;
  height?: number;
  depth?: number;
  curve?: IGlassRefractionCurve;
}

interface IGlassDispersion {
  amount?: number;
  reach?: number;
}
interface IGlassHighlight {
  intensity?: number;
  angle?: number;
}
interface IGlassBorder {
  width?: number;
  opacity?: number;
}
interface IGlassMetalOptions {
  blurRadius?: number;
  captureQuality?: number;
  opacity?: number;
  frost?: number;
  saturation?: number;
  noise?: number;
  light?: number;
  refraction?: IGlassRefraction;
  dispersion?: IGlassDispersion;
  highlight?: IGlassHighlight;
  border?: IGlassBorder;
}
export type {
  IGlassMetalOptions,
  IGlassRefraction,
  IGlassRefractionCurve,
  IGlassDispersion,
  IGlassHighlight,
  IGlassBorder,
};
