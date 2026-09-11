import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

ClickAwayPopup {
    id: root

    required property var oneorganizeModel
    required property var panelWindow

    readonly property int cardWidth: 410
    readonly property int cardHeight: 450

    visible: panelWindow !== null && panelWindow.screen !== null && oneorganizeModel.visible
    targetWindow: panelWindow
    popupWidth: cardWidth
    popupHeight: cardHeight
    popupX: panelWindow
        ? Math.max(Theme.rowSpacing, panelWindow.width - cardWidth - Theme.rowSpacing)
        : Theme.rowSpacing
    popupY: Theme.panelHeight
    onDismissed: oneorganizeModel.close()

    onVisibleChanged: if (!visible) root.oneorganizeModel.close()

    ShellSurface {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.oneorganizeModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingLg

            // Header Hero
            PanelHero {
                Layout.fillWidth: true
                iconText: "󰥔"
                iconColor: root.oneorganizeModel.clockedIn ? Theme.success : Theme.warning
                title: "OneOrganize HRM"
                subtitle: root.oneorganizeModel.employee

                ShellButton {
                    label: "Refresh"
                    compact: true
                    enabled: !root.oneorganizeModel.busy
                    onActivated: root.oneorganizeModel.refresh()
                }

                ShellButton {
                    label: "Portal"
                    compact: true
                    primary: true
                    onActivated: root.oneorganizeModel.openPortal()
                }
            }

            // Attendance Status & Live Worked Timer Banner
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 68
                radius: Theme.smallRadius
                color: Theme.controlNormalFill
                border.color: root.oneorganizeModel.clockedIn ? Theme.success : Theme.controlNormalBorder
                border.width: Theme.controlBorderWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLg
                    spacing: Theme.spacingLg

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXxs

                        RowLayout {
                            spacing: Theme.spacingSm
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: root.oneorganizeModel.clockedIn
                                    ? (root.oneorganizeModel.clockedOut ? Theme.menuMutedText : Theme.success)
                                    : Theme.warning
                            }
                            UiText {
                                text: root.oneorganizeModel.statusText
                                color: Theme.textStrong
                                font.bold: true
                                font.pixelSize: Theme.fontBodySize
                            }
                        }

                        UiText {
                            text: root.oneorganizeModel.clockedIn
                                ? ("Started: " + (root.oneorganizeModel.clockInTime || root.oneorganizeModel.clockInRaw))
                                : "Not clocked in today"
                            color: Theme.menuMutedText
                            font.pixelSize: Theme.fontCaptionSize
                        }
                    }

                    // Large Digital Timer Box
                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 44
                        radius: Theme.controlRadius
                        color: Theme.bg
                        border.color: Theme.border
                        border.width: 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 1

                            UiText {
                                Layout.alignment: Qt.AlignHCenter
                                text: "WORKED TODAY"
                                color: Theme.menuMutedText
                                font.pixelSize: 8
                                font.bold: true
                                font.letterSpacing: 1.0
                            }

                            UiText {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.oneorganizeModel.workedDuration
                                color: root.oneorganizeModel.clockedIn ? Theme.textStrong : Theme.menuMutedText
                                font.bold: true
                                font.pixelSize: Theme.fontSubtitleSize
                            }
                        }
                    }
                }
            }

            // Status message if any
            UiText {
                Layout.fillWidth: true
                visible: root.oneorganizeModel.message.length > 0
                text: root.oneorganizeModel.message
                color: Theme.accentSecondary
                font.pixelSize: Theme.fontCaptionSize
                elide: Text.ElideRight
            }

            PanelSeparator {}

            // Clock In Action Section
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLg

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    UiText {
                        text: "Clock In"
                        color: Theme.textStrong
                        font.bold: true
                    }
                    UiText {
                        text: root.oneorganizeModel.clockedIn ? "Active for today" : "Record arrival time"
                        color: Theme.menuMutedText
                        font.pixelSize: Theme.fontCaptionSize
                    }
                }

                ShellButton {
                    label: root.oneorganizeModel.clockedIn ? "Clocked In ✓" : "Clock In Now"
                    enabled: !root.oneorganizeModel.clockedIn && !root.oneorganizeModel.busy
                    primary: !root.oneorganizeModel.clockedIn
                    onActivated: root.oneorganizeModel.clockIn()
                }
            }

            PanelSeparator {}

            // Clock Out Action Section
            SectionLabel { label: "Clock Out (Daily Task)" }

            // Project tag
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSm

                UiText {
                    text: "Project:"
                    color: Theme.menuMutedText
                    font.pixelSize: Theme.fontCaptionSize
                }

                Rectangle {
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: projectTagText.implicitWidth + 16
                    radius: 4
                    color: Theme.controlSelectedFill
                    border.color: Theme.accent
                    border.width: 1

                    UiText {
                        id: projectTagText
                        anchors.centerIn: parent
                        text: root.oneorganizeModel.projectName + " (#" + root.oneorganizeModel.projectId + ")"
                        color: Theme.accentSecondary
                        font.bold: true
                        font.pixelSize: Theme.fontCaptionSize
                    }
                }
            }

            // Task textarea
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.controlRadius
                color: Theme.controlNormalFill
                border.color: taskInput.activeFocus ? Theme.controlFocusBorder : Theme.controlNormalBorder
                border.width: Theme.controlBorderWidth

                Flickable {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMd
                    clip: true
                    contentWidth: width
                    contentHeight: taskInput.implicitHeight

                    TextEdit {
                        id: taskInput
                        width: parent.width
                        text: root.oneorganizeModel.taskText
                        color: Theme.textStrong
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.accentText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBodySmallSize
                        wrapMode: TextEdit.Wrap
                        enabled: !root.oneorganizeModel.busy && root.oneorganizeModel.clockedIn && !root.oneorganizeModel.clockedOut

                        onTextChanged: {
                            root.oneorganizeModel.taskText = text;
                        }
                    }
                }
            }

            // Task length indicator & Clock Out button
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLg

                UiText {
                    Layout.fillWidth: true
                    text: taskInput.text.length + " / 50 min chars"
                    color: taskInput.text.length >= 50 ? Theme.success : Theme.warning
                    font.pixelSize: Theme.fontCaptionSize
                }

                ShellButton {
                    label: "Clock Out"
                    danger: true
                    enabled: root.oneorganizeModel.clockedIn && !root.oneorganizeModel.clockedOut
                        && taskInput.text.trim().length >= 50 && !root.oneorganizeModel.busy
                    onActivated: root.oneorganizeModel.clockOut(taskInput.text)
                }
            }
        }
    }
}
