//
//  EncryptionExtension.swift
//  Matche
//
//  Created by Andre Maytorena on 14/01/2024.
//

import SwiftUI
import CryptoKit

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

func encrypt(message: String, usingKey key: SymmetricKey) -> String? {
            
    guard let data = message.data(using: .utf8) else { return nil }

    do {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined?.base64EncodedString()
    } catch {
        print("Encryption error: \(error)")
        return nil
    }
}

func decrypt(encryptedMessage: String, usingKey key: SymmetricKey) -> String? {
            
    guard let data = Data(base64Encoded: encryptedMessage),
          let sealedBox = try? AES.GCM.SealedBox(combined: data) else { return nil }

    do {
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)
    } catch {
        print("Decryption error: \(error)")
        return nil
    }
}
