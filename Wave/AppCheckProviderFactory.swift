swift
import FirebaseAppCheck
import DeviceCheck
import FirebaseCore

class AppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            if DCDevice.current.isSupported {
                return AppAttestProvider(app: app)
            } else {
                return nil
            }
        } else {
            return nil
        }
        
    }
}

class DebugAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppCheckDebugProvider(app: app)
    }
}