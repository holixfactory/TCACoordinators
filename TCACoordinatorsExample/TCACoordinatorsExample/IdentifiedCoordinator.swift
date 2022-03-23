import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IdentifiedCoordinatorView: View {
  
  let store: Store<IdentifiedCoordinatorState, IdentifiedCoordinatorAction>
  
  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
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
}

struct IdentifiedCoordinatorState: Equatable, IdentifiedRouterState {
  
  static let initialState = IdentifiedCoordinatorState(
    routes: [.root(.home(.init()), embedInNavigationView: true)]
  )
  
  var routes: IdentifiedArrayOf<Route<ScreenState>>
}

enum IdentifiedCoordinatorAction: IdentifiedRouterAction {
  
  case routeAction(ScreenState.ID, action: ScreenAction)
  case updateRoutes(IdentifiedArrayOf<Route<ScreenState>>)
}

struct IdentifiedCoordinatorEnvironment {}

typealias IdentifiedCoordinatorReducer = Reducer<
  IdentifiedCoordinatorState, IdentifiedCoordinatorAction, IdentifiedCoordinatorEnvironment
>

let identifiedCoordinatorReducer: IdentifiedCoordinatorReducer = screenReducer
  .forEachIdentifiedRoute(environment: { _ in .init() })
  .withRouteReducer(Reducer { state, action, environment in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.presentSheet(.number(.list(.init(numbers: Array(0..<4)))), embedInNavigationView: true)
      default:
        break
      }
      return .none
  }.combined(
    with: Reducer.numberCoordinatorReducer(
      toScreenState: { .number($0) },
      fromScreenState: /ScreenState.number,
      screenAction: /ScreenAction.number
    )
  )
)
