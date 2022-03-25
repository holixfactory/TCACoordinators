//
//  Screen2.swift
//  TCACoordinatorsExample
//
//  Created by Dahoon Kim on 2022/03/23.
//

import Foundation
import SwiftUI
import TCACoordinators
import CasePaths
import ComposableArchitecture

struct NumbersListView: View {

  let store: Store<NumbersListState, NumbersListAction>

  var body: some View {
    WithViewStore(store.scope(state: \.numbers)) { viewStore in
      List(viewStore.state, id: \.self) { number in
        Button(
          "\(number)",
          action: {
            viewStore.send(.numberSelected(number))
          })
      }
    }
    .navigationTitle("Numbers")
  }
}

enum NumbersListAction {

  case numberSelected(Int)
}

struct NumbersListState: Equatable {

  let id = UUID()
  var numbers: [Int]
}

struct NumbersListEnvironment {}

let numbersListReducer = Reducer<
  NumbersListState, NumbersListAction, NumbersListEnvironment
> { state, action, environment in
  return .none
}

// NumberDetail

struct NumberDetailView: View {

  let store: Store<NumberDetailState, NumberDetailAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      VStack(spacing: 8.0) {
        Text("Number \(viewStore.number)")
        Button("Increment") {
          viewStore.send(.incrementTapped)
        }
        Button("Increment after delay") {
          viewStore.send(.incrementAfterDelayTapped)
        }
        Button("Show double") {
          viewStore.send(.showDouble(viewStore.number))
        }
        Button("Go back") {
          viewStore.send(.goBackTapped)
        }
        Button("Go back to root") {
          viewStore.send(.goBackToRootTapped)
        }
        Button("Go back to numbers list") {
          viewStore.send(.goBackToNumbersList)
        }
        Button("Test Kill All") {
          viewStore.send(.killAll)
        }
      }
      .navigationTitle("Number \(viewStore.number)")
    }
  }
}

enum NumberDetailAction {
  case goBackTapped
  case goBackToRootTapped
  case goBackToNumbersList
  case incrementAfterDelayTapped
  case incrementTapped
  case showDouble(Int)
  case killAll
}

struct NumberDetailState: Equatable {

  let id = UUID()
  var number: Int
}

struct NumberDetailEnvironment {}

let numberDetailReducer = Reducer<NumberDetailState, NumberDetailAction, NumberDetailEnvironment> {
  state, action, environment in
  switch action {
  case .goBackToRootTapped, .goBackTapped, .goBackToNumbersList, .showDouble, .killAll:
    return .none

  case .incrementAfterDelayTapped:
    return Effect(value: NumberDetailAction.incrementTapped)
      .delay(for: 3.0, tolerance: nil, scheduler: DispatchQueue.main, options: nil)
      .eraseToEffect()

  case .incrementTapped:
    state.number += 1
    return .none
  }
}


enum NumberState: Equatable, Identifiable {
  case list(NumbersListState)
  case detail(NumberDetailState)

  var id: UUID {
    switch self {
    case .list(let state):
      return state.id
    case .detail(let state):
      return state.id
    }
  }
}

enum NumberAction {
  case list(NumbersListAction)
  case detail(NumberDetailAction)
}


let numberReducer = Reducer<NumberState, NumberAction, Void>.combine(
  numbersListReducer
    .pullback(
      state: /NumberState.list,
      action: /NumberAction.list,
      environment: { _ in NumbersListEnvironment() }
    ),
  numberDetailReducer
    .pullback(
      state: /NumberState.detail,
      action: /NumberAction.detail,
      environment: { _ in NumberDetailEnvironment() }
    )
)

struct NumberCoordinatorView: View {
  let store: Store<NumberState, NumberAction>

  var body: some View {
    SwitchStore(store) {
      CaseLet(
        state: /NumberState.list,
        action: NumberAction.list,
        then: NumbersListView.init
      )
      CaseLet(
        state: /NumberState.detail,
        action: NumberAction.detail,
        then: NumberDetailView.init
      )
    }
  }

}

extension Reducer where State: IdentifiedRouterState, Action: IdentifiedRouterAction, State.Screen == Action.Screen {
  static func numberCoordinatorReducer(
    toScreenState: @escaping (_: NumberState) -> State.Screen,
    fromScreenState: CasePath<State.Screen, NumberState>,
    fromScreenAction: CasePath<Action.ScreenAction, NumberAction>
  ) -> Self where State.Screen.ID == NumberState.ID {
    .init { (state, action, _) -> Effect in
      guard let (_, routeAction) = (/Action.routeAction).extract(from: action) else {
        return .none
      }

      guard let numberAction = fromScreenAction.extract(from: routeAction) else {
        return .none
      }

      switch numberAction {
      // Test: 다른 screen의 state를 변경해보자
      case .detail(.incrementTapped):
        if var listScreen = state.routes.compactMap({ (route) -> NumbersListState? in
          guard let numberScreen = fromScreenState.extract(from: route.screen), case let .list(listScreen) = numberScreen else {
            return nil
          }
          return listScreen
        }).last {
          if var currentRoute = state.routes[id: listScreen.id] {
            listScreen.numbers = [10, 20, 30, 50, 100]
            currentRoute.screen = toScreenState(.list(listScreen))
            state.routes.updateOrAppend(currentRoute)
          }
        }

      case .list(.numberSelected(let number)):
        state.routes.push(toScreenState(.detail(.init(number: number))))
      case .detail(.showDouble(let number)):
        state.routes.presentSheet(toScreenState(.detail(.init(number: number * 2))))
      case .detail(.goBackTapped):
        state.routes.goBack()
      case .detail(.goBackToNumbersList):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackTo { (screen: State.Screen) in
            guard let numberScreen = fromScreenState.extract(from: screen), case .list(_) = numberScreen else {
              return false
            }
            return true
          }
        }
      case .detail(.goBackToRootTapped):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackToRoot()
        }
      case .detail(.killAll):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBack($0.count)
        }
      default:
        break
      }
      return .none
    }
  }
}
