import SwiftUI

enum WeaponLibrary {

    static func makeAll() -> [Weapon] {
        var all: [Weapon] = []
        all += sniper()
        all += rifles()
        all += smgs()
        all += pistols()
        all += shotguns()
        all += specials()
        all += melees()
        return all
    }

    // 通用槽位模板
    private static func gunSlots(_ ids: [(String,String)], focus: Bool = true) -> [SlotDef] {
        ids.enumerated().map { i, pair in
            SlotDef(id: pair.0, name: pair.1,
                    tiltX: Double((i % 2 == 0) ? 6 : -5),
                    tiltY: Double((i % 3 == 0) ? 8 : -6),
                    zoom: 1.55, offsetX: 0, offsetY: 0,
                    anchor: CGPoint(x: 0.25 + Double(i) * 0.09, y: 0.5))
        }
    }

    // 通用配件生成（补全了 focus, cooling, energyEfficiency 参数）
    private static func parts(_ slot: String, base: [String], desc: String,
                              recoil: Double = 0, stability: Double = 0,
                              handling: Double = 0, hip: Double = 0,
                              vel: Double = 0, range: Double = 0,
                              fireRate: Double = 0, reload: Double = 0,
                              mag: Int = 0, variant: Int = 0,
                              reveals: [String] = [],
                              focus: Double = 0, cooling: Double = 0, energyEfficiency: Double = 0) -> [Attachment] {
        base.enumerated().map { i, n in
            Attachment(id: "\(slot)_\(i)", slotID: slot, name: n,
                       desc: desc,
                       recoil: recoil * Double(i),
                       stability: stability * Double(i),
                       handling: handling * Double(i),
                       hipAccuracy: hip * Double(i),
                       muzzleVelocity: vel * Double(i),
                       range: range * Double(i),
                       fireRate: fireRate * Double(i),
                       reloadSpeed: reload * Double(i),
                       magCapacity: mag * i,
                       focus: focus * Double(i),
                       cooling: cooling * Double(i),
                       energyEfficiency: energyEfficiency * Double(i),
                       visualVariant: variant + i,
                       reveals: i == 0 ? reveals : [])
        }
    }

