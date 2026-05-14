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
            # Interface finden
            iface=$(ip route show default | awk '/default/ {print $5}' | head -n1)
            
            # Erste Messung
            read rx1 tx1 < <(awk -v iface=\"$iface\" '$1 ~ iface {print $2, $10}' /proc/net/dev)
            sleep 0.5
            # Zweite Messung
            read rx2 tx2 < <(awk -v iface=\"$iface\" '$1 ~ iface {print $2, $10}' /proc/net/dev)
            
            # Rate berechnen (Bytes -> KB)
            dr=$(( (rx2 - rx1) / 512 )) # /512 statt 1024 wegen 0.5s sleep
            ur=$(( (tx2 - tx1) / 512 ))
            
            # IPs & SSID
            lip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \\K\\S+' || echo '127.0.0.1')
            tip=$(tailscale ip -4 2>/dev/null || echo 'Aus')
            wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo 'Ethernet')
            
            # Ping (Cooles Feature)
            latency=$(ping -c 1 -W 1 1.1.1.1 2>/dev/null | grep 'time=' | sed 's/.*time=\\(.*\\) ms/\\1/')
            
            echo \"$dr|$ur|$lip|$tip|$wifi|$latency\"
        "]
        running: dashWindow.visible
        onExited: netTimer.start()
	stdout: SplitParser {
// In NetworkTab.qml -> stdout: SplitParser
	    onRead: data => {
		let parts = data.trim().split("|");
		if (parts.length >= 6) {
		    let d = parseInt(parts[0]);
		    let u = parseInt(parts[1]);
		    
		    // Wir setzen ein Limit, ab dem der Graph 100% Höhe erreicht.
		    // Für eine 100 Mbit Leitung sind ~13.000 KB/s realistisch.
		    // Wir nehmen 15.000 als Puffer.
		    let maxRange = 15000; 

		    let newDown = networkTab.downloadHistory;
		    newDown.shift(); 
		    newDown.push(Math.min(1.0, d / maxRange)); // Normalisierung auf 0.0 - 1.0
		    networkTab.downloadHistory = newDown;
		    
		    let newUp = networkTab.uploadHistory;
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: Theme.spc2

        RowLayout {
            spacing: Theme.spc2
            Text { text: "󰖩 " + networkTab.ssid; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.ac1; Layout.fillWidth: true }
            Text { text: "󰓅 " + networkTab.ping; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.ac1 }
        }
        // Top Row: IP Karten
        RowLayout {
            spacing: Theme.spc2
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70
                color: networkTab.selectedIndex === 0 && networkTab.isFocused ? Theme.bg2 : Theme.bg1
                radius: Theme.rad; border { width: 1; color: networkTab.selectedIndex === 0 && networkTab.isFocused ? Theme.ac1 : Theme.bg2 }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Text { text: "Lokale IP"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac1; Layout.alignment: Qt.AlignHCenter }
                    Text { text: networkTab.localIp; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0; Layout.alignment: Qt.AlignHCenter }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70
                color: networkTab.selectedIndex === 1 && networkTab.isFocused ? Theme.bg2 : Theme.bg1
                radius: Theme.rad; border { width: 1; color: networkTab.selectedIndex === 1 && networkTab.isFocused ? Theme.ac2 : Theme.bg2 }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 2
                    Text { text: "Tailscale"; font.family: Theme.fnt; font.pixelSize: Theme.t4; color: Theme.ac2; Layout.alignment: Qt.AlignHCenter }
                    Text { text: networkTab.tailscaleIp; font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.fg0; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }

        RowLayout {
            spacing: Theme.spc2
            NetGraph {
                Layout.fillWidth: true; Layout.preferredHeight: 140
                title: "DOWNLOAD"; valueText: networkTab.downText; accentColor: Theme.ac1
                history: networkTab.downloadHistory
                isFocused: networkTab.isFocused && networkTab.selectedIndex === 2
            }
            NetGraph {
                Layout.fillWidth: true; Layout.preferredHeight: 140
                title: "UPLOAD"; valueText: networkTab.upText; accentColor: Theme.ac2
                history: networkTab.uploadHistory
                isFocused: networkTab.isFocused && networkTab.selectedIndex === 3
            }
        }
    }
}
