import SwiftUI

struct HorizontalDatePickerView: View {
    @Binding var selectedDate: Date
    let dates: [Date]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(dates, id: \.self) { date in
                        Button(action: {
                            withAnimation {
                                selectedDate = date
                            }
                        }) {
                            VStack {
                                Text(dayOfWeek(date))
                                    .font(.caption)
                                    .foregroundColor(isSameDay(date, selectedDate) ? .white : .secondary)
                                
                                Text(dayOfMonth(date))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(isSameDay(date, selectedDate) ? .white : .primary)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(isSameDay(date, selectedDate) ? Color.blue : Color.clear)
                                    )
                            }
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // "Mon", "Tue", etc.
        return formatter.string(from: date).uppercased()
    }
    
    private func dayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
} 