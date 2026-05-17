import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io 
import QtQuick
import QtQuick.Layouts
import "./../color"
import "./dashboard"

PanelWindow {
    id: dashWindow
    visible: GlobalDashboard.dashboardVisible
    color: Theme.trans
    width: 650 
    
    // --- FIX: Feste Fensterhöhe (groß genug für den StartTab + 30px Bounce-Spielraum) ---
    height: 520 
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.anchors.bottom: true
    WlrLayershell.margins.bottom: 16
    WlrLayershell.exclusionMode: ExclusionMode.Normal
    WlrLayershell.keyboardFocus: dashWindow.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    
    IpcHandler { target: "dashboard"; function toggle() { GlobalDashboard.toggle(); } }
    MouseArea { anchors.fill: parent; onClicked: GlobalDashboard.close() }

    Rectangle {
        id: dashBox
        width: parent.width
	height: {
	    if (currentTab === 1) return 340;
	    if (currentTab === 2) return 480;
	    if (currentTab === 3) return 350;
	    if (currentTab === 4) return 480;
	    return 420;
	}
        
        color: Theme.bg0
        radius: Theme.rad
        border { width: 1; color: Theme.bg2 }
        
        // Klebt am Boden des transparenten PanelWindows
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom 
        
        opacity: dashWindow.visible ? 1.0 : 0.0
        transform: Translate { y: dashWindow.visible ? 0 : 30 }
        
        // --- Weiche interne Höhen-Animation ---
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on transform { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
        
        property int currentTab: 2 
        property bool isContentFocused: false 
        
        property var tabs: [
            { name: "System", icon: "" },
            { name: "Media", icon: "" },
            { name: "Start", icon: "󰣇" },
            { name: "Netzwerk", icon: "" },
            { name: "Wetter", icon: "" }
        ]
        
        onVisibleChanged: { 
            if (visible) { 
                forceActiveFocus();
                dashBox.currentTab = 2; 
                dashBox.isContentFocused = false; 
            }
        }
        
        focus: true
        Keys.onPressed: event => {
            // 1. Globale Fallbacks (Escape / Quit)
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q) {
                if (dashBox.isContentFocused) {
                    dashBox.isContentFocused = false; // Visual Mode abbrechen
                    event.accepted = true;
                } else {
                    GlobalDashboard.close();
                    event.accepted = true;
                }
                return;
            }

            // 2. LAYER 0: Tab-Leiste fokussiert (Unten)
            if (!dashBox.isContentFocused) {
                if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
                    dashBox.currentTab = (dashBox.currentTab + 1) % dashBox.tabs.length;
                    event.accepted = true;
                } else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
                    dashBox.currentTab = (dashBox.currentTab - 1 + dashBox.tabs.length) % dashBox.tabs.length;
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                    dashBox.isContentFocused = true; // Steige auf in den Content!
                    event.accepted = true;
                }
            } 
            // 3. LAYER 1: Content fokussiert (Oben)
            else {
                if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                    dashBox.isContentFocused = false; // Falle zurück in die Tab-Leiste
                    event.accepted = true;
                    return;
                }

                // Delegation an die einzelnen Tabs
                if (dashBox.currentTab === 1) {
                    mediaTab.handleKey(event);
                }
                // (Später kannst du hier systemTab.handleKey(event) hinzufügen)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spc2
            spacing: Theme.spc2
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: dashBox.currentTab
                SystemTab { 
                    id: systemTab 
                    property bool isFocused: dashBox.isContentFocused && dashBox.currentTab === 0
                }
                MediaTab { 
                    id: mediaTab 
                    isFocused: dashBox.isContentFocused && dashBox.currentTab === 1
                }
                StartTab { 
                    id: startTab 
                    property bool isFocused: dashBox.isContentFocused && dashBox.currentTab === 2
                }
		NetworkTab {
		    id: networkTab
                    property bool isFocused: dashBox.isContentFocused && dashBox.currentTab === 3
		}
		WeatherTab {
		    id: weatherTab
                    property bool isFocused: dashBox.isContentFocused && dashBox.currentTab === 4
		}
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46 
                Layout.maximumHeight: 46 
                Layout.alignment: Qt.AlignTop 
                radius: Theme.rad
                color: Theme.bg0
                border { width: 1; color: Theme.bg2 }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.outmrg
                    spacing: Theme.spc

                    Repeater {
                        model: dashBox.tabs
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.rad
                            
                            property bool isSelected: dashBox.currentTab === index
                            color: isSelected 
                                ? (dashBox.isContentFocused ? Theme.bg1 : Theme.ac1) 
                                : Theme.bg0
                                
                            border { 
                                width: 1
                                color: isSelected && !dashBox.isContentFocused ? Theme.ac1 : Theme.bg2
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spc
                                Text { 
                                    text: modelData.icon;
                                    font { family: Theme.fnt; pixelSize: Theme.t1 }
                                    color: isSelected ? (dashBox.isContentFocused ? Theme.fg0 : Theme.bg0) : Theme.ac1
                                }
                                Text { 
                                    text: modelData.name;
                                    font { family: Theme.fnt; pixelSize: Theme.t1; bold: true }
                                    color: isSelected ? (dashBox.isContentFocused ? Theme.fg0 : Theme.bg0) : Theme.ac1 
                                }
                            }
                            MouseArea { 
                                anchors.fill: parent; 
                                onClicked: { dashBox.currentTab = index; dashBox.isContentFocused = false; } 
                            }
                        }
                    }
                }           
            }
        }
    }
}
