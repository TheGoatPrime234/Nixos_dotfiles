import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "./../color"

Rectangle {
    id: graphRoot
    
    property string title: ""
    property string valueText: ""
    property var history: []
    property color accentColor: Theme.ac1
    property bool isFocused: false

    implicitWidth: 200
    implicitHeight: 120
    radius: Theme.rad
    color: isFocused ? Theme.bg2 : Theme.bg1
    border { width: 1; color: isFocused ? accentColor : Theme.bg2 }
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Text { 
                text: title
                font { family: Theme.fnt; pixelSize: Theme.t2; bold: true }
                color: accentColor 
            }
            Item { Layout.fillWidth: true } // Korrekter Spacer im Layout
            Text { 
                text: valueText
                font { family: Theme.fnt; pixelSize: Theme.t2 }
                color: Theme.fg0 
            }
        }

	Shape {
	    id: canvas
	    Layout.fillWidth: true
	    Layout.fillHeight: true
	    layer.enabled: true
	    layer.samples: 4

	    ShapePath {
		fillColor: "transparent"
		strokeColor: accentColor
		strokeWidth: 2
		capStyle: ShapePath.RoundCap
		joinStyle: ShapePath.RoundJoin

		PathPolyline {
		    id: line
		    path: {
			let coords = [];
			let h = graphRoot.history;
			if (h && h.length > 1) {
			    for (let i = 0; i < h.length; i++) {
				// Wir nutzen canvas.width/height für die Skalierung
				coords.push(Qt.point(
				    (i / (h.length - 1)) * canvas.width,
				    canvas.height - (h[i] * (canvas.height - 5))
				));
			    }
			}
			return coords;
		    }
		}
	    }
	}
    }
}
