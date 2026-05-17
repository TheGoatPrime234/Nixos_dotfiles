import QtQuick
import QtQuick.Layouts
import Quickshell.Io 
import "./../../color"

Item {
    id: weatherTab
    
    // === VIM FOCUS LAYER ===
    property bool isFocused: false
    
    property int viewMode: 0 
    property int scrollIndex: 0

    // FIX: Eine kugelsichere Funktion, die das Karussell aktualisiert
    function updateCarousel() {
        let arr = viewMode === 0 ? hourlyForecast : dailyForecast;
        if (!arr || arr.length === 0) return;
        
        let maxScroll = Math.max(0, arr.length - 4);
        if (scrollIndex > maxScroll) scrollIndex = maxScroll;
        
        // Zuweisung eines GANZ NEUEN Arrays erzwingt das UI-Update im Repeater!
        visibleForecast = arr.slice(scrollIndex, scrollIndex + 4);
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            viewMode = (viewMode === 0) ? 1 : 0;
            scrollIndex = 0; 
            updateCarousel(); // Update erzwingen
            event.accepted = true;
        } 
        else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            let arr = viewMode === 0 ? hourlyForecast : dailyForecast;
            let maxScroll = Math.max(0, arr.length - 4);
            if (scrollIndex < maxScroll) {
                scrollIndex++;
                updateCarousel(); // Update erzwingen
            }
            event.accepted = true;
        } 
        else if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            if (scrollIndex > 0) {
                scrollIndex--;
                updateCarousel(); // Update erzwingen
            }
            event.accepted = true;
        }
    }

    // === DATEN ===
    property string location: "Halstenbek"
    property string temp: "--"
    property string feelsLike: "--"
    property string humidity: "--"
    property string wind: "--"
    property string desc: "Lade Wetter..."
    property string weatherIcon: "" 
    property string sunrise: "--:--"
    property string sunset: "--:--"
    
    property var hourlyForecast: []
    property var dailyForecast: []
    property var visibleForecast: [] // Wird jetzt von updateCarousel() befüllt
    
    function mapWeatherIcon(code) {
        let c = parseInt(code);
        if (c === 113) return ""; 
        if (c === 116) return ""; 
        if (c === 119 || c === 122) return ""; 
        if (c === 143 || c === 248 || c === 260) return ""; 
        if (c >= 293 && c <= 311) return ""; 
        if (c >= 353 && c <= 365) return ""; 
        if (c >= 386 && c <= 395) return ""; 
        if (c >= 323 && c <= 338) return ""; 
        if (c >= 368 && c <= 374) return ""; 
        return ""; 
    }

    Process {
        id: weatherProcess
        command: ["bash", "-c", "
            CACHE=\"/tmp/weather_cache.json\"
            if [ ! -f \"$CACHE\" ] || [ $(expr $(date +%s) - $(stat -c %Y \"$CACHE\")) -gt 1800 ]; then
                curl -s 'de.wttr.in/Halstenbek?format=j1' > \"$CACHE\"
            fi
            cat \"$CACHE\"
        "]
        running: dashWindow.visible
        onExited: weatherTimer.start()
        
        stdout: SplitParser {
            property string jsonBuffer: ""
            onRead: data => {
                jsonBuffer += data;
                try {
                    let json = JSON.parse(jsonBuffer);
                    
                    let current = json.current_condition[0];
                    weatherTab.temp = current.temp_C + "°C";
                    weatherTab.feelsLike = current.FeelsLikeC + "°C";
                    weatherTab.humidity = current.humidity + "%";
                    weatherTab.wind = current.windspeedKmph + " km/h";
                    weatherTab.desc = current.lang_de ? current.lang_de[0].value : current.weatherDesc[0].value;
                    weatherTab.weatherIcon = weatherTab.mapWeatherIcon(current.weatherCode);
                    
                    let astro = json.weather[0].astronomy[0];
                    weatherTab.sunrise = astro.sunrise;
                    weatherTab.sunset = astro.sunset;
                    
                    // --- 24h Vorhersage ---
                    let hList = [];
                    let currentH = new Date().getHours();
                    let today = json.weather[0].hourly;
                    let tomorrow = json.weather[1].hourly;

                    let startIndex = 0;
                    for (let i = 0; i < 8; i++) {
                        if (parseInt(today[i].time) / 100 >= currentH - 2) { startIndex = i; break; }
                        if (i === 7) startIndex = 7; 
                    }

                    let combined = today.concat(tomorrow);
                    let nextHours = combined.slice(startIndex, startIndex + 12); 

                    for (let i = 0; i < nextHours.length; i++) {
                        let item = nextHours[i];
                        let t = parseInt(item.time) / 100;
                        hList.push({
                            time: (t < 10 ? "0" + t : t) + ":00",
                            temp: item.tempC + "°",
                            icon: weatherTab.mapWeatherIcon(item.weatherCode)
                        });
                    }
                    weatherTab.hourlyForecast = hList;
                    
                    // --- Tages-Vorhersage ---
                    let dList = [];
                    let wochenTage = ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"];
                    for (let i = 0; i < json.weather.length; i++) {
                        let day = json.weather[i];
                        let dateObj = new Date(day.date);
                        let dayName = wochenTage[dateObj.getDay()];
                        if (i === 0) dayName = "Heute";
                        if (i === 1) dayName = "Morgen";

                        dList.push({
                            time: dayName,
                            temp: day.mintempC + "°/" + day.maxtempC + "°",
                            icon: weatherTab.mapWeatherIcon(day.hourly[4].weatherCode) 
                        });
                    }
                    weatherTab.dailyForecast = dList;
                    
                    // INITIALES UPDATE AUSLÖSEN
                    weatherTab.updateCarousel();
                    
                    jsonBuffer = "";
                } catch(e) { }
            }
        }
    }
    
    Timer { id: weatherTimer; interval: 600000; onTriggered: weatherProcess.running = true }

    // === UI LAYOUT (NACH SKIZZE) ===
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spc2
        spacing: Theme.spc2 * 2

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spc2
            component DetailBox : Rectangle {
                id: boxRoot 
                property string titleText
                property string valueText
                Layout.fillWidth: true 
                Layout.preferredHeight: 65
                color: Theme.bg1
                radius: Theme.rad
                border { width: 1; color: Theme.bg2 }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { 
                        text: boxRoot.titleText; // Greift jetzt sicher auf die Box zu
                        font.family: Theme.fnt; 
                        font.pixelSize: Theme.t4; 
                        color: Theme.ac2
                        Layout.alignment: Qt.AlignHCenter 
                    }
                    Text { 
                        text: boxRoot.valueText; // Greift jetzt sicher auf die Box zu
                        font.family: Theme.fnt; 
                        font.pixelSize: Theme.t1; 
                        font.bold: true;
                        color: Theme.fg0; 
                        Layout.alignment: Qt.AlignHCenter 
                    }
                }
            }

            // Die Boxen werden jetzt korrekt befüllt!
            DetailBox { titleText: "Gefühlt"; valueText: weatherTab.feelsLike }
            DetailBox { titleText: "Wind"; valueText: weatherTab.wind }
            DetailBox { titleText: "Feuchtigkeit"; valueText: weatherTab.humidity }
            DetailBox { titleText: "Quelle"; valueText: "wttr.in" }
        }

        // --- ZEILE 2: Hauptwetter (Zentriert) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.spc2 * 4 // Viel Platz zwischen Icon und Text

            Text {
                text: weatherTab.weatherIcon
                font.family: Theme.fnt
                font.pixelSize: 130
                color: Theme.ac1
                Layout.alignment: Qt.AlignVCenter
            }
            
            RowLayout {
                spacing: Theme.spc2 * 2
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: weatherTab.temp
                    font { family: Theme.fnt; pixelSize: 48; bold: true }
                    color: Theme.fg0
                }
                Text {
                    text: weatherTab.desc
                    font { family: Theme.fnt; pixelSize: 32 }
                    color: Theme.ac1
                }
            }
        }
        Item { Layout.fillHeight: true } 
