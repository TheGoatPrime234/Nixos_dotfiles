import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./../color"

PanelWindow {
    id: appLauncher
    visible: false
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.trans
    WlrLayershell.layer: WlrLayer.Overlay
    aboveWindows: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    IpcHandler {
        target: "applauncher"
        function toggle() {
            if (appLauncher.visible) {
                appLauncher.close();
            } else {
                appLauncher.visible = true;
                searchInput.text = "";
                searchInput.forceActiveFocus(); // Setzt den Cursor direkt in die Suchleiste
            }
        }
    }

    function close() {
        appLauncher.visible = false;
        searchInput.text = "";
    }
    Rectangle {
        id: launcherBox
        width: 600
        height: Math.min(500, 80 + (appList.count * 56)) 
        anchors.centerIn: parent
        color: Theme.bg0
        radius: Theme.rad
        border { width: 1; color: Theme.bg2 }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spc1
            spacing: Theme.spc2
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 48
                color: Theme.bg1
                radius: Theme.rad
                border { width: 1; color: searchInput.activeFocus ? Theme.ac1 : Theme.bg2 }
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spc2
                    Text {
                        text: "" 
                        font.family: Theme.fnt
                        font.pixelSize: Theme.t1 + 4
                        color: Theme.ac1
                    }
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.ac1
                        font.family: Theme.fnt
                        font.pixelSize: Theme.t1 + 2
                        focus: true
                        onTextChanged: appList.currentIndex = 0
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                appList.incrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                appList.decrementCurrentIndex();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                appLauncher.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                if (appList.currentItem) {
                                    // Startet das Programm, das aktuell in der Liste markiert ist!
                                    appList.model.values[appList.currentIndex].execute();
                                    appLauncher.close();
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
            ListView {
                id: appList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.spc2 / 2
                model: ScriptModel {
                    values: {
                        const allEntries = [...DesktopEntries.applications.values];
                        const q = searchInput.text.trim().toLowerCase();
                        if (q === "") return allEntries;
                        return allEntries.filter(a => 
                            a.name.toLowerCase().includes(q) || 
                            (a.genericName && a.genericName.toLowerCase().includes(q))
                        );
                    }
                }
                delegate: Rectangle {
                    width: appList.width
                    height: 48
                    radius: Theme.rad / 2
                    readonly property bool isSelected: ListView.isCurrentItem
                    color: isSelected ? Theme.ac1 : Theme.trans
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spc2
                        spacing: Theme.spc2
                        Text {
                            text: modelData.name
                            font.family: Theme.fnt
                            font.pixelSize: Theme.t1 + 2
                            font.bold: true
                            color: parent.parent.isSelected ? Theme.bg0 : Theme.fg0
                        }
                        Text {
                            text: modelData.genericName ? "— " + modelData.genericName : ""
                            font.family: Theme.fnt
                            font.pixelSize: Theme.t1
                            color: parent.parent.isSelected ? Theme.bg0 : Theme.bg3
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            modelData.execute();
                            appLauncher.close();
                        }
                    }
                }
            }
        }
    }
}
