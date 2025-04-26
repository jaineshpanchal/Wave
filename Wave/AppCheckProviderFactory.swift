import FirebaseAppCheck
import DeviceCheck
import FirebaseCore

import Foundation
import FirebaseAppCheck
import FirebaseCore

class AppAttestAppCheckProviderFactory: NSObject, FirebaseAppCheck.AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return nil
        }
    }
}
