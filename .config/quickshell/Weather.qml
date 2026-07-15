pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var data: null
    property string error: ""
    property alias fahrenheit: state.fahrenheit

    readonly property FileView stateFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/weather.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: state

            property bool fahrenheit: false
        }
    }

    readonly property var cur: data?.current_condition?.[0] ?? null
    readonly property var area: data?.nearest_area?.[0] ?? null

    readonly property string glyph: cur ? glyphFor(parseInt(cur.weatherCode)) : "󰖐"
    readonly property string temp: cur ? cur[fahrenheit ? "temp_F" : "temp_C"] + "°" : "--°"
    readonly property string condition: cur ? cur.weatherDesc[0].value.toLowerCase() : "loading"
    readonly property string feels: cur ? cur[fahrenheit ? "FeelsLikeF" : "FeelsLikeC"] + "°" : "--"
    readonly property string humidity: cur ? cur.humidity + "%" : "--"
    readonly property string wind: cur
        ? cur[fahrenheit ? "windspeedMiles" : "windspeedKmph"] + (fahrenheit ? "mph " : "km/h ") + cur.winddir16Point
        : "--"

    readonly property string location: {
        if (!area)
            return "...";
        const name = area.areaName[0].value;
        const region = area.region[0].value;
        let country = area.country[0].value;
        if (country === "United States of America")
            country = "US";
        else if (country === "United Kingdom")
            country = "UK";
        return region && region !== name
            ? name + ", " + region + ", " + country
            : name + ", " + country;
    }

    // wttr.in WWO weather codes -> nerd font glyph
    function glyphFor(code) {
        const night = new Date().getHours() < 6 || new Date().getHours() >= 20;
        if (code === 113)
            return night ? "󰖔" : "󰖙";
        if (code === 116)
            return "󰖕";
        if ([119, 122].includes(code))
            return "󰖐";
        if ([143, 248, 260].includes(code))
            return "󰖑";
        if ([176, 263, 266, 281, 284, 293, 296, 353].includes(code))
            return "󰖗";
        if ([299, 302, 305, 308, 311, 314, 356, 359].includes(code))
            return "󰖖";
        if ([200, 386, 389, 392, 395].includes(code))
            return "󰖓";
        if (code >= 179)
            return "󰖘";
        return "󰖐";
    }

    // forecast day i (0-2): { name, glyph, hi, lo }
    function day(i) {
        if (!data)
            return { name: "--", glyph: "󰖐", hi: "--°", lo: "--°" };
        const d = data.weather[i];
        let name;
        if (i === 0) {
            name = "today";
        } else if (i === 1) {
            name = "tomorrow";
        } else {
            const dt = new Date();
            dt.setDate(dt.getDate() + i);
            name = dt.toLocaleDateString(Qt.locale("en_US"), "ddd").toLowerCase();
        }
        return {
            name: name,
            glyph: glyphFor(parseInt(d.hourly[4].weatherCode)),
            hi: d[fahrenheit ? "maxtempF" : "maxtempC"] + "°",
            lo: d[fahrenheit ? "mintempF" : "mintempC"] + "°"
        };
    }

    function reload() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    root.data = JSON.parse(xhr.responseText);
                    root.error = "";
                } catch (e) {
                    root.error = "bad response from wttr.in";
                }
            } else {
                root.error = "couldn't reach wttr.in";
            }
        };
        xhr.open("GET", "https://wttr.in/?format=j1");
        xhr.send();
    }

    readonly property Timer timer: Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reload()
    }
}
