import SwiftUI

// MARK: - 射击模式
enum FireMode: String, CaseIterable, Identifiable {
    case fullAuto = "全自动连发"
    case semiAuto = "半自动单发"
    case boltAction = "栓动单发"
    case pumpAction = "泵动单发"
    case burst = "三连发点射"
    case singleShot = "单发发射"
    case melee = "近战挥砍"
    var id: String { rawValue }
}

// MARK: - 武器大类
enum WeaponCategory: String, CaseIterable, Identifiable {
    case sniper = "狙击枪"
    case rifle = "步枪"
    case smg = "冲锋枪"
    case pistol = "手枪"
    case shotgun = "霰弹枪"
    case special = "特殊武器"
    case melee = "近战武器"
    var id: String { rawValue }
}

// MARK: - 槽位定义
struct SlotDef: Identifiable, Hashable {
    let id: String            // 内部 id
    let name: String          // 中文名，如“枪口”
    // 聚焦视角参数
    var tiltX: Double = 0
    var tiltY: Double = 0
    var zoom: Double = 1.0
    var offsetX: Double = 0
    var offsetY: Double = 0
    // 该槽位在武器图上的锚点（归一化 0~1）
    var anchor: CGPoint = .init(x: 0.5, y: 0.5)
    // 装上特定配件后联动出现的新槽位 id 列表
    var reveals: [String] = []
    var revealTriggerPartID: String? = nil
}

// MARK: - 配件
struct Attachment: Identifiable, Hashable {
    let id: String
    let slotID: String
    let name: String
    let desc: String
    // 属性增减
    var recoil: Double = 0
    var stability: Double = 0
    var handling: Double = 0
    var hipAccuracy: Double = 0
    var muzzleVelocity: Double = 0
    var range: Double = 0
    var fireRate: Double = 0
    var reloadSpeed: Double = 0
    var magCapacity: Int = 0
    var meleeSpeed: Double = 0
    var meleeRange: Double = 0
    var penetration: Double = 0
    var balance: Double = 0
    var blastRadius: Double = 0
    var energyEfficiency: Double = 0
    var cooling: Double = 0
    var focus: Double = 0
    // 外观变体标记（用于绘制不同轮廓）
    var visualVariant: Int = 0
    var reveals: [String] = []   // 装上后联动出现的槽位 id
}

// MARK: - 武器
struct Weapon: Identifiable {
    let id: String
    let name: String
    let category: WeaponCategory
    let fireModes: [FireMode]
    var defaultMode: FireMode
    let baseFireRate: Double      // 发/分钟
    let baseMag: Int
    let baseReload: Double        // 秒
    let baseRecoil: Double
    let baseStability: Double
    let baseHandling: Double
    let baseHip: Double
    let baseVelocity: Double
    let baseRange: Double
    // 近战
    var meleeSpeed: Double = 0
    var meleeRange: Double = 0
    var penetration: Double = 0
    var balance: Double = 0
    // 槽位
    var slots: [SlotDef]
    var slotAttachments: [String: [Attachment]] // slotID -> attachments
    // 初始配件（每槽第一个）
    var initialParts: [String: String] = [:]
    // 外观差异参数：用于绘制不同枪型
    var visual: WeaponVisual
}

struct WeaponVisual {
    var barrelLen: Double = 0.45
    var stockStyle: Int = 0       // 0无 1固定 2折叠 3骨架
    var magStyle: Int = 0         // 0无 1直 2弯 3弹鼓 4短
    var scopeStyle: Int = 0       // 0无 1小红点 2高倍 3热成像
    var bodyStyle: Int = 0        // 0步枪 1狙击 2手枪 3霰弹 4冲锋 5火箭筒 6榴弹 7激光 8刀
    var bladeStyle: Int = 0       // 刀型：0蝴蝶 1爪 2弹簧 3直刀 4战术
    var colorSeed: Double = 0
}