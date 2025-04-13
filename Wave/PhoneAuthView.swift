import SwiftUI
import FirebaseAuth

struct CountryCode: Identifiable, Hashable, Decodable {
    var id: UUID { UUID() } // Computed property instead of stored
    let name: String
    let code: String        // Dial code like "+1"
    let iso: String         // ISO country code like "US"
    let emoji: String
}

struct PhoneAuthView: View {
    @State private var phoneNumber = ""
    @State private var countryCodes: [CountryCode] = []
    @State private var selectedCountry: CountryCode? = nil
    @State private var verificationID: String? = nil
    @State private var smsCode: [String] = Array(repeating: "", count: 6)
    @State private var showCodeEntry = false
    @State private var authError = ""
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 24) {
                if showCodeEntry {
                    VStack(spacing: 12) {
                        Text("Enter your one time setup code here.")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(0..<6) { i in
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
                        Text("Thank You, for giving us a chance to serve you.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if let country = selectedCountry {
                            Text("\(country.emoji) \(country.name) (\(country.code))")
                                .font(.headline)
                        }

                        TextField("Enter your phone number here...", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

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
            .navigationDestination(for: String.self) { value in
                if value == "main" {
                    ContentView()
                }
            }
            .onAppear {
                loadCountryCodes()
            }
        }
    }

    private func loadCountryCodes() {
        guard let url = Bundle.main.url(forResource: "complete_country_codes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CountryCode].self, from: data) else {
            print("Failed to load or decode complete_country_codes.json")
            return
        }

        self.countryCodes = decoded

        if let region = Locale.current.region?.identifier,
           let match = decoded.first(where: { $0.iso == region }) {
            selectedCountry = match
        } else {
            print("Could not auto-detect region code")
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
            authError = "Unable to auto-detect your country code."
            return
        }

        let fullPhoneNumber = (country.code + trimmedPhone)

        guard fullPhoneNumber.starts(with: "+"), fullPhoneNumber.count > 4 else {
            authError = "Invalid full phone number format."
            return
        }

        print("Sending code to: \(fullPhoneNumber)")

        PhoneAuthProvider.provider().verifyPhoneNumber(fullPhoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                self.authError = "Firebase PhoneAuth Error: \(error.localizedDescription)"
                return
            }

            guard let verificationID = verificationID else {
                self.authError = "Firebase returned nil verificationID."
                return
            }

            self.verificationID = verificationID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.showCodeEntry = true
            print("Code sent successfully. verificationID: \(verificationID)")
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
                print("Logged in as: \(result?.user.phoneNumber ?? "")")
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                path.append("main")
            }
        }
    }
}

