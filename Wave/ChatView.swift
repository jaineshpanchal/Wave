//
//  ChatView.swift
//  Wave
//
//  Created by Jainesh Panchal on 4/11/25.
//

import SwiftUI
import ContactsUI
import FirebaseFirestore
import FirebaseAuth

struct Message: Identifiable {
    var id: String
    var sender: String
    var content: String
    var timestamp: Date
    var isBot: Bool = false
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var newMessage: String = ""
    @State private var showContactPicker = false
    @State private var showGreeting = false

    var body: some View {
        VStack {
            List(messages) { message in
                HStack(alignment: .top) {
                    if message.isBot {
                        Text("🤖 ") + Text(message.sender).bold()
                    } else {
                        Text(message.sender).bold()
                    }
                    Spacer()
                    Text(message.content)
                        .multilineTextAlignment(.leading)
                }
            }

            HStack {
                TextField("Message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    sendMessage()
                }
            }
            .padding()

            Button("➕ Start Chat from Contacts") {
                showContactPicker = true
            }
            .padding(.bottom)
        }
        .onAppear {
            loadInitialMessages()
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { contactName in
                startChat(with: contactName)
            }
        }
    }

    func loadInitialMessages() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("users").document(userId).collection("messages")

        ref.getDocuments { snapshot, error in
            if let documents = snapshot?.documents, documents.isEmpty {
                let greeting = Message(
                    id: UUID().uuidString,
                    sender: "Greetings",
                    content: "👋 Welcome to Wave! Let us know if you need anything.",
                    timestamp: Date(),
                    isBot: true
                )
                messages.append(greeting)
                ref.document(greeting.id).setData([
                    "sender": greeting.sender,
                    "content": greeting.content,
                    "timestamp": greeting.timestamp,
                    "isBot": true
                ])
            } else {
                self.messages = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return Message(
                        id: doc.documentID,
                        sender: data["sender"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        isBot: data["isBot"] as? Bool ?? false
                    )
                } ?? []
            }
        }
    }

    func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let msg = Message(id: UUID().uuidString, sender: user.phoneNumber ?? "You", content: newMessage, timestamp: Date())
        messages.append(msg)
        db.collection("users").document(user.uid).collection("messages").document(msg.id).setData([
            "sender": msg.sender,
            "content": msg.content,
            "timestamp": msg.timestamp,
            "isBot": false
        ])
        newMessage = ""
    }

    func startChat(with contactName: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let greeting = Message(
            id: UUID().uuidString,
            sender: "You",
            content: "Hi \(contactName), let’s chat on Wave!",
            timestamp: Date()
        )
        messages.append(greeting)
        db.collection("users").document(user.uid).collection("messages").document(greeting.id).setData([
            "sender": greeting.sender,
            "content": greeting.content,
            "timestamp": greeting.timestamp,
            "isBot": false
        ])
    }
}

struct ContactPickerView: UIViewControllerRepresentable {
    var onContactSelected: (String) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? "Unknown"
            parent.onContactSelected(name)
        }
    }
}
