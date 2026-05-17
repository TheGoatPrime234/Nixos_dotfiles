import Quickshell
import Quickshell.Wayland
import Quickshell.Io 
import QtQuick
import QtQuick.Layouts
import "./../../color"
import "./../../elements" 

Item {
    id: startTab
    
    property bool isFocused: false
    property int selectedIndex: 0 

    function handleKey(event) {
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            selectedIndex = (selectedIndex + 1) % 3;
            event.accepted = true;
        } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            selectedIndex = (selectedIndex - 1 + 3) % 3;
            event.accepted = true;
        }
    }

    Process {
        id: userProcess
        command: ["bash", "-c", "echo $USER@$HOSTNAME"]
        running: true 
        property string userHost: "user@nixos"
        stdout: SplitParser { onRead: data => { userProcess.userHost = data.trim() } }
    }

    Process {
        id: sysInfoProcess
        command: ["bash", "-c", "
            uptime=$(awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime)
            kernel=$(uname -r)
            os=$(nixos-version | cut -d. -f1,2)
            echo \"$uptime|$kernel|$os\"
        "]
        running: dashWindow.visible
        property string uptime: "Lade..."
        property string kernel: "Lade..."
        property string osVersion: "Lade..."
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                if (parts.length >= 3) {
                    sysInfoProcess.uptime = parts[0];
                    sysInfoProcess.kernel = parts[1];
                    sysInfoProcess.osVersion = parts[2];
                }
            }
        }
    }

    property var nixenStats: { "level": 0, "pct": 0 }
    property var nvimStats:  { "level": 0, "pct": 0 }
    property var terminalStats:  { "level": 0, "pct": 0 }

    Process {
        id: trackerProcess
        command: ["bash", "-c", "
            nixen=$(nix-timetracker status nixen 2>/dev/null || echo '{}')
            nvim=$(nix-timetracker status nvim 2>/dev/null || echo '{}')
            terminal=$(nix-timetracker status terminal 2>/dev/null || echo '{}')
            echo \"$nixen|$nvim|$terminal\"
        "]
        running: dashWindow.visible
        onExited: trackerTimer.start()
        
        stdout: SplitParser {
            onRead: data => {
                let parts = data.split("|");
                if (parts.length >= 3) {
                    try {
                        let nx = JSON.parse(parts[0]);
                        if (nx.app) startTab.nixenStats = { "level": nx.level, "pct": nx.progress_percent };
                    } catch(e) {}
                    
                    try {
                        let nv = JSON.parse(parts[1]);
                        if (nv.app) startTab.nvimStats = { "level": nv.level, "pct": nv.progress_percent };
                    } catch(e) {}
                    
                    try {
                        let rs = JSON.parse(parts[2]);
                        if (rs.app) startTab.terminalStats = { "level": rs.level, "pct": rs.progress_percent };
                    } catch(e) {}
                }
            }
        }
    }
    
    Timer { id: trackerTimer; interval: 5000; onTriggered: trackerProcess.running = true }

    property string greeting: {
        let hour = new Date().getHours();
        if (hour < 11) return "Guten Morgen";
        if (hour < 18) return "Guten Tag";
        return "Guten Abend";
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc1
        spacing: Theme.spc1 * 2

        // --- LINKE SEITE ---
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.4
            spacing: Theme.spc2
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "" 
                font.family: Theme.fnt
                font.pixelSize: 120
                color: Theme.ac1
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "hh:mm")
                font { family: Theme.fnt; pixelSize: 42; bold: true }
                color: Theme.fg0
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(new Date(), "dd. MMMM yyyy")
                font { family: Theme.fnt; pixelSize: Theme.t2 }
                color: Theme.bg2 
            }
        }

        // --- RECHTE SEITE ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 24

            ColumnLayout {
                spacing: 2
                Text { text: startTab.greeting + ","; font { family: Theme.fnt; pixelSize: Theme.t1 + 2 } color: Theme.bg2 }
                Text { text: userProcess.userHost; font { family: Theme.fnt; pixelSize: 28; bold: true } color: Theme.fg0 }
            }

            RowLayout {
                spacing: Theme.spc1
                
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    color: Theme.bg1; radius: Theme.rad / 2
                    border { width: 1; color: Theme.bg2 }
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 2
                        Text { text: "Uptime"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac1; Layout.alignment: Qt.AlignHCenter }
                        Text { text: sysInfoProcess.uptime; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0; Layout.alignment: Qt.AlignHCenter }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    color: Theme.bg1; radius: Theme.rad / 2
                    border { width: 1; color: Theme.bg2 }
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 2
                        Text { text: "Kernel"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac2; Layout.alignment: Qt.AlignHCenter }
                        Text { text: sysInfoProcess.kernel; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0; Layout.alignment: Qt.AlignHCenter }
                    }
                }
                
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    color: Theme.bg1; radius: Theme.rad / 2
                    border { width: 1; color: Theme.bg2 }
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 2
                        Text { text: "NixOS"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac1; Layout.alignment: Qt.AlignHCenter }
                        Text { text: sysInfoProcess.osVersion; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0; Layout.alignment: Qt.AlignHCenter }
                    }
                }
            }

            ColumnLayout {
                spacing: Theme.spc2
                Text { text: "Level Tracker"; font { family: Theme.fnt; pixelSize: Theme.t2; bold: true } color: Theme.ac1 }
                
                RowLayout {
                    spacing: Theme.spc2
                    Tacho {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        icon: "" 
                        name: "Terminal"
                        pct: startTab.terminalStats.pct
                        subText: "Level " + startTab.terminalStats.level
                        accentColor: Theme.ac1
                        isFocused: startTab.isFocused && startTab.selectedIndex === 2
                    }
                    Tacho {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        icon: "" 
                        name: "Nix"
                        pct: startTab.nixenStats.pct
                        subText: "Level " + startTab.nixenStats.level
                        accentColor: Theme.ac1
                        isFocused: startTab.isFocused && startTab.selectedIndex === 0
                    }
                    Tacho {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        icon: "" 
                        name: "Neovim"
                        pct: startTab.nvimStats.pct
                        subText: "Level " + startTab.nvimStats.level
                        accentColor: Theme.ac2
                        isFocused: startTab.isFocused && startTab.selectedIndex === 1
                    }
                }
            }
        }
    }
}
