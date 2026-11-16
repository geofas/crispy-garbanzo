import SwiftUI
import NudgyKit

/// Lets the user pick a theme. Basic is free; the other two open the upgrade screen until
/// the one-time purchase is made.
struct ThemePickerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.themeStyle) private var style
    @Environment(\.dismiss) private var dismiss
    @State private var showingUpgrade = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Theme.allCases) { theme in
                        ThemeRow(
                            theme: theme,
                            selected: theme == model.theme,
                            locked: !theme.isAvailable(unlocked: model.unlocked)
                        ) {
                            if theme.isAvailable(unlocked: model.unlocked) {
                                model.select(theme)
                            } else {
                                showingUpgrade = true
                            }
                        }
                        .themedRow(style)
                    }
                } footer: {
                    Text("The app icon changes with the theme; iPhone shows a message when it does. Your Apple Watch uses the theme you pick here.")
                        .font(style.text(.footnote))
                        .foregroundStyle(style.secondaryText)
                }
            }
            .themedListBackground(style)
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView().themed(model.theme)
            }
        }
    }
}

private struct ThemeRow: View {
    @Environment(\.themeStyle) private var style
    let theme: Theme
    let selected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ThemeSwatch(theme: theme)
                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.name).font(style.text(.headline, weight: .semibold))
                    Text(theme.summary).font(style.text(.subheadline)).foregroundStyle(style.secondaryText)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(style.secondaryText)
                } else if selected {
                    Image(systemName: "checkmark").font(.body.weight(.semibold)).foregroundStyle(style.accent)
                }
            }
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(locked ? 0.8 : 1)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(locked ? "Locked. Opens the upgrade screen." : "")
    }
}

/// A small preview of a theme: its background with the accent dot.
private struct ThemeSwatch: View {
    let theme: Theme

    var body: some View {
        let s = ThemeStyle.of(theme)
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(s.background ?? Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .overlay(Circle().fill(s.accent).frame(width: 14, height: 14))
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }
}
