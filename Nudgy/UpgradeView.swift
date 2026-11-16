import SwiftUI
import StoreKit

struct UpgradeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("All built-in timers, including Pomodoro", systemImage: "timer")
                    Label("Unlimited timers of your own", systemImage: "slider.horizontal.3")
                    Label("On iPhone and Apple Watch", systemImage: "applewatch")
                    Label("Pay once. No subscription.", systemImage: "checkmark.seal")
                } header: {
                    Text("Nudgy, unlocked")
                }

                Section {
                    if store.unlocked {
                        Label("Unlocked. Thank you.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if let product = store.product {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            Text("Unlock for \(product.displayPrice)").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.busy)
                    } else {
                        Text("The purchase isn't available yet.")
                            .foregroundStyle(.secondary)
                    }

                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                    .disabled(store.busy)
                } footer: {
                    if let message = store.message {
                        Text(message)
                    }
                }

                #if DEBUG
                Section {
                    Toggle("Unlock for testing", isOn: Binding(
                        get: { store.debugUnlocked },
                        set: { store.debugUnlocked = $0 }
                    ))
                } footer: {
                    Text("Only in builds run from Xcode. Not in App Store builds.")
                }
                #endif
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                store.message = nil
                if store.product == nil { await store.loadProduct() }
            }
        }
    }
}
