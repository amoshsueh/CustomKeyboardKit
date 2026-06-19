//
//  CustomKeyboardBuilder.swift
//  
//
//  Created by Pascal Burlet on 26.11.22.
//

import Foundation
import UIKit
import SwiftUI

///`CustomKeyboardBuilder` lets you build a custom keyboard in SwiftUI, together with haptic/audible feedback and callback on a "submit" button if provided in your layout
///- `UITextDocumentProxy` provides you the capability to modify the text thats in focus (e.g. inserting characters or strings, deleting backwards etc.),
///- `SubmitHandler` closure parameter is a closure, when called triggers the registered closure (using the `.onCustomSubmit(action:)` modifier.
///- `SystemFeedbackHandler?` closure parameter is a closure, when called will play the keyboard system sounds and haptic feedback if enabled in the settings by the user
public class CustomKeyboard: Keyboard {
    public init(@ViewBuilder customKeyboardView: @escaping ((UITextDocumentProxy, @escaping SubmitHandler, SystemFeedbackHandler?) -> some View)) {
        super.init(nibName: nil, bundle: nil)
        let onSubmitClosure = {
            if let onSubmit = self.onSubmit {
                onSubmit()
            } else {
                self.textDocumentProxy.insertText("\n")
            }
        }
        let hostingController = UIHostingController.init(
            rootView: customKeyboardView(
                self.textDocumentProxy,
                onSubmitClosure,
                self.playSystemFeedback
            )
        )
        keyboardView = hostingController.view

        // Tie the host's lifetime to the input view UIKit retains while presented. UIKit only
        // retains `keyboardView` (the host's `.view`), not `hostingController`; without this the
        // host deallocates and iOS 26.0/26.0.1 trait propagation messages a freed host.
        keyboardInputView?.keyboardViewController = hostingController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
