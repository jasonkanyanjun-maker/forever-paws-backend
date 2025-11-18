//
//  VideoPlayerView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import AVKit
import AVFoundation
import Combine

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            // 视频播放器
            VideoPlayer(player: player)
                .onTapGesture {
                    toggleControlsVisibility()
                }
                .onAppear {
                    setupPlayer()
                }
                .onDisappear {
                    player?.pause()
                    controlsTimer?.invalidate()
                }
            
            // 自定义控制界面
            if showControls {
                VStack {
                    Spacer()
                    
                    // 控制栏
                    VStack(spacing: 12) {
                        // 进度条
                        VStack(spacing: 8) {
                            HStack {
                                Text(timeString(from: currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                
                                Spacer()
                                
                                Text(timeString(from: duration))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .monospacedDigit()
                            }
                            
                            // 进度滑块
                            Slider(value: $currentTime, in: 0...max(duration, 1)) { editing in
                                if !editing {
                                    player?.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600))
                                }
                            }
                            .accentColor(.white)
                        }
                        
                        // 播放控制按钮
                        HStack(spacing: 24) {
                            // 后退15秒
                            Button(action: {
                                seekBy(-15)
                            }) {
                                Image(systemName: "gobackward.15")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // 播放/暂停按钮
                            Button(action: togglePlayback) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                            .scaleEffect(isPlaying ? 0.95 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: isPlaying)
                            
                            Spacer()
                            
                            // 前进15秒
                            Button(action: {
                                seekBy(15)
                            }) {
                                Image(systemName: "goforward.15")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.0),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: showControls)
            }
            
            // 加载指示器
            if player?.currentItem?.status == .readyToPlay && duration == 0 {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("加载中...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial.opacity(0.8))
                )
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
        }
    }
    
    private func setupPlayer() {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // 监听播放状态
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            isPlaying = false
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seekBy(_ seconds: Double) {
        guard let player = player else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(0, min(currentTime + seconds, duration))
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
    }
    
    private func toggleControlsVisibility() {
        showControls.toggle()
        
        // 重置控制栏自动隐藏计时器
        controlsTimer?.invalidate()
        if showControls {
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    private func updateProgress() {
        guard let player = player,
              let currentItem = player.currentItem else { return }
        
        // 更新当前播放时间
        currentTime = CMTimeGetSeconds(player.currentTime())
        
        // 更新总时长
        if duration == 0 {
            duration = CMTimeGetSeconds(currentItem.duration)
        }
        
        // 检查播放状态
        if player.rate > 0 {
            isPlaying = true
        } else {
            isPlaying = false
        }
    }
    
    private func timeString(from seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    if let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
        VideoPlayerView(url: url)
            .frame(height: 300)
    } else {
        Text("No sample video found")
    }
}