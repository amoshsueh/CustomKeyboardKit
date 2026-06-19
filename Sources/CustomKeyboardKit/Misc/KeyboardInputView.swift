//
//  KeyboardSoundEnablingView.swift
//  performify
//
//  Created by Pascal Burlet on 25.11.22.
//  Copyright © 2022 Pascal Burlet. All rights reserved.
//

import Foundation
import UIKit

public class KeyboardInputView: UIView, UIInputViewAudioFeedback {
    var keyboardUIView: UIView

    // Retain the SwiftUI host controller for the lifetime of this input view. UIKit keeps the
    // input view alive while it is presented, but only retains the host's `.view` (keyboardUIView),
    // not the host controller itself. Once the transient CustomKeyboard is released the host would
    // deallocate, leaving an orphaned hosting view; iOS 26.0/26.0.1 trait propagation then messages
    // the freed host (_wrappedProcessTraitChanges crash). Holding it here ties the host's lifetime
    // to the presented input view.
    var keyboardViewController: UIViewController?

    public var enableInputClicksWhenVisible: Bool {
        true
    }
    
    init?(keyboardUIView: UIView?) {
        guard let keyboardUIView else { return nil }
        self.keyboardUIView = keyboardUIView
        keyboardUIView.backgroundColor = .clear
        keyboardUIView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(keyboardUIView)
        let constraints = [
            leadingAnchor.constraint(equalTo: keyboardUIView.leadingAnchor),
            trailingAnchor.constraint(equalTo: keyboardUIView.trailingAnchor),
            topAnchor.constraint(equalTo: keyboardUIView.topAnchor),
            bottomAnchor.constraint(equalTo: keyboardUIView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        backgroundColor = .clear
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return keyboardUIView.intrinsicContentSize
    }
}
