<p align="center">
  <img src="./assets/liquid-glass.jpg" alt="expo-liquid-glass-view" style="width:100%; max-width:800px;" />
</p>

<h1 align="center">expo-liquid-glass-view</h1>

<p align="center">
  Liquid Glass for React Native — Apple's native material on iOS 26, a custom Metal renderer below it.
</p>

## Install

```bash
npx expo install expo-liquid-glass-view
npx expo prebuild --platform ios
npx expo run:ios
```

iOS only. On Android and web the components render as plain views.

## Usage

```tsx
import { LiquidGlassView } from "expo-liquid-glass-view";

<LiquidGlassView
  variant="regular"
  cornerRadius={32}
  tint="#4da3ff33"
  interactive
  style={{ width: 260, height: 120 }}
  containerStyle={{ alignItems: "center", justifyContent: "center" }}
>
  <Text style={{ color: "#fff" }}>Liquid Glass</Text>
</LiquidGlassView>;
```

Corners take one number for all four, or an object for per-corner control.

```tsx
<LiquidGlassView cornerRadius={32} />
<LiquidGlassView cornerRadius={{ topLeft: 32, topRight: 32 }} />
```

### Backends

`renderer` defaults to `"auto"` — `UIGlassEffect` on iOS 26+, the Metal renderer below it. Force one with `renderer="native"` or `renderer="metal"`, and read back what a device actually chose:

```tsx
import { supportsNativeGlass } from "expo-liquid-glass-view";

<LiquidGlassView onRendererChange={(renderer) => console.log(renderer)} />;
```

`supportsNativeGlass` is a boolean, resolved once at import.

## Props

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `variant` | `"regular" \| "clear"` | `"regular"` | Material character. `clear` is thinner and less frosted. |
| `renderer` | `"auto" \| "native" \| "metal"` | `"auto"` | Which backend draws the glass. |
| `cornerRadius` | `number \| { topLeft?, topRight?, bottomRight?, bottomLeft? }` | `0` | One radius for every corner, or one per corner. |
| `cornerStyle` | `"continuous" \| "circular"` | `"continuous"` | Corner curvature. |
| `tint` | `ColorValue` | — | Colour washed through the glass; alpha controls strength. |
| `interactive` | `boolean` | `false` | System touch response. iOS 26+ only; ignored by the Metal renderer. |
| `metal` | `GlassMetalOptions` | — | Metal-renderer tuning. |
| `style` | `StyleProp<ViewStyle>` | — | Style for the native glass view. |
| `containerStyle` | `StyleProp<ViewStyle>` | — | Style for the wrapper around `children`. |
| `children` | `React.ReactNode` | — | Content rendered inside the glass. |
| `onRendererChange` | `(renderer) => void` | — | Fires with `"native"`, `"metal"`, or `"fallback-blur"`. |

### `metal`

Shapes the custom renderer only — Apple owns the equivalents internally, so it is ignored whenever `renderer` resolves to `"native"`. Leave a field unset to follow `variant`.

```tsx
<LiquidGlassView
  renderer="metal"
  metal={{
    blurRadius: 4,
    frost: 0.4,
    saturation: 1.8,
    refraction: { amount: 80, width: 24, height: 24, depth: 1 },
    dispersion: { amount: 8 },
    highlight: { intensity: 0.3, angle: 135 },
    border: { width: 1, opacity: 0.3 },
  }}
/>
```

