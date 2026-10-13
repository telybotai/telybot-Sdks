// The 0.x names, kept for one major so an app updates the package first and its
// code after: the `KeydaBot` product re-exports `TelyBot`, and the old names are
// deprecated aliases of the new ones. Nothing here has behaviour of its own.
// Removed in 2.0.0.
#if canImport(UIKit)
@_exported import TelyBot
import SwiftUI

@available(*, deprecated, renamed: "TelyBot")
public typealias KeydaBot = TelyBot

@available(*, deprecated, renamed: "TelyBotView")
@available(iOSApplicationExtension, unavailable)
public typealias KeydaBotView = TelyBotView

@available(iOSApplicationExtension, unavailable)
public extension View {
    @available(*, deprecated, renamed: "telyBot(isPresented:question:)")
    func keydaBot(isPresented: Binding<Bool>, question: String? = nil) -> some View {
        telyBot(isPresented: isPresented, question: question)
    }
}
#endif
