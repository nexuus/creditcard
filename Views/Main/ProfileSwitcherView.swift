//
//  ProfileSwitcherView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/22/25.
//


import SwiftUI

struct ProfileSwitcherView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showingCreateProfile = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header
                    Text("Switch Profile")
                        .font(.headline)
                        .padding(.top)
                    
                    // Profiles list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.profiles) { profile in
                                // In ProfileSwitcherView.swift, modify the onSelect action
                                ProfileRowView(
                                    profile: profile,
                                    isActive: profile.id == viewModel.activeProfile?.id,
                                    onSelect: {
                                        // Add this line to sync cards before switching
                                        if let cardViewModel = AppState.shared.cardViewModel {
                                            cardViewModel.syncCardsToActiveProfile()
                                        }
                                        
                                        viewModel.switchProfile(profile.id)
                                    },
                                    onDelete: {
                                        viewModel.deleteProfile(profile.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Create new profile button
                    Button(action: {
                        showingCreateProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Create New Profile")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarItems(trailing: Button("Done") {
                viewModel.isProfileSwitcherVisible = false
            })
            .sheet(isPresented: $showingCreateProfile) {
                CreateProfileView(viewModel: viewModel)
            }
        }
    }
}
