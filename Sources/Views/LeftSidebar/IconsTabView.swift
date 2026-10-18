import SwiftUI

public struct IconsTabView: View {
    @ObservedObject var viewModel: CanvasDocumentViewModel
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var insertColor: CodableColor = .inkBlack

    /// Curated swatches for standard (mono) icon insertion.
    private let swatchColors: [(name: String, hex: String)] = [
        ("Ink", "#1C1917"), ("Slate", "#475569"), ("Gray", "#94A3B8"),
        ("Red", "#DC2626"), ("Orange", "#EA580C"), ("Amber", "#F59E0B"),
        ("Green", "#16A34A"), ("Teal", "#0D9488"), ("Blue", "#2563EB"),
        ("Indigo", "#4F46E5"), ("Purple", "#7C3AED"), ("Pink", "#E11D48"),
        ("Brown", "#78350F"), ("White", "#F8FAFC")
    ]

    struct MulticolorIconPreset: Identifiable {
        let id = UUID()
        let name: String
        let symbol: String
        let primary: CodableColor
        let secondary: CodableColor
        let tertiary: CodableColor

        init(_ name: String, _ symbol: String, _ primaryHex: String, _ secondaryHex: String, _ tertiaryHex: String = "#F59E0B") {
            self.name = name
            self.symbol = symbol
            self.primary = CodableColor(hex: primaryHex)
            self.secondary = CodableColor(hex: secondaryHex)
            self.tertiary = CodableColor(hex: tertiaryHex)
        }
    }