// --- ZEILE 3: Header für Karussell (Aufgang, Modus, Untergang) ---
        RowLayout {
            Layout.fillWidth: true
            
            Text { 
                text: "  " + weatherTab.sunrise
                font { family: Theme.fnt; pixelSize: Theme.t2 }
                color: Theme.fg0
            }
            
            Item { Layout.fillWidth: true } // SPACER 1: Drückt nach links/Mitte
            // Zentrierter Modus-Indikator
            RowLayout {
                spacing: 8
                Text { text: "◀"; font.pixelSize: 12; color: weatherTab.scrollIndex > 0 ? Theme.ac1 : Theme.bg2; visible: weatherTab.isFocused }
                Text { 
                    text: weatherTab.viewMode === 0 ? "24 Stunden" : "Tagesvorschau"
                    font { family: Theme.fnt; pixelSize: Theme.t2; bold: weatherTab.isFocused }
                    color: weatherTab.isFocused ? Theme.ac1 : Theme.ac1
                }
                Text { 
                    // Versteckt den rechten Pfeil, wenn wir am Ende angekommen sind (oder bei 3 Tagen)
                    property int maxS: Math.max(0, (weatherTab.viewMode === 0 ? weatherTab.hourlyForecast.length : weatherTab.dailyForecast.length) - 4)
                    text: "▶"; font.pixelSize: 12; color: weatherTab.scrollIndex < maxS ? Theme.ac1 : Theme.bg2; visible: weatherTab.isFocused 
                }
            }

            Item { Layout.fillWidth: true } // SPACER 2: Drückt nach Mitte/rechts

            Text { 
                text: "  " + weatherTab.sunset
                font { family: Theme.fnt; pixelSize: Theme.t2 }
                color: Theme.fg0
            }
        }
        // --- ZEILE 4: Das 4-Kachel Karussell ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            spacing: Theme.spc2

            Repeater {
                model: weatherTab.visibleForecast // Zeigt immer exakt 4 Kacheln an
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg1
                    radius: Theme.rad
                    border { width: 1; color: weatherTab.isFocused ? Theme.ac2 : Theme.bg2 } // Kacheln leuchten leicht auf bei Fokus

                    ColumnLayout {
                        anchors.fill: parent

			Item {
			    Layout.fillHeight: true
			}
                        
                        Text { 
                            text: modelData.time
                            font { family: Theme.fnt; pixelSize: Theme.t2 }
                            color: Theme.ac1
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Text { 
                            text: modelData.icon
                            font { family: Theme.fnt; pixelSize: 25 }
                            color: Theme.ac1
                            Layout.alignment: Qt.AlignHCenter 
                        }
                        
                        Text { 
                            text: modelData.temp
                            font { family: Theme.fnt; pixelSize: Theme.t1; bold: true }
                            color: Theme.fg0
                            Layout.alignment: Qt.AlignHCenter 
                        }
			Item {
			    Layout.fillHeight: true
			}
                    }
                }
            }
        }
    }
}
