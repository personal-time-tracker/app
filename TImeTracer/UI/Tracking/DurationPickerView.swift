import SwiftUI

struct DurationPickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int

    var body: some View {
        HStack {
            Spacer()
            // Пикер для часов
            Picker("Часы", selection: $hours) {
                ForEach(0..<24) { hour in
                    Text("\(hour) ч").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()

            // Пикер для минут
            Picker("Минуты", selection: $minutes) {
                ForEach(stride(from: 0, to: 60, by: 5).map { $0 }, id: \.self) { minute in
                    Text("\(minute) мин").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 100)
            .clipped()
            Spacer()
        }
        .frame(height: 150) // Общая высота, чтобы пикеры не были слишком большими
    }
}

struct DurationPickerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var hours = 1
        @State private var minutes = 30
        
        var body: some View {
            DurationPickerView(hours: $hours, minutes: $minutes)
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
} 