    // MARK: 狙击枪 10
    static func sniper() -> [Weapon] {
        let names = ["远望-1 栓动狙击","远望-2 半自动狙击","雷脊 反器材","寒鸦 栓动","长弓 精确狙击","夜幕 半自动","山脊 反器材","静默 栓动","猎隼 精确","霜刃 半自动"]
        return names.enumerated().map { i, n in
            let bolt = i % 2 == 0
            let slots = gunSlots([("muzzle","枪口"),("barrel","枪管"),("scope","瞄准镜"),("stock","枪托"),("mag","弹匣"),("bipod","脚架")])
            var partsMap: [String:[Attachment]] = [:]
            partsMap["muzzle"] = parts("muzzle", base: ["制退器","消焰器","消音器"], desc: "影响后坐力与枪口焰", recoil: 4, stability: 2, range: 2)
            partsMap["barrel"] = parts("barrel", base: ["标准枪管","加长枪管","轻量枪管"], desc: "影响初速与射程", vel: 12, range: 8, handling: -3, reveals: ["rail"])
            partsMap["scope"] = parts("scope", base: ["高倍镜","热成像镜","夜视镜"], desc: "影响远距识别", stability: 3, range: 4, reveals: ["riser"])
            partsMap["stock"] = parts("stock", base: ["固定枪托","折叠枪托","骨架枪托"], desc: "影响稳定性", stability: 5, handling: -2, reveals: ["buttpad"])
            partsMap["mag"] = parts("mag", base: ["标准弹匣","扩容弹匣","快拔弹匣"], desc: "影响容量与换弹", mag: 2, reload: -0.15)
            partsMap["bipod"] = parts("bipod", base: ["无脚架","轻型脚架","重型脚架"], desc: "卧姿稳定", stability: 4)
            // 联动槽位
            let extraSlots = [SlotDef(id:"rail", name:"护木导轨", zoom:1.6, anchor:.init(x:0.55,y:0.55)),
                              SlotDef(id:"riser", name:"增高架", zoom:1.7, anchor:.init(x:0.45,y:0.4)),
                              SlotDef(id:"buttpad", name:"缓冲垫", zoom:1.7, anchor:.init(x:0.15,y:0.55))]
            var w = Weapon(id: "sn\(i)", name: n, category: .sniper,
                           fireModes: bolt ? [.boltAction] : [.semiAuto],
                           defaultMode: bolt ? .boltAction : .semiAuto,
                           baseFireRate: bolt ? 45 : 180,
                           baseMag: bolt ? 5 : 10,
                           baseReload: bolt ? 3.2 : 2.6,
                           baseRecoil: 70, baseStability: 62, baseHandling: 40,
                           baseHip: 30, baseVelocity: 860, baseRange: 900,
                           slots: slots + extraSlots,
                           slotAttachments: partsMap,
                           initialParts: ["muzzle":"muzzle_0","barrel":"barrel_0","scope":"scope_0","stock":"stock_0","mag":"mag_0","bipod":"bipod_0"],
                           visual: WeaponVisual(barrelLen: 0.7, stockStyle: bolt ? 1 : 3,
                                                magStyle: 1, scopeStyle: 2, bodyStyle: 1,
                                                colorSeed: Double(i) * 0.13))
            w.slotAttachments["rail"] = parts("rail", base: ["短导轨","长导轨"], desc: "扩展安装位", stability: 1)
            w.slotAttachments["riser"] = parts("riser", base: ["标准增高架","高位增高架"], desc: "瞄准高度", stability: 1)
            w.slotAttachments["buttpad"] = parts("buttpad", base: ["橡胶垫","液压垫"], desc: "后坐缓冲", recoil: 3)
            return w
        }
    }

    // MARK: 步枪 10
    static func rifles() -> [Weapon] {
        let names = ["锋刃-1 突击步枪","锋刃-2 精确射手","锋刃-3 战斗步枪","铁砧 突击","长矛 精确射手","壁垒 战斗步枪","疾风 突击","鹰眼 精确射手","重锤 战斗步枪","游骑 突击"]
        return names.enumerated().map { i, n in
            let dmr = i % 3 == 1
            let modes: [FireMode] = dmr ? [.semiAuto, .burst] : [.fullAuto, .semiAuto, .burst]
            let slots = gunSlots([("muzzle","枪口"),("barrel","枪管"),("grip","握把"),("stock","枪托"),("mag","弹匣"),("scope","瞄准镜"),("handguard","护木")])
            var pm: [String:[Attachment]] = [:]
            pm["muzzle"] = parts("muzzle", base: ["制退器","消焰器","补偿器"], desc: "后坐控制", recoil: 5, hip: 2)
            pm["barrel"] = parts("barrel", base: ["标准枪管","长枪管","短枪管"], desc: "射程与操控", vel: 10, range: 6, handling: -2, reveals: ["rail"])
            pm["grip"] = parts("grip", base: ["垂直握把","斜角握把","轻型握把"], desc: "据枪稳定", stability: 4, handling: 2)
            pm["stock"] = parts("stock", base: ["固定枪托","折叠枪托","骨架枪托"], desc: "稳定与操控", stability: 4, handling: -1, reveals: ["buttpad"])
            pm["mag"] = parts("mag", base: ["标准弹匣","扩容弹匣","快拔弹匣"], desc: "容量与换弹", mag: 5, reload: -0.2)
            pm["scope"] = parts("scope", base: ["机械瞄具","红点镜","倍镜"], desc: "瞄准方式", stability: 2, range: 3, reveals: ["riser"])
            pm["handguard"] = parts("handguard", base: ["短护木","长护木","战术护木"], desc: "安装位与稳定", stability: 3)
            var w = Weapon(id: "rf\(i)", name: n, category: .rifle, fireModes: modes,
                           defaultMode: dmr ? .semiAuto : .fullAuto,
                           baseFireRate: dmr ? 220 : 620,
                           baseMag: dmr ? 20 : 30, baseReload: dmr ? 2.4 : 2.0,
                           baseRecoil: dmr ? 55 : 42, baseStability: dmr ? 66 : 55,
                           baseHandling: 60, baseHip: 55, baseVelocity: 820,
                           baseRange: dmr ? 600 : 400,
                           slots: slots, slotAttachments: pm,
                           initialParts: ["muzzle":"muzzle_0","barrel":"barrel_0","grip":"grip_0","stock":"stock_0","mag":"mag_0","scope":"scope_0","handguard":"handguard_0"],
                           visual: WeaponVisual(barrelLen: dmr ? 0.6 : 0.45,
                                                stockStyle: 2, magStyle: 2, scopeStyle: dmr ? 2 : 1,
                                                bodyStyle: 0, colorSeed: Double(i) * 0.11))
            w.slotAttachments["rail"] = parts("rail", base: ["短导轨","长导轨"], desc: "扩展位", stability: 1)
            w.slotAttachments["buttpad"] = parts("buttpad", base: ["橡胶垫","液压垫"], desc: "缓冲", recoil: 3)
            w.slotAttachments["riser"] = parts("riser", base: ["标准增高架","高位增高架"], desc: "瞄准高度", stability: 1)
            return w
        }
    }

