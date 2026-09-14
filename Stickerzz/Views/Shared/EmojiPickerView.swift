import SwiftUI
import UIKit

// Zero-size hidden text field that forces the system emoji keyboard.
// Set isFirstResponder = true to open the picker; binding updates on pick and keyboard auto-dismisses.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator,
                        action: #selector(Coordinator.textChanged(_:)),
                        for: .editingChanged)
        field.alpha = 0
        field.autocorrectionType = .no
        return field
    }

    func updateUIView(_ uiView: EmojiUITextField, context: Context) {
        DispatchQueue.main.async {
            if isFirstResponder && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFirstResponder && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }

    class EmojiUITextField: UITextField {
        override var textInputMode: UITextInputMode? {
            .activeInputModes.first { $0.primaryLanguage == "emoji" }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: EmojiTextField
        init(_ parent: EmojiTextField) { self.parent = parent }

        @objc func textChanged(_ sender: UITextField) {
            guard let last = sender.text?.last else { return }
            parent.text = String(last)
            sender.text = ""
            sender.resignFirstResponder()
            parent.isFirstResponder = false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFirstResponder = false
        }
    }
}
