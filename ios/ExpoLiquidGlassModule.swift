import ExpoModulesCore
import UIKit

public class ExpoLiquidGlassModule: Module {

    public func definition() -> ModuleDefinition {
        Name("ExpoLiquidGlass")

        Constant("supportsNativeGlass") { () -> Bool in
            if #available(iOS 26.0, *) { return true }
            return false
        }

        View(LiquidGlassView.self) {
            Events("onRendererChange")

            Prop("variant") { (view: LiquidGlassView, variant: GlassVariant?) in
                view.variant = variant ?? .regular
            }

            Prop("renderer") { (view: LiquidGlassView, renderer: GlassBackend?) in
                view.backend = renderer ?? .auto
            }

            Prop("cornerStyle") { (view: LiquidGlassView, style: GlassCornerStyle?) in
                view.cornerStyle = style ?? .continuous
            }

            Prop("cornerRadius") { (view: LiquidGlassView, value: Either<Double, GlassCornerRadii>?) in
                view.cornerRadii = CornerRadiiValues(value)
            }

            Prop("tint") { (view: LiquidGlassView, color: UIColor?) in
                view.tint = color ?? .clear
            }

            Prop("interactive") { (view: LiquidGlassView, interactive: Bool?) in
                view.isInteractive = interactive ?? false
            }

            Prop("metal") { (view: LiquidGlassView, options: GlassMetalOptions?) in
                view.metal = options ?? GlassMetalOptions()
            }
        }

        View(LiquidGlassContainerView.self) {
            Prop("spacing") { (view: LiquidGlassContainerView, value: Double?) in
                view.spacing = value
            }
        }
    }
}
