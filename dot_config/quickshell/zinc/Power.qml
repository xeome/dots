import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// The battery module's power-profile menu, hung off it the way Calendar hangs
// off Clock.
//
// The CPU half is just a property assignment: tlp-pd answers the standard
// org.freedesktop.UPower.PowerProfiles interface that quickshell already
// binds, with polkit allow_active, so there is no script and no prompt. Each
// profile is the matching TLP parameter set — performance is *_ON_AC,
// balanced *_ON_BAT, power-saver *_ON_SAV — which is why the row subtitles
// stay vague: the specifics live in /etc/tlp.conf and differ per machine.
//
// The scheduler half shells out to scxctl, which 49-scx-loader.rules lets a
// wheel user do unprompted.
PopupWindow {
    id: root

    required property Item anchorItem

    // grabFocus dismisses on any outside click — including the click on the
    // battery that meant "close". Battery reads this so that click doesn't
    // immediately reopen what it just closed.
    property double closedAt: 0

    // Parsed out of `scxctl get`. Both empty when scx_loader isn't answering,
    // which is what hides the scheduler line on a machine without it.
    property string sched: ""
    property string modeLabel: ""

    readonly property var profiles: [
        {
            profile: PowerProfile.Performance,
            mode: "lowlatency",
            name: "Performance",
            detail: "max EPP · esports scheduler"
        },
        {
            profile: PowerProfile.Balanced,
            mode: "auto",
            name: "Balanced",
            detail: "stock tuning · default scheduler"
        },
        {
            profile: PowerProfile.PowerSaver,
            mode: "powersave",
            name: "Power saver",
            detail: "no turbo · battery scheduler"
        }
    ]

    // Shared with Battery, which shows the same glyph in the bar.
    function glyph(profile: int): string {
        return profile === PowerProfile.Performance ? "󰓅" : profile === PowerProfile.PowerSaver ? "󰾆" : "󰾅";
    }

    function apply(p: var): void {
        PowerProfiles.profile = p.profile;

        // A mode change stops and restarts the BPF scheduler, and the kernel
        // falls back to EEVDF for the gap — so it only happens when the mode
        // actually differs. Re-picking the profile you're already on is free.
        if (root.modeLabel.toLowerCase() !== p.mode) {
            switcher.command = ["scxctl", "switch", "--mode", p.mode];
            switcher.running = true;
        }

        root.visible = false;
    }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: body.implicitWidth + 24
    implicitHeight: body.implicitHeight + 24
    color: "transparent"
    visible: false
    grabFocus: true

    onVisibleChanged: if (visible)
        reader.running = true;
    else
        closedAt = Date.now();

    Process {
        id: reader
        command: ["scxctl", "get"]

        stdout: StdioCollector {
            // "running Cake in LowLatency mode"
            onStreamFinished: {
                const m = text.match(/running (\w+) in (\w+) mode/);
                root.sched = m ? m[1] : "";
                root.modeLabel = m ? m[2] : "";
            }
        }
    }

    Process {
        id: switcher
        // Read the state back rather than assuming the switch took: if the
        // scheduler fails to start, scx_loader leaves you on EEVDF quietly and
        // this line is the only place that shows it.
        onExited: reader.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: body
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: root.profiles

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool current: PowerProfiles.profile === modelData.profile

                    Layout.fillWidth: true
                    implicitWidth: 272
                    implicitHeight: 46
                    color: row.current ? Theme.active : rowMa.containsMouse ? Theme.surfaceHover : "transparent"
                    border.width: 1
                    border.color: row.current ? Theme.active : rowMa.containsMouse ? Theme.borderHover : Theme.border

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.anim
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 10

                        BarText {
                            text: root.glyph(row.modelData.profile)
                            font.pixelSize: Theme.size + 5
                            color: row.current ? Theme.fgInverted : Theme.fg
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BarText {
                                text: row.modelData.name
                                color: row.current ? Theme.fgInverted : Theme.fg
                            }

                            BarText {
                                text: row.modelData.detail
                                font.pixelSize: Theme.size - 4
                                font.weight: 450
                                color: row.current ? Theme.fgInverted : Theme.fgMuted
                            }
                        }
                    }

                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.apply(row.modelData)
                    }
                }
            }

            Rule {
                Layout.topMargin: 4
                visible: bri.visible
            }

            ColumnLayout {
                id: bri

                Layout.fillWidth: true
                spacing: 2
                visible: Backlight.available

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    BarText {
                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: Backlight.value > 0.66 ? "󰃠" : Backlight.value > 0.33 ? "󰃟" : "󰃞"
                        font.pixelSize: Theme.size + 5
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: "Brightness"
                    }

                    BarText {
                        text: `${Math.round(Backlight.value * 100)}%`
                        font.weight: 500
                    }
                }

                Track {
                    value: Backlight.value
                    onMoved: fraction => Backlight.set(fraction)
                }
            }

            Rule {
                Layout.topMargin: 4
                visible: footer.visible
            }

            ColumnLayout {
                id: footer

                Layout.fillWidth: true
                spacing: 1
                visible: root.sched !== "" || PowerProfiles.degradationReason !== PerformanceDegradationReason.None || PowerProfiles.holds.length > 0

                BarText {
                    Layout.fillWidth: true
                    visible: root.sched !== ""
                    text: `󰬔  ${root.sched} · ${root.modeLabel}`
                    font.pixelSize: Theme.size - 3
                    font.weight: 500
                    color: Theme.fgDim
                }

                BarText {
                    Layout.fillWidth: true
                    visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                    // Firmware telling us it is capping the CPU regardless of
                    // what profile is selected.
                    text: PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "󰀦  capped: high temperature" : "󰀦  capped: lap detected"
                    font.pixelSize: Theme.size - 3
                    font.weight: 500
                    color: Theme.fgDim
                }

                Repeater {
                    // `tlpctl launch` sets these: an app asking for a profile
                    // for as long as it runs. Worth showing, since it overrides
                    // the row highlighted above.
                    model: PowerProfiles.holds

                    delegate: BarText {
                        required property var modelData

                        Layout.fillWidth: true
                        text: `󰅢  ${modelData.applicationId} holds ${PowerProfile.toString(modelData.profile)}`
                        font.pixelSize: Theme.size - 3
                        font.weight: 500
                        color: Theme.fgDim
                    }
                }
            }
        }
    }
}
