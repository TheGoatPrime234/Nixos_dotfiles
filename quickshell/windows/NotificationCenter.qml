import Quickshell
import Quickshell.Wayland
import Quickshell.Io 
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "./../color"

PanelWindow {
    id: ncWindow
    visible: GlobalNotifs.centerVisible
    color: Theme.trans
    implicitWidth: ncBox.width
    implicitHeight: ncBox.height + (ncWindow.visible ? 0 : 50)
    anchors { bottom: true; right: true }
    margins { left: Theme.spc1 * 2 }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: ncWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    IpcHandler {
        target: "notifcenter"
        function toggle() { GlobalNotifs.toggleCenter(); }
    }
    Rectangle {
        id: ncBox
	width: 420
        color: Theme.bg0
        radius: Theme.rad
        border { width: 1; color: Theme.bg2 }
        property string pendingCmd: ""
        property real lastKeyTime: 0
        property bool visualMode: false
        property var selectedIndices: ({}) // Merkt sich markierte Indizes im Visual Mode
        property var expandedApps: ({})
        function toggleApp(appName) {
            let temp = expandedApps;
            temp[appName] = (temp[appName] === undefined) ? false : !temp[appName];
            expandedApps = Object.assign({}, temp);
        }
        property var flatModel: {
            let forceUpdate = GlobalNotifs.trackedNotifications.values.length; // Reaktivität erzwingen
            let notifs = GlobalNotifs.trackedNotifications.values;
            let groups = {};
            for (let i = 0; i < notifs.length; i++) {
                let app = notifs[i].appName || "System";
                if (!groups[app]) groups[app] = [];
                groups[app].push(notifs[i]);
            }
            let result = [];
            for (let app in groups) {
                let isExp = expandedApps[app] !== false;
                result.push({ isHeader: true, appName: app, icon: GlobalNotifs.getAppIcon(app), count: groups[app].length, expanded: isExp });
                if (isExp) {
                    for (let i = 0; i < groups[app].length; i++) {
                        result.push({ isHeader: false, appName: app, notif: groups[app][i] });
                    }
                }
            }
            return result;
        }
        property int notifCount: GlobalNotifs.trackedNotifications.values.length
        property real targetHeight: 240 + (notifCount > 0 ? 40 : 0) + listView.contentHeight + (notifCount > 0 ? Theme.spc2 : 0)
        height: Math.min(800, targetHeight)
        opacity: ncWindow.visible ? 1.0 : 0.0
        transform: Translate { y: ncWindow.visible ? 0 : 50 }
        Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on transform { NumberAnimation { duration: 500; easing.type: Easing.OutExpo } }
        focus: true
        onVisibleChanged: { 
            if (visible) { forceActiveFocus(); visualMode = false; selectedIndices = {}; pendingCmd = ""; }
        }
        Keys.onPressed: event => {
            let now = Date.now();
            if (now - lastKeyTime > 600) pendingCmd = ""; // Timeout für Tastenfolgen (wie in Vim)
            lastKeyTime = now;
            let idx = listView.currentIndex;
            let currentItem = flatModel[idx];
            if (!currentItem) return;
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                if (visualMode) {
                    visualMode = false; selectedIndices = {}; // Visual Mode abbrechen
                } else {
                    GlobalNotifs.centerVisible = false; // Fenster schließen
                }
                event.accepted = true;
            } 
            else if (event.key === Qt.Key_J) {
                if (event.modifiers & Qt.ShiftModifier) { // Shift+J (Nächster Stapel)
                    for (let i = idx + 1; i < flatModel.length; i++) {
                        if (flatModel[i].isHeader) { listView.currentIndex = i; break; }
                    }
                } else { // j (Eins runter)
                    listView.incrementCurrentIndex();
                }
                if (visualMode) { let temp = selectedIndices; temp[listView.currentIndex] = true; selectedIndices = Object.assign({}, temp); }
                event.accepted = true;
            } 
            else if (event.key === Qt.Key_K) {
                if (event.modifiers & Qt.ShiftModifier) { // Shift+K (Vorheriger Stapel)
                    for (let i = idx - 1; i >= 0; i--) {
                        if (flatModel[i].isHeader) { listView.currentIndex = i; break; }
                    }
                } else { // k (Eins hoch)
                    listView.decrementCurrentIndex();
                }
                if (visualMode) { let temp = selectedIndices; temp[listView.currentIndex] = true; selectedIndices = Object.assign({}, temp); }
                event.accepted = true;
            } 
            else if (event.key === Qt.Key_G) {
                if (event.modifiers & Qt.ShiftModifier) { // G (Ganz nach unten)
                    listView.currentIndex = flatModel.length - 1;
                    pendingCmd = "";
                } else { // gg (Ganz nach oben)
                    if (pendingCmd === "g") { listView.currentIndex = 0; pendingCmd = ""; } 
                    else { pendingCmd = "g"; }
                }
                event.accepted = true;
            }
            else if (event.key === Qt.Key_V) { // v / V (Visual Mode)
                visualMode = !visualMode;
                if (visualMode) { selectedIndices = {}; selectedIndices[idx] = true; }
                else { selectedIndices = {}; }
                event.accepted = true;
            }
            else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                if (currentItem.isHeader) ncBox.toggleApp(currentItem.appName);
                event.accepted = true;
            }
            else if (event.key === Qt.Key_X || event.key === Qt.Key_D) {
                if (event.key === Qt.Key_D && pendingCmd !== "d" && !visualMode) {
                    pendingCmd = "d";
                    event.accepted = true;
                    return;
                }
                let toDelete = [];
                if (visualMode) {
                    for (let i in selectedIndices) {
                        let item = flatModel[i];
                        if (item.isHeader) {
                            let notifs = GlobalNotifs.trackedNotifications.values.filter(n => (n.appName || "System") === item.appName);
                            toDelete = toDelete.concat(notifs);
                        } else {
                            toDelete.push(item.notif);
                        }
                    }
                } else if (pendingCmd === "d") {
                    toDelete = GlobalNotifs.trackedNotifications.values.filter(n => (n.appName || "System") === currentItem.appName);
                } else {
                    if (currentItem.isHeader) {
                        toDelete = GlobalNotifs.trackedNotifications.values.filter(n => (n.appName || "System") === currentItem.appName);
                    } else {
                        toDelete.push(currentItem.notif);
                    }
                }
                for (let i = 0; i < toDelete.length; i++) toDelete[i].tracked = false;
                visualMode = false; selectedIndices = {}; pendingCmd = "";
                event.accepted = true;
            }
        }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: Theme.spc2; spacing: Theme.spc2
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 200
                color: Theme.bg1; radius: Theme.rad; border { width: 1; color: Theme.bg2 }
                Text { anchors.centerIn: parent; text: "Schnelleinstellungen"; color: Theme.bg3; font.family: Theme.fnt }
            }
            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 30
                visible: ncBox.notifCount > 0 
                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Benachrichtigungen"; font.family: Theme.fnt; font.pixelSize: Theme.t1 + 2; font.bold: true; color: Theme.ac1 }
            }
            ListView {
                id: listView
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: Theme.spc2
                model: ncBox.flatModel
                delegate: Loader {
                    width: listView.width
                    sourceComponent: modelData.isHeader ? headerComponent : notifComponent
                    property bool isSelected: ListView.isCurrentItem
                    property bool isVisuallySelected: ncBox.visualMode && ncBox.selectedIndices[index]
                    Component {
                        id: headerComponent
                        Rectangle {
                            width: listView.width; height: 36; radius: Theme.rad / 2
                            color: isVisuallySelected ? Theme.ac1 : (isSelected ? Theme.bg1 : Theme.trans)
                            border { width: 1; color: isSelected && !isVisuallySelected ? Theme.ac1 : Theme.trans }
                            MouseArea { anchors.fill: parent; onClicked: { listView.currentIndex = index; ncBox.toggleApp(modelData.appName); } }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: Theme.spc2; spacing: Theme.spc2
                                Text { text: modelData.icon; font.family: Theme.fnt; color: isVisuallySelected ? Theme.bg0 : Theme.ac1 }
                                Text { text: modelData.appName + "  (" + modelData.count + ")"; font.family: Theme.fnt; font.bold: true; color: isVisuallySelected ? Theme.bg0 : Theme.bg3; Layout.fillWidth: true }
                                Text { text: modelData.expanded ? "" : ""; font.family: Theme.fnt; color: isVisuallySelected ? Theme.bg0 : Theme.bg3 }
                            }
                        }
                    }
                    Component {
                        id: notifComponent
                        Rectangle {
                            width: listView.width; height: 88; radius: Theme.rad
                            color: isVisuallySelected ? Theme.ac1 : Theme.bg1
                            border { width: 1; color: isSelected ? Theme.ac1 : Theme.bg2 }
                            MouseArea { anchors.fill: parent; onClicked: listView.currentIndex = index }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: Theme.spc2; spacing: Theme.spc2
                                Rectangle {
                                    Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 20; color: isVisuallySelected ? Theme.bg0 : Theme.bg2
                                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.fnt; color: Theme.ac1 }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    Text { text: modelData.notif.summary; font.family: Theme.fnt; font.bold: true; color: isVisuallySelected ? Theme.bg0 : Theme.fg0; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: modelData.notif.body; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: isVisuallySelected ? Theme.bg0 : Theme.bg3; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: Text.Wrap }
                                }
                                Rectangle {
                                    Layout.preferredWidth: 30; Layout.fillHeight: true; color: Theme.trans
                                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.fnt; color: isVisuallySelected ? Theme.bg0 : Theme.bg3; font.pixelSize: Theme.t1 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.notif.tracked = false }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
