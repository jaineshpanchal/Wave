import SwiftUI
import FirebaseAuth

struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let name: String
    let code: String
}

let countryCodes: [CountryCode] = [
    CountryCode(emoji: "🇺🇸", name: "United States", code: "+1"),
    CountryCode(emoji: "🇮🇳", name: "India", code: "+91"),
    CountryCode(emoji: "🇬🇧", name: "United Kingdom", code: "+44"),
    CountryCode(emoji: "🇨🇦", name: "Canada", code: "+1"),
    CountryCode(emoji: "🇦🇺", name: "Australia", code: "+61")
]

struct PhoneAuthView: View {
    @State private var phoneNumber = ""
    @State private var selectedCountry: CountryCode? = nil
    @State private var verificationID: String? = nil
    @State private var smsCode: [String] = Array(repeating: "", count: 6)
    @State private var showCodeEntry = false
    @State private var authError = ""

    class PhoneAuthProviderVerifier: NSObject, PhoneAuthProviderDelegate {
    }


    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if showCodeEntry {
                    VStack(spacing: 12) {
                        Text("Enter your disposable code here...")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { i in
                                TextField("", text: Binding(
                                    get: { smsCode.indices.contains(i) ? smsCode[i] : "" },
                                    set: { newValue in
                                        if newValue.count <= 1 && smsCode.indices.contains(i) {
                                            smsCode[i] = newValue
                                        }
                                    })
                                )
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }

                        Button("Verify Code") {
                            verifyCode()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        HStack {
                            Button("Send code again") {
                                resendCode()
                            }
                            .font(.footnote)

                            Spacer()

                            Button("Nevermind") {
                                showCodeEntry = false
                                smsCode = Array(repeating: "", count: 6)
                            }
                            .font(.footnote)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("🙏 Thank You, for giving us a chance to serve you.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Picker("Select Country Code", selection: $selectedCountry) {
                            Text("Choose a country").tag(Optional<CountryCode>.none)
                            ForEach(countryCodes) { country in
                                Text("\(country.emoji) \(country.name) (\(country.code))").tag(Optional(country))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal)

                        TextField("Enter your phone number here...", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .onChange(of: phoneNumber) { oldNumber, newNumber in
                                autoDetectCountryCode(newNumber: newNumber)
                            }

                        Button("Send me the code") {
                            sendVerificationCode()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                if !authError.isEmpty {
                    Text(authError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Setup")
        }
    }

    private func sendVerificationCode() {
        authError = ""

        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPhone.isEmpty else {
            authError = "Please enter a valid phone number."
            return
        }

        guard let country = selectedCountry else {
            authError = "Select country code for your phone number please..."
            return
        }

        let fullPhoneNumber = (country.code + trimmedPhone).trimmingCharacters(in: .whitespacesAndNewlines)

        guard fullPhoneNumber.starts(with: "+"), fullPhoneNumber.count > 4 else {
            authError = "Invalid full phone number format."
            return
        }

        print("📲 Attempting to send code to: \(fullPhoneNumber)")

        let verifier = PhoneAuthProviderVerifier()
        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: verifier) { verificationID, error in
            if let error = error {
                self.authError = "🔥 Firebase PhoneAuth Error: \(error.localizedDescription)"
                return
            }

            guard let verificationID = verificationID else {
                self.authError = "❗️Firebase returned nil verificationID."
                return
            }

            self.verificationID = verificationID
            self.showCodeEntry = true
            print("✅ Code sent successfully. verificationID: \(verificationID)")
        }
    }

    private func autoDetectCountryCode(newNumber: String) {
        if newNumber.hasPrefix("+") {
            for country in countryCodes {
                if newNumber.starts(with: country.code) {
                    selectedCountry = country
                    phoneNumber = newNumber.replacingOccurrences(of: country.code, with: "")
                    break
                }
            }
        }
    }

    private func resendCode() {
        sendVerificationCode()
    }

    private func verifyCode() {
        let code = smsCode.joined()
        guard let verificationID = verificationID, !code.isEmpty else {
            authError = "Missing code or verification ID"
            return
        }

        let credential = PhoneAuthProvider.provider()
            .credential(withVerificationID: verificationID, verificationCode: code)

        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                authError = error.localizedDescription
            } else {
                print("✅ Logged in as: \(result?.user.phoneNumber ?? "")")
            }
        }
    }
}

