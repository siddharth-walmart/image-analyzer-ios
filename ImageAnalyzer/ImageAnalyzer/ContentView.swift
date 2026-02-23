//
//  ContentView.swift
//  ImageAnalyzer
//
//  Created by s0s08at on 2/23/26.
//

import SwiftUI
import PhotosUI
                                                                                                                                                                      
struct ContentView: View {
    // State variables - these hold our app's data
    @State private var selectedImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    @State private var suggestedActions: [String] = []
    @State private var showCamera = false
                                                                                                                                                                      
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image Display Area
                    imageDisplaySection
                                                                                                                                                                      
                    // Buttons to get image
                    buttonSection
                                                                                                                                                                      
                    // Analysis Results
                    if isAnalyzing {
                        ProgressView("Analyzing image...")
                            .padding()
                    }
                                                                                                                                                                      
                    if !analysisResult.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("📸 Image Analyzer")
        }
    }
                                                                                                                                                                      
    // MARK: - UI Components
                                                                                                                                                                      
    private var imageDisplaySection: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No image selected")
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
                                                                                                                                                                      
    private var buttonSection: some View {
        HStack(spacing: 16) {
            // Photo Library Picker
            PhotosPicker(selection: $imageSelection, matching: .images) {
                Label("Gallery", systemImage: "photo.library")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .onChange(of: imageSelection) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        analysisResult = ""
                        suggestedActions = []
                    }
                }
            }
                                                                                                                                                                      
            // Camera Button
            Button(action: { showCamera = true }) {
                Label("Camera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
            }
        }
                                                                                                                                                                      
        // Analyze Button
        if selectedImage != nil {
            Button(action: analyzeImage) {
                Label("Analyze Image", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isAnalyzing)
        }
    }
                                                                                                                                                                      
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📝 Analysis")
                .font(.headline)
                                                                                                                                                                      
            Text(analysisResult)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                                                                                                                                                                      
            if !suggestedActions.isEmpty {
                Text("💡 Suggested Actions")
                    .font(.headline)
                                                                                                                                                                      
                ForEach(suggestedActions, id: \.self) { action in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text(action)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
                                                                                                                                                                      
    // MARK: - Functions
                                                                                                                                                                      
    private func analyzeImage() {
        guard let image = selectedImage else { return }
                                                                                                                                                                          
        isAnalyzing = true
        analysisResult = ""
        suggestedActions = []
                                                                                                                                                                          
        Task {
            do {
                let service = ImageAnalysisService()
                let result = try await service.analyzeImage(image)
                                                                                                                                                                          
                await MainActor.run {
                    analysisResult = result.description
                    suggestedActions = result.suggestedActions
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analysisResult = "Error: \(error.localizedDescription)"
                    isAnalyzing = false
                }
            }
        }
    }   
                                                                                                                                                                      
#Preview {
    ContentView()
}
