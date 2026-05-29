import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var animate = false
    @State private var step: Int = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Добро пожаловать в")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("Memory")
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .tracking(-0.5)
                        .scaleEffect(animate ? 1.0 : 0.92)
                        .opacity(animate ? 1.0 : 0.3)
                        .animation(.spring(response: 0.7, dampingFraction: 0.75), value: animate)
                }

                VStack(alignment: .leading, spacing: 12) {
                    OnboardingBullet(
                        title: "Записывай день голосом или текстом",
                        subtitle: "Мы превратим это в понятную хронологию событий."
                    )
                    .opacity(step >= 0 ? 1 : 0)

                    OnboardingBullet(
                        title: "Всё автоматически структурируется",
                        subtitle: "Можно уточнить время, порядок и прикрепить фото."
                    )
                    .opacity(step >= 1 ? 1 : 0)

                    OnboardingBullet(
                        title: "Без регистрации",
                        subtitle: "Позже подключим синхронизацию через iCloud одним нажатием."
                    )
                    .opacity(step >= 2 ? 1 : 0)
                }
                .frame(maxWidth: 420, alignment: .leading)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.35), value: step)

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        onFinish()
                    } label: {
                        Text("Продолжить")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.black)
                            )
                            .foregroundStyle(.white)
                    }

                    Text(" ")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 22)
        }
        .onAppear {
            animate = true
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                step = 0
                try? await Task.sleep(for: .milliseconds(250))
                step = 1
                try? await Task.sleep(for: .milliseconds(250))
                step = 2
            }
        }
    }
}

private struct OnboardingBullet: View {
    var title: String
    var subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.black.opacity(0.85))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

