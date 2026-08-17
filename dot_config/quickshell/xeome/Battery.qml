import Quickshell.Services.UPower

// 11-step icon ramp, filled with the warn tone below the 30% line — the one
// module on the bar that means "do something about this", so it gets the only
// red in the shell rather than sharing a fill with the toggles.
//
// Also the power-profile button — clicking it opens Power. On a machine
// without a laptop battery (xeome-desktop) there is no charge to report, so
// the module drops the ramp and shows the profile glyph on its own rather than
// hiding itself the way it used to.
BarModule {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat?.isLaptopBattery ?? false
    readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
    // waybar only showed the bolt for `format-charging`, i.e. actively
    // charging — a full battery on AC gets the plain icon. `plugged` is the
    // wider test, used to suppress the low-battery warning.
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || bat?.state === UPowerDeviceState.FullyCharged || bat?.state === UPowerDeviceState.PendingCharge

    function hm(s: real): string {
        return s > 0 ? `${Math.floor(s / 3600)}h ${Math.floor(s % 3600 / 60)}m` : "unknown";
    }

    tone: hasBattery && !plugged && pct <= 30 ? "warn" : ""
    // healthSupported is false on this hardware, so the health line is
    // dropped rather than reporting waybar's misleading "Capacity: 0%".
    // Suppressed while the menu is open: both anchor below this module, so
    // otherwise they stack on top of each other.
    tooltipText: menu.visible ? "" : [hasBattery ? `Time: ${hm(plugged ? bat?.timeToFull ?? 0 : bat?.timeToEmpty ?? 0)} left` : "", hasBattery && bat?.healthSupported ? `Capacity: ${Math.round(bat.healthPercentage)}%` : "", hasBattery ? `${Math.abs(bat?.changeRate ?? 0).toFixed(1)} watts` : "", `Profile: ${PowerProfile.toString(PowerProfiles.profile)}`].filter(l => l !== "").join("\n")

    onClicked: if (!menu.visible && Date.now() - menu.closedAt > 200)
        menu.visible = true

    BarText {
        readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        // The profile glyph rides along only when the profile isn't the
        // default — the exceptional states are worth seeing without hovering,
        // Balanced isn't.
        readonly property string profileGlyph: PowerProfiles.profile === PowerProfile.Balanced ? "" : `${menu.glyph(PowerProfiles.profile)} `

        text: root.hasBattery ? `${profileGlyph}${icons[Math.min(10, Math.floor(root.pct / 10))]}${root.charging ? "󱐋" : ""} ${root.pct}%` : menu.glyph(PowerProfiles.profile)
        color: root.fg
        // md-speedometer* is drawn shorter than neighboring glyphs — only
        // matters standalone (no battery), since the ramp icon carries it otherwise.
        font.pixelSize: root.hasBattery ? Theme.size : Theme.size + 2
        // Both spaces here sit between glyphs, or between a glyph and the
        // percentage — none of them are between words.
        font.wordSpacing: Theme.glyphGap
    }

    // A PopupWindow isn't an Item, so the RowLayout that BarModule's default
    // property points at stores it without trying to lay it out.
    Power {
        id: menu
        anchorItem: root
    }
}
