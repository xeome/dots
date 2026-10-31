import Quickshell.Services.UPower

// Battery ramp, filled with the warn tone at 30% and below while unplugged.
// Also the power-profile button: a click opens Power. Without a laptop battery
// it shows the profile glyph alone.
BarModule {
    id: root

    readonly property var bat: UPower.displayDevice
    readonly property bool hasBattery: bat?.isLaptopBattery ?? false
    readonly property int pct: Math.round((bat?.percentage ?? 0) * 100)
    // The bolt shows only while charging; `plugged` is the wider test that
    // silences the low-battery warning.
    readonly property bool charging: bat?.state === UPowerDeviceState.Charging
    readonly property bool plugged: charging || bat?.state === UPowerDeviceState.FullyCharged || bat?.state === UPowerDeviceState.PendingCharge

    function hm(s: real): string {
        return s > 0 ? `${Math.floor(s / 3600)}h ${Math.floor(s % 3600 / 60)}m` : "unknown";
    }

    tone: hasBattery && !plugged && pct <= 30 ? "warn" : ""
    tooltipText: menu.visible ? "" : [hasBattery ? `Time: ${hm(plugged ? bat?.timeToFull ?? 0 : bat?.timeToEmpty ?? 0)} left` : "", hasBattery && bat?.healthSupported ? `Capacity: ${Math.round(bat.healthPercentage)}%` : "", hasBattery ? `${Math.abs(bat?.changeRate ?? 0).toFixed(1)} watts` : "", `Profile: ${PowerProfile.toString(PowerProfiles.profile)}`].filter(l => l !== "").join("\n")

    onClicked: root.openMenu(menu)

    BarText {
        readonly property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        readonly property string profileGlyph: PowerProfiles.profile === PowerProfile.Balanced ? "" : `${menu.glyph(PowerProfiles.profile)} `

        text: root.hasBattery ? `${profileGlyph}${icons[Math.min(10, Math.floor(root.pct / 10))]}${root.charging ? "󱐋" : ""} ${root.pct}%` : menu.glyph(PowerProfiles.profile)
        color: root.fg
        // md-speedometer* is drawn shorter than its neighbours, which shows
        // only when it stands alone.
        font.pixelSize: root.hasBattery ? Theme.size : Theme.size + 2
        // Every space here separates glyphs or a glyph from the percentage.
        font.wordSpacing: Theme.glyphGap
    }

    Power {
        id: menu
        anchorItem: root
    }
}
