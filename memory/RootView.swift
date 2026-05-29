import SwiftUI

struct RootView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding = false

    var body: some View {
        Group {
            if didCompleteOnboarding {
                CalendarHomeView()
            } else {
                OnboardingView {
                    didCompleteOnboarding = true
                }
            }
        }
        .tint(.black)
    }
}

