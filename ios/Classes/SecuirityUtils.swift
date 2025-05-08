import Foundation
import UIKit

class SecurityUtils {
    /**
     * Gets a unique device ID
     *
     * @return A unique device ID
     */
    static func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    /**
     * Checks if the device is jailbroken
     *
     * @return true if the device is jailbroken, false otherwise
     */
    static func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for common jailbreak files
        let jailbreakFiles = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        
        for path in jailbreakFiles {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if the app can write to system directories
        let stringToWrite = "Jailbreak Test"
        do {
            try stringToWrite.write(toFile: "/private/jailbreak.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/jailbreak.txt")
            return true
        } catch {
            return false
        }
        #endif
    }
}
