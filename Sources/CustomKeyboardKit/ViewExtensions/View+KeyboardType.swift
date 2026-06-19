//
//  CustomKeyboardModifier.swift
//  
//
//  Created by PascalBurlet on 30.06.22.
//

import Foundation
import UIKit
import SwiftUI
import Combine
@_spi(Advanced) import SwiftUIIntrospect

public extension View {
    @available(*, deprecated, message: "Use the keyboardType(_:) overload instead.")
    func customKeyboard(view: @escaping (UITextDocumentProxy, @escaping CustomKeyboard.SubmitHandler, CustomKeyboard.SystemFeedbackHandler?) -> some View) -> some View {
        customKeyboard(CustomKeyboard(customKeyboardView: view))
    }
    
    func keyboardType(view: @escaping (UITextDocumentProxy, @escaping CustomKeyboard.SubmitHandler, CustomKeyboard.SystemFeedbackHandler?) -> some View) -> some View {
        customKeyboard(CustomKeyboard(customKeyboardView: view))
    }
}


public extension View {
    @available(*, deprecated, message: "Use the keyboardType(_:) overload instead.")
    func customKeyboard(_ keyboardType: Keyboard) -> some View {
        self
            .keyboardType(keyboardType)
    }
}

public extension View {
    func keyboardType(_ keyboardType: Keyboard) -> some View {
        self
            .modifier(KeyboardModifier(keyboardType: keyboardType))
    }
}

struct KeyboardModifier: ViewModifier {
    let keyboardType: Keyboard
    @Environment(\.onCustomSubmit) var onCustomSubmit
    @StateObject var textViewObserver = ActiveTextViewObserver()
    
    public init(keyboardType: Keyboard) {
        self.keyboardType = keyboardType
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(textViewObserver.$isEditing, perform: assignSubmitForEditingView)
            .onChange(of: textViewObserver.textView, perform: recoverCustomKeyboardIfNeeded)
            .onChange(of: keyboardType) { newKeyboard in
                switchKeyboard(to: newKeyboard, on: textViewObserver.textView)
            }
            .introspect(.textEditor, on: .iOS(.v15...)) { uiTextView in
                switchKeyboard(to: keyboardType, on: uiTextView)
                textViewObserver.set(textView: uiTextView)
            }
            .introspect(.textField, on: .iOS(.v15...)) { uiTextField in
                switchKeyboard(to: keyboardType, on: uiTextField)
                textViewObserver.set(textView: uiTextField)
            }
    }
    
    private func switchKeyboard(to keyboard: Keyboard, on textView: (any TextEditing)?) {
        guard let textView else { return }

        let previousInputView = textView.inputView
        let previousKeyboardType = textView.keyboardType

        switch keyboard {
        case let systemKeyboard as SystemKeyboard:
            textView.inputView = nil
            textView.keyboardType = systemKeyboard.keyboardType
        case let customKeyboard as Keyboard:
            textView.inputView = customKeyboard.keyboardInputView
        default:
            textView.inputView = nil
        }

        // Reload only when the keyboard *kind* actually changes (custom <-> system, or the system
        // keyboardType changes). The introspect/onChange callbacks fire on every SwiftUI update
        // carrying a freshly built keyboard instance; calling reloadInputViews() unconditionally
        // makes UIKit spin up a new UICompatibilityInputViewController on every tick without ever
        // releasing the old ones — hundreds of hosted keyboards pile up (runaway memory) — and it
        // reenters iOS 26.0/26.0.1 trait propagation, closing+reopening the keyboard and feeding
        // SwiftUI rebuild loops. (Pre-2.0 never reloaded here.)
        let inputKindChanged = (previousInputView == nil) != (textView.inputView == nil)
        let systemKeyboardTypeChanged = textView.inputView == nil && previousKeyboardType != textView.keyboardType

        guard inputKindChanged || systemKeyboardTypeChanged else { return }

        // Defer to the next runloop: a synchronous reloadInputViews() inside trait propagation
        // crashes on iOS 26.0/26.0.1 (_wrappedProcessTraitChanges) and fights the in-flight
        // keyboard transition.
        DispatchQueue.main.async {
            textView.reloadInputViews()
        }
    }
    
    func assignSubmitForEditingView(isEditing: Bool) {
        if isEditing {
            keyboardType.onSubmit = onCustomSubmit
        }
    }
    
    func recoverCustomKeyboardIfNeeded(for view: UIView?) {
        guard let view else { return }
        
        if view.isFirstResponder && !keyboardType.view.isVisible {
            view.resignFirstResponder()
            view.becomeFirstResponder()
        }
    }
}
