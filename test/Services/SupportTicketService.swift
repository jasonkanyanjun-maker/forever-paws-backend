import Foundation
import SwiftUI
import Combine

struct TicketAttachment: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let fileUrl: String
    let fileSize: Int
    let mimeType: String
    
    enum CodingKeys: String, CodingKey {
        case id, fileName = "file_name", fileUrl = "file_url"
        case fileSize = "file_size", mimeType = "mime_type"
    }
}

struct NewTicketRequest {
    let category: String
    let subject: String
    let description: String
    let attachments: [Data]
}

// MARK: - Support Ticket Service
class SupportTicketService: ObservableObject {
    private let supabase = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var tickets: [SupportTicket] = []
    @Published var currentTicket: SupportTicket?
    
    // MARK: - Fetch User Tickets
    func fetchUserTickets(for userId: UUID) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let data = try await supabase.client
                .from("support_tickets")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            let tickets = try JSONDecoder().decode([SupportTicket].self, from: data)
            
            await MainActor.run {
                self.tickets = tickets.sorted { $0.createdAt > $1.createdAt }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load tickets: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch Single Ticket
    func fetchTicket(id: UUID) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let data = try await supabase.client
                .from("support_tickets")
                .select()
                .eq("id", value: id.uuidString)
                .execute()
            
            let tickets = try JSONDecoder().decode([SupportTicket].self, from: data)
            
            await MainActor.run {
                self.currentTicket = tickets.first
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load ticket: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Create Support Ticket
    func createTicket(userId: UUID, request: NewTicketRequest) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Process attachments (in a real implementation, upload to storage)
            var attachments: [TicketAttachment] = []
            for (index, attachmentData) in request.attachments.enumerated() {
                let attachment = TicketAttachment(
                    id: UUID(),
                    fileName: "attachment_\(index + 1).jpg",
                    fileUrl: "https://placeholder.com/attachment/\(UUID().uuidString)",
                    fileSize: attachmentData.count,
                    mimeType: "image/jpeg"
                )
                attachments.append(attachment)
            }
            
            let attachmentsData = try JSONEncoder().encode(attachments)
            
            let ticketData: [String: Any] = [
                "user_id": userId.uuidString,
                "category": request.category,
                "subject": request.subject,
                "description": request.description,
                "status": SupportTicket.TicketStatus.open.rawValue,
                "attachments": attachmentsData
            ]
            
            _ = try await supabase.client
                .from("support_tickets")
                .insert(ticketData)
                .execute()
            
            // Refresh tickets after creation
            await fetchUserTickets(for: userId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create ticket: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Update Ticket Status
    func updateTicketStatus(ticketId: UUID, status: SupportTicket.TicketStatus) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let updateData: [String: Any] = [
                "status": status.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            _ = try await supabase.client
                .from("support_tickets")
                .update(updateData)
                .eq("id", value: ticketId.uuidString)
                .execute()
            
            // Refresh current ticket if it's the one being updated
            if currentTicket?.id == ticketId {
                await fetchTicket(id: ticketId)
            }
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update ticket status: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Add Admin Response
    func addAdminResponse(ticketId: UUID, response: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let updateData: [String: Any] = [
                "admin_response": response,
                "status": SupportTicket.TicketStatus.resolved.rawValue,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            _ = try await supabase.client
                .from("support_tickets")
                .update(updateData)
                .eq("id", value: ticketId.uuidString)
                .execute()
            
            // Refresh current ticket
            await fetchTicket(id: ticketId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add admin response: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Delete Ticket
    func deleteTicket(ticketId: UUID, userId: UUID) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            _ = try await supabase.client
                .from("support_tickets")
                .delete()
                .eq("id", value: ticketId.uuidString)
                .execute()
            
            // Refresh tickets after deletion
            await fetchUserTickets(for: userId)
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete ticket: \(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Get Tickets by Status
    func getTicketsByStatus(_ status: SupportTicket.TicketStatus) -> [SupportTicket] {
        return tickets.filter { $0.status == status }
    }
    
    // MARK: - Get Ticket Statistics
    func getTicketStatistics() -> (open: Int, inProgress: Int, resolved: Int, closed: Int) {
        let open = tickets.filter { $0.status == .open }.count
        let inProgress = tickets.filter { $0.status == .inProgress }.count
        let resolved = tickets.filter { $0.status == .resolved }.count
        let closed = tickets.filter { $0.status == .closed }.count
        
        return (open: open, inProgress: inProgress, resolved: resolved, closed: closed)
    }
}