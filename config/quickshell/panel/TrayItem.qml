import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core

Rectangle {
    id: root

    required property var trayItem
    property var iconSources: Icons.trayIconSources(root.trayItem)
    property int iconSourceIndex: 0

    function toggleContextMenu() {
        if (root.trayItem && root.trayItem.hasMenu) {
            if (trayMenu.visible) {
                trayMenu.close();
            } else {
                trayMenu.open();
            }
        } else if (root.trayItem) {
            root.trayItem.activate();
        }
    }

    function openContextMenu() {
        if (root.trayItem && root.trayItem.hasMenu) {
            trayMenu.open();
        }
    }

    function handleClick(button) {
        if (button === Qt.LeftButton || button === Qt.RightButton) {
            root.toggleContextMenu();
        } else if (button === Qt.MiddleButton) {
            if (root.trayItem) {
                root.trayItem.secondaryActivate();
            }
        }
    }

    onIconSourcesChanged: {
        iconSourceIndex = 0;
    }

    Layout.preferredWidth: Theme.trayItemSize
    Layout.preferredHeight: Theme.trayItemSize
    radius: Theme.smallRadius
    color: trayMouse.containsMouse ? Theme.controlHoverFill : Theme.transparent
    border.color: trayMouse.containsMouse ? Theme.controlHoverBorder : Theme.transparent
    border.width: trayMouse.containsMouse ? Theme.pillBorderWidth : 0

    QsMenuAnchor {
        id: trayMenu

        menu: root.trayItem ? root.trayItem.menu : null
        anchor.item: root
    }

    IconImage {
        id: trayIcon

        anchors.centerIn: parent
        width: Theme.trayIconSize
        height: Theme.trayIconSize
        source: root.iconSources.length > root.iconSourceIndex ? root.iconSources[root.iconSourceIndex] : ""
        implicitSize: Theme.trayIconSize
        asynchronous: true
        mipmap: true
        visible: status === Image.Ready

        onStatusChanged: {
            if (status === Image.Error && root.iconSourceIndex < root.iconSources.length - 1) {
                root.iconSourceIndex += 1;
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !trayIcon.visible
        text: {
            const title = root.trayItem.tooltipTitle || root.trayItem.title || root.trayItem.id || "?";
            return title.length > 0 ? title.charAt(0).toUpperCase() : "?";
        }
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.tinyFontSize
        font.bold: true
    }

    MouseArea {
        id: trayMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton) {
                root.toggleContextMenu();
                mouse.accepted = true;
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.trayItem) {
                    root.trayItem.secondaryActivate();
                }
                mouse.accepted = true;
            }
        }
    }
}