| Field | Type | Description |
| --- | --- | --- |
| `blurRadius` | `number` | Backdrop blur radius, in points. |
| `captureQuality` | `number` | Backdrop capture resolution, as a multiplier on screen scale. Floor `0.25`, default `1`. Lower is cheaper and softer. |
| `opacity` | `number` | Opacity of the glass layer, `0`–`1`. Default `1`. |
| `frost` | `number` | How far the backdrop is pulled toward the interface background colour. The main dial for reading as a material rather than a plain blur. |
| `saturation` | `number` | Backdrop saturation multiplier. System materials sit well above `1`. |
| `noise` | `number` | Film grain, hiding banding in the blurred backdrop. |
| `light` | `number` | Flat brightness added before the rim sheen. Small values, `0`–`0.1`. |
| `refraction.amount` | `number` | How far the rim drags the backdrop, in points — the biggest dial on how strong the glass reads. |
| `refraction.width` / `.height` | `number` | How far in from the left/right and top/bottom edges the stretch reaches. |
| `refraction.depth` | `number` | Direction blend, edge normal (`0`) to radial (`1`). Radial makes corners sweep. |
| `refraction.curve` | `{ power?, bias? }` | Falloff shaping across the band. Reach for it last. |
| `dispersion.amount` | `number` | Chromatic split along the edge, in points. |
| `dispersion.reach` | `number` | How far in from the edge the split reaches. |
| `highlight.intensity` | `number` | Specular rim strength, `0`–`1`. |
| `highlight.angle` | `number` | Light direction in degrees. Default `135`. |
| `border.width` | `number` | Edge stroke width. `0` disables. Default `1`. |
| `border.opacity` | `number` | Edge stroke opacity. |

### `LiquidGlassContainer`

Wraps sibling glass views so they merge into one another as they get close, the way system controls do. iOS 26+; elsewhere a plain `View`.

```tsx
import { LiquidGlassContainer, LiquidGlassView } from "expo-liquid-glass-view";

<LiquidGlassContainer spacing={40} style={{ flexDirection: "row", gap: 12 }}>
  <LiquidGlassView cornerRadius={24} style={{ width: 64, height: 64 }} />
  <LiquidGlassView cornerRadius={24} style={{ width: 64, height: 64 }} />
</LiquidGlassContainer>;
```

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `spacing` | `number` | system | Distance, in points, at which nested glass elements begin to merge. |

## How the Metal path works

Below iOS 26 there is no system Liquid Glass, so the effect is rebuilt in three steps.

**Capture.** The window is rasterised into an `MTLTexture` at reduced scale, clipped to the union of the on-screen glass views and padded for blur reach. `CGContext` draws straight into the texture's `MTLBuffer`, so there is no upload step, and two buffers alternate so the CPU never writes memory the GPU is still reading. A Metal-backed view's own content is excluded, otherwise it refracts its own output and smears; views on the native path stay in, so a Metal glass moving over a native one still refracts it. SwiftUI content is composited by the render server and comes out of `CALayer.render(in:)` blank, so hosting views — `@expo/ui`'s `<Host>` included — are drawn in a second `drawHierarchy(in:)` pass that lands on top of the window pass.

**Blur.** Separable gaussian, horizontal then vertical, in capture space. Each view reads its own sub-rect of the shared texture through a UV offset, so N views cost the same as one.

**Glass.** One pass into the drawable: refraction, chromatic dispersion along the edge tangent, saturation, frost, tint, grain, an angular rim glow, and an antialiased shape mask. Refraction scales the sample coordinate about the centre by an exponential falloff of distance-to-edge, so a rim pixel reads content from further in and the whole surface refracts like a lens rather than leaving a flat interior. It is a pure coordinate remap, so it needs no render target of its own.

Every glass view encodes into a single command buffer per frame, driven by one shared display link, and presents asynchronously — nothing waits on the GPU from the main thread. The remaining per-frame cost is `CALayer.render(in:)` over the window, inherent to sampling outside the compositor. Its measured cost feeds a rate limiter that holds capture to a fixed share of the frame budget, so a dense screen settles to a lower refresh rate instead of dropping frames. On iOS 26 none of this applies — `UIGlassEffect` samples in the compositor directly.

## Support

| Platform | Backend |
| --- | --- |
| iOS 26+ | `UIGlassEffect` |
| iOS 16.4–25 | Metal renderer |
| Android / web | Not supported |

## Preview

https://github.com/user-attachments/assets/a08878fb-6a90-474b-8f21-1b46fe990177

## License

MIT © [rit3zh](https://github.com/rit3zh)