    // MARK: 冲锋枪 10
    static func smgs() -> [Weapon] {
        let names = ["蜂鸟-1 冲锋枪","蜂鸟-2 微冲","蜂鸟-3 战术冲锋","疾影 冲锋","短刺 微冲","雨燕 战术冲锋","碎星 冲锋","低语 微冲","快刀 战术冲锋","流光 冲锋"]
        return names.enumerated().map { i, n in
            let slots = gunSlots([("muzzle","枪口"),("barrel","枪管"),("grip","握把"),("stock","枪托"),("mag","弹匣"),("scope","瞄准镜")])
            var pm: [String:[Attachment]] = [:]
            pm["muzzle"] = parts("muzzle", base: ["消焰器","补偿器","消音器"], desc: "后坐与隐蔽", recoil: 4, hip: 3)
            pm["barrel"] = parts("barrel", base: ["短枪管","标准枪管","长枪管"], desc: "射程与操控", vel: 8, range: 5, handling: 2)
            pm["grip"] = parts("grip", base: ["垂直握把","斜角握把"], desc: "稳定", stability: 3)
            pm["stock"] = parts("stock", base: ["折叠枪托","伸缩枪托","无枪托"], desc: "操控与稳定", stability: 2, handling: 4, reveals: ["buttpad"])
            pm["mag"] = parts("mag", base: ["标准弹匣","扩容弹匣","快拔弹匣"], desc: "容量与换弹", mag: 6, reload: -0.2)
            pm["scope"] = parts("scope", base: ["机械瞄具","红点镜"], desc: "瞄准", stability: 1, reveals: ["riser"])
            var w = Weapon(id: "sm\(i)", name: n, category: .smg,
                           fireModes: [.fullAuto, .semiAuto, .burst],
                           defaultMode: .fullAuto,
                           baseFireRate: 780 + Double(i) * 40,
                           baseMag: 25 + i, baseReload: 1.9,
                           baseRecoil: 35, baseStability: 50, baseHandling: 78,
                           baseHip: 70, baseVelocity: 420, baseRange: 200,
                           slots: slots, slotAttachments: pm,
                           initialParts: ["muzzle":"muzzle_0","barrel":"barrel_0","grip":"grip_0","stock":"stock_0","mag":"mag_0","scope":"scope_0"],
                           visual: WeaponVisual(barrelLen: 0.3, stockStyle: 2, magStyle: 1,
                                                scopeStyle: 1, bodyStyle: 4, colorSeed: Double(i) * 0.09))
            w.slotAttachments["buttpad"] = parts("buttpad", base: ["橡胶垫"], desc: "缓冲", recoil: 2)
            w.slotAttachments["riser"] = parts("riser", base: ["标准增高架"], desc: "瞄准高度", stability: 1)
            return w
        }
    }

