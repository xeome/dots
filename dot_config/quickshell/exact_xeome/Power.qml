import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Battery's menu: power profiles, brightness, the CPU limit, and whatever is
// capping or holding the profile. Not a Menu: its width follows its rows.
//
// tlp-pd serves org.freedesktop.UPower.PowerProfiles with polkit allow_active,
// so picking a profile is a property write with no prompt. Each profile is a
// TLP parameter set (performance *_ON_AC, balanced *_ON_BAT, power-saver
// *_ON_SAV) in /etc/tlp.d/50-dots-profiles.conf, which differs per machine,
// so the row subtitles stay vague.
//
// On a hybrid Intel CPU, power-saver also pins user.slice to the E-cores. The
// pin follows the profile, not the click, so a profile set elsewhere pins too.
// 49-dots-ecore-pin.rules lets a wheel user do it without a prompt.
PopupWindow {
    id: root

    required property Item anchorItem

    // Read by Battery; see Menu.closedAt.
    property double closedAt: 0

    // The E-core list, e.g. "4-11". Empty on a CPU without E-cores, which
    // makes the pin a no-op.
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

    // --runtime, so a reboot comes back unpinned. An empty AllowedCPUs resets
    // to every CPU.
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
        // The E-core PMU exists only on hybrid Intel, and its CPU list cannot
        // change while running. Pinning on load also restores the cpuset after
        // a quickshell restart.
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
                                Layout.fillWidth: true
                                text: row.modelData.name
                                color: row.current ? Theme.bright : Theme.text
                            }

                            BarText {
                                Layout.fillWidth: true
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
                visible: perf.visible
            }

            ColumnLayout {
                id: perf

                Layout.fillWidth: true
                spacing: 2
                visible: CpuPerf.available

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    BarText {
                        Layout.preferredWidth: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: "󰈐"
                        font.pixelSize: Theme.size + 5
                    }

                    BarText {
                        Layout.fillWidth: true
                        text: "CPU limit"
                    }

                    BarText {
                        text: `${CpuPerf.pct}%`
                    }
                }

                Track {
                    value: CpuPerf.fraction
                    onMoved: fraction => CpuPerf.set(fraction)
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
                    // Firmware caps the CPU whatever the profile.
                    text: PowerProfiles.degradationReason === PerformanceDegradationReason.HighTemperature ? "󰀦  capped: high temperature" : "󰀦  capped: lap detected"
                    font.pixelSize: Theme.size - 3
                    color: Theme.dim
                }

                Repeater {
                    // `tlpctl launch` holds a profile while an app runs,
                    // overriding the row highlighted above.
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
