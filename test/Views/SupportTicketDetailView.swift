import SwiftUI

struct SupportTicketDetailView: View {
    let ticket: SupportTicket
    @Environment(\.dismiss) private var dismiss
    @StateObject private var supportService = SupportTicketService()
    
    @State private var showingStatusUpdate = false
    @State private var selectedStatus: SupportTicket.TicketStatus = .open
    @State private var adminResponse = ""
    @State private var showingAdminResponse = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        // Status Badge
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(ticket.status.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(ticket.status.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ticket.status.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ticket.status.color.opacity(0.1))
                            .cornerRadius(16)
                        }
                        
                        // Category and Date
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: ticket.category.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(ticket.category.color)
                                
                                Text(ticket.category.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(ticket.category.color)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ticket.category.color.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text("Created \(ticket.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Ticket Content
                    VStack(alignment: .leading, spacing: 20) {
                        // Subject
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(ticket.subject)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(ticket.description)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Attachments
                        if !ticket.attachments.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Attachments")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(ticket.attachments, id: \.self) { attachment in
                                        AttachmentView(attachmentUrl: attachment)
                                    }
                                }
                            }
                        }
                        
                        // Admin Response
                        if let adminResponse = ticket.adminResponse {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.badge.shield.checkmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                    
                                    Text("Support Team Response")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                
                                Text(adminResponse)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if ticket.status != .closed {
                                Button(action: { showingStatusUpdate = true }) {
                                    HStack {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                        Text("Update Status")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                            
                            if ticket.adminResponse == nil && ticket.status != .resolved && ticket.status != .closed {
                                Button(action: { showingAdminResponse = true }) {
                                    HStack {
                                        Image(systemName: "bubble.left.and.bubble.right")
                                        Text("Add Response")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Ticket Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingStatusUpdate) {
            StatusUpdateView(
                currentStatus: ticket.status,
                onStatusUpdate: { newStatus in
                    Task {
                        await supportService.updateTicketStatus(ticketId: ticket.id, status: newStatus)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAdminResponse) {
            AdminResponseView(
                ticketId: ticket.id,
                onResponseAdded: { response in
                    Task {
                        await supportService.addAdminResponse(ticketId: ticket.id, response: response)
                    }
                }
            )
        }
    }
}

struct AttachmentView: View {
    let attachmentUrl: String
    
    var body: some View {
        Button(action: {
            // TODO: Open attachment
        }) {
            VStack(spacing: 8) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text("Attachment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusUpdateView: View {
    let currentStatus: SupportTicket.TicketStatus
    let onStatusUpdate: (SupportTicket.TicketStatus) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: SupportTicket.TicketStatus
    
    init(currentStatus: SupportTicket.TicketStatus, onStatusUpdate: @escaping (SupportTicket.TicketStatus) -> Void) {
        self.currentStatus = currentStatus
        self.onStatusUpdate = onStatusUpdate
        self._selectedStatus = State(initialValue: currentStatus)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Update Ticket Status")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    ForEach(SupportTicket.TicketStatus.allCases, id: \.self) { status in
                        StatusRow(
                            status: status,
                            isSelected: selectedStatus == status,
                            isCurrent: currentStatus == status
                        ) {
                            selectedStatus = status
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Update Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        onStatusUpdate(selectedStatus)
                        dismiss()
                    }
                    .disabled(selectedStatus == currentStatus)
                }
            }
        }
    }
}

struct StatusRow: View {
    let status: SupportTicket.TicketStatus
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if isCurrent {
                        Text("Current Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminResponseView: View {
    let ticketId: UUID
    let onResponseAdded: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var response = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Add Support Response")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Response")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .frame(minHeight: 200)
                        
                        TextEditor(text: $response)
                            .padding(12)
                            .font(.system(size: 16))
                            .scrollContentBackground(.hidden)
                        
                        if response.isEmpty {
                            Text("Enter your response to help resolve this ticket...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("Add Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        onResponseAdded(response)
                        dismiss()
                    }
                    .disabled(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    SupportTicketDetailView(
        ticket: SupportTicket(
            id: UUID(),
            userId: UUID(),
            category: .technical,
            subject: "Video generation not working",
            description: "The AI video generation fails after uploading pet photos. I've tried multiple times but it keeps showing an error message.",
            status: .open,
            attachments: ["attachment1.jpg", "attachment2.jpg"],
            adminResponse: nil,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86400)
        )
    )
}