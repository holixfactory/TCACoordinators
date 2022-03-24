import SwiftUI
import ComposableArchitecture
import TCACoordinators



extension TCARouter where Screen: Identifiable,
                          CoordinatorState == IdentifiedArrayOf<Route<Screen>>,
                          CoordinatorAction: IdentifiedRouterAction,
                          CoordinatorAction.Screen.ID == Screen.ID,
                          CoordinatorAction.ScreenAction == ScreenAction,
                          Screen.ID == ID
                          {

  public init<ComplexCoordinatorState>(
    complexStore store: Store<ComplexCoordinatorState, CoordinatorAction>,
    fromComplex: @escaping (_: ID) -> Screen,
    screenContent: @escaping (Store<ComplexCoordinatorState.Screen, CoordinatorAction.ScreenAction>) -> ScreenContent
  ) where ComplexCoordinatorState: IdentifiedRouterState & Equatable,
          ComplexCoordinatorState.Screen.ID == ID,
          ComplexCoordinatorState.Screen == CoordinatorAction.Screen
  {
    self.init(
      store: store.scope(state: {
        IdentifiedArray.init(
          uniqueElements: $0.routes.map { (route: Route<ComplexCoordinatorState.Screen>) -> Route<Screen> in
            switch route {
            case .push(let screen):
              return .push(fromComplex(screen.id))
            case let .cover(screen, embedInNavigationView: embed, onDismiss: onDismiss):
              return .cover(fromComplex(screen.id), embedInNavigationView: embed, onDismiss: onDismiss)
            case let .sheet(screen, embedInNavigationView: embed, onDismiss: onDismiss):
              return .sheet(fromComplex(screen.id), embedInNavigationView: embed, onDismiss: onDismiss)
            }
          }
        )
      }),
      routes: { $0 },
      updateRoutes: {
        .updateRoutes(.init(uniqueElements: $0.compactMap { idOnly in
          ViewStore(store).routes[id: idOnly.id]
        }))
      },
      action: CoordinatorAction.routeAction,
      screenContent: { idOnlyScreen in
        var screenState = ViewStore(store).routes[id: ViewStore(idOnlyScreen).id]!.screen
        return screenContent(idOnlyScreen.scope(state: {
          screenState = ViewStore(store).routes[id: $0.id]?.screen ?? screenState
          return screenState
        }))
      }
    )
  }
}

struct IdOnlyScreen: Equatable, Identifiable {
  let id: UUID
}

struct IdentifiedCoordinatorView: View {

  let store: Store<IdentifiedCoordinatorState, IdentifiedCoordinatorAction>

  var body: some View {
    TCARouter(
      complexStore: store,
      fromComplex: { IdOnlyScreen(id: $0) }
    ) { screen in
      ScreenView(store: screen).equatable()
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
