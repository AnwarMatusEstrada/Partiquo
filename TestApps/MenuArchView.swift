//
//  MenuArchView.swift
//  TestApps
//
//  Created by Lourdes Estrada Terres on 23/12/25.
//

import SwiftUI
import Foundation
internal import Combine

struct MenuArchView: View {
    
    @Binding var maxread: Int
    @State var Dir: String = URL.documentsDirectory.path
    @State var cont: [String] = []
    @State private var files: [URL] = []
    
    private func deleteFile(at offsets: IndexSet) {
        // The IndexSet contains the indices of the items to be deleted
        
        let fileManager = FileManager.default
        var url = offsets.map { files[$0] }
        for url2 in url{
            //print("url2:\(url2)")
            do {
                try fileManager.removeItem(at: url2)
            } catch {
                print("\(error)")
            }
        }
        
        //print("Deleting files at offsets:\(offsets.map{ files[$0] })")
        files.remove(atOffsets: offsets)

        // *File Deletion (Conceptual):*
        // At this point, you would also add the necessary code
        // to delete the actual file from your app's persistent storage
        // (e.g., Core Data, SwiftData, or the file system).
    }
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(cont, id: \.self) { c in
                    NavigationLink(destination: MapView(fn: c, maxread: $maxread)){
                        Button("\(c)"){
                            print("c = :\(c):")
                        }
                    }
                }.onDelete(perform: deleteFile)
            }
        }.onAppear {
            do{
                //print("Directory =\(Dir):")
                cont = try FileManager.default.contentsOfDirectory(atPath: "\(Dir)")
                print("cont =\(cont):")
                
                var FILE: String = ""
                for c in cont{
                    FILE = ("\(Dir)/\(c)")
                    //print("File_________:\(FILE):")
                    files.append(URL(fileURLWithPath:FILE))
                    
                }
            } catch {
                print("Not Read for \(Dir): \(error)")
            }
        }
    }
}
