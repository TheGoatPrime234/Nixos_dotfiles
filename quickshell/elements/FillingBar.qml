import QtQuick
import QtQuick.Layouts
import "./../color"

Rectangle {
    id: barRoot
    
    property real pct: 0
    property string icon: ""
    property string name: ""
    property string subText: ""
    property color accentColor: Theme.ac1
    property bool isFocused: false
    implicitWidth: 150
    implicitHeight: 70
    
    radius: Theme.rad
    color: isFocused ? Theme.bg2 : Theme.bg1
    border { 
        width: 1
        color: isFocused ? accentColor : Theme.bg2 
    }

    property real animPct: pct
    Behavior on animPct { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 200 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: Theme.spc2
        
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spc2
            
            Text { text: barRoot.icon; font.family: Theme.fnt; font.pixelSize: Theme.t1 + 2; color: accentColor }
            Text { text: barRoot.name; font.family: Theme.fnt; font.pixelSize: Theme.t1; font.bold: true; color: accentColor }
            
            // Elastischer Platzhalter (Drückt "SubText" und "Prozent" ganz nach rechts!)
            Item { Layout.fillWidth: true }
            
            Text { text: barRoot.subText; font.family: Theme.fnt; font.pixelSize: Theme.t1; color: Theme.fg0 }
            Text { text: Math.round(animPct) + "%"; font.family: Theme.fnt; font.pixelSize: Theme.t1; font.bold: true; color: accentColor }
        }
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.rad / 2
            color: Theme.bg2
            
            Rectangle {
                width: parent.width * (animPct / 100)
                height: parent.height
                radius: Theme.rad / 2
                color: accentColor
            }
        }
    }
}
