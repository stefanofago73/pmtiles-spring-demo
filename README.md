# PMTiles + MapLibre + Spring Boot Demo

An interactive map rendered entirely from a **static file**: no tile server, no API key, no per-request cost. Spring Boot serves the PMTiles archive as a static resource; the browser fetches only the tiles it needs via HTTP range requests.

The demo works on a map of **Italy**: the basemap is an extract of Italy at zoom 0–6, the map opens centered on Rome, and the mock devices sit around Italian cities.

## What it does

- **Basemap**: vector tiles of Italy (zoom 0–6) from a [PMTiles](https://github.com/protomaps/PMTiles) archive, rendered client-side by [MapLibre GL JS](https://maplibre.org/) with [Protomaps](https://protomaps.com/) cartographic styles.
- **Device layer**: 500 mock IoT devices clustered around major Italian cities, served as GeoJSON from a Spring Boot REST endpoint (`/api/devices?bbox=...`), filtered by the current viewport.
- **No tile server, no database, no API key**: the JavaScript libraries, fonts and sprites are loaded from public CDNs.

## Prerequisites

- **Java 17+** (tested with 17 and 21)
- **pmtiles CLI**: to download the basemap tiles ([releases](https://github.com/protomaps/go-pmtiles/releases))

## Quick start

```bash
# 1. Clone the repository
git clone https://github.com/stefanofago73/pmtiles-spring-demo.git
cd pmtiles-spring-demo

# 2. Extract the Italy basemap (zoom 0-6, ~1.6 MB) from a Protomaps daily build
./download-tiles.sh

# 3. Run the application
./mvnw spring-boot:run

# 4. Open the map
open http://localhost:8080
```

### Windows

```cmd
git clone https://github.com/stefanofago73/pmtiles-spring-demo.git
cd pmtiles-spring-demo

download-tiles.cmd
mvnw.cmd spring-boot:run
```

Then open [http://localhost:8080](http://localhost:8080).

Both scripts extract Italy at zoom 0–6 by default. For more detail when zooming in, pass a higher zoom level, for example `./download-tiles.sh --maxzoom 8` or `download-tiles.cmd --maxzoom 8`: the file gets larger, and it keeps the same name.

## Downloading tiles manually

If you prefer not to use the script, install the [pmtiles CLI](https://github.com/protomaps/go-pmtiles/releases) and run the command below, which extracts the same Italy basemap the scripts produce, replacing `YYYYMMDD` with a build date from the last seven days (see [maps.protomaps.com/builds](https://maps.protomaps.com/builds)):

```bash
pmtiles extract \
  https://build.protomaps.com/YYYYMMDD.pmtiles \
  src/main/resources/static/data/planet_z6.pmtiles \
  --bbox=6.63,36.62,18.52,47.09 \
  --maxzoom=6
```

The bounding box `6.63,36.62,18.52,47.09` covers mainland Italy, Sicily and Sardinia; the southernmost islands, such as Lampedusa, fall outside it.

To use a different region, change the bounding box: in the manual command, or with the `BBOX` variable of `download-tiles.sh` (`download-tiles.cmd` always uses Italy). The mock devices and the initial view stay on Italy, so for another region you also need to change `center` in `app.js` and `CITY_CLUSTERS` in `DeviceController.java`. Some examples:

| Region | `--bbox` |
|---|---|
| Italy (default) | `6.63,36.62,18.52,47.09` |
| France | `-5.14,41.33,9.56,51.09` |
| Germany | `5.87,47.27,15.04,55.06` |
| Europe | `-10.0,35.0,40.0,72.0` |

Higher `--maxzoom` values produce larger files but more detail when zooming in.

## Project structure

```
pmtiles-spring-demo/
├── pom.xml                              # Spring Boot 3.3.10, Java 17
├── mvnw / mvnw.cmd                      # Maven wrapper
├── download-tiles.sh                    # Download PMTiles basemap (Linux/macOS)
├── download-tiles.cmd                   # Download PMTiles basemap (Windows)
├── src/main/
│   ├── java/com/example/pmtiles/
│   │   ├── PmtilesDemoApplication.java  # Spring Boot entry point
│   │   ├── Device.java                  # Device record
│   │   └── DeviceController.java        # /api/devices endpoint (mock data)
│   └── resources/
│       ├── application.properties
│       └── static/
│           ├── index.html               # Single-page map UI
│           ├── app.js                   # MapLibre + PMTiles setup
│           └── data/
│               └── planet_z6.pmtiles    # ← Italy extract, downloaded, not in git
└── src/test/
    └── java/com/example/pmtiles/
        ├── PmtilesDemoApplicationTests.java
        └── DeviceControllerTests.java
```

Despite its name, `planet_z6.pmtiles` contains only the Italy extract, not the whole planet.

## How it works

1. **PMTiles** is a single-file archive that packs an entire tile pyramid (header + directory + tile data) into one binary blob.
2. The **PMTiles JavaScript library** registers a custom protocol with MapLibre, translates z/x/y tile coordinates into byte offsets using the in-memory directory, and fetches each tile via an **HTTP range request** (`Range: bytes=start-end`).
3. **Spring Boot** serves the `.pmtiles` file as a static resource. Spring MVC's `ResourceHttpRequestHandler` answers `Range` requests with `206 Partial Content`, with no configuration needed.
4. The **/api/devices** endpoint returns a GeoJSON `FeatureCollection` of mock devices, filtered by bounding box. The frontend refreshes the layer on every `moveend` event.

## Running tests

```bash
./mvnw test
```

## Technology stack

| Component | Version | License |
|---|---|---|
| Spring Boot | 3.3.10 | Apache-2.0 |
| Java | 17+ | GPL-2.0 (OpenJDK) |
| MapLibre GL JS | 5.4.0 | BSD-3-Clause |
| PMTiles | 4.3.0 (JS) / spec v3 | BSD-3 / CC0 |
| Protomaps Basemaps | 5.7.2 | BSD-3 |

## License

MIT. See [LICENSE](LICENSE).

The MIT license covers the code only. The basemap data comes from the Protomaps builds of OpenStreetMap and is licensed under the [ODbL](https://opendatacommons.org/licenses/odbl/): the map shows the required attribution (Protomaps © OpenStreetMap).
