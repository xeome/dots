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
// The E-core half: on a hybrid Intel CPU, power-saver pins user.slice (your
// session and every app in it) to the E-cores with a runtime cpuset. It
// follows the profile rather than the click, so a profile set from anywhere
// else pins too. 49-ecore-pin.rules lets a wheel user do it unprompted.
PopupWindow {
    id: root

    required property Item anchorItem

    // grabFocus dismisses on any outside click — including the click on the
    // battery that meant "close". Battery reads this so that click doesn't
    // immediately reopen what it just closed.
    property double closedAt: 0

    // The E-core list, e.g. "4-11". Empty on a CPU without E-cores, which is
    // what turns the pin into a no-op on every other machine.
    property string ecores: ""

    readonly property var profiles: [
        {
            profile: PowerProfile.Performance,
            name: "Performance",
            detail: "max EPP"
        },
        {
            profile: PowerProfile.Balanced,
            name: "Balanced",
            detail: "balanced EPP"
        },
        {
            profile: PowerProfile.PowerSaver,
            name: "Power saver",
            detail: root.ecores !== "" ? "no turbo · E-cores only" : "no turbo"
        }
    ]

    // Shared with Battery, which shows the same glyph in the bar.
    function glyph(profile: int): string {
        return profile === PowerProfile.Performance ? "󰓅" : profile === PowerProfile.PowerSaver ? "󰾆" : "󰾅";
    }

    function apply(p: var): void {
        PowerProfiles.profile = p.profile;
        root.visible = false;
    }

    // --runtime, so a reboot always comes back unpinned. An empty AllowedCPUs
    // resets to every CPU.
    function pin(): void {
        if (root.ecores === "")
            return;
        const cpus = PowerProfiles.profile === PowerProfile.PowerSaver ? root.ecores : "";
        pinner.command = ["systemctl", "--no-ask-password", "set-property", "--runtime", "user.slice", `AllowedCPUs=${cpus}`];
        pinner.running = true;
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

    onVisibleChanged: if (!visible)
        closedAt = Date.now()

    Connections {
        target: PowerProfiles

        function onProfileChanged(): void {
            root.pin();
        }
    }

    Process {
        // The perf PMU for the E-cores only exists on hybrid Intel. Read once:
        // the list cannot change while running. Pinning on load also
        // reconciles the cpuset after a quickshell restart.
        running: true
        command: ["cat", "/sys/devices/cpu_atom/cpus"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.ecores = text.trim();
                root.pin();
            }
        }
    }

    Process {
        id: pinner
    }

    Surface {
        anchors.fill: parent

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
                    radius: Theme.radius
                    color: row.current ? Theme.sel : rowMa.containsMouse ? Theme.hover : "transparent"
                    border.width: 1
                    border.color: Theme.line

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
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: root.glyph(row.modelData.profile)
                            font.pixelSize: Theme.size + 5
                            color: row.current ? Theme.bright : Theme.text
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BarText {
                                text: row.modelData.name
                                color: row.current ? Theme.bright : Theme.text
                            }

                            BarText {
                                text: row.modelData.detail
                                font.pixelSize: Theme.size - 4
                                weight: 450
                                color: Theme.dim
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
                visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None || PowerProfiles.holds.length > 0

                BarText {
                    Layout.fillWidth: true
                    visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                    // Firmware telling us it is capping the CPU regardless of
                    // what profile is selected.
                    text: PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "󰀦  capped: high temperature" : "󰀦  capped: lap detected"
                    font.pixelSize: Theme.size - 3
                    color: Theme.dim
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
                        color: Theme.dim
                    }
                }
            }
        }
    }
}