    // MARK: 手枪 10
    static func pistols() -> [Weapon] {
        let names = ["短铳-1 半自动手枪","短铳-2 左轮","短铳-3 冲锋手枪","迅击 半自动","铁指 左轮","蜂刺 冲锋手枪","轻语 半自动","响尾 左轮","连珠 冲锋手枪","冷锋 半自动"]
        return names.enumerated().map { i, n in
            let revolver = i % 3 == 1
            let machine = i % 3 == 2
            let slots = gunSlots([("muzzle","枪口"),("barrel","枪管"),("grip","握把"),("mag","弹匣"),("scope","瞄准镜")])
            var pm: [String:[Attachment]] = [:]
            pm["muzzle"] = parts("muzzle", base: ["消焰器","补偿器"], desc: "后坐", recoil: 3)
            pm["barrel"] = parts("barrel", base: ["短枪管","标准枪管","长枪管"], desc: "射程", vel: 6, range: 4)
            pm["grip"] = parts("grip", base: ["标准握把","防滑握把"], desc: "操控", handling: 2)
            pm["mag"] = parts("mag", base: revolver ? ["标准弹巢","快装弹巢"] : ["标准弹匣","扩容弹匣","快拔弹匣"], desc: "容量与换弹", mag: revolver ? 1 : 3, reload: -0.2)
            pm["scope"] = parts("scope", base: ["机械瞄具","微型红点"], desc: "瞄准", stability: 1, reveals: ["riser"])
            let modes: [FireMode] = machine ? [.fullAuto, .semiAuto] : [.semiAuto]
            var w = Weapon(id: "ps\(i)", name: n, category: .pistol, fireModes: modes,
                           defaultMode: machine ? .fullAuto : .semiAuto,
                           baseFireRate: machine ? 900 : 300,
                           baseMag: revolver ? 6 : (machine ? 20 : 12),
                           baseReload: revolver ? 2.4 : 1.6,
                           baseRecoil: 30, baseStability: 55, baseHandling: 85,
                           baseHip: 75, baseVelocity: 380, baseRange: 100,
                           slots: slots, slotAttachments: pm,
                           initialParts: ["muzzle":"muzzle_0","barrel":"barrel_0","grip":"grip_0","mag":"mag_0","scope":"scope_0"],
                           visual: WeaponVisual(barrelLen: 0.18, stockStyle: 0,
                                                magStyle: revolver ? 4 : (machine ? 1 : 0),
                                                scopeStyle: 1, bodyStyle: 2,
                                                colorSeed: Double(i) * 0.07))
            w.slotAttachments["riser"] = parts("riser", base: ["微型增高架"], desc: "瞄准高度", stability: 1)
            return w
        }
    }

