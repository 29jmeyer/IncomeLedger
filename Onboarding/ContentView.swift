//  ContentView.swift
//  APP
//
//  Created by john meyer on 2025-11-29.
//

import SwiftUI

// MARK: - Constants

enum Timing {
    // Tap forward timing (slide)
    static let slide: Double = 1.75
    // Dot-jump timing (backward fade)
    static let backFade: Double = 0.5
}

struct OnboardingStep {
    let symbol: String
    let title: String
    let subtitle: String
}

// MARK: - ContentView

struct ContentView: View {
    // Data-driven onboarding steps (5 steps)
    static let steps: [OnboardingStep] = [
        .init(
            symbol: "dollarsign.circle.fill",
            title: "Know your paycheck. Every Shift.",
            subtitle: "Track your hours and earnings instantly  no spreadsheets, no math."
        ),
        .init(
            symbol: "hand.tap",
            title: "Add shifts in seconds.",
            subtitle: "Enter your start and end times - we calculate everything for you."
        ),
        .init(
            symbol: "square.and.pencil",
            title: "See your estimated paycheck before it arrives.",
            subtitle: "Automatically track your pay period total and take-home estimate."
        ),
        .init(
            symbol: "list.bullet",
            title: "Overtime Calculated automatically.",
            subtitle: "Your rate switches the moment you pass your weekly hours threshold - no manual math."
        ),
        .init(
            symbol: "checkmark.seal",
            title: "Ready to Begin?",
            subtitle: "Let’s jump into the app."
        )
    ]
    
    // State
    @State private var stepIndex = 0
    @State private var onboardingDone = false
    @State private var isTransitioning = false
    @State private var showingPage = true
    // Opacity for dot-jump fade (single page, no crossfade overlap)
    @State private var fadeOpacity: Double = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
                financeBackground
                    .ignoresSafeArea()
                
                if onboardingDone {
                    instructionsView
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.35), value: onboardingDone)
                } else {
                    onboarding
                        .transition(.opacity)
                }
            }
            .navigationTitle("")
            #if os(iOS) || os(tvOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 700)
        #endif
        .onAppear {
            showingPage = true
            fadeOpacity = 1.0
        }
    }
    
    // MARK: - Background
    
    private var financeBackground: some View {
        ZStack {
            // Premium finance gradient: deep teal -> emerald -> blue
            LinearGradient(
                colors: [
                    Color(hex: 0x0A3D3F),                   // deep teal
                    Color(hex: 0x0F6B5F).opacity(0.95),    // teal-emerald
                    Color(hex: 0x0E5AA7).opacity(0.90)     // finance blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Soft vignette for depth and to anchor content
            RadialGradient(
                gradient: Gradient(colors: [
                    .black.opacity(0.0),
                    .black.opacity(0.15)
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 600
            )
            .blendMode(.multiply)
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Onboarding
    
    private var onboarding: some View {
        ZStack {
            if showingPage {
                OnboardingPage(
                    step: Self.steps[stepIndex],
                    isFinal: stepIndex == Self.steps.count - 1,
                    index: stepIndex,
                    total: Self.steps.count,
                    onDotTap: jumpToStep(_:),
                    onFinish: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            onboardingDone = true
                        }
                    }
                )
                // Transition depends on destination step
                .transition(transitionForCurrentStep)
                // Manual fade for dot jumps (no transition used)
                .opacity(fadeOpacity)
            }
        }
        .contentShape(Rectangle())
        // Tap anywhere to go forward
        .onTapGesture {
            guard canGoNext, !isTransitioning else { return }
            goToNextStep()
        }
        .allowsHitTesting(!isTransitioning)
    }
    
    // Use slide for most steps; for slide 4 (index 3) use fade
    private var transitionForCurrentStep: AnyTransition {
        if stepIndex == 3 {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }
    
    private var canGoNext: Bool {
        stepIndex < Self.steps.count - 1
    }
    
    // MARK: - Navigation
    
    private func goToNextStep() {
        guard canGoNext, !isTransitioning else { return }
        isTransitioning = true
        
        let duration = Timing.slide
        
        withAnimation(.easeInOut(duration: duration)) {
            showingPage = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            stepIndex = min(stepIndex + 1, Self.steps.count - 1)
            
            withAnimation(.easeInOut(duration: duration)) {
                showingPage = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isTransitioning = false
            }
        }
    }
    
    private func jumpToStep(_ target: Int) {
        // Only allow jumping strictly backward; never forward via dots
        guard target >= 0, target < stepIndex, !isTransitioning else { return }
        isTransitioning = true
        
        let duration = Timing.backFade
        
        // Fade current out
        withAnimation(.easeInOut(duration: duration)) {
            fadeOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            stepIndex = target
            
            // Fade new in
            withAnimation(.easeInOut(duration: duration)) {
                fadeOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isTransitioning = false
            }
        }
    }
    
    // MARK: - Instructions (post-onboarding)
    
    private var instructionsView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Instructions")
                    .font(.largeTitle.bold())
                Text("Filler steps you can replace later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InstructionCard(title: "Step 1", text: "Explain the first thing users should do.")
                    InstructionCard(title: "Step 2", text: "Describe a key feature or action.")
                    InstructionCard(title: "Step 3", text: "Add tips for better results.")
                    InstructionCard(title: "Step 4", text: "Show how to manage or edit items.")
                    InstructionCard(title: "Support", text: "Tell users where to get help.")
                }
                .padding(16)
            }
        }
        .background(.clear)
    }
}

#Preview {
    ContentView()
}

