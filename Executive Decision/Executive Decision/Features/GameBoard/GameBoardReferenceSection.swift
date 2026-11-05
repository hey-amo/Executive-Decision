//
//  GameBoardReferenceSection.swift
//  Executive Decision
//

import SwiftUI

struct GameBoardReferenceSection<Content: View>: View {
    let title: String
    let helpText: String
    private let content: Content

    @State private var isExpanded = true
    @State private var isPresented = false

    init(
        title: String,
        helpText: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helpText = helpText
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(PlayerSetupStyle.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(
                        isExpanded ? "Hide" : "Show",
                        systemImage: isExpanded ? "chevron.up" : "chevron.down"
                    )
                }
                .accessibilityHint(isExpanded ? "Collapse this section" : "Expand this section")

                Button {
                    isPresented = true
                } label: {
                    Label("Open", systemImage: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityHint("Show this reference in a larger window")
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .buttonStyle(.plain)
            .padding(14)

            if isExpanded {
                content
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlayerSetupStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(PlayerSetupStyle.ink, lineWidth: 2)
        }
        .help(helpText)
        .sheet(isPresented: $isPresented) {
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.custom("Georgia-Bold", size: 20))
                        .foregroundStyle(PlayerSetupStyle.ink)

                    Spacer()

                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                ScrollView {
                    content
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(PlayerSetupStyle.paper.ignoresSafeArea())
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}