    // MARK: 霰弹枪 10
    static func shotguns() -> [Weapon] {
        let names = ["破门-1 泵动霰弹枪","破门-2 半自动霰弹枪","破门-3 双管霰弹枪","雷霆 泵动","铁雨 半自动","双牙 双管","震击 泵动","风暴 半自动","响雷 双管","碎门 弹鼓霰弹枪"]
        return names.enumerated().map { i, n in
            let pump = i % 3 == 0
            let semi = i % 3 == 1
            let dbl = i % 3 == 2 && i != 9
            let drum = i == 9
            let slots = gunSlots([("muzzle","枪口"),("barrel","枪管"),("grip","握把"),("stock","枪托"),("mag","弹仓"),("scope","瞄准镜")])
            var pm: [String:[Attachment]] = [:]
            pm["muzzle"] = parts("muzzle", base: ["收束器","消焰器","扩散器"], desc: "散布与后坐", recoil: 5, range: 3)
            pm["barrel"] = parts("barrel", base: ["标准枪管","长枪管","短枪管"], desc: "射程", vel: 8, range: 5)
            pm["grip"] = parts("grip", base: ["垂直握把","战术握把"], desc: "稳定", stability: 4)
            pm["stock"] = parts("stock", base: ["固定枪托","折叠枪托","无枪托"], desc: "稳定与操控", stability: 3, handling: 3, reveals: ["buttpad"])
            pm["mag"] = parts("mag", base: drum ? ["弹鼓","扩容弹鼓"] : ["标准弹仓","扩容弹仓","快速装填器"], desc: "容量与换弹", mag: 2, reload: -0.3)
            pm["scope"] = parts("scope", base: ["机械瞄具","红点镜"], desc: "瞄准", stability: 1, reveals: ["riser"])
            let modes: [FireMode] = pump ? [.pumpAction] : (semi ? [.semiAuto] : [.semiAuto, .burst])
            var w = Weapon(id: "sg\(i)", name: n, category: .shotgun, fireModes: modes,
                           defaultMode: modes[0],
                           baseFireRate: pump ? 70 : (semi ? 180 : 120),
                           baseMag: drum ? 20 : (dbl ? 2 : (pump ? 6 : 8)),
                           baseReload: pump ? 2.8 : 2.2,
                           baseRecoil: 80, baseStability: 45, baseHandling: 45,
                           baseHip: 50, baseVelocity: 400, baseRange: 80,
                           slots: slots, slotAttachments: pm,
                           initialParts: ["muzzle":"muzzle_0","barrel":"barrel_0","grip":"grip_0","stock":"stock_0","mag":"mag_0","scope":"scope_0"],
                           visual: WeaponVisual(barrelLen: 0.5, stockStyle: dbl ? 1 : 2,
                                                magStyle: drum ? 3 : 0, scopeStyle: 1,
                                                bodyStyle: 3, colorSeed: Double(i) * 0.12))
            w.slotAttachments["buttpad"] = parts("buttpad", base: ["橡胶垫"], desc: "缓冲", recoil: 3)
            w.slotAttachments["riser"] = parts("riser", base: ["标准增高架"], desc: "瞄准高度", stability: 1)
            return w
        }
    }

