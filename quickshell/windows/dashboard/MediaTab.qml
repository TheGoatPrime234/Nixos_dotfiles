import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io 
import QtQuick
import QtQuick.Layouts
import "./../../color"

Item {
    id: mediaTab
    
    // === VIM FOCUS LAYER ===
    property bool isFocused: false
    property int selectedAction: 1 

    function handleKey(event) {
        if (!player) return;
        if (event.modifiers & Qt.ShiftModifier) {
            if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                player.position = player.position + 10; 
                event.accepted = true;
            } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                player.position = Math.max(0, player.position - 10);
                event.accepted = true;
            }
            return;
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00";
        let totalSeconds = Math.floor(seconds); 
        let minutes = Math.floor(totalSeconds / 60);
        let secs = totalSeconds % 60;
        return minutes + ":" + (secs < 10 ? "0" + secs : secs);
    }

    property var player: {
        var pList = Mpris.players.values; 
        if (!pList || pList.length === 0) return null;
        var fallback = pList[0];
        for (var i = 0; i < pList.length; i++) {
            if (pList[i].isPlaying) { return pList[i]; }
        }
        return fallback;
    }

    property int timeTicker: 0
    Timer {
        interval: 1000
        running: mediaTab.player && mediaTab.player.isPlaying && GlobalDashboard.dashboardVisible
        repeat: true
        onTriggered: mediaTab.timeTicker++ // Tickt jede Sekunde um 1 hoch
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: Theme.spc2

        Text {
            visible: !mediaTab.player
            text: "Keine aktive Wiedergabe"
            font.family: Theme.fnt
            color: Theme.bg2 // Theme Fix: bg2 statt bg3
            anchors.centerIn: parent
        }

        RowLayout {
            visible: !!mediaTab.player
            Layout.fillWidth: true
            spacing: Theme.spc2 * 2

            // Album Art
            Rectangle {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 160
                radius: Theme.rad
                color: Theme.bg1
                clip: true
                border { width: 1; color: Theme.ac2 }

                Image {
                    anchors.fill: parent
                    source: mediaTab.player && mediaTab.player.trackArtUrl ? mediaTab.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                Text {
                    visible: parent.children[0].status !== Image.Ready
                    anchors.centerIn: parent
                    text: ""
                    font.family: Theme.fnt
                    font.pixelSize: 40
                    color: Theme.bg2
                }
            }

            // Info & Controls
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: mediaTab.player && mediaTab.player.trackTitle ? mediaTab.player.trackTitle : "Unbekannter Titel"
                        font.family: Theme.fnt; font.pixelSize: Theme.t1 + 2; font.bold: true; color: Theme.fg0
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                    Text {
                        text: mediaTab.player && mediaTab.player.trackArtist ? mediaTab.player.trackArtist : "Unbekannter Interpret"
                        font.family: Theme.fnt; font.pixelSize: Theme.t1; color: Theme.ac1
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }

                // Fortschrittsbalken & Zeitangaben
		ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        color: Theme.bg2
                        radius: 2

                        Rectangle {
                            // Dynamische Breite
                            width: {
                                var tick = mediaTab.timeTicker; // Löst das Update aus
                                return parent.width * (mediaTab.player && mediaTab.player.length > 0 
                                    ? (mediaTab.player.position / mediaTab.player.length) 
                                    : 0);
                            }
                            height: parent.height
                            color: Theme.ac1
                            radius: Theme.rad
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.Linear } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { 
                            // Links: Aktuelle Position
                            text: {
                                var tick = mediaTab.timeTicker; // Löst das Update aus
                                return mediaTab.formatTime(mediaTab.player ? mediaTab.player.position : 0);
                            }
                            font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0 
                        }
                        Item { Layout.fillWidth: true }
                        Text { 
                            // Rechts: Maximale Länge des Songs
                            text: mediaTab.player && mediaTab.player.length > 0 
                                  ? mediaTab.formatTime(mediaTab.player.length)
                                  : "0:00"
                            font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.bg2 
                        }
                    }
                }

                // Controls
                RowLayout {
                    spacing: 30
                    Layout.alignment: Qt.AlignHCenter

                    Text { 
                        text: "󰒮"; font.family: Theme.fnt; font.pixelSize: 24;
                        color: (mediaTab.isFocused && mediaTab.selectedAction === 0) ? Theme.ac1 : Theme.bg2
                        scale: (mediaTab.isFocused && mediaTab.selectedAction === 0) ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }
                    }
                    Text { 
                        text: mediaTab.player && mediaTab.player.isPlaying ? "󰏤" : "󰐊"
                        font.family: Theme.fnt; font.pixelSize: 32; 
                        color: (mediaTab.isFocused && mediaTab.selectedAction === 1) ? Theme.ac1 : Theme.bg2
                        scale: (mediaTab.isFocused && mediaTab.selectedAction === 1) ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }
                    }
                    Text { 
                        text: "󰒭"; font.family: Theme.fnt; font.pixelSize: 24; 
                        color: (mediaTab.isFocused && mediaTab.selectedAction === 2) ? Theme.ac1 : Theme.bg2
                        scale: (mediaTab.isFocused && mediaTab.selectedAction === 2) ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
