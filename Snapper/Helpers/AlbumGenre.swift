import Foundation

enum AlbumGenre: String, CaseIterable, Hashable, Identifiable {
  case rock = "Rock"
  case electronic = "Electronic"
  case pop = "Pop"
  case folkWorldCountry = "Folk, World, & Country"
  case jazz = "Jazz"
  case funkSoul = "Funk / Soul"
  case classical = "Classical"
  case hipHop = "Hip Hop"
  case latin = "Latin"
  case stageScreen = "Stage & Screen"
  case reggae = "Reggae"
  case blues = "Blues"
  case nonMusic = "Non-Music"
  case childrens = "Children's"
  case brassMilitary = "Brass & Military"

  var id: Self { self }

  var resource: LocalizedStringResource {
    switch self {
    case .rock: .genresRock
    case .electronic: .genresElectronic
    case .pop: .genresPop
    case .folkWorldCountry: .genresFolkWorldCountry
    case .jazz: .genresJazz
    case .funkSoul: .genresFunkSoul
    case .classical: .genresClassical
    case .hipHop: .genresHipHop
    case .latin: .genresLatin
    case .stageScreen: .genresStageScreen
    case .reggae: .genresReggae
    case .blues: .genresBlues
    case .nonMusic: .genresNonMusic
    case .childrens: .genresChildrens
    case .brassMilitary: .genresBrassMilitary
    }
  }
}
