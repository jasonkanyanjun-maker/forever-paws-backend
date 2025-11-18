//
//  testApp.swift
//  test
//
//  Created by junlish on 10/13/25.
//

import SwiftUI
import SwiftData

@main
struct testApp: App {
    @StateObject private var supabaseService = SupabaseService.shared
    

    
    init() {
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "prefer_production_backend")
        #endif
    }
    var sharedModelContainer: ModelContainer = {
        func ensureAppSupportDirectory() throws {
            let fm = FileManager.default
            let urls = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            guard let appSupport = urls.first else { throw NSError(domain: "File", code: 1) }
            var isDir: ObjCBool = false
            if !fm.fileExists(atPath: appSupport.path, isDirectory: &isDir) {
                try fm.createDirectory(at: appSupport, withIntermediateDirectories: true)
                print("✅ Created Application Support directory at: \(appSupport.path)")
            } else if !isDir.boolValue {
                throw NSError(domain: "File", code: 2)
            }
        }
        let schema = Schema([
            Item.self,
            VideoGeneration.self,
            Pet.self,
            Letter.self,
            Product.self,
            Order.self,
            OrderItem.self,
            Subscription.self,
            CartItem.self  // 添加CartItem到Schema中
        ])
        
        // 使用持久化存储而不是内存存储
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            try ensureAppSupportDirectory()
            print("🔄 Initializing ModelContainer...")
            print("📋 Schema contains models: Item, VideoGeneration, Pet, Letter, Product, Order, OrderItem, Subscription, CartItem")
            print("💾 Using persistent storage (not in-memory)")
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ ModelContainer initialized successfully")
            return container
        } catch {
            print("❌ ModelContainer initialization failed: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            // 如果持久化存储失败，尝试清理并重新创建
            print("🔄 Attempting to create new persistent storage...")
            do {
                try ensureAppSupportDirectory()
                // 创建新的持久化配置
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("✅ Fallback ModelContainer created successfully")
                return container
            } catch {
                print("❌ Fallback also failed, using in-memory as last resort")
                
                // 最后的备用方案：使用内存存储
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                    print("⚠️ Using in-memory storage - data will not persist")
                    return container
                } catch {
                    fatalError("Unable to create any ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // 应用进入后台时保存状态
                    print("🔄 App entering background, saving login state...")
                    if supabaseService.isAuthenticated {
                        UserDefaults.standard.set(true, forKey: "autoLogin")
                        print("✅ Auto login state saved")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // 应用重新获得焦点时检查登录状态
                    print("🔄 App became active, checking login state...")
                    Task {
                        await supabaseService.checkAutoLogin()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
