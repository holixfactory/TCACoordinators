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
    _ complexStore: Store<ComplexCoordinatorState, CoordinatorAction>,
    toIdOnlyScreen toScreen: @escaping (_: ID) -> Screen,
    screenContent: @escaping (Store<ComplexCoordinatorState.Screen, CoordinatorAction.ScreenAction>) -> ScreenContent
  ) where ComplexCoordinatorState: IdentifiedRouterState & Equatable,
          ComplexCoordinatorState.Screen.ID == ID,
          ComplexCoordinatorState.Screen == CoordinatorAction.Screen
  {
    let complexViewStore = ViewStore(complexStore)
    self.init(
      store: complexStore.scope(state: {
        IdentifiedArray.init(
          uniqueElements: $0.routes.map { (route: Route<ComplexCoordinatorState.Screen>) -> Route<Screen> in
            switch route {
            case .push(let screen):
              return .push(toScreen(screen.id))
            case let .cover(screen, embedInNavigationView: embed, onDismiss: onDismiss):
              return .cover(toScreen(screen.id), embedInNavigationView: embed, onDismiss: onDismiss)
            case let .sheet(screen, embedInNavigationView: embed, onDismiss: onDismiss):
              return .sheet(toScreen(screen.id), embedInNavigationView: embed, onDismiss: onDismiss)
            }
          }
        )
      }),
      routes: { $0 },
      updateRoutes: {
        .updateRoutes(.init(uniqueElements: $0.compactMap { idOnly in
          complexViewStore.routes[id: idOnly.id]
        }))
      },
      action: CoordinatorAction.routeAction,
      screenContent: { idOnlyScreen in
        var screenState = complexViewStore.routes[id: ViewStore(idOnlyScreen).id]!.screen
        return screenContent(idOnlyScreen.scope(state: {
          screenState = complexViewStore.routes[id: $0.id]?.screen ?? screenState
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
      store,
      toIdOnlyScreen: { IdOnlyScreen(id: $0) }
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
      fromScreenAction: /ScreenAction.number
    )
  )
)
