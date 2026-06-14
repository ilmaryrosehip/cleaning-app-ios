import Foundation

// MARK: - タスクプリセット

struct TaskPreset: Identifiable {
    let id: String
    let nameJA: String
    let nameEN: String
    let icon: String
    let frequency: Frequency
    let estimatedMinutes: Int
    let categoryJA: String
    let categoryEN: String

    var name: String {
        (UserDefaults.standard.string(forKey: "app_language") ?? "ja") == "ja" ? nameJA : nameEN
    }
    var category: String {
        (UserDefaults.standard.string(forKey: "app_language") ?? "ja") == "ja" ? categoryJA : categoryEN
    }
}

extension TaskPreset {
    // MARK: - リビング・ダイニング
    static let living: [TaskPreset] = [
        TaskPreset(id: "vacuum",        nameJA: "掃除機をかける",         nameEN: "Vacuum",               icon: "wind",                      frequency: .weekly,   estimatedMinutes: 15, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "mop",           nameJA: "床を水拭きする",          nameEN: "Mop floor",            icon: "drop",                      frequency: .weekly,   estimatedMinutes: 20, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "dust",          nameJA: "ほこりを拭く",           nameEN: "Dust surfaces",        icon: "sparkles",                  frequency: .weekly,   estimatedMinutes: 10, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "sofa",          nameJA: "ソファを掃除する",        nameEN: "Clean sofa",           icon: "sofa",                      frequency: .monthly,  estimatedMinutes: 15, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "window",        nameJA: "窓を拭く",              nameEN: "Clean windows",        icon: "window.horizontal",         frequency: .monthly,  estimatedMinutes: 20, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "curtain",       nameJA: "カーテンを洗う",          nameEN: "Wash curtains",        icon: "wind",                      frequency: .monthly,  estimatedMinutes: 30, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "tv",            nameJA: "テレビ画面を拭く",        nameEN: "Clean TV screen",      icon: "tv",                        frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
        TaskPreset(id: "aircon_clean",  nameJA: "エアコンフィルター掃除",   nameEN: "AC filter cleaning",   icon: "air.conditioner.horizontal",frequency: .monthly,  estimatedMinutes: 20, categoryJA: "リビング・ダイニング", categoryEN: "Living/Dining"),
    ]

    // MARK: - キッチン
    static let kitchen: [TaskPreset] = [
        TaskPreset(id: "sink",          nameJA: "シンクを磨く",           nameEN: "Clean sink",           icon: "sink",                      frequency: .weekly,   estimatedMinutes: 10, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "stove",         nameJA: "コンロを拭く",           nameEN: "Clean stovetop",       icon: "stove",                     frequency: .weekly,   estimatedMinutes: 15, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "microwave",     nameJA: "電子レンジを拭く",        nameEN: "Clean microwave",      icon: "microwave",                 frequency: .weekly,   estimatedMinutes: 10, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "fridge_clean",  nameJA: "冷蔵庫内を拭く",         nameEN: "Clean refrigerator",   icon: "refrigerator",              frequency: .monthly,  estimatedMinutes: 20, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "hood",          nameJA: "換気扇・フィルター掃除",   nameEN: "Clean range hood",     icon: "arrow.up.to.line",          frequency: .monthly,  estimatedMinutes: 30, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "trash",         nameJA: "ゴミ箱を洗う",           nameEN: "Clean trash bin",      icon: "trash",                     frequency: .monthly,  estimatedMinutes: 10, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "dishwasher_clean", nameJA: "食洗機フィルター掃除",  nameEN: "Dishwasher filter",    icon: "drop.triangle",             frequency: .weekly,   estimatedMinutes: 10, categoryJA: "キッチン", categoryEN: "Kitchen"),
        TaskPreset(id: "floor_kitchen", nameJA: "キッチンの床を拭く",      nameEN: "Mop kitchen floor",    icon: "drop",                      frequency: .weekly,   estimatedMinutes: 10, categoryJA: "キッチン", categoryEN: "Kitchen"),
    ]

    // MARK: - バスルーム
    static let bathroom: [TaskPreset] = [
        TaskPreset(id: "bath_tub",      nameJA: "浴槽を洗う",            nameEN: "Clean bathtub",        icon: "bathtub",                   frequency: .daily,    estimatedMinutes: 10, categoryJA: "バスルーム", categoryEN: "Bathroom"),
        TaskPreset(id: "bath_wall",     nameJA: "浴室の壁を磨く",         nameEN: "Scrub bath walls",     icon: "shower",                    frequency: .weekly,   estimatedMinutes: 20, categoryJA: "バスルーム", categoryEN: "Bathroom"),
        TaskPreset(id: "drain",         nameJA: "排水口を掃除する",        nameEN: "Clean drain",          icon: "drop.triangle",             frequency: .weekly,   estimatedMinutes: 10, categoryJA: "バスルーム", categoryEN: "Bathroom"),
        TaskPreset(id: "mirror",        nameJA: "鏡を拭く",              nameEN: "Clean mirror",         icon: "sparkle",                   frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "バスルーム", categoryEN: "Bathroom"),
        TaskPreset(id: "bath_dryer_clean", nameJA: "浴室乾燥機フィルター掃除", nameEN: "Bath dryer filter",  icon: "wind",                      frequency: .monthly,  estimatedMinutes: 15, categoryJA: "バスルーム", categoryEN: "Bathroom"),
        TaskPreset(id: "mold",          nameJA: "カビ取りをする",          nameEN: "Remove mold",          icon: "exclamationmark.triangle",  frequency: .monthly,  estimatedMinutes: 20, categoryJA: "バスルーム", categoryEN: "Bathroom"),
    ]

    // MARK: - トイレ
    static let toilet: [TaskPreset] = [
        TaskPreset(id: "toilet_bowl",   nameJA: "トイレを洗う",           nameEN: "Clean toilet bowl",    icon: "toilet",                    frequency: .weekly,   estimatedMinutes: 10, categoryJA: "トイレ", categoryEN: "Toilet"),
        TaskPreset(id: "toilet_floor",  nameJA: "トイレの床を拭く",        nameEN: "Mop toilet floor",     icon: "drop",                      frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "トイレ", categoryEN: "Toilet"),
        TaskPreset(id: "toilet_wall",   nameJA: "トイレの壁を拭く",        nameEN: "Wipe toilet walls",    icon: "square.fill",               frequency: .monthly,  estimatedMinutes: 10, categoryJA: "トイレ", categoryEN: "Toilet"),
        TaskPreset(id: "toilet_tank",   nameJA: "タンクを掃除する",        nameEN: "Clean toilet tank",    icon: "toilet",                    frequency: .monthly,  estimatedMinutes: 10, categoryJA: "トイレ", categoryEN: "Toilet"),
    ]

    // MARK: - 洗面所
    static let washroom: [TaskPreset] = [
        TaskPreset(id: "washbasin",     nameJA: "洗面台を磨く",           nameEN: "Clean washbasin",      icon: "sink",                      frequency: .weekly,   estimatedMinutes: 10, categoryJA: "洗面所", categoryEN: "Washroom"),
        TaskPreset(id: "toothbrush",    nameJA: "歯ブラシホルダーを洗う",   nameEN: "Clean toothbrush holder", icon: "drop",                  frequency: .monthly,  estimatedMinutes: 5,  categoryJA: "洗面所", categoryEN: "Washroom"),
        TaskPreset(id: "washing_machine", nameJA: "洗濯槽を洗う",         nameEN: "Clean washing machine", icon: "washer",                   frequency: .monthly,  estimatedMinutes: 5,  categoryJA: "洗面所", categoryEN: "Washroom"),
        TaskPreset(id: "lint",          nameJA: "糸くずフィルター掃除",     nameEN: "Lint filter cleaning",  icon: "washer",                   frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "洗面所", categoryEN: "Washroom"),
    ]

    // MARK: - 寝室
    static let bedroom: [TaskPreset] = [
        TaskPreset(id: "sheet",         nameJA: "シーツを洗う",           nameEN: "Wash sheets",          icon: "bed.double",                frequency: .weekly,   estimatedMinutes: 10, categoryJA: "寝室", categoryEN: "Bedroom"),
        TaskPreset(id: "pillow",        nameJA: "枕カバーを洗う",          nameEN: "Wash pillowcases",     icon: "bed.double",                frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "寝室", categoryEN: "Bedroom"),
        TaskPreset(id: "quilt",         nameJA: "布団を干す",             nameEN: "Air out futon/quilt",  icon: "sun.max",                   frequency: .monthly,  estimatedMinutes: 10, categoryJA: "寝室", categoryEN: "Bedroom"),
        TaskPreset(id: "bedroom_dust",  nameJA: "寝室のほこりを拭く",      nameEN: "Dust bedroom",         icon: "sparkles",                  frequency: .weekly,   estimatedMinutes: 10, categoryJA: "寝室", categoryEN: "Bedroom"),
    ]

    // MARK: - 玄関・廊下
    static let entrance: [TaskPreset] = [
        TaskPreset(id: "entrance_floor", nameJA: "玄関を掃く",            nameEN: "Sweep entrance",       icon: "door.left.hand.open",       frequency: .weekly,   estimatedMinutes: 5,  categoryJA: "玄関・廊下", categoryEN: "Entrance"),
        TaskPreset(id: "entrance_clean", nameJA: "玄関を水拭きする",       nameEN: "Mop entrance",         icon: "drop",                      frequency: .monthly,  estimatedMinutes: 10, categoryJA: "玄関・廊下", categoryEN: "Entrance"),
        TaskPreset(id: "hall_floor",    nameJA: "廊下を掃除機かける",      nameEN: "Vacuum hallway",       icon: "wind",                      frequency: .weekly,   estimatedMinutes: 10, categoryJA: "玄関・廊下", categoryEN: "Entrance"),
    ]

    // MARK: - 全カテゴリまとめ
    static let allCategories: [(nameJA: String, nameEN: String, icon: String, presets: [TaskPreset])] = [
        (nameJA: "リビング・ダイニング", nameEN: "Living/Dining",  icon: "sofa",                living),
        (nameJA: "キッチン",          nameEN: "Kitchen",         icon: "fork.knife",          kitchen),
        (nameJA: "バスルーム",         nameEN: "Bathroom",        icon: "shower",              bathroom),
        (nameJA: "トイレ",            nameEN: "Toilet",          icon: "toilet",              toilet),
        (nameJA: "洗面所",            nameEN: "Washroom",        icon: "washer",              washroom),
        (nameJA: "寝室",              nameEN: "Bedroom",         icon: "bed.double",          bedroom),
        (nameJA: "玄関・廊下",         nameEN: "Entrance",        icon: "door.left.hand.open", entrance),
    ]

    static func categoryName(_ cat: (nameJA: String, nameEN: String, icon: String, presets: [TaskPreset])) -> String {
        (UserDefaults.standard.string(forKey: "app_language") ?? "ja") == "ja" ? cat.nameJA : cat.nameEN
    }
}