    // MARK: 特殊武器 6
    static func specials() -> [Weapon] {
        let defs: [(String, WeaponVisual, [String], [String:[Attachment]])] = [
            ("破城 火箭筒", WeaponVisual(barrelLen: 0.7, stockStyle: 1, magStyle: 0, scopeStyle: 2, bodyStyle: 5),
             ["scope","grip","tube","suppressor"],
             ["scope": parts("scope", base: ["机械瞄具","光学瞄具"], desc: "瞄准", stability: 2),
              "grip": parts("grip", base: ["标准握把","战术握把"], desc: "稳定", stability: 3),
              "tube": parts("tube", base: ["标准发射管","加长发射管"], desc: "初速", vel: 10),
              "suppressor": parts("suppressor", base: ["无尾焰抑制","尾焰抑制器"], desc: "尾焰", recoil: 4)]),
            ("雷霆 火箭筒", WeaponVisual(barrelLen: 0.8, stockStyle: 2, magStyle: 0, scopeStyle: 2, bodyStyle: 5),
             ["scope","grip","tube","suppressor"],
             ["scope": parts("scope", base: ["光学瞄具","热成像瞄具"], desc: "瞄准", stability: 2),
              "grip": parts("grip", base: ["标准握把","液压握把"], desc: "稳定", stability: 4),
              "tube": parts("tube", base: ["标准发射管","重型发射管"], desc: "初速", vel: 12),
              "suppressor": parts("suppressor", base: ["无尾焰抑制","尾焰抑制器"], desc: "尾焰", recoil: 5)]),
            ("雷鸣 榴弹发射器", WeaponVisual(barrelLen: 0.4, stockStyle: 1, magStyle: 3, scopeStyle: 1, bodyStyle: 6),
             ["scope","grip","drum","barrel"],
             ["scope": parts("scope", base: ["机械瞄具","红点镜"], desc: "瞄准", stability: 2),
              "grip": parts("grip", base: ["标准握把","垂直握把"], desc: "稳定", stability: 3),
              "drum": parts("drum", base: ["标准弹鼓","扩容弹鼓"], desc: "容量", mag: 2, reload: -0.2),
              "barrel": parts("barrel", base: ["标准管","短管"], desc: "射程", range: 4)]),
            ("裂地 榴弹发射器", WeaponVisual(barrelLen: 0.5, stockStyle: 2, magStyle: 3, scopeStyle: 1, bodyStyle: 6),
             ["scope","grip","drum","barrel"],
             ["scope": parts("scope", base: ["红点镜","倍镜"], desc: "瞄准", stability: 2),
              "grip": parts("grip", base: ["垂直握把","斜角握把"], desc: "稳定", stability: 4),
              "drum": parts("drum", base: ["标准弹鼓","大容量弹鼓"], desc: "容量", mag: 3, reload: -0.3),
              "barrel": parts("barrel", base: ["标准管","长管"], desc: "射程", range: 5)]),
            ("光束 激光武器", WeaponVisual(barrelLen: 0.55, stockStyle: 1, magStyle: 0, scopeStyle: 2, bodyStyle: 7),
             ["crystal","cooling","battery","scope"],
             ["crystal": parts("crystal", base: ["标准聚焦晶体","高纯聚焦晶体"], desc: "聚焦", focus: 4),
              "cooling": parts("cooling", base: ["标准散热片","高效散热片"], desc: "散热", cooling: 5),
              "battery": parts("battery", base: ["标准电池","高能电池"], desc: "能量效率", energyEfficiency: 4),
              "scope": parts("scope", base: ["光学瞄具","精密瞄具"], desc: "精度", stability: 2)]),
            ("脉冲 激光武器", WeaponVisual(barrelLen: 0.65, stockStyle: 3, magStyle: 0, scopeStyle: 2, bodyStyle: 7),
             ["crystal","cooling","battery","scope"],
             ["crystal": parts("crystal", base: ["聚焦晶体","相位晶体"], desc: "聚焦", focus: 5),
              "cooling": parts("cooling", base: ["散热片","液冷模块"], desc: "散热", cooling: 6),
              "battery": parts("battery", base: ["标准电池","脉冲电池"], desc: "能量效率", energyEfficiency: 5),
              "scope": parts("scope", base: ["光学瞄具","热成像瞄具"], desc: "精度", stability: 3)])
        ]
        return defs.enumerated().map { i, d in
            let (name, vis, slotIDs, pm) = d
            let cn: [String:String] = ["scope":"瞄具","grip":"握把","tube":"发射管","suppressor":"尾焰抑制","drum":"弹鼓","barrel":"发射管","crystal":"聚焦晶体","cooling":"散热模块","battery":"能量电池"]
            let slots = slotIDs.map { SlotDef(id: $0, name: cn[$0] ?? $0, tiltX: 6, tiltY: -6, zoom: 1.5, anchor: .init(x: 0.4, y: 0.5)) }
            return Weapon(id: "sp\(i)", name: name, category: .special,
                          fireModes: [.singleShot], defaultMode: .singleShot,
                          baseFireRate: 60, baseMag: 1 + (i % 3), baseReload: 3.0,
                          baseRecoil: 60, baseStability: 60, baseHandling: 35,
                          baseHip: 40, baseVelocity: 300, baseRange: 300,
                          slots: slots, slotAttachments: pm,
                          initialParts: Dictionary(uniqueKeysWithValues: slotIDs.map { ($0, "\($0)_0") }),
                          visual: vis)
        }
    }

