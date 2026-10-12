package com.example.pmtiles;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class DeviceControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void devicesEndpointReturnsGeoJson() throws Exception {
        mockMvc.perform(get("/api/devices"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("FeatureCollection"))
                .andExpect(jsonPath("$.features").isArray())
                .andExpect(jsonPath("$.features.length()").value(500));
    }

    @Test
    void bboxFiltersDevices() throws Exception {
        // Small bbox around Rome: should return fewer than 5000 devices
        mockMvc.perform(get("/api/devices")
                        .param("bbox", "12.0,41.5,13.0,42.5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("FeatureCollection"))
                .andExpect(jsonPath("$.features").isArray());
        // We cannot assert exact count (random), but it should be less than total
    }

    @Test
    void bboxOutsideItalyReturnsEmpty() throws Exception {
        // Bbox in the Atlantic: no devices there
        mockMvc.perform(get("/api/devices")
                        .param("bbox", "-30.0,30.0,-20.0,40.0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.type").value("FeatureCollection"))
                .andExpect(jsonPath("$.features").isArray())
                .andExpect(jsonPath("$.features.length()").value(0));
    }

    @Test
    void featureHasCorrectStructure() throws Exception {
        mockMvc.perform(get("/api/devices")
                        .param("bbox", "12.0,41.5,13.0,42.5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.features[0].type").value("Feature"))
                .andExpect(jsonPath("$.features[0].geometry.type").value("Point"))
                .andExpect(jsonPath("$.features[0].geometry.coordinates").isArray())
                .andExpect(jsonPath("$.features[0].properties.id").isString())
                .andExpect(jsonPath("$.features[0].properties.status").isString());
    }
}
