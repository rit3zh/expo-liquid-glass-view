//
//  ExpoLiquidGlassContainer.swift
//  Pods
//
//  Created by rit3zh CX on 9/19/25.
//

import ExpoModulesCore
import SwiftUI

class ExpoLiquidGlassContainerProps: ExpoSwiftUI.ViewProps {
    @Field var spacing: CGFloat = 0
    @Field var horizontal: Bool
    
}

struct ExpoLiquidGlassContainer: ExpoSwiftUI.View, ExpoSwiftUI.WithHostingView {
  @ObservedObject var props: ExpoLiquidGlassContainerProps
  
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: props.spacing) {
                if props.horizontal {
                    HStack(spacing: props.spacing){
                        Children()
                    }
                } else {
                    VStack(spacing: props.spacing){
                        Children()
                    }
                }
                
            }
        
        } else  {
            Children()
        }
    }
}
