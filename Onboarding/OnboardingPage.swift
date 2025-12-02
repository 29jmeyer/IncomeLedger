//  OnboardingPage.swift
//  APP

import SwiftUI

struct OnboardingPage: View {
    let step: OnboardingStep
    let isFinal: Bool
    let index: Int
    let total: Int
    let onDotTap: (Int) -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: step.symbol)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(radius: 8)
                .padding(.top, 20)
                .accessibilityHidden(true)
            
            Text(step.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Text(step.subtitle)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            
            demo
                .padding(.horizontal, 24)
                .padding(.top, 4)
            
            Spacer()
            
            if isFinal {
                Button {
                    onFinish()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("onboarding.getStartedButton")
            }
            
            ProgressDots(current: index, total: total, onTap: onDotTap)
                .padding(.bottom, isFinal ? 0 : 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 24)
    }
    
    @ViewBuilder
    private var demo: some View {
        switch index {
        case 0:
            EarningsAutoDemo(hourlyRate: 22.00, targetHours: 8.0)
        case 1:
            ShiftListAutoDemo()
        case 2:
            PaycheckAutoDemo(
                totalTarget: 1742.00,
                startDays: 5,
                dateLabel: "Nov 28"
            )
        case 3:
            OvertimeSplitDemo(
                hourlyRate: 22.0,
                thresholdHours: 40.0,
                otMultiplier: 1.5,
                weeklyHoursAtStart: 38.0,
                shiftLength: 6.0
            )
        default:
            EmptyView()
        }
    }
}

struct ProgressDots: View {
    let current: Int
    let total: Int
    let onTap: (Int) -> Void
    
    private let smallSize: CGFloat = 8
    private let largeSize: CGFloat = 12
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                let isCurrent = (i == current)
                let isEnabled = (i < current)
                
                Circle()
                    .fill(.white.opacity(0.95))
                    .frame(
                        width: isCurrent ? largeSize : smallSize,
                        height: isCurrent ? largeSize : smallSize
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.9), lineWidth: isCurrent ? 0 : 0.5)
                    )
                    .opacity(isEnabled ? 1.0 : 0.5)
                    .contentShape(Circle())
                    .onTapGesture {
                        if isEnabled { onTap(i) }
                    }
                    .animation(.easeInOut(duration: 0.2), value: current)
                    .accessibilityLabel("Go to step \(i + 1)")
                    .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
                    .accessibilityHint(isEnabled ? "Tap to jump back to this step" : "Disabled; you can only go back")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

struct InstructionCard: View {
    let title: String
    let text: String
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

