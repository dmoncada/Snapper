import SwiftUI

struct TransitionView<
  Content1: View,
  Content2: View,
  T: Transition,
>: View {
  let showFirst: Bool
  let animation: Animation
  let transition: T

  @ViewBuilder let first: () -> Content1
  @ViewBuilder let second: () -> Content2

  init(
    showFirst: Bool,
    animation: Animation,
    transition: T = .opacity,
    @ViewBuilder first: @escaping () -> Content1,
    @ViewBuilder second: @escaping () -> Content2,
  ) {
    self.showFirst = showFirst
    self.animation = animation
    self.transition = transition
    self.first = first
    self.second = second
  }

  var body: some View {
    Group {
      if showFirst {
        first().transition(transition)
      } else {
        second().transition(transition)
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
    Text("First").fullBackground(.red)
  } second: {
    Text("Second").fullBackground(.blue)
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
