import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var isDeactivated = false
    @State private var toggleState = false
    @State private var showDeactivateAlert = false
    @State private var showDeleteWarning = false
    @State private var showFinalDeleteConfirmation = false
    @State private var navigateToSetup = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.headline)
                    .padding(.top)

                Toggle(isOn: $toggleState) {
                    Text(isDeactivated ? "Activate Account" : "Deactivate Account")
                }
                .onChange(of: toggleState) { _, newValue in
                    if !isDeactivated && newValue {
                        showDeactivateAlert = true
                        deactivateAccount()
                    } else if isDeactivated && newValue {
                        reactivateAccount()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toggleState = false
                    }
                }
                .padding()

                Button(role: .destructive) {
                    showDeleteWarning = true
                } label: {
                    Text("Delete Account")
                        .foregroundColor(.red)
                }
                .alert("We don't like to grow apart but we respect your decision, hope you'll re-consider in future!", isPresented: $showDeleteWarning) {
                    Button("Got it", role: .cancel) {
                        showFinalDeleteConfirmation = true
                    }
                }
                .alert("Your chat history will be removed and Account will be deleted after this step.", isPresented: $showFinalDeleteConfirmation) {
                    Button("Goodbye", role: .destructive) {
                        reauthenticateAndDelete()
                    }
                    Button("Cancel", role: .cancel) {}
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationDestination(isPresented: $navigateToSetup) {
                PhoneAuthView()
            }
            .alert("We understand the need of a break, hope to see you soon!", isPresented: $showDeactivateAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func deactivateAccount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "isDeactivated": true
        ], merge: true) { error in
            if let error = error {
                print("Error deactivating: \(error.localizedDescription)")
            } else {
                print("Account deactivated")
                isDeactivated = true
            }
        }
    }

    private func reactivateAccount() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "isDeactivated": false
        ], merge: true) { error in
            if let error = error {
                print("Error reactivating: \(error.localizedDescription)")
            } else {
                print("Account reactivated")
                isDeactivated = false
            }
        }
    }

    private func reauthenticateAndDelete() {
        guard let user = Auth.auth().currentUser else { return }
        guard let phoneNumber = user.phoneNumber else {
            print("No phone number linked.")
            return
        }

        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                print("Error sending verification code: \(error.localizedDescription)")
                return
            }

            guard let verificationID = verificationID else {
                print("Firebase returned nil verificationID.")
                return
            }

            let alert = UIAlertController(title: "Re-authenticate", message: "Enter the code you just received to confirm account deletion.", preferredStyle: .alert)
            alert.addTextField { $0.placeholder = "6-digit code" }

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                let code = alert.textFields?.first?.text ?? ""
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)

                user.reauthenticate(with: credential) { _, error in
                    if let error = error {
                        print("Reauthentication failed: \(error.localizedDescription)")
                    } else {
                        deleteAccount(for: user)
                    }
                }
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(alert, animated: true)
            }
        }
    }

    private func deleteAccount(for user: User00) {
        let db = Firestore.firestore()
        let uid = user.uid

        db.collection("users").document(uid).collection("messages").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                for doc in docs {
                    doc.reference.delete()
                }
            }

            db.collection("users").document(uid).delete { error in
                if let error = error {
                    print("Error deleting user doc: \(error.localizedDescription)")
                } else {
                    user.delete { error in
                        if let error = error {
                            print("Firebase delete error: \(error.localizedDescription)")
                        } else {
                            print("Account fully deleted")
                            DispatchQueue.main.async {
                                navigateToSetup = true
                            }
                        }
                    }
                }
            }
        }
    }
}

