import SwiftUI

struct CalendarSearchBar: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.35))

            TextField("Ask your memory", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 15, weight: .medium, design: .serif))
                .submitLabel(.search)
                .onSubmit(onSubmit)

            Image(systemName: "mic.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.06))
        )
    }
}

