import Foundation
import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct ScreenView: View, Equatable {
  static func == (lhs: ScreenView, rhs: ScreenView) -> Bool {
    lhs.viewStore.state.id == rhs.viewStore.state.id
  }

  let store: Store<ScreenState, ScreenAction>
  let viewStore: ViewStore<ScreenState, Never>

  init(store: Store<ScreenState, ScreenAction>) {
    self.store = store
    self.viewStore = .init(store.actionless)
  }

  var body: some View {
    SwitchStore(store) {
      CaseLet(
        state: /ScreenState.home,
        action: ScreenAction.home,
        then: HomeView.init
      )
      CaseLet(
        state: /ScreenState.number,
        action: ScreenAction.number,
        then: NumberCoordinatorView.init
      )
    }
  }

}


enum ScreenAction {
  case home(HomeAction)
  case number(NumberAction)
}

enum ScreenState: Equatable, Identifiable {
  case home(HomeState)
  case number(NumberState)

  var id: UUID {
    switch self {
    case .home(let state):
      return state.id
    case .number(let state):
      return state.id
    }
  }
}

struct ScreenEnvironment {}

let screenReducer = Reducer<ScreenState, ScreenAction, ScreenEnvironment>.combine(
  homeReducer
    .pullback(
      state: /ScreenState.home,
      action: /ScreenAction.home,
      environment: { _ in HomeEnvironment() }
    ),
  numberReducer
    .pullback(
      state: /ScreenState.number,
      action: /ScreenAction.number,
      environment: { _ in }
    )
)

// Home

struct HomeView: View {
  
  let store: Store<HomeState, HomeAction>
  
  var body: some View {
    WithViewStore(store) { viewStore in
      VStack {
        Button("Start", action: {
          viewStore.send(.startTapped)
        })
      }
    }
    .navigationTitle("Home")
  }
}

enum HomeAction {
  
  case startTapped
}

struct HomeState: Equatable {
  
  let id = UUID()
}

struct HomeEnvironment {}

let homeReducer = Reducer<
  HomeState, HomeAction, HomeEnvironment
> { state, action, environment in
  return .none
}
