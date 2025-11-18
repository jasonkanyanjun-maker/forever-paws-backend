//
//  AuthenticationView.swift
//  Forever Paws
//
//  Created by AI Assistant
//

import SwiftUI
import CoreHaptics

struct AuthenticationView: View {
    @Binding var isAuthenticated: Bool
    @Binding var currentUser: UserProfile?
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var emailValidationMessage = ""
    @State private var passwordValidationMessage = ""
    
    // 保存注册信息用于自动填充
    @State private var savedEmail = ""
    @State private var savedPassword = ""
    @State private var showRegistrationSuccess = false
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    
    // 记住账号密码功能
    @State private var rememberCredentials = false
    
    // 添加键盘避让状态
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    private let supabaseService = SupabaseService.shared
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(hex: "F8F4F0"),
                    Color(hex: "E879F9").opacity(0.1),
                    Color(hex: "F472B6").opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 加载时显示进度指示器
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "E879F9")))
                        .scaleEffect(1.5)
                    
                    Text(isSignUp ? "Creating account..." : "Signing in...")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .padding(32)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Logo和标题
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Forever Paws")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Keep your beloved pets forever in your heart")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // 移除了 Apple 和 Google 登录按钮
                    VStack(spacing: 16) {
                        
                        // 模拟器跳过登录
                        #if targetEnvironment(simulator)
                        Button(action: skipLoginForSimulator) {
                            HStack {
                                Image(systemName: "iphone")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Skip Login (Simulator Only)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        #endif
                    }
                    .padding(.horizontal, 32)
                    
                    // 分隔线
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("Or")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    
                    // 邮箱登录表单
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($isEmailFocused)
                                .onChange(of: email) { oldValue, newValue in
                                    // 简化的验证机制
                                    Task { @MainActor in
                                        // 如果邮箱为空，立即清除验证消息
                                        if newValue.isEmpty {
                                            emailValidationMessage = ""
                                        } else {
                                            // 延迟验证，避免频繁调用
                                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                            validateEmailDelayed(newValue)
                                        }
                                    }
                                }
                            
                            // 邮箱验证提示
                            if !emailValidationMessage.isEmpty {
                                Text(emailValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($isPasswordFocused)
                                .onChange(of: password) { oldValue, newValue in
                                    // 安全的防抖机制，避免频繁验证导致崩溃
                                    Task { @MainActor in
                                        if isSignUp && !newValue.isEmpty {
                                            // 延迟验证，避免频繁调用
                                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                            validatePasswordDelayed(newValue)
                                        } else {
                                            passwordValidationMessage = ""
                                        }
                                    }
                                }
                            
                            // 密码格式要求显示
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Password Requirements:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(password.count >= 8 ? .green : .gray)
                                            .font(.caption)
                                        Text("At least 8 characters")
                                            .font(.caption)
                                            .foregroundColor(password.count >= 8 ? .green : .secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: containsUppercase(password) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(containsUppercase(password) ? .green : .gray)
                                            .font(.caption)
                                        Text("At least one uppercase letter")
                                            .font(.caption)
                                            .foregroundColor(containsUppercase(password) ? .green : .secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: containsLowercase(password) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(containsLowercase(password) ? .green : .gray)
                                            .font(.caption)
                                        Text("At least one lowercase letter")
                                            .font(.caption)
                                            .foregroundColor(containsLowercase(password) ? .green : .secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: containsNumber(password) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(containsNumber(password) ? .green : .gray)
                                            .font(.caption)
                                        Text("At least one number")
                                            .font(.caption)
                                            .foregroundColor(containsNumber(password) ? .green : .secondary)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            // 密码验证错误信息
                            if !passwordValidationMessage.isEmpty {
                                Text(passwordValidationMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                            }
                        }
                        
                        // 登录/注册按钮
                        // 记住账号密码选项（仅登录时显示）
                        if !isSignUp {
                            HStack {
                                Button(action: {
                                    rememberCredentials.toggle()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: rememberCredentials ? "checkmark.square.fill" : "square")
                                            .foregroundColor(rememberCredentials ? Color(hex: "E879F9") : .gray)
                                            .font(.system(size: 16))
                                        
                                        Text("Remember account and password")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        
                        Button(action: handleEmailAuth) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && !isPasswordValid()))
                        
                        // 忘记密码链接
                        if !isSignUp {
                            Button("Forgot password?") {
                                showForgotPasswordAlert()
                            }
                            .font(.subheadline)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // 切换登录/注册
                    HStack {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(isSignUp ? "Login" : "Register") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isSignUp.toggle()
                                
                                // 清除验证消息
                                emailValidationMessage = ""
                                passwordValidationMessage = ""
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "E879F9"), Color(hex: "F472B6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        // 添加键盘避让
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            // 点击空白区域隐藏键盘
            isEmailFocused = false
            isPasswordFocused = false
        }
        .onAppear {
            // 应用启动时加载保存的凭据
            loadSavedCredentials()
        }
        .alert("Alert", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Registration Successful", isPresented: $showRegistrationSuccess) {
            Button("Continue") {
                // 注册成功后直接进入app，不需要再次登录
                Task { @MainActor in
                    // 检查用户是否已经被认证
                    if SupabaseService.shared.isAuthenticated, let supabaseUser = SupabaseService.shared.currentUser {
                        let userProfile = UserProfile(
                            id: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                            userId: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                            name: supabaseUser.displayName ?? "User"
                        )
                        currentUser = userProfile
                        isAuthenticated = true
                        print("✅ Registration successful, user authenticated and ready to enter app")
                    } else {
                        print("⚠️ Registration completed but user not authenticated, attempting auto-login")
                        // 如果由于某种原因用户未被认证，则尝试自动登录
                        do {
                            try await SupabaseService.shared.signInWithEmail(savedEmail, password: savedPassword, rememberCredentials: rememberCredentials)
                            
                            if let supabaseUser = SupabaseService.shared.currentUser {
                                let userProfile = UserProfile(
                                    id: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                                    userId: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                                    name: supabaseUser.displayName ?? "User"
                                )
                                currentUser = userProfile
                                isAuthenticated = SupabaseService.shared.isAuthenticated
                            }
                        } catch {
                            showAlert("Auto-login failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } message: {
            Text("Your account has been created successfully. Welcome to Forever Paws!")
        }
        .alert("Forgot Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $forgotPasswordEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            Button("Send Reset Link") {
                sendPasswordResetEmail()
            }
            .disabled(forgotPasswordEmail.isEmpty || !isValidEmail(forgotPasswordEmail))
            Button("Cancel", role: .cancel) {
                forgotPasswordEmail = ""
            }
        } message: {
            Text("Enter your email address to receive a password reset link.")
        }
    }
    
    // MARK: - 模拟器跳过登录
    private func skipLoginForSimulator() {
        Task {
            await supabaseService.skipLoginForSimulator()
            
            await MainActor.run {
                // 创建模拟用户资料
                let mockUserProfile = UserProfile(
                    id: UUID(),
                    userId: UUID(),
                    name: "Simulator User"
                )
                
                self.currentUser = mockUserProfile
                self.isAuthenticated = true
                
                print("✅ 模拟器登录成功")
            }
        }
    }
    
    // 移除了 Apple 和 Google 登录处理函数
    
    // MARK: - 忘记密码功能
    private func showForgotPasswordAlert() {
        forgotPasswordEmail = email // 预填充当前输入的邮箱
        showForgotPassword = true
    }
    
    private func sendPasswordResetEmail() {
        guard !forgotPasswordEmail.isEmpty, isValidEmail(forgotPasswordEmail) else { return }
        
        Task {
            do {
                try await supabaseService.resetPassword(email: forgotPasswordEmail)
                
                await MainActor.run {
                    showAlert("Password reset email sent to \(forgotPasswordEmail). Please check your inbox.")
                    forgotPasswordEmail = ""
                }
            } catch {
                await MainActor.run {
                    showAlert("Failed to send password reset email: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 邮箱登录/注册
    private func handleEmailAuth() {
        guard !email.isEmpty && !password.isEmpty else {
            showAlert("Please fill in all fields")
            return
        }
        
        guard isValidEmail(email) else {
            showAlert("Please enter a valid email address")
            return
        }
        
        // 注册时验证密码格式
        if isSignUp && !isPasswordValid() {
            showAlert("Please ensure your password meets all requirements")
            return
        }
        
        // 隐藏键盘
        isEmailFocused = false
        isPasswordFocused = false
        
        // 添加触觉反馈的安全处理
        performHapticFeedback()
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    print("🔧 [AuthenticationView] Starting registration for: \(email)")
                    let credentials = try await SupabaseService.shared.signUpWithEmail(email, password: password)
                    
                    await MainActor.run {
                        // 保存注册信息用于自动填充
                        savedEmail = credentials.email
                        savedPassword = credentials.password
                        print("✅ [AuthenticationView] Registration successful for: \(credentials.email)")
                        showRegistrationSuccess = true
                        isLoading = false
                    }
                } else {
                    print("🔧 [AuthenticationView] Starting login for: \(email)")
                    try await SupabaseService.shared.signInWithEmail(email, password: password, rememberCredentials: rememberCredentials)
                    
                    // 登录成功后，立即在主线程更新UI状态
                    await MainActor.run {
                        // 直接使用SupabaseService的认证状态，因为登录成功没有抛出异常
                        isAuthenticated = SupabaseService.shared.isAuthenticated
                        
                        // 设置用户资料
                        if let supabaseUser = SupabaseService.shared.currentUser {
                            let userProfile = UserProfile(
                                id: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                                userId: UUID(uuidString: supabaseUser.id.uuidString) ?? UUID(),
                                name: supabaseUser.displayName ?? "User"
                            )
                            currentUser = userProfile
                    let userName = userProfile.name
                    // 明确可选值插值，避免生成调试描述
                    print("✅ [AuthenticationView] Login completed - User: \(userName ?? "User"), isAuthenticated: \(isAuthenticated)")
                        }
                        
                        isLoading = false
                    }
                    
                    // 登录成功后，触发数据同步（异步执行，不阻塞UI）
                    Task {
                        await DataSyncService.shared.syncUserData()
                    }
                }
            } catch {
                await MainActor.run {
                    // 显示详细的错误消息
                    let errorMessage = isSignUp ? "Sign up failed: \(error.localizedDescription)" : "Sign in failed: \(error.localizedDescription)"
                    print("❌ [AuthenticationView] \(errorMessage)")
                    showAlert(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - 安全的触觉反馈处理
    private func performHapticFeedback() {
        if #available(iOS 13.0, *) {
            if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - 邮箱验证辅助函数
    private func hasConsecutiveCharacterPattern(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // 检查连续相同字符 (如 "aaa", "111")
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let endIndex = lowercased.index(startIndex, offsetBy: 3)
            let substring = String(lowercased[startIndex..<endIndex])
            
            if substring.allSatisfy({ $0 == substring.first }) {
                return true
            }
        }
        
        // 检查连续字母序列 (如 "abc", "def")
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let char1 = lowercased[startIndex]
            let char2 = lowercased[lowercased.index(after: startIndex)]
            let char3 = lowercased[lowercased.index(startIndex, offsetBy: 2)]
            
            if char1.isLetter && char2.isLetter && char3.isLetter {
                let ascii1 = char1.asciiValue ?? 0
                let ascii2 = char2.asciiValue ?? 0
                let ascii3 = char3.asciiValue ?? 0
                
                if ascii2 == ascii1 + 1 && ascii3 == ascii2 + 1 {
                    return true
                }
            }
        }
        
        // 检查连续数字序列 (如 "123", "456")
        for i in 0..<lowercased.count - 2 {
            let startIndex = lowercased.index(lowercased.startIndex, offsetBy: i)
            let char1 = lowercased[startIndex]
            let char2 = lowercased[lowercased.index(after: startIndex)]
            let char3 = lowercased[lowercased.index(startIndex, offsetBy: 2)]
            
            if char1.isNumber && char2.isNumber && char3.isNumber {
                let num1 = Int(String(char1)) ?? 0
                let num2 = Int(String(char2)) ?? 0
                let num3 = Int(String(char3)) ?? 0
                
                if num2 == num1 + 1 && num3 == num2 + 1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - 密码验证辅助函数
    private func isPasswordValid() -> Bool {
        return password.count >= 8 &&
               containsUppercase(password) &&
               containsLowercase(password) &&
               containsNumber(password)
    }
    
    private func validatePassword(_ password: String) {
        if !isPasswordValid() {
            passwordValidationMessage = "Password must meet all requirements"
        } else {
            passwordValidationMessage = ""
        }
    }
    
    // MARK: - 防抖验证方法
    private func validateEmailDelayed(_ email: String) {
        // 确保在主线程上执行UI更新，并添加安全检查
        Task { @MainActor in
            // 检查视图是否仍然存在
            guard !email.isEmpty else {
                emailValidationMessage = ""
                return
            }
            
            // 简化的邮箱验证，避免复杂逻辑导致崩溃
            if !isValidEmail(email) {
                emailValidationMessage = "Please enter a valid email address"
            } else {
                emailValidationMessage = ""
            }
        }
    }
    
    private func validatePasswordDelayed(_ password: String) {
        // 确保在主线程上执行UI更新，并添加安全检查
        Task { @MainActor in
            // 检查视图是否仍然存在且处于注册模式
            guard isSignUp && !password.isEmpty else {
                passwordValidationMessage = ""
                return
            }
            
            // 简化的密码验证，避免复杂逻辑导致崩溃
            if !isPasswordValid() {
                passwordValidationMessage = "Password must meet all requirements"
            } else {
                passwordValidationMessage = ""
            }
        }
    }
    
    private func containsUppercase(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .uppercaseLetters) != nil
    }
    
    private func containsLowercase(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .lowercaseLetters) != nil
    }
    
    private func containsNumber(_ text: String) -> Bool {
        return text.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    // MARK: - 加载保存的凭据
    private func loadSavedCredentials() {
        print("🔍 [AuthenticationView] Loading saved credentials...")
        
        // 首先检查是否启用了记住凭据功能
        let shouldRemember = UserDefaults.standard.bool(forKey: "rememberCredentials")
        print("🔍 [AuthenticationView] Remember credentials setting: \(shouldRemember)")
        
        if shouldRemember {
            let credentials = KeychainService.shared.loadCredentials()
            if let savedEmail = credentials.email, let savedPassword = credentials.password {
                email = savedEmail
                password = savedPassword
                rememberCredentials = true
                print("✅ [AuthenticationView] Loaded saved credentials for: \(savedEmail)")
            } else {
                // 如果设置了记住凭据但没有找到凭据，重置状态
                print("⚠️ [AuthenticationView] Remember credentials enabled but no credentials found, resetting...")
                UserDefaults.standard.removeObject(forKey: "rememberCredentials")
                rememberCredentials = false
            }
        } else {
            // 记住凭据未启用：不预填字段，保持输入为空
            let credentials = KeychainService.shared.loadCredentials()
            if let savedEmail = credentials.email {
                print("ℹ️ [AuthenticationView] Credentials exist but remember is disabled, not pre-filling: \(savedEmail)")
            }
            email = ""
            password = ""
            rememberCredentials = false
        }
    }
    
    // MARK: - 邮箱验证
    private func isValidEmail(_ email: String) -> Bool {
        // 使用更严格的RFC 5322标准邮箱验证
        let emailRegex = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        // 基本格式验证
        let basicFormatValid = emailPredicate.evaluate(with: email)
        
        // 额外检查：确保邮箱不以点开头或结尾，不包含连续的点
        let hasValidDots = !email.hasPrefix(".") && !email.hasSuffix(".") && !email.contains("..")
        
        // 检查@符号前后的部分
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return false }
        
        let localPart = components[0]
        let domainPart = components[1]
        
        // 本地部分不能为空，不能超过64个字符
        guard !localPart.isEmpty, localPart.count <= 64 else { return false }
        
        // 域名部分不能为空，不能超过253个字符，必须包含至少一个点
        guard !domainPart.isEmpty, domainPart.count <= 253, domainPart.contains(".") else { return false }
        
        // 域名不能以点或连字符开头或结尾
        guard !domainPart.hasPrefix("."), !domainPart.hasSuffix("."),
              !domainPart.hasPrefix("-"), !domainPart.hasSuffix("-") else { return false }
        
        return basicFormatValid && hasValidDots
    }
}

#if canImport(UIKit)
struct AuthFormTemplate: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isSignUp: Bool
    @Binding var isLoading: Bool
    var title: String
    var subtitle: String
    var onPrimary: () -> Void
    var onForgot: (() -> Void)?
    @FocusState private var focusedField: Field?
    private enum Field { case email, password }
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(title).font(.largeTitle).fontWeight(.bold).foregroundColor(.primary)
                        Text(subtitle).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email").font(.subheadline).fontWeight(.medium)
                            TextField("Enter your email address", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password").font(.subheadline).fontWeight(.medium)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .password)
                                .submitLabel(.go)
                                .onSubmit { onPrimary() }
                        }
                    }
                    VStack(spacing: 12) {
                        Button(action: onPrimary) {
                            Text(isSignUp ? "Sign Up" : "Sign In").font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(colors: [Color(hex: "E879F9"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        if !isSignUp, let onForgot = onForgot {
                            Button("Forgot password?", action: onForgot)
                                .font(.subheadline)
                                .foregroundStyle(LinearGradient(colors: [Color(hex: "E879F9"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
                        }
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?").font(.subheadline).foregroundColor(.secondary)
                            Button(isSignUp ? "Login" : "Register") { withAnimation(.easeInOut(duration: 0.25)) { isSignUp.toggle() } }
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(LinearGradient(colors: [Color(hex: "E879F9"), Color(hex: "F472B6")], startPoint: .leading, endPoint: .trailing))
                        }
                    }
                    .padding(.top, 8)
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "E879F9"))).scaleEffect(1.3)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onTapGesture { focusedField = nil }
    }
}
#endif

#Preview {
    AuthenticationView(isAuthenticated: .constant(false), currentUser: .constant(nil))
}
