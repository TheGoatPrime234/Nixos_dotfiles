import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "./../color"

Rectangle {
    id: tachoRoot
    
    property real pct: 0
    property string icon: ""
    property string name: ""
    property string subText: ""
    property color accentColor: Theme.ac1
    property bool isFocused: false

    // WICHTIG: Gibt dem Loader eine Basisgröße, an die er sich klammern kann!
    implicitWidth: 150
    implicitHeight: 160
    
    radius: Theme.rad
    color: isFocused ? Theme.bg2 : Theme.bg1
    border { 
        width: 1
        color: isFocused ? accentColor : Theme.bg2 
    }

    property real animPct: pct
    Behavior on animPct { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
    Behavior on color { ColorAnimation { duration: 200 } }

    // CONTAINER 1: Der Tacho (Fest oben zentriert)
    Item {
        width: 100
        height: 100
        anchors.top: parent.top
        anchors.topMargin: Theme.spc2
        anchors.horizontalCenter: parent.horizontalCenter
        
        Shape {
            anchors.fill: parent
            ShapePath {
                fillColor: Theme.trans
                strokeColor: Theme.bg2
                strokeWidth: 8
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 50; centerY: 50
                    radiusX: 42; radiusY: 42
                    startAngle: 135
                    sweepAngle: 270
                }
            }
            ShapePath {
                fillColor: Theme.trans
                strokeColor: accentColor
                strokeWidth: 8
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 50; centerY: 50
                    radiusX: 42; radiusY: 42
                    startAngle: 135
                    sweepAngle: (animPct / 100) * 270 
                }
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: tachoRoot.icon
            font.family: Theme.fnt
            font.pixelSize: 32
            color: accentColor
        }
    }
    
    // CONTAINER 2: Der Text (Fest unten zentriert)
    ColumnLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.spc2
        spacing: 2
        
        Text { 
            text: tachoRoot.name + " " + Math.round(animPct) + "%"
            font.family: Theme.fnt; font.pixelSize: Theme.t1; font.bold: true; color: Theme.fg0 
            Layout.alignment: Qt.AlignHCenter
        }
        Text { 
            text: tachoRoot.subText
            font.family: Theme.fnt; font.pixelSize: Theme.t2; color: Theme.ac3
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
