//
//  SimpleVideoPlayerView.swift
//  test
//
//  Created by AI Assistant
//

import SwiftUI
import AVKit
import AVFoundation

struct SimpleVideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showPlayButton = true
    
    var body: some View {
        ZStack {
            // 视频播放器
            VideoPlayer(player: player)
                .onTapGesture {
                    togglePlayback()
                }
                .onAppear {
                    setupPlayer()
                }
                .onDisappear {
                    player?.pause()
                }
            
            // 播放按钮覆盖层
            if showPlayButton && !isPlaying {
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(showPlayButton ? 1.0 : 0.8)
                .opacity(showPlayButton ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showPlayButton)
            }
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: url)
        
        // 监听播放状态
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            showPlayButton = true
            player?.seek(to: .zero)
        }
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            showPlayButton = true
        } else {
            player.play()
            showPlayButton = false
            
            // 3秒后隐藏播放按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    showPlayButton = false
                }
            }
        }
        isPlaying.toggle()
    }
}

#Preview {
    if let url = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
        SimpleVideoPlayerView(url: url)
            .frame(height: 200)
    } else {
        Text("No sample video found")
    }
}