import Foundation

enum Asset {
    
    enum TabBar {
        case home
        case places
        case calendar
        case stats
        
        var off: String {
            switch self {
            case .home: return "tab_home_off"
            case .places: return "tab_places_off"
            case .calendar: return "tab_calendar_off"
            case .stats: return "tab_stats_off"
            }
        }
        
        var on: String {
            switch self {
            case .home: return "tab_home_on"
            case .places: return "tab_places_on"
            case .calendar: return "tab_calendar_on"
            case .stats: return "tab_stats_on"
            }
        }
    }
}

enum TabItem: CaseIterable, Hashable {
    case home
    case places
    case calendar
    case stats
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .places: return "Places and routes"
        case .calendar: return "Calendar"
        case .stats: return "Statistic"
        }
    }
    
    var asset: Asset.TabBar {
        switch self {
        case .home: return .home
        case .places: return .places
        case .calendar: return .calendar
        case .stats: return .stats
        }
    }
}


import Foundation

enum ClimbingGrade: String, CaseIterable, Codable, Hashable, Identifiable {
    case g4 = "4"
    case g5a = "5a"
    case g5b = "5b"
    case g5c = "5c"
    case g6a = "6a"
    case g6aPlus = "6a+"
    case g6b = "6b"
    case g6bPlus = "6b+"
    case g6c = "6c"
    case g6cPlus = "6c+"
    case g7a = "7a"
    case g7aPlus = "7a+"
    case g7b = "7b"
    case g7bPlus = "7b+"
    case g7c = "7c"
    case g7cPlus = "7c+"
    case g8a = "8a"
    case g8aPlus = "8a+"
    case g8b = "8b"
    case g8bPlus = "8b+"
    case g8c = "8c"
    case g8cPlus = "8c+"

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .g4: return 0
        case .g5a: return 1
        case .g5b: return 2
        case .g5c: return 3
        case .g6a: return 4
        case .g6aPlus: return 5
        case .g6b: return 6
        case .g6bPlus: return 7
        case .g6c: return 8
        case .g6cPlus: return 9
        case .g7a: return 10
        case .g7aPlus: return 11
        case .g7b: return 12
        case .g7bPlus: return 13
        case .g7c: return 14
        case .g7cPlus: return 15
        case .g8a: return 16
        case .g8aPlus: return 17
        case .g8b: return 18
        case .g8bPlus: return 19
        case .g8c: return 20
        case .g8cPlus: return 21
        }
    }
}

enum PlaceKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case natural = "Natural"
    case climbing = "Climbing"
    var id: String { rawValue }
    var title: String { rawValue }
}

enum RouteKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case sports = "Sports"
    case crack = "Crack"
    case boulder = "Boulder"
    var id: String { rawValue }
    var title: String { rawValue }
}

enum WeatherKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case snow, partlyRain, heavySnow, rain, sun, thunder, wind, night
    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .snow: return "weather_snow"
        case .partlyRain: return "weather_partly_rain"
        case .heavySnow: return "weather_snow_heavy"
        case .rain: return "weather_rain"
        case .sun: return "weather_sun"
        case .thunder: return "weather_thunder"
        case .wind: return "weather_wind"
        case .night: return "weather_night"
        }
    }
    
    var selectedAssetName: String { assetName + "_selected" }
}

enum ClimbingResult: String, CaseIterable, Codable, Hashable, Identifiable {
    case complete, fail
    var id: String { rawValue }

    var title: String {
        switch self {
        case .complete: return "Complete"
        case .fail: return "Fail"
        }
    }

    var assetName: String {
        switch self {
        case .complete: return "result_success"
        case .fail: return "result_fail"
        }
    }
}

enum MoodKind: String, CaseIterable, Codable, Hashable, Identifiable {
    case happyBig, happy, neutral, sad, playful, laugh, angry, verySad
    var id: String { rawValue }

    var assetName: String {
        switch self {
        case .happyBig: return "mood_happy_big"
        case .happy: return "mood_happy"
        case .neutral: return "mood_neutral"
        case .sad: return "mood_sad"
        case .playful: return "mood_playful"
        case .laugh: return "mood_laugh"
        case .angry: return "mood_angry"
        case .verySad: return "mood_very_sad"
        }
    }

    var selectedAssetName: String { assetName + "_selected" }

    var title: String {
        switch self {
        case .happyBig: return "Great"
        case .happy: return "Good"
        case .neutral: return "Neutral"
        case .sad: return "Sad"
        case .playful: return "Playful"
        case .laugh: return "Fun"
        case .angry: return "Angry"
        case .verySad: return "Upset"
        }
    }
}

struct Place: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var kind: PlaceKind
    var details: String

    init(id: UUID = UUID(), name: String, kind: PlaceKind, details: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.details = details
    }
}

struct Route: Identifiable, Codable, Hashable {
    let id: UUID
    var placeId: UUID
    var name: String
    var grade: ClimbingGrade
    var kind: RouteKind
    var details: String

    init(id: UUID = UUID(), placeId: UUID, name: String, grade: ClimbingGrade, kind: RouteKind, details: String) {
        self.id = id
        self.placeId = placeId
        self.name = name
        self.grade = grade
        self.kind = kind
        self.details = details
    }
}

struct ClimbingPhoto: Identifiable, Codable, Hashable {
    let id: UUID
    var filename: String

    init(id: UUID = UUID(), filename: String) {
        self.id = id
        self.filename = filename
    }
}

struct Climbing: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date

    var placeId: UUID
    var routeId: UUID

    var weather: WeatherKind
    var result: ClimbingResult
    var attempts: Int

    var mood: MoodKind
    var photos: [ClimbingPhoto]
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        placeId: UUID,
        routeId: UUID,
        weather: WeatherKind,
        result: ClimbingResult,
        attempts: Int,
        mood: MoodKind,
        photos: [ClimbingPhoto],
        note: String
    ) {
        self.id = id
        self.date = date
        self.placeId = placeId
        self.routeId = routeId
        self.weather = weather
        self.result = result
        self.attempts = max(1, attempts)
        self.mood = mood
        self.photos = Array(photos.prefix(3))
        self.note = String(note.prefix(150))
    }
}

extension Date {
    func startOfDay(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    func startOfMonth(in calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: comps) ?? self
    }
}
