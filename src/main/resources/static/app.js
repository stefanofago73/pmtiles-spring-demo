/**
 * PMTiles + MapLibre GL JS demo application.
 *
 * - Basemap tiles served from a local PMTiles file via HTTP range requests.
 * - Device markers loaded from /api/devices as GeoJSON, refreshed on every map move.
 * - No API keys, no tile server: the JavaScript libraries, fonts and sprites come from public CDNs.
 */

import maplibregl from "https://cdn.jsdelivr.net/npm/maplibre-gl@5.4.0/+esm";
import { Protocol, PMTiles } from "https://cdn.jsdelivr.net/npm/pmtiles@4.3.0/+esm";
import { layers, namedFlavor } from "https://cdn.jsdelivr.net/npm/@protomaps/basemaps@5.7.2/+esm";

// --- PMTiles protocol setup ---

const protocol = new Protocol();
maplibregl.addProtocol("pmtiles", protocol.tile);

const pmtiles = new PMTiles("/data/planet_z6.pmtiles");
protocol.add(pmtiles);

// --- Map initialization ---

const map = new maplibregl.Map({
    container: "map",
    center: [12.4964, 41.9028],    // Rome
    zoom: 5,
    style: {
        version: 8,
        glyphs: "https://protomaps.github.io/basemaps-assets/fonts/{fontstack}/{range}.pbf",
        sprite: "https://protomaps.github.io/basemaps-assets/sprites/v4/light",
        sources: {
            protomaps: {
                type: "vector",
                url: "pmtiles:///data/planet_z6.pmtiles",
                attribution: '<a href="https://protomaps.com">Protomaps</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            }
        },
        layers: layers("protomaps", namedFlavor("light"), { lang: "en" })
    }
});

map.addControl(new maplibregl.NavigationControl(), "top-right");

// --- Device layer ---

map.on("load", () => {

    // Add an empty GeoJSON source, populated after the first fetch
    map.addSource("devices", {
        type: "geojson",
        data: { type: "FeatureCollection", features: [] }
    });

    // Circle layer with data-driven color
    map.addLayer({
        id: "devices-circles",
        type: "circle",
        source: "devices",
        paint: {
            "circle-color": [
                "match", ["get", "status"],
                "online",  "#16a34a",
                "offline", "#dc2626",
                "#2563eb"
            ],
            "circle-radius": [
                "interpolate", ["linear"], ["zoom"],
                3, 3,
                8, 5,
                12, 7
            ],
            "circle-stroke-width": 1,
            "circle-stroke-color": "#ffffff"
        }
    });

    // Popup on click
    map.on("click", "devices-circles", (e) => {
        const props = e.features[0].properties;
        const coords = e.features[0].geometry.coordinates.slice();
        new maplibregl.Popup({ offset: 8 })
            .setLngLat(coords)
            .setHTML(`<strong>${props.id}</strong><br>Status: ${props.status}`)
            .addTo(map);
    });

    map.on("mouseenter", "devices-circles", () => {
        map.getCanvas().style.cursor = "pointer";
    });
    map.on("mouseleave", "devices-circles", () => {
        map.getCanvas().style.cursor = "";
    });

    // Fetch devices for the current viewport
    loadDevices();
    map.on("moveend", loadDevices);
});

// --- Data loading ---

async function loadDevices() {
    const bounds = map.getBounds();
    const bbox = [
        bounds.getWest().toFixed(4),
        bounds.getSouth().toFixed(4),
        bounds.getEast().toFixed(4),
        bounds.getNorth().toFixed(4)
    ].join(",");

    try {
        const response = await fetch(`/api/devices?bbox=${bbox}`);
        if (!response.ok) return;

        const geojson = await response.json();
        map.getSource("devices").setData(geojson);

        // Update device count in the info panel
        const countEl = document.getElementById("device-count");
        if (countEl) {
            countEl.textContent = geojson.features.length.toLocaleString();
        }
    } catch (err) {
        console.error("Failed to load devices:", err);
    }
}
