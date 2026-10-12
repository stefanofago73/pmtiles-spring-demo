package com.example.pmtiles;

public record Device(String id, double latitude, double longitude, String status) {

    public boolean isWithinBbox(double minLon, double minLat, double maxLon, double maxLat) {
        return longitude >= minLon && longitude <= maxLon
                && latitude >= minLat && latitude <= maxLat;
    }
}
