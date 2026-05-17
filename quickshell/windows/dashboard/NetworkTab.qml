import QtQuick
import QtQuick.Layouts
import Quickshell.Io 
import "./../../color"
import "./../../elements"

Item {
    id: networkTab
    
    property bool isFocused: false
    property int selectedIndex: 0

    function handleKey(event) {
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            selectedIndex = (selectedIndex + 1) % 4;
            event.accepted = true;
        } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            selectedIndex = (selectedIndex - 1 + 4) % 4;
            event.accepted = true;
        }
    }

    // --- DATEN ---
    property string localIp: "0.0.0.0"
    property string tailscaleIp: "N/A"
    property string ssid: "Getrennt"
    property string ping: "0ms"
    
    property var downloadHistory: new Array(30).fill(0)
    property var uploadHistory:   new Array(30).fill(0)
    property string downText: "0 KB/s"
    property string upText: "0 KB/s"

    Process {
        id: netDataProcess
        command: ["bash", "-c", "
            iface=$(ip route show default | awk '/default/ {print $5}' | head -n1)
            read rx1 tx1 < <(awk -v iface=\"$iface\" '$1 ~ iface {print $2, $10}' /proc/net/dev)
            sleep 0.5
            read rx2 tx2 < <(awk -v iface=\"$iface\" '$1 ~ iface {print $2, $10}' /proc/net/dev)
            dr=$(( (rx2 - rx1) / 512 ))
            ur=$(( (tx2 - tx1) / 512 ))
            lip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+' || echo '127.0.0.1')
            tip=$(tailscale ip -4 2>/dev/null || echo 'Aus')
            wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo 'Ethernet')
            latency=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep 'time=' | sed 's/.*time=\\(.*\\) ms/\\1/')
            echo \"$dr|$ur|$lip|$tip|$wifi|$latency\"
        "]
        running: dashWindow.visible
        onExited: netTimer.start()
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split("|");
                if (parts.length >= 6) {
                    let d = parseInt(parts[0]);
                    let u = parseInt(parts[1]);
                    let maxRange = 15000; 
                    
                    let newDown = [...networkTab.downloadHistory];
                    newDown.shift(); 
                    newDown.push(Math.min(1.0, d / maxRange)); 
                    networkTab.downloadHistory = newDown;
                    
                    let newUp = [...networkTab.uploadHistory];
                    newUp.shift(); 
                    newUp.push(Math.min(1.0, u / maxRange));
                    networkTab.uploadHistory = newUp;
                    
                    networkTab.downText = d + " KB/s";
                    networkTab.upText = u + " KB/s";
                    networkTab.localIp = parts[2];
                    networkTab.tailscaleIp = parts[3];
                    networkTab.ssid = parts[4];
                    networkTab.ping = (parts[5] || "0") + "ms";
                }
            }
        }
    }
    
    Timer { id: netTimer; interval: 1500; onTriggered: netDataProcess.running = true }

    // HIER STARTET DAS REPARIERTE LAYOUT:
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: Theme.spc2

        // Zeile 1: WLAN & Ping Status
        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰖩 " + networkTab.ssid; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.ac1; Layout.fillWidth: true }
            Text { text: "󰓅 " + networkTab.ping; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.ac2 }
        }
        
        // Zeile 2: IP-Karten (Feste Höhe, kein fillHeight mehr!)
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spc2
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70 // <-- FIX: Feste Höhe
                color: networkTab.selectedIndex === 0 && networkTab.isFocused ? Theme.bg2 : Theme.bg1
                radius: Theme.rad
                border { width: 1; color: networkTab.selectedIndex === 0 && networkTab.isFocused ? Theme.ac1 : Theme.bg2 }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Text { text: "Lokale IP"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac1; Layout.alignment: Qt.AlignHCenter }
                    Text { text: networkTab.localIp; font.family: Theme.fnt; font.pixelSize: Theme.t1 + 2; font.bold: true; color: "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70 // <-- FIX: Feste Höhe
                color: networkTab.selectedIndex === 1 && networkTab.isFocused ? Theme.bg2 : Theme.bg1
                radius: Theme.rad
                border { width: 1; color: networkTab.selectedIndex === 1 && networkTab.isFocused ? Theme.ac2 : Theme.bg2 }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Text { text: "Tailscale"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac2; Layout.alignment: Qt.AlignHCenter }
                    Text { text: networkTab.tailscaleIp; font.family: Theme.fnt; font.pixelSize: Theme.t1 + 2; font.bold: true; color: "#ffffff"; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        // Zeile 3: Graphen (Füllen den REST des Platzes)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true // <-- Diese dürfen wachsen!
            spacing: Theme.spc2
            
            NetGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "DOWNLOAD"
                valueText: networkTab.downText
                accentColor: Theme.ac1
                history: networkTab.downloadHistory
                isFocused: networkTab.isFocused && networkTab.selectedIndex === 2
            }
            
            NetGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "UPLOAD"
                valueText: networkTab.upText
                accentColor: Theme.ac2
                history: networkTab.uploadHistory
                isFocused: networkTab.isFocused && networkTab.selectedIndex === 3
            }
        }
    }
}
