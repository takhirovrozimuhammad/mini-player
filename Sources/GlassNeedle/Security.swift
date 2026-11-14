import Foundation
import LocalAuthentication

/// Real biometric authentication for app actions, NOT Mac login/unlock.
/// MacBook Air M2 has Touch ID, not a TrueDepth Face ID camera.
struct SecureAction {
    static func authenticate(completion: @escaping (Bool, String) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, error?.localizedDescription ?? "Authentication unavailable")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
            localizedReason: "Authorize GlassNeedle settings") { success, error in
            DispatchQueue.main.async {
                completion(success, success ? "Verified" : (error?.localizedDescription ?? "Cancelled"))
            }
        }
    }
}
