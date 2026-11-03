import EDEngine
import SwiftUI

struct PlayerRosterSelectScreen: View {
    @State private var viewModel: PlayerRosterViewModel
    @State private var isShowingPlayerDrawer = false
    private let onContinue: ([EDPlayer]) -> Void

    init(
        firstPlayer: EDPlayer,
        onContinue: @escaping ([EDPlayer]) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: PlayerRosterViewModel(firstPlayer: firstPlayer))
        self.onContinue = onContinue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PlayerRosterHeaderView(
                    playerCount: viewModel.players.count,
                    maximumPlayers: kConstants.maxPlayers
                )

                LazyVStack(spacing: 14) {
                    ForEach(Array(viewModel.players.enumerated()), id: \.element.id) { index, player in
                        PlayerRosterRowView(player: player, isFirstPlayer: index == 0) {
                            viewModel.removePlayer(id: player.id)
                        }
                    }

                    if viewModel.players.count < kConstants.maxPlayers {
                        AddPlayerButtonView {
                            isShowingPlayerDrawer = true
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(PlayerRosterStyle.parchment.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ContinuePlayersButton(isEnabled: viewModel.canContinue) {
                onContinue(viewModel.players)
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(PlayerRosterStyle.parchment)
        }
        .sheet(isPresented: $isShowingPlayerDrawer) {
            AvailablePlayersDrawer(availablePlayers: viewModel.availableCharacters) { character, kind in
                viewModel.addPlayer(character, isAI: kind.isAI)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }
}

#Preview {
    PlayerRosterSelectScreen(firstPlayer: EDPlayer(name: "Vivian", avatar: .avt5))
}
