import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var screen: Screen = .lobby
    @Published var weapons: [Weapon] = WeaponLibrary.makeAll()
    @Published var selectedCategory: WeaponCategory? = .sniper
    @Published var selectedWeaponID: String?
    @Published var selectedSlotID: String?
    @Published var configs: [String: WeaponConfig] = [:]
    @Published var returnWeaponID: String?
    @Published var settingsOpen = false

    enum Screen { case lobby, workshop, range }

    func weapon(_ id: String) -> Weapon? { weapons.first { $0.id == id } }

    func config(for id: String) -> WeaponConfig {
        if let c = configs[id] { return c }
        var c = WeaponConfig()
        if let w = weapon(id) {
            for (slot, part) in w.initialParts { c.parts[slot] = part }
        }
        configs[id] = c
        return c
    }

    func setPart(weaponID: String, slotID: String, partID: String) {
        var c = config(for: weaponID)
        c.parts[slotID] = partID
        // 联动出现的新槽位自动填充默认配件（若尚未有）
        if let w = weapon(weaponID),
           let part = w.slotAttachments[slotID]?.first(where: { $0.id == partID }) {
            for newSlot in part.reveals where c.parts[newSlot] == nil {
                if let first = w.slotAttachments[newSlot]?.first {
                    c.parts[newSlot] = first.id
                }
            }
        }
        configs[weaponID] = c
    }

    // 有效槽位：基础槽位 + 联动已出现的槽位
    func activeSlots(for weapon: Weapon) -> [SlotDef] {
        let c = config(for: weapon.id)
        var result = weapon.slots
        for slot in weapon.slots {
            if let pid = c.parts[slot.id],
               let part = weapon.slotAttachments[slot.id]?.first(where: { $0.id == pid }) {
                for newID in part.reveals {
                    if let s = weapon.slots.first(where: { $0.id == newID }), !result.contains(where: { $0.id == newID }) {
                        result.append(s)
                    }
                }
            }
        }
        return result
    }

    // 汇总属性
    func stats(for weapon: Weapon) -> WeaponStats {
        let c = config(for: weapon.id)
        var s = WeaponStats()
        s.recoil = weapon.baseRecoil
        s.stability = weapon.baseStability
        s.handling = weapon.baseHandling
        s.hip = weapon.baseHip
        s.velocity = weapon.baseVelocity
        s.range = weapon.baseRange
        s.fireRate = weapon.baseFireRate
        s.mag = weapon.baseMag
        s.reload = weapon.baseReload
        s.meleeSpeed = weapon.meleeSpeed
        s.meleeRange = weapon.meleeRange
        s.penetration = weapon.penetration
        s.balance = weapon.balance
        for (slot, pid) in c.parts {
            guard let part = weapon.slotAttachments[slot]?.first(where: { $0.id == pid }) else { continue }
            s.recoil += part.recoil
            s.stability += part.stability
            s.handling += part.handling
            s.hip += part.hipAccuracy
            s.velocity += part.muzzleVelocity
            s.range += part.range
            s.fireRate += part.fireRate
            s.mag += part.magCapacity
            s.reload += part.reloadSpeed
            s.meleeSpeed += part.meleeSpeed
            s.meleeRange += part.meleeRange
            s.penetration += part.penetration
            s.balance += part.balance
        }
        s.mag = max(1, s.mag)
        s.reload = max(0.5, s.reload)
        return s
    }
}

struct WeaponConfig {
    var parts: [String:String] = [:]
    var fireMode: FireMode? = nil
}

struct WeaponStats {
    var recoil: Double = 0
    var stability: Double = 0
    var handling: Double = 0
    var hip: Double = 0
    var velocity: Double = 0
    var range: Double = 0
    var fireRate: Double = 0
    var mag: Int = 0
    var reload: Double = 0
    var meleeSpeed: Double = 0
    var meleeRange: Double = 0
    var penetration: Double = 0
    var balance: Double = 0
}