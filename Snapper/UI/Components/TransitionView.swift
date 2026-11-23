import SwiftUI

struct TransitionView<
  Primary: View,
  Secondary: View,
  T: Transition,
>: View {
  let showFirst: Bool
  let animation: Animation
  let transition: T

  @ViewBuilder let primary: () -> Primary
  @ViewBuilder let secondary: () -> Secondary

  init(
    showFirst: Bool,
    animation: Animation,
    transition: T = .opacity,
    @ViewBuilder primary: @escaping () -> Primary,
    @ViewBuilder secondary: @escaping () -> Secondary,
  ) {
    self.showFirst = showFirst
    self.animation = animation
    self.transition = transition
    self.primary = primary
    self.secondary = secondary
  }

  var body: some View {
    Group {
      if showFirst {
        primary().transition(transition)
      } else {
        secondary().transition(transition)
      }
    }
    .animation(animation, value: showFirst)
  }
}

#if DEBUG
#Preview {
  @Previewable @State var showFirst = true

  TransitionView(
    showFirst: showFirst,
    animation: .easeInOut,
  ) {
    Text("Primary").withFullBackground(.red)
  } secondary: {
    Text("Secondary").withFullBackground(.blue)
  }
  .task {
    while Task.isCancelled == false {
      try? await Task.sleep(for: .seconds(3))
      withAnimation {
        showFirst.toggle()
      }
    }
  }
}
#endif
