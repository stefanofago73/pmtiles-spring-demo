package com.example.pmtiles;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * REST endpoint that returns mock IoT devices as a GeoJSON FeatureCollection.
 * <p>
 * Devices are clustered around major Italian cities using a Gaussian spread,
 * producing a realistic distribution instead of a uniform random scatter.
 * The {@code bbox} parameter filters the result to the current map viewport.
 */
@RestController
@RequestMapping("/api")
public class DeviceController {

    private static final int DEVICE_COUNT = 500;

    /**
     * City centers used as cluster seeds. Each device is placed near one of
     * these cities with a Gaussian offset (sigma ~0.15 degrees, roughly 15 km).
     * Larger cities get proportionally more devices.
     */
    private static final double[][] CITY_CLUSTERS = {
            // { latitude, longitude, relative weight }
            {45.4642, 9.1900, 4.0},    // Milano
            {41.9028, 12.4964, 4.0},   // Roma
            {40.8518, 14.2681, 3.0},   // Napoli
            {45.0703, 7.6869, 2.5},    // Torino
            {44.4949, 11.3426, 2.0},   // Bologna
            {43.7696, 11.2558, 1.5},   // Firenze
            {45.4384, 12.3267, 1.5},   // Venezia
            {38.1157, 13.3615, 1.5},   // Palermo
            {44.4056, 8.9463, 1.5},    // Genova
            {39.2238, 9.1217, 1.0},    // Cagliari
            {46.0667, 11.1167, 1.0},   // Trento
            {40.6400, 15.8050, 0.8},   // Potenza
            {42.3505, 13.3995, 0.8},   // L'Aquila
            {39.3088, 16.3464, 0.8},   // Cosenza
            {41.1171, 16.8719, 1.0},   // Bari
            {45.4064, 11.8768, 1.0},   // Verona
            {37.5079, 15.0830, 1.0},   // Catania
    };

    private final List<Device> devices;

    public DeviceController() {
        this.devices = generateDevices();
    }

    /**
     * Returns devices as a GeoJSON FeatureCollection, optionally filtered by bounding box.
     *
     * @param bbox comma-separated bounding box: minLon,minLat,maxLon,maxLat
     */
    @GetMapping("/devices")
    public Map<String, Object> getDevices(
            @RequestParam(required = false) String bbox) {

        List<Device> filtered = devices;

        if (bbox != null && !bbox.isBlank()) {
            String[] parts = bbox.split(",");
            if (parts.length == 4) {
                double minLon = Double.parseDouble(parts[0].trim());
                double minLat = Double.parseDouble(parts[1].trim());
                double maxLon = Double.parseDouble(parts[2].trim());
                double maxLat = Double.parseDouble(parts[3].trim());
                filtered = devices.stream()
                        .filter(d -> d.isWithinBbox(minLon, minLat, maxLon, maxLat))
                        .toList();
            }
        }

        return toFeatureCollection(filtered);
    }

    // --- GeoJSON serialization ---

    private Map<String, Object> toFeatureCollection(List<Device> list) {
        List<Map<String, Object>> features = list.stream()
                .map(this::toFeature)
                .toList();
        Map<String, Object> fc = new LinkedHashMap<>();
        fc.put("type", "FeatureCollection");
        fc.put("features", features);
        return fc;
    }

    private Map<String, Object> toFeature(Device device) {
        Map<String, Object> geometry = new LinkedHashMap<>();
        geometry.put("type", "Point");
        geometry.put("coordinates", List.of(device.longitude(), device.latitude()));

        Map<String, Object> properties = new LinkedHashMap<>();
        properties.put("id", device.id());
        properties.put("status", device.status());

        Map<String, Object> feature = new LinkedHashMap<>();
        feature.put("type", "Feature");
        feature.put("geometry", geometry);
        feature.put("properties", properties);
        return feature;
    }

    // --- Mock data generation ---

    private static List<Device> generateDevices() {
        Random rng = new Random(42); // fixed seed for reproducibility
        List<Device> list = new ArrayList<>(DEVICE_COUNT);
        String[] statuses = {"online", "offline"};

        // Compute total weight for proportional allocation
        double totalWeight = 0;
        for (double[] city : CITY_CLUSTERS) {
            totalWeight += city[2];
        }

        int generated = 0;
        for (double[] city : CITY_CLUSTERS) {
            // How many devices for this city (proportional to weight)
            int count = (int) Math.round((city[2] / totalWeight) * DEVICE_COUNT);
            // Last city gets the remainder to hit DEVICE_COUNT exactly
            if (city == CITY_CLUSTERS[CITY_CLUSTERS.length - 1]) {
                count = DEVICE_COUNT - generated;
            }

            double centerLat = city[0];
            double centerLon = city[1];

            for (int i = 0; i < count && generated < DEVICE_COUNT; i++) {
                String id = "DEV-%04d".formatted(generated + 1);
                // Gaussian spread: sigma ~0.15 degrees ≈ 15 km
                double lat = centerLat + rng.nextGaussian() * 0.15;
                double lon = centerLon + rng.nextGaussian() * 0.15;
                // 80% online, 20% offline
                String status = rng.nextDouble() < 0.8 ? statuses[0] : statuses[1];
                list.add(new Device(id, lat, lon, status));
                generated++;
            }
        }

        return List.copyOf(list);
    }
}
