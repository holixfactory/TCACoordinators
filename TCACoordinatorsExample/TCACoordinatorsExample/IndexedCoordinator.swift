import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IndexedCoordinatorView: View {

  let store: Store<IndexedCoordinatorState, IndexedCoordinatorAction>

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

enum IndexedCoordinatorAction: IndexedRouterAction {

  case routeAction(Int, action: ScreenAction)
  case updateRoutes([Route<ScreenState>])
}

struct IndexedCoordinatorState: Equatable, IndexedRouterState {

  static let initialState = IndexedCoordinatorState(
    routes: [.root(.home(.init()), embedInNavigationView: true)]
  )

  var routes: [Route<ScreenState>]
}

struct IndexedCoordinatorEnvironment {}

typealias IndexedCoordinatorReducer = Reducer<
  IndexedCoordinatorState, IndexedCoordinatorAction, IndexedCoordinatorEnvironment
>

let indexedCoordinatorReducer: IndexedCoordinatorReducer = screenReducer
  .forEachIndexedRoute(environment: { _ in ScreenEnvironment() })
  .withRouteReducer(
    Reducer { state, action, environment in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.presentSheet(.number(.list(.init(numbers: Array(0..<4)))), embedInNavigationView: true)

      case .routeAction(_, .number(.list(.numberSelected(let number)))):
        state.routes.push(.number(.detail(.init(number: number))))

      case .routeAction(_, .number(.detail(.showDouble(let number)))):
        state.routes.presentSheet(.number(.detail(.init(number: number * 2))))

      case .routeAction(_, .number(.detail(.goBackTapped))):
        state.routes.goBack()

      case .routeAction(_, .number(.detail(.goBackToNumbersList))):
        return .routeWithDelaysIfUnsupported(state.routes) {
          // 이거 multiple 어떻게 함?
          $0.goBackTo { (screen: ScreenState) in
            guard case let .number(numberScreen) = screen, case .list(_) = numberScreen else {
              return false
            }
            return true
          }
        }

      case .routeAction(_, .number(.detail(.goBackToRootTapped))):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
    }
  )