    private let multicolorPresets: [MulticolorIconPreset] = [
        // MARK: Weather & Nature (all symbols verified multi-level)
        MulticolorIconPreset("Sunny Day", "cloud.sun.fill", "#38BDF8", "#F59E0B"),
        MulticolorIconPreset("Night Sky", "moon.stars.fill", "#6366F1", "#FBBF24"),
        MulticolorIconPreset("Storm Cloud", "cloud.bolt.fill", "#475569", "#FBBF24"),
        MulticolorIconPreset("Rain Shower", "cloud.rain.fill", "#64748B", "#38BDF8"),
        MulticolorIconPreset("Thunder Rain", "cloud.bolt.rain.fill", "#475569", "#FBBF24", "#38BDF8"),
        MulticolorIconPreset("Moonlit Storm", "cloud.moon.bolt.fill", "#64748B", "#818CF8", "#FBBF24"),
        MulticolorIconPreset("Snow Drift", "wind.snow", "#64748B", "#7DD3FC"),
        MulticolorIconPreset("Snowflake Badge", "snowflake.circle.fill", "#0EA5E9", "#F0F9FF"),
        MulticolorIconPreset("Rain Drop", "drop.circle.fill", "#0284C7", "#E0F2FE"),
        MulticolorIconPreset("Drop Alert", "drop.triangle.fill", "#0284C7", "#BAE6FD"),
        MulticolorIconPreset("Humid Air", "humidity.fill", "#38BDF8", "#0369A1"),
        MulticolorIconPreset("Heat Wave", "thermometer.high", "#DC2626", "#FBBF24"),
        MulticolorIconPreset("Deep Frost", "thermometer.snowflake", "#0EA5E9", "#BAE6FD"),
        MulticolorIconPreset("Sunrise Glow", "sunrise.fill", "#FBBF24", "#EA580C"),
        MulticolorIconPreset("Sunset Fade", "sunset.fill", "#EA580C", "#78350F"),
        MulticolorIconPreset("Horizon Sun", "sun.and.horizon.fill", "#F59E0B", "#0369A1"),
        MulticolorIconPreset("Sunny Badge", "sun.max.circle.fill", "#F59E0B", "#FEF3C7"),
        MulticolorIconPreset("Sleepy Moon", "moon.zzz.fill", "#6366F1", "#C7D2FE"),
        MulticolorIconPreset("Moon Badge", "moon.circle.fill", "#4F46E5", "#E0E7FF"),
        MulticolorIconPreset("Evergreen", "tree.circle.fill", "#15803D", "#DCFCE7"),
        MulticolorIconPreset("Eco Cycle", "leaf.arrow.triangle.circlepath", "#16A34A", "#65A30D"),
        MulticolorIconPreset("Mountain Peak", "mountain.2.circle.fill", "#475569", "#F1F5F9"),
        MulticolorIconPreset("Tide Rising", "water.waves.and.arrow.up", "#0284C7", "#38BDF8"),
        MulticolorIconPreset("Tide Falling", "water.waves.and.arrow.down", "#0369A1", "#67E8F9"),

        // MARK: Animals
        MulticolorIconPreset("Lady Bug", "ladybug.circle.fill", "#DC2626", "#1C1917"),
        MulticolorIconPreset("Sea Fish", "fish.circle.fill", "#0284C7", "#BAE6FD"),
        MulticolorIconPreset("Pet Paw", "pawprint.circle.fill", "#92400E", "#FEF3C7"),
        MulticolorIconPreset("Sparkle Hands", "hands.sparkles.fill", "#0D9488", "#FBBF24"),

        // MARK: Food, Wear & Travel
        MulticolorIconPreset("Takeout", "takeoutbag.and.cup.and.straw.fill", "#C2410C", "#F59E0B", "#38BDF8"),
        MulticolorIconPreset("Movie Snack", "popcorn.circle.fill", "#DC2626", "#FDE68A"),
        MulticolorIconPreset("Tee Shirt", "tshirt.circle.fill", "#2563EB", "#BFDBFE"),
        MulticolorIconPreset("Travel Pack", "backpack.circle.fill", "#B45309", "#FDE68A"),
        MulticolorIconPreset("Rolling Case", "suitcase.rolling.circle.fill", "#1E293B", "#7DD3FC"),
        MulticolorIconPreset("Event Ticket", "ticket.circle.fill", "#C2410C", "#FDE68A"),
        MulticolorIconPreset("Night Camp", "tent.circle.fill", "#B45309", "#FEF3C7"),
        MulticolorIconPreset("City Car", "car.circle.fill", "#2563EB", "#BFDBFE"),
        MulticolorIconPreset("Route Plan", "point.topleft.down.curvedto.point.bottomright.up", "#2563EB", "#DC2626"),
        MulticolorIconPreset("North Point", "location.north.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Compass", "safari.fill", "#0D9488", "#F59E0B"),
        MulticolorIconPreset("Bird Watch", "binoculars.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Map Pin", "mappin.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("World Map", "map.circle.fill", "#0D9488", "#FDE68A"),
        MulticolorIconPreset("Airborne", "airplane.circle.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Departure", "airplane.departure", "#0284C7", "#94A3B8"),
        MulticolorIconPreset("Fuel Stop", "fuelpump.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Parking Spot", "parkingsign.circle.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Delivery Van", "box.truck.badge.clock.fill", "#334155", "#C2410C", "#FBBF24"),

        // MARK: Sports & Games
        MulticolorIconPreset("Arena", "sportscourt.circle.fill", "#15803D", "#DCFCE7"),
        MulticolorIconPreset("Graduate", "graduationcap.circle.fill", "#1E293B", "#FBBF24"),
        MulticolorIconPreset("Team Up", "person.2.circle.fill", "#2563EB", "#BFDBFE"),
        MulticolorIconPreset("Victory Flag", "flag.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Focus Ring", "viewfinder.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Game Pad", "gamecontroller.circle.fill", "#1E293B", "#60A5FA"),
        MulticolorIconPreset("Lucky Dice", "die.face.6.fill", "#F8FAFC", "#1C1917"),
        MulticolorIconPreset("Roll Dice", "dice.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Champion Cup", "trophy.circle.fill", "#D97706", "#FEF3C7"),
        MulticolorIconPreset("Party Popper", "party.popper.fill", "#E11D48", "#FBBF24", "#2563EB"),
        MulticolorIconPreset("Fireworks", "fireworks", "#6366F1", "#FBBF24", "#E11D48"),
        MulticolorIconPreset("Balloons", "balloon.2.fill", "#E11D48", "#38BDF8"),
        MulticolorIconPreset("Gift Badge", "gift.circle.fill", "#DC2626", "#FDE68A"),
        MulticolorIconPreset("Magic Wand", "wand.and.stars", "#334155", "#FBBF24"),
        MulticolorIconPreset("Theater", "theatermasks.circle.fill", "#7C3AED", "#DDD6FE"),
        MulticolorIconPreset("Art Show", "theatermask.and.paintbrush.fill", "#C2410C", "#7C3AED"),
        MulticolorIconPreset("Music Hall", "music.note.house.fill", "#7C3AED", "#FBBF24"),
        MulticolorIconPreset("Set List", "music.note.list", "#1E293B", "#0D9488"),
        MulticolorIconPreset("Guitar Duo", "guitars.fill", "#92400E", "#F59E0B"),
        MulticolorIconPreset("Speaker", "speaker.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Headphones", "headphones.circle.fill", "#1E293B", "#F59E0B"),
        MulticolorIconPreset("Studio Mic", "mic.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Mic Plus", "mic.badge.plus", "#334155", "#16A34A"),
        MulticolorIconPreset("Film Reel", "film.circle.fill", "#1C1917", "#FBBF24"),
        MulticolorIconPreset("TV Night", "tv.circle.fill", "#1E293B", "#7DD3FC"),
        MulticolorIconPreset("Home Cinema", "tv.and.hifispeaker.fill", "#1E293B", "#818CF8"),
        MulticolorIconPreset("Photo Tilt", "photo.on.rectangle.angled", "#0284C7", "#F59E0B"),
        MulticolorIconPreset("Framed Art", "photo.artframe", "#92400E", "#7DD3FC"),
        MulticolorIconPreset("Memory Lane", "memories.badge.plus", "#2563EB", "#FBBF24"),
        MulticolorIconPreset("Camera Lens", "camera.badge.ellipsis", "#334155", "#2563EB"),
        MulticolorIconPreset("Camera Filters", "camera.filters", "#334155", "#FBBF24"),
        MulticolorIconPreset("Play Button", "play.rectangle.fill", "#DC2626", "#F8FAFC"),

        // MARK: Tech & Code
        MulticolorIconPreset("Pro Laptop", "laptopcomputer.and.iphone", "#1E293B", "#0284C7"),
        MulticolorIconPreset("Workstation", "desktopcomputer", "#1E293B", "#7DD3FC"),
        MulticolorIconPreset("Studio Display", "display.2", "#1E293B", "#38BDF8"),
        MulticolorIconPreset("MacBook", "macbook", "#334155", "#7DD3FC"),
        MulticolorIconPreset("iPad", "ipad", "#334155", "#93C5FD"),
        MulticolorIconPreset("iPhone", "iphone", "#1E293B", "#7DD3FC"),
        MulticolorIconPreset("Smart Watch", "applewatch", "#1C1917", "#7DD3FC"),
        MulticolorIconPreset("Secure Net", "network.badge.shield.half.filled", "#334155", "#10B981"),
        MulticolorIconPreset("WiFi Badge", "wifi.circle.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Airwaves", "antenna.radiowaves.left.and.right.circle.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("iCloud Sync", "checkmark.icloud.fill", "#0284C7", "#10B981"),
        MulticolorIconPreset("Cloud Upload", "icloud.and.arrow.up.fill", "#0284C7", "#F8FAFC"),
        MulticolorIconPreset("Time Machine", "externaldrive.badge.timemachine", "#334155", "#FBBF24"),
        MulticolorIconPreset("Drive Plus", "externaldrive.badge.plus", "#334155", "#16A34A"),
        MulticolorIconPreset("Charging", "battery.100.bolt", "#16A34A", "#FBBF24"),
        MulticolorIconPreset("Bolt Badge", "bolt.circle.fill", "#F59E0B", "#1C1917"),
        MulticolorIconPreset("Bolt Heart", "bolt.heart.fill", "#E11D48", "#FBBF24"),
        MulticolorIconPreset("Connector", "cable.connector", "#334155", "#94A3B8"),
        MulticolorIconPreset("App Badge", "app.badge.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("New Window", "macwindow.badge.plus", "#334155", "#16A34A"),
        MulticolorIconPreset("Face ID", "faceid", "#0D9488", "#334155"),
        MulticolorIconPreset("Code Braces", "curlybraces.square.fill", "#1E293B", "#FBBF24"),
        MulticolorIconPreset("Git Graph", "point.3.connected.trianglepath.dotted", "#7C3AED", "#38BDF8"),
        MulticolorIconPreset("Layers 3D", "square.3.layers.3d", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Widget Stack", "square.stack.3d.up.fill", "#2563EB", "#BFDBFE"),

        // MARK: Communication
        MulticolorIconPreset("Chat Bubbles", "bubble.left.and.bubble.right.fill", "#2563EB", "#93C5FD"),
        MulticolorIconPreset("Talk Bubble", "text.bubble.fill", "#2563EB", "#EFF6FF"),
        MulticolorIconPreset("Quote Mark", "quote.bubble.fill", "#334155", "#BAE6FD"),
        MulticolorIconPreset("Phone Call", "phone.badge.plus", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Video Call", "video.badge.plus", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Mail Alert", "envelope.badge.fill", "#334155", "#DC2626"),
        MulticolorIconPreset("Message Badge", "message.badge.fill", "#2563EB", "#DC2626"),

        // MARK: Docs & Office
        MulticolorIconPreset("Doc Scan", "doc.viewfinder.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("Doc Plus", "doc.badge.plus", "#334155", "#16A34A"),
        MulticolorIconPreset("Doc Copy", "doc.on.doc.fill", "#334155", "#94A3B8"),
        MulticolorIconPreset("Clipboard", "doc.on.clipboard.fill", "#B45309", "#F8FAFC"),
        MulticolorIconPreset("Folder Plus", "folder.badge.plus", "#D97706", "#16A34A"),
        MulticolorIconPreset("Folder Query", "folder.badge.questionmark", "#D97706", "#FBBF24"),
        MulticolorIconPreset("System Folder", "folder.badge.gearshape", "#D97706", "#475569"),
        MulticolorIconPreset("Inbox", "tray.and.arrow.down.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Meeting Day", "calendar.badge.clock", "#C2410C", "#1E293B"),
        MulticolorIconPreset("Important Day", "calendar.badge.exclamationmark", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("New Event", "calendar.badge.plus", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Clock Check", "clock.badge.checkmark.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Alarm Ring", "alarm.waves.left.and.right.fill", "#DC2626", "#FBBF24"),
        MulticolorIconPreset("Deadline", "hourglass.circle.fill", "#B45309", "#FDE68A"),
        MulticolorIconPreset("Package", "shippingbox.circle.fill", "#B45309", "#FDE68A"),
        MulticolorIconPreset("Briefcase", "briefcase.circle.fill", "#78350F", "#FDE68A"),
        MulticolorIconPreset("ID Card", "person.text.rectangle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Study Book", "book.circle.fill", "#7C3AED", "#DDD6FE"),
        MulticolorIconPreset("Tag Badge", "tag.circle.fill", "#C2410C", "#FDE68A"),
        MulticolorIconPreset("Staff Badge", "person.badge.shield.checkmark.fill", "#2563EB", "#10B981"),

        // MARK: Commerce
        MulticolorIconPreset("Card Pay", "creditcard.circle.fill", "#1E293B", "#FBBF24"),
        MulticolorIconPreset("Card Warning", "creditcard.trianglebadge.exclamationmark", "#1E293B", "#FBBF24"),
        MulticolorIconPreset("Bitcoin", "bitcoinsign.circle.fill", "#F59E0B", "#F8FAFC"),
        MulticolorIconPreset("Dollar Sign", "dollarsign.circle.fill", "#16A34A", "#DCFCE7"),
        MulticolorIconPreset("Growth Chart", "chart.line.uptrend.xyaxis.circle.fill", "#4F46E5", "#10B981"),
        MulticolorIconPreset("Line Chart", "chart.xyaxis.line", "#94A3B8", "#2563EB"),
        MulticolorIconPreset("Trend Up", "chart.line.uptrend.xyaxis", "#94A3B8", "#16A34A"),
        MulticolorIconPreset("Scan QR", "qrcode.viewfinder", "#1C1917", "#2563EB"),
        MulticolorIconPreset("Bank Vault", "building.columns.circle.fill", "#334155", "#FBBF24"),
        MulticolorIconPreset("Bag Plus", "bag.badge.plus", "#C2410C", "#16A34A"),
        MulticolorIconPreset("Cart Plus", "cart.badge.plus", "#2563EB", "#F8FAFC"),

        // MARK: Security & Marks
        MulticolorIconPreset("Warning", "exclamationmark.triangle.fill", "#FBBF24", "#1C1917"),
        MulticolorIconPreset("Stop Sign", "xmark.octagon.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Shield Check", "checkmark.shield.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Shield Block", "xmark.shield.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Shield Alert", "exclamationmark.shield.fill", "#FBBF24", "#1C1917"),
        MulticolorIconPreset("Key Vault", "lock.shield.fill", "#334155", "#FBBF24"),
        MulticolorIconPreset("Verified Seal", "checkmark.seal.fill", "#10B981", "#FFFFFF"),
        MulticolorIconPreset("Verified Check", "checkmark.circle.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Info Badge", "info.circle.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Question Diamond", "questionmark.diamond.fill", "#7C3AED", "#F8FAFC"),
        MulticolorIconPreset("Caution", "exclamationmark.octagon.fill", "#F59E0B", "#1C1917"),

        // MARK: People & Health
        MulticolorIconPreset("Add Friend", "person.crop.circle.badge.plus", "#2563EB", "#16A34A"),
        MulticolorIconPreset("Verified User", "person.crop.circle.badge.checkmark", "#2563EB", "#10B981"),
        MulticolorIconPreset("Thumbs Up", "hand.thumbsup.circle.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("Happy Face", "face.smiling", "#FBBF24", "#92400E"),
        MulticolorIconPreset("Watcher", "eye.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Medical Star", "staroflife.circle.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Health Card", "heart.text.square.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Doctor", "stethoscope.circle.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("First Aid", "cross.case.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Red Cross", "cross.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Medicine", "pills.circle.fill", "#0284C7", "#F8FAFC"),
        MulticolorIconPreset("Deep Mind", "brain.head.profile", "#7C3AED", "#C4B5FD"),
        MulticolorIconPreset("Lab Test", "testtube.2", "#0284C7", "#10B981"),

        // MARK: Home & Controls
        MulticolorIconPreset("Home Badge", "house.circle.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("City Tower", "building.2.crop.circle.fill", "#475569", "#BAE6FD"),
        MulticolorIconPreset("Hotel Bed", "bed.double.circle.fill", "#4F46E5", "#E0E7FF"),
        MulticolorIconPreset("Bright Idea", "lightbulb.circle.fill", "#FBBF24", "#1C1917"),
        MulticolorIconPreset("Laundry", "washer.fill", "#0284C7", "#BAE6FD"),
        MulticolorIconPreset("Heart Badge", "heart.circle.fill", "#E11D48", "#FFFFFF"),
        MulticolorIconPreset("Star Badge", "star.circle.fill", "#F59E0B", "#FEF3C7"),
        MulticolorIconPreset("Bookmark", "bookmark.circle.fill", "#2563EB", "#BFDBFE"),
        MulticolorIconPreset("Bell Alert", "bell.badge.fill", "#FBBF24", "#DC2626"),
        MulticolorIconPreset("Pin It", "pin.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Trash Bin", "trash.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Add New", "plus.circle.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Done Check", "checkmark.rectangle.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Gear Check", "gear.badge.checkmark", "#475569", "#16A34A"),
        MulticolorIconPreset("Gear Block", "gear.badge.xmark", "#475569", "#DC2626"),
        MulticolorIconPreset("More Menu", "ellipsis.rectangle.fill", "#334155", "#F8FAFC"),
        MulticolorIconPreset("Filter", "line.3.horizontal.decrease.circle.fill", "#334155", "#7DD3FC"),
        MulticolorIconPreset("Switcher", "switch.2", "#2563EB", "#94A3B8"),
        MulticolorIconPreset("Upload Doc", "arrow.up.doc.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Sync Loop", "arrow.2.circlepath.circle.fill", "#0D9488", "#F8FAFC"),
        MulticolorIconPreset("Go Up", "arrow.up.circle.fill", "#16A34A", "#F8FAFC"),
        MulticolorIconPreset("Go Down", "arrow.down.circle.fill", "#DC2626", "#F8FAFC"),
        MulticolorIconPreset("Chevron Up", "chevron.up.circle.fill", "#334155", "#BAE6FD"),
        MulticolorIconPreset("Add App", "plus.app.fill", "#2563EB", "#F8FAFC"),
        MulticolorIconPreset("Artist Palette", "swatchpalette.fill", "#C2410C", "#0D9488", "#FBBF24")
    ]

    private let categories: [(name: String, symbols: [String])] = [
        ("Design & Craft", [
            "paintbrush.pointed.fill", "pencil.tip", "pencil.tip.crop.circle", "paintbrush.fill", "pencil.and.scribble",
            "pencil.circle.fill", "eyedropper.halffull", "eyedropper.full", "crop", "crop.rotate", "skew", "perspective",
            "wand.and.stars", "sparkles", "seal.fill", "rosette", "swatchpalette.fill", "paintpalette.fill",
            "square.2.layers.3d.top.filled", "square.3.layers.3d", "circle.dashed", "square.dashed", "ruler.fill",
            "scissors", "highlighter", "eraser.fill", "scribble.variable", "compass.drawing", "circle.grid.cross.fill",
            "circle.hexagongrid.fill", "lasso", "signature", "text.viewfinder", "square.on.square", "rectangle.on.rectangle",
            "grid", "grid.circle.fill", "square.grid.2x2.fill", "square.grid.3x3.fill", "circle.grid.2x2.fill",
            "photo.artframe", "doc.viewfinder.fill"
        ]),
        ("UI & Navigation", [
            "cursorarrow", "cursorarrow.rays", "cursorarrow.click.2", "cursorarrow.motionlines", "hand.point.up.left.fill",
            "hand.tap.fill", "hand.draw.fill", "magnifyingglass", "magnifyingglass.circle.fill", "plus.magnifyingglass",
            "minus.magnifyingglass", "slider.horizontal.3", "slider.vertical.3", "slider.horizontal.below.rectangle",
            "switch.2", "gearshape.fill", "gearshape.2.fill", "bell.fill", "bell.circle.fill", "bell.slash.fill",
            "bell.badge.fill", "bookmark.fill", "bookmark.circle.fill", "bookmark.square.fill", "bookmark.slash.fill",
            "star.fill", "star.circle.fill", "star.square.fill", "star.slash.fill", "heart.fill", "heart.circle.fill",
            "heart.square.fill", "flag.fill", "flag.circle.fill", "flag.checkered", "flag.2.crossed.fill", "pin.fill",
            "pin.circle.fill", "pin.slash.fill", "paperclip", "paperclip.circle.fill", "link", "link.circle.fill",
            "link.badge.plus", "checkmark.circle.fill", "checkmark.square.fill", "checkmark.rectangle.fill",
            "xmark.circle.fill", "xmark.square.fill", "plus.circle.fill", "plus.square.fill", "minus.circle.fill",
            "minus.square.fill", "ellipsis", "ellipsis.circle.fill", "ellipsis.rectangle.fill", "line.3.horizontal",
            "line.3.horizontal.decrease.circle.fill", "square.and.arrow.up", "square.and.arrow.down",
            "square.and.arrow.up.circle.fill", "square.and.arrow.up.on.square.fill", "trash.fill", "trash.circle.fill",
            "trash.square.fill", "trash.slash.fill", "viewfinder", "viewfinder.circle.fill", "target", "scope",
            "questionmark.circle.fill", "questionmark.square.fill", "questionmark.diamond.fill", "info.circle.fill",
            "info.square.fill", "exclamationmark.circle.fill", "exclamationmark.square.fill", "exclamationmark.triangle.fill",
            "exclamationmark.octagon.fill"
        ]),
        ("Text & Formatting", [
            "bold", "italic", "underline", "strikethrough", "textformat", "textformat.size", "textformat.alt",
            "textformat.superscript", "textformat.subscript", "textformat.abc", "textformat.123", "text.alignleft",
            "text.aligncenter", "text.alignright", "text.justify", "list.bullet", "list.number", "list.dash",
            "list.star", "list.bullet.circle.fill", "list.clipboard.fill", "list.bullet.clipboard.fill", "note.text",
            "note.text.badge.plus", "quote.bubble.fill", "quote.opening", "quote.closing", "character.textbox",
            "signature", "sum", "x.squareroot", "plus.forwardslash.minus", "percent", "equal.circle.fill",
            "plusminus.circle.fill", "multiply.circle.fill", "divide.circle.fill", "doc.richtext.fill", "doc.plaintext.fill"
        ]),
        ("Tech & Code", [
            "chevron.left.forwardslash.chevron.right", "curlybraces", "terminal.fill", "cpu.fill", "memorychip.fill",
            "network", "network.badge.shield.half.filled", "server.rack", "laptopcomputer", "laptopcomputer.and.iphone",
            "desktopcomputer", "display", "display.2", "pc", "macmini.fill", "macstudio.fill", "macpro.gen3.fill",
            "macbook", "ipad", "iphone", "applewatch", "keyboard.fill", "computermouse.fill", "printer.fill",
            "printer.dotmatrix.fill", "printer.filled.and.paper", "faxmachine.fill", "externaldrive.fill",
            "externaldrive.badge.plus", "externaldrive.badge.minus", "externaldrive.badge.checkmark",
            "externaldrive.badge.xmark", "externaldrive.badge.timemachine", "opticaldiscdrive.fill", "apps.iphone",
            "app.fill", "app.badge", "app.badge.fill", "macwindow", "macwindow.badge.plus", "uiwindow.split.2x1",
            "squares.below.rectangle", "wifi", "wifi.circle.fill", "cellularbars", "antenna.radiowaves.left.and.right",
            "antenna.radiowaves.left.and.right.circle.fill", "dot.radiowaves.left.and.right", "dot.radiowaves.up.forward",
            "sensor.tag.radiowaves.forward.fill", "airtag.radiowaves.forward.fill", "bonjour", "personalhotspot",
            "simcard.fill", "simcard.2.fill", "icloud.fill", "checkmark.icloud.fill", "exclamationmark.icloud.fill",
            "icloud.and.arrow.up.fill", "icloud.and.arrow.down.fill", "link.icloud.fill", "hammer.fill", "hammer.circle.fill",
            "wrench.and.screwdriver.fill", "wrench.adjustable.fill", "arrow.triangle.branch", "arrow.triangle.merge",
            "arrow.triangle.pull", "cube.fill", "puzzlepiece.fill", "puzzlepiece.extension.fill",
            "shippingbox.and.arrow.backward.fill", "command", "option", "shift.fill", "control", "escape", "return",
            "delete.left.fill", "capslock.fill", "power", "power.circle.fill", "eject.fill", "battery.100", "battery.75",
            "battery.50", "battery.25", "battery.100.bolt", "bolt.fill", "bolt.circle.fill", "bolt.square.fill",
            "bolt.slash.fill", "bolt.horizontal.circle.fill", "bolt.trianglebadge.exclamationmark.fill", "bolt.heart.fill",
            "cable.connector", "cable.connector.horizontal", "flashlight.on.fill", "flashlight.off.fill",
            "point.3.connected.trianglepath.dotted"
        ]),
        ("Media & Capture", [
            "camera.fill", "camera.circle.fill", "camera.badge.ellipsis", "camera.aperture", "camera.filters",
            "camera.macro", "camera.viewfinder", "photo.fill", "photo.circle.fill", "photo.stack.fill",
            "photo.on.rectangle.angled", "photo.artframe", "photo.badge.plus", "memories", "memories.badge.plus",
            "livephoto", "livephoto.slash", "livephoto.play", "film.fill", "film.circle.fill", "video.fill",
            "video.circle.fill", "video.badge.plus", "mic.fill", "mic.circle.fill", "mic.slash.fill", "mic.badge.plus",
            "waveform", "waveform.circle.fill", "speaker.wave.1.fill", "speaker.wave.2.fill", "speaker.wave.3.fill",
            "speaker.slash.fill", "speaker.circle.fill", "headphones", "headphones.circle.fill", "hifispeaker.fill",
            "homepod.fill", "radio.fill", "play.fill", "play.circle.fill", "play.square.fill", "play.rectangle.fill",
            "playpause.fill", "pause.fill", "pause.circle.fill", "stop.fill", "stop.circle.fill", "record.circle",
            "record.circle.fill", "backward.fill", "backward.circle.fill", "forward.fill", "forward.circle.fill",
            "forward.end.fill", "backward.end.fill", "shuffle", "repeat", "repeat.1", "infinity", "infinity.circle.fill",
            "music.note", "music.note.list", "music.quarternote.3", "music.note.house.fill", "music.mic", "guitars.fill",
            "pianokeys", "theatermasks.fill", "theatermasks.circle.fill", "theatermask.and.paintbrush.fill", "tv.fill",
            "tv.circle.fill", "tv.and.hifispeaker.fill", "appletv.fill"
        ]),
        ("Communication", [
            "envelope.fill", "envelope.circle.fill", "envelope.badge.fill", "envelope.open.fill", "paperplane.fill",
            "paperplane.circle.fill", "message.fill", "message.circle.fill", "message.badge.fill", "bubble.left.fill",
            "bubble.right.fill", "bubble.left.and.bubble.right.fill", "bubble.middle.bottom.fill", "bubble.middle.top.fill",
            "bubble.left.and.exclamationmark.bubble.right.fill", "text.bubble.fill", "phone.fill", "phone.circle.fill",
            "phone.badge.plus", "phone.down.fill", "phone.arrow.up.right", "mail.stack.fill", "megaphone.fill",
            "ellipsis.bubble.fill", "ellipsis.vertical.bubble.fill", "quote.bubble.fill"
        ]),
        ("Office & School", [
            "doc.plaintext.fill", "doc.text.fill", "doc.fill", "doc.circle.fill", "doc.append.fill", "doc.on.doc.fill",
            "doc.on.clipboard.fill", "doc.badge.plus", "doc.badge.ellipsis", "doc.zipper", "doc.viewfinder.fill",
            "books.vertical.fill", "book.fill", "book.closed.fill", "book.circle.fill", "magazine.fill", "newspaper.fill",
            "newspaper.circle.fill", "folder.fill", "folder.circle.fill", "folder.badge.plus", "folder.badge.minus",
            "folder.badge.person.crop", "folder.badge.questionmark", "folder.badge.gearshape", "archivebox.fill",
            "tray.fill", "tray.circle.fill", "tray.full.fill", "tray.2.fill", "tray.and.arrow.down.fill",
            "tray.and.arrow.up.fill", "tag.fill", "tag.circle.fill", "shippingbox.fill", "shippingbox.circle.fill",
            "scroll.fill", "graduationcap.fill", "graduationcap.circle.fill", "backpack.fill", "briefcase.fill",
            "briefcase.circle.fill", "lanyardcard.fill", "person.text.rectangle.fill", "menucard.fill"
        ]),
        ("Commerce & Finance", [
            "creditcard.fill", "creditcard.circle.fill", "creditcard.trianglebadge.exclamationmark", "giftcard.fill",
            "wallet.pass.fill", "banknote.fill", "dollarsign.circle.fill", "dollarsign.square.fill", "eurosign.circle.fill",
            "sterlingsign.circle.fill", "yensign.circle.fill", "bitcoinsign.circle.fill", "indianrupeesign.circle.fill",
            "australiandollarsign.circle.fill", "chineseyuanrenminbisign.circle.fill", "rublesign.circle.fill",
            "wonsign.circle.fill", "turkishlirasign.circle.fill", "francsign.circle.fill", "centsign.circle.fill",
            "chart.xyaxis.line", "chart.bar.xaxis", "chart.pie.fill", "chart.line.uptrend.xyaxis",
            "chart.line.uptrend.xyaxis.circle.fill", "chart.bar.doc.horizontal.fill", "bag.fill", "bag.circle.fill",
            "bag.badge.plus", "bag.badge.minus", "cart.fill", "cart.circle.fill", "cart.badge.plus", "cart.badge.minus",
            "barcode", "barcode.viewfinder", "qrcode", "qrcode.viewfinder", "building.columns.fill"
        ]),
        ("Nature & Weather", [
            "sun.max.fill", "sun.min.fill", "sun.max.circle.fill", "sunrise.fill", "sunset.fill", "sun.and.horizon.fill",
            "sun.dust.fill", "sun.haze.fill", "moon.fill", "moon.circle.fill", "moon.stars.fill", "moon.zzz.fill",
            "moonphase.new.moon", "moonphase.full.moon", "cloud.fill", "cloud.circle.fill", "cloud.sun.fill",
            "cloud.moon.fill", "cloud.rain.fill", "cloud.drizzle.fill", "cloud.heavyrain.fill", "cloud.hail.fill",
            "cloud.sleet.fill", "cloud.snow.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill", "cloud.fog.fill",
            "cloud.moon.bolt.fill", "wind", "wind.snow", "tornado", "tropicalstorm", "hurricane", "snowflake",
            "snowflake.circle.fill", "rainbow", "sparkle", "flame.fill", "flame.circle.fill", "drop.fill",
            "drop.circle.fill", "drop.triangle.fill", "humidity.fill", "thermometer.sun.fill", "thermometer.snowflake",
            "thermometer.medium", "thermometer.high", "thermometer.low", "leaf.fill", "leaf.circle.fill",
            "leaf.arrow.triangle.circlepath", "arrow.3.trianglepath", "tree.fill", "tree.circle.fill",
            "globe.americas.fill", "globe.europe.africa.fill", "globe.asia.australia.fill", "globe.central.south.asia.fill",
            "globe.desk.fill", "mountain.2.fill", "mountain.2.circle.fill", "water.waves"
        ]),
        ("Animals", [
            "cat.fill", "dog.fill", "bird.fill", "hare.fill", "tortoise.fill", "ant.fill", "ladybug.fill", "fish.fill",
            "fish.circle.fill", "pawprint.fill", "pawprint.circle.fill", "teddybear.fill"
        ]),
        ("Food & Drink", [
            "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "mug.fill", "takeoutbag.and.cup.and.straw.fill",
            "popcorn.fill", "waterbottle.fill", "frying.pan.fill", "carrot.fill"
        ]),
        ("Home & Buildings", [
            "house.fill", "house.circle.fill", "house.lodge.fill", "building.fill", "building.2.fill",
            "building.columns.fill", "tent.fill", "bed.double.fill", "bed.double.circle.fill", "fan.fill", "washer.fill",
            "lightbulb.fill", "lightbulb.circle.fill", "lightbulb.2.fill"
        ]),
        ("Travel & Transport", [
            "car.fill", "car.circle.fill", "car.rear.fill", "bolt.car.fill", "bus.fill", "bus.doubledecker.fill",
            "tram.fill", "tram.fill.tunnel", "airplane", "airplane.circle.fill", "airplane.arrival", "airplane.departure",
            "bicycle", "bicycle.circle.fill", "scooter", "fuelpump.fill", "fuelpump.circle.fill", "parkingsign",
            "parkingsign.circle.fill", "box.truck.fill", "box.truck.badge.clock.fill", "road.lanes",
            "point.topleft.down.curvedto.point.bottomright.up", "signpost.right.fill", "signpost.left.fill",
            "signpost.right.and.left.fill", "map.fill", "map.circle.fill", "mappin", "mappin.circle.fill",
            "mappin.and.ellipse", "location.fill", "location.circle.fill", "location.north.circle.fill", "safari.fill",
            "binoculars.fill", "suitcase.rolling.fill", "suitcase.cart.fill", "ticket.fill", "umbrella.fill"
        ]),
        ("Sports & Fitness", [
            "figure.walk", "figure.run", "figure.hiking", "figure.dance", "figure.mind.and.body", "dumbbell.fill",
            "sportscourt.fill", "sportscourt.circle.fill", "soccerball", "soccerball.inverse", "football.fill",
            "basketball.fill", "baseball.fill", "tennisball.fill", "volleyball.fill", "cricket.ball.fill",
            "hockey.puck.fill", "trophy.fill", "trophy.circle.fill", "medal.fill", "flag.checkered"
        ]),
        ("Games & Fun", [
            "gamecontroller.fill", "dice.fill", "die.face.1.fill", "die.face.2.fill", "die.face.3.fill", "die.face.4.fill",
            "die.face.5.fill", "die.face.6.fill", "suit.spade.fill", "suit.heart.fill", "suit.diamond.fill",
            "suit.club.fill", "balloon.fill", "balloon.2.fill", "party.popper.fill", "fireworks", "laurel.leading",
            "laurel.trailing", "crown.fill", "gift.fill", "gift.circle.fill"
        ]),
        ("People & Gestures", [
            "person.fill", "person.circle.fill", "person.crop.circle.fill", "person.crop.square.fill", "person.2.fill",
            "person.2.circle.fill", "person.3.fill", "person.badge.plus", "person.badge.minus", "person.badge.key.fill",
            "person.crop.circle.badge.plus", "person.crop.circle.badge.minus", "person.crop.circle.badge.checkmark",
            "person.crop.circle.badge.xmark", "person.crop.circle.badge.exclamationmark",
            "person.crop.circle.badge.questionmark", "figure.2.and.child.holdinghands", "figure.stand", "figure.wave",
            "face.smiling", "face.smiling.inverse", "eyes", "eyes.inverse", "accessibility", "hand.wave.fill",
            "hand.thumbsup.fill", "hand.thumbsdown.fill", "hand.point.up.fill", "hand.point.down.fill",
            "hand.point.left.fill", "hand.point.right.fill", "hand.raised.fill", "hand.raised.circle.fill",
            "hand.raised.fingers.spread.fill", "hands.sparkles.fill"
        ]),
        ("Health & Science", [
            "heart.text.square.fill", "stethoscope", "stethoscope.circle.fill", "cross.fill", "cross.circle.fill",
            "cross.case.fill", "staroflife.fill", "staroflife.circle.fill", "pills.fill", "pills.circle.fill",
            "bandage.fill", "waveform.path.ecg", "waveform.path.ecg.rectangle.fill", "brain.head.profile", "atom",
            "testtube.2", "scalemass.fill", "ear.fill", "eye.fill", "eye.circle.fill", "eye.slash.fill"
        ]),
        ("Time & Calendar", [
            "clock.fill", "clock.circle.fill", "clock.arrow.circlepath", "deskclock.fill", "alarm.fill",
            "alarm.waves.left.and.right.fill", "stopwatch.fill", "timer", "hourglass", "hourglass.circle.fill",
            "calendar", "calendar.circle.fill", "calendar.badge.plus", "calendar.badge.clock",
            "calendar.badge.exclamationmark"
        ]),
        ("Security & Badges", [
            "lock.fill", "lock.open.fill", "lock.shield.fill", "key.fill", "key.horizontal.fill", "shield.fill",
            "shield.lefthalf.filled", "shield.righthalf.filled", "shield.checkered", "checkmark.shield.fill",
            "xmark.shield.fill", "exclamationmark.shield.fill", "checkmark.seal.fill", "faceid", "touchid",
            "person.badge.shield.checkmark.fill", "hand.raised.fill"
        ]),
        ("Arrows & Direction", [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right", "arrow.up.circle.fill", "arrow.down.circle.fill",
            "arrow.left.circle.fill", "arrow.right.circle.fill", "arrow.up.square.fill", "arrow.down.square.fill",
            "arrow.left.square.fill", "arrow.right.square.fill", "arrow.up.right.circle.fill",
            "arrow.down.right.circle.fill", "arrow.up.left.circle.fill", "arrow.down.left.circle.fill",
            "arrow.up.and.down.circle.fill", "arrow.left.and.right.circle.fill", "arrow.clockwise",
            "arrow.clockwise.circle.fill", "arrow.counterclockwise", "arrow.counterclockwise.circle.fill",
            "arrow.2.circlepath", "arrow.2.circlepath.circle.fill", "arrow.triangle.2.circlepath", "arrow.uturn.left",
            "arrow.uturn.right", "arrow.uturn.left.circle.fill", "arrow.up.doc.fill", "arrow.down.doc.fill",
            "arrow.up.to.line", "arrow.down.to.line", "arrowshape.up.fill", "arrowshape.down.fill",
            "arrowshape.left.fill", "arrowshape.right.fill", "arrowshape.turn.up.left.fill",
            "arrowshape.turn.up.right.fill", "chevron.up", "chevron.down", "chevron.left", "chevron.right",
            "chevron.up.circle.fill", "chevron.down.circle.fill", "chevron.left.circle.fill", "chevron.right.circle.fill",
            "arrowtriangle.up.fill", "arrowtriangle.down.fill", "arrowtriangle.left.fill", "arrowtriangle.right.fill"
        ]),
        ("Shapes & Symbols", [
            "circle", "circle.fill", "square", "square.fill", "rectangle", "rectangle.fill", "triangle", "triangle.fill",
            "diamond", "diamond.fill", "hexagon", "hexagon.fill", "octagon", "octagon.fill", "pentagon", "pentagon.fill",
            "oval", "oval.fill", "capsule", "capsule.fill", "app.fill", "plus.app.fill"
        ]),
        ("Numbers", [
            "0.circle.fill", "1.circle.fill", "2.circle.fill", "3.circle.fill", "4.circle.fill", "5.circle.fill",
            "6.circle.fill", "7.circle.fill", "8.circle.fill", "9.circle.fill", "0.square.fill", "1.square.fill",
            "2.square.fill", "3.square.fill", "4.square.fill", "5.square.fill", "6.square.fill", "7.square.fill",
            "8.square.fill", "9.square.fill"
        ])
    ]

    /// Deduplicated flat list — some symbols legitimately appear in more than one
    /// category, and `ForEach(id: \.self)` needs unique IDs.
    private var uniqueSymbols: [String] {
        var seen = Set<String>()
        return categories.flatMap { $0.symbols }.filter { seen.insert($0).inserted }
    }

    private var allSymbols: [String] {
        if selectedCategory == "All" || selectedCategory == "Multicolor" {
            if searchText.isEmpty { return uniqueSymbols }
            return uniqueSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        } else {
            guard let cat = categories.first(where: { $0.name == selectedCategory }) else { return [] }
            if searchText.isEmpty { return cat.symbols }
            return cat.symbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYMBOLS & ICONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primary)
                .tracking(0.5)
                .padding(.horizontal, 14)
                .padding(.top, 12)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search \(uniqueSymbols.count) symbols...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
            }
            .padding(6)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 14)

            // Category Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    filterChip("All")
                    filterChip("Multicolor")
                    ForEach(categories, id: \.name) { cat in
                        filterChip(cat.name)
                    }
                }
                .padding(.horizontal, 14)
            }

            // Insert color swatches — standard icons drop onto the canvas in
            // the chosen color, and the grid previews it live.
            HStack(spacing: 6) {
                Text("COLOR")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.3)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(swatchColors, id: \.hex) { swatch in
                            let isSel = insertColor == CodableColor(hex: swatch.hex)
                            Button(action: { insertColor = CodableColor(hex: swatch.hex) }) {
                                Circle()
                                    .fill(Color(hex: swatch.hex))
                                    .frame(width: 15, height: 15)
                                    .overlay(Circle().stroke(Color.primary.opacity(0.18), lineWidth: 0.5))
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#C2410C"), lineWidth: isSel ? 2 : 0)
                                            .frame(width: 21, height: 21)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(swatch.name)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 14)

            // Icons Grid
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Multicolor Preset Showcase
                    if selectedCategory == "All" || selectedCategory == "Multicolor" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MULTICOLOR & DUOTONE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#C2410C"))
                                .tracking(0.3)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(multicolorPresets) { preset in
                                    Button(action: {
                                        viewModel.addMulticolorIcon(
                                            preset.symbol,
                                            primary: preset.primary,
                                            secondary: preset.secondary,
                                            tertiary: preset.tertiary
                                        )
                                    }) {
                                        VStack(spacing: 3) {
                                            Image(systemName: preset.symbol)
                                                .font(.system(size: 18))
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(preset.primary.color, preset.secondary.color, preset.tertiary.color)
                                                .frame(width: 44, height: 38)

                                            Text(preset.name)
                                                .font(.system(size: 8, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                        }
                                        .padding(.vertical, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.secondary.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()
                                    .help("\(preset.name) (Multicolor)")
                                }
                            }
                        }
                    }

                    if selectedCategory != "Multicolor" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(selectedCategory == "All" ? "STANDARD ICONS" : selectedCategory.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#C2410C"))
                                .tracking(0.3)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(allSymbols, id: \.self) { symbol in
                                    Button(action: {
                                        viewModel.addIcon(symbol, color: insertColor)
                                    }) {
                                        Image(systemName: symbol)
                                            .font(.system(size: 17))
                                            // Near-black ink would vanish on a dark panel;
                                            // preview it as .primary (insert still uses the ink).
                                            .foregroundColor(insertColor.relativeLuminance < 0.03 ? .primary : insertColor.color)
                                            .frame(width: 44, height: 44)
                                            .background(Color.secondary.opacity(0.06))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                .hoverHighlight()
                                    .help(symbol)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private func filterChip(_ name: String) -> some View {
        let isSel = (selectedCategory == name)
        return Button(action: { selectedCategory = name }) {
            Text(name)
                .font(.system(size: 10, weight: isSel ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(isSel ? Color(hex: "#C2410C") : Color.secondary.opacity(0.08))
                .foregroundColor(isSel ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
                .hoverHighlight()
    }
}
