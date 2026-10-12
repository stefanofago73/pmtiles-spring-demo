package com.example.pmtiles;

/**
 * A simple device with a geographic position and a status.
 * Used to demonstrate overlaying application data on a PMTiles basemap.
 */
public record Device(String id, double latitude, double longitude, String status) {

    /**
     * Returns true if this device falls within the given bounding box.
     *
     * @param minLon western boundary
     * @param minLat southern boundary
     * @param maxLon eastern boundary
     * @param maxLat northern boundary
     */
    public boolean isWithinBbox(double minLon, double minLat, double maxLon, double maxLat) {
        return longitude >= minLon && longitude <= maxLon
                && latitude >= minLat && latitude <= maxLat;
    }
}
