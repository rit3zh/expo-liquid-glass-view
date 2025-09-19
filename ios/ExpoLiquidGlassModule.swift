import ExpoModulesCore

public class ExpoLiquidGlassModule: Module {

    public func definition() -> ModuleDefinition {
        Name("ExpoLiquidGlass")
        View(ExpoLiquidGlassView.self)
        View(ExpoLiquidGlassContainer.self)
        
    }
}
