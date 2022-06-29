//
//  ContentView.swift
//  ShazamTest
//
//  Created by 이주화 on 2022/06/20.
//

import ShazamKit
import SwiftUI

struct music{
    @State var title: String?
    @State var subtitle: String?
    @State var artist: String?
    @State var coverUrl: URL?

}


struct ContentView: View {
    @State var matcher: MatchingMusic?
    @State var status = ""
    @State var coverUrl: URL?
    @State var title: String?
    @State var subtitle: String?
    @State var artist: String?
    @State var isListening = false
    @State var musics: [music] = []
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    AsyncImage(
                        url: coverUrl
                    ) { image in
                        image.resizable()
                    } placeholder: {
                        Color("coinPurple", bundle: nil)
                    }
                    .frame(width: 256, height: 256)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                    
                    Text(title ?? "")
                        .font(.title)
                    Text(subtitle ?? "")
                        .font(.subheadline)
                    Text(artist ?? "")
                        .font(.body)
                    
                    Spacer()
                    
                    if isListening {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                    
                    Text(status)
                    
                    HStack(alignment: .bottom, spacing: 30) {
                        VStack {
                            Divider()
                            
                            Button("노래 검색하기") {
                                status = "검색중입니다..."
                                isListening = true
                                do {
                                    try matcher?.match()
                                } catch {
                                    status = "일치하는 노래를 검색하지 못했어요"
                                    print("Error audio")
                                }
                            }
                            .font(.title)
                            
                            Divider()
                        }
                    }
                    HStack{
                        VStack{
                            ForEach(musics.indices, id: \.self){ item in
                                VStack{
                                    AsyncImage(
                                        url: musics[item].coverUrl
                                    ) { image in
                                        image.resizable()
                                    } placeholder: {
                                        Color("coinPurple", bundle: nil)
                                    }
                                    .frame(width: 45, height: 45)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                }
                                .padding()
                                VStack{
                                    Text(musics[item].title ?? "")
                                        .font(.title)
                                    Text(musics[item].subtitle ?? "")
                                        .font(.subheadline)
                                    Text(musics[item].artist ?? "")
                                        .font(.body)
                                }
                                
                            }
                        }
                        .padding(.bottom, 10)
                        
                    }
                }
            }
            
            .navigationBarTitle("노래 검색")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            matcher = MatchingMusic(matchHandler: songMatched)
        }
        .onDisappear {
            isListening = false
            matcher?.stopListening()
            status = ""
        }
        .onChange(of: title){ i in
            musics.append(music(title: title, subtitle: subtitle, artist: artist, coverUrl: coverUrl))
        }
    }
    
    
    func songMatched(item: SHMatchedMediaItem?, error: Error?) {
        isListening = false
        if error != nil {
            status = "일치하는 노래를 찾지 못했어요 ㅠㅠ :("
            print(String(describing: error.debugDescription))
        } else {
            status = "노래를 찾았어요!"
            print("Found song!")
            title = item?.title
            subtitle = item?.subtitle
            artist = item?.artist
            coverUrl = item?.artworkURL
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct inner {
    let innerNum: Int = 0
}