    // MARK: 近战 5
    static func melees() -> [Weapon] {
        let defs: [(String, Int, WeaponVisual)] = [
            ("蝶影 蝴蝶刀", 0, WeaponVisual(barrelLen: 0.35, bladeStyle: 0)),
            ("钩爪 爪刀", 1, WeaponVisual(barrelLen: 0.3, bladeStyle: 1)),
            ("弹锋 弹簧刀", 2, WeaponVisual(barrelLen: 0.38, bladeStyle: 2)),
            ("直刃 战术直刀", 3, WeaponVisual(barrelLen: 0.45, bladeStyle: 3)),
            ("破阵 战术刀", 4, WeaponVisual(barrelLen: 0.5, bladeStyle: 4))
        ]
        return defs.enumerated().map { i, d in
            let (name, style, vis) = d
            _ = style
            let slots = [SlotDef(id:"blade", name:"刀身", zoom:1.7, anchor:.init(x:0.5,y:0.4)),
                         SlotDef(id:"tip", name:"刀尖", zoom:1.8, anchor:.init(x:0.8,y:0.4)),
                         SlotDef(id:"guard", name:"护手", zoom:1.6, anchor:.init(x:0.35,y:0.55)),
                         SlotDef(id:"handle", name:"握柄", zoom:1.6, anchor:.init(x:0.2,y:0.6)),
                         SlotDef(id:"weight", name:"配重", zoom:1.7, anchor:.init(x:0.1,y:0.7)),
                         SlotDef(id:"sheath", name:"刀鞘", zoom:1.5, anchor:.init(x:0.5,y:0.8)),
                         SlotDef(id:"joint", name:"联动关节", zoom:1.7, anchor:.init(x:0.3,y:0.6))]
            var pm: [String:[Attachment]] = [:]
            pm["blade"] = parts("blade", base: ["等离子强化刃身","碳纤维刃身","纳米自锐刃身"], desc: "刃身与穿透", penetration: 5, meleeRange: 3)
            pm["tip"] = parts("tip", base: ["热能聚焦刀尖","强化刀尖"], desc: "刀尖与穿透", penetration: 3)
            pm["guard"] = parts("guard", base: ["碳纤维机械护手","能量护手"], desc: "护手与平衡", balance: 3)
            pm["handle"] = parts("handle", base: ["磁吸防滑握柄","机械折叠握柄"], desc: "握持与速度", meleeSpeed: 4, reveals: ["joint"])
            pm["weight"] = parts("weight", base: ["配重尾环","轻量尾环"], desc: "配重与平衡", balance: 4, meleeSpeed: -1)
            pm["sheath"] = parts("sheath", base: ["折叠联动刀鞘","标准刀鞘"], desc: "刀鞘", handling: 2)
            var w = Weapon(id: "me\(i)", name: name, category: .melee,
                           fireModes: [.melee], defaultMode: .melee,
                           baseFireRate: 80, baseMag: 1, baseReload: 0,
                           baseRecoil: 0, baseStability: 0, baseHandling: 70,
                           baseHip: 0, baseVelocity: 0, baseRange: 0,
                           meleeSpeed: 60, meleeRange: 50, penetration: 55, balance: 50,
                           slots: slots, slotAttachments: pm,
                           initialParts: ["blade":"blade_0","tip":"tip_0","guard":"guard_0","handle":"handle_0","weight":"weight_0","sheath":"sheath_0"],
                           visual: vis)
            w.slotAttachments["joint"] = parts("joint", base: ["联动关节模块","增强联动关节"], desc: "折叠联动", meleeSpeed: 2)
            return w
        }
    }
}
