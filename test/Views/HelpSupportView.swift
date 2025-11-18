import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supportService = SupportTicketService()
    
    @State private var showingNewTicket = false
    @State private var selectedTicket: SupportTicket?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("How can we help you?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Get quick answers or submit a support ticket")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Actions
                        quickActionsSection
                        
                        // FAQ Section
                        faqSection
                        
                        // Support Tickets
                        supportTicketsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewTicket = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewTicket) {
            NewSupportTicketView()
        }
        .sheet(item: $selectedTicket) { ticket in
            SupportTicketDetailView(ticket: ticket)
        }
        .onAppear {
            Task {
                // Get current user ID from SupabaseService
                if let userId = SupabaseService.shared.currentUser?.id {
                    await supportService.fetchUserTickets(for: userId)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Help")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "envelope.fill",
                    title: "Contact Us",
                    subtitle: "Send us an email",
                    color: .blue
                ) {
                    if let url = URL(string: "mailto:support@foreverpaws.com") {
                        UIApplication.shared.open(url)
                    }
                }
                
                QuickActionCard(
                    icon: "phone.fill",
                    title: "Call Support",
                    subtitle: "Speak with our team",
                    color: .green
                ) {
                    if let url = URL(string: "tel:+1-800-PAWS-HELP") {
                        UIApplication.shared.open(url)
                    }
                }
                
                QuickActionCard(
                    icon: "globe",
                    title: "Website",
                    subtitle: "Visit our help center",
                    color: .orange
                ) {
                    if let url = URL(string: "https://foreverpaws.com/help") {
                        UIApplication.shared.open(url)
                    }
                }
                
                QuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Live Chat",
                    subtitle: "Chat with support",
                    color: .purple
                ) {
                    // TODO: Implement live chat
                }
            }
        }
    }
    
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                FAQItem(
                    question: "How do I add a new pet?",
                    answer: "Go to the main dashboard and tap the '+' button to add a new pet. Fill in your pet's information and upload a photo."
                )
                
                FAQItem(
                    question: "How does the AI video generation work?",
                    answer: "Our AI uses your pet's photos and personality traits to create personalized videos. The process typically takes 2-3 minutes."
                )
                

                
                FAQItem(
                    question: "How do I cancel my subscription?",
                    answer: "You can manage your subscription through your Apple ID settings or contact our support team for assistance."
                )
            }
        }
    }
    
    private var supportTicketsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Support Tickets")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if supportService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if supportService.tickets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "ticket")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No support tickets yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: { showingNewTicket = true }) {
                        Text("Create Your First Ticket")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(supportService.tickets) { ticket in
                        SupportTicketRow(ticket: ticket) {
                            selectedTicket = ticket
                        }
                    }
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct SupportTicketRow: View {
    let ticket: SupportTicket
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(ticket.status.color)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.subject)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(ticket.category.displayName)
                            .font(.caption)
                            .foregroundColor(ticket.category.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ticket.category.color.opacity(0.1))
                            .cornerRadius(4)
                        
                        Text(ticket.status.displayName)
                            .font(.caption)
                            .foregroundColor(ticket.status.color)
                    }
                    
                    Text(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}



#Preview {
    HelpSupportView()
}