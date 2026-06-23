package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@SpringBootApplication
@RestController
@RequestMapping("/api/load")
public class SyntheticLoadApplication {

    // Volatile prevents the JIT from optimizing away our CPU math loop
    private volatile double blackhole = 0;

    public static void main(String[] args) {
        SpringApplication.run(SyntheticLoadApplication.class, args);
    }

    /**
     * Burns CPU for a specified number of seconds.
     * Accessible at: GET /api/load/cpu?seconds=30
     */
    @GetMapping("/cpu")
    public String burnCpu(@RequestParam(defaultValue = "10") int seconds) {
        long durationMs = seconds * 1000L;
        long startTime = System.currentTimeMillis();
        long ops = 0;

        while ((System.currentTimeMillis() - startTime) < durationMs) {
            // Expensive math operation to keep the CPU saturated
            for (int i = 0; i < 1000; i++) {
                blackhole += Math.sqrt(Math.PI * i) / Math.sin(i + 1);
                ops++;
            }
        }

        return String.format("CPU Burn complete. Duration: %d seconds. Operations: %d. Blackhole state: %f",
                seconds, ops, blackhole);
    }

    /**
     * Allocates garbage objects on the heap to trigger GC and show up in TLAB profiling.
     * Accessible at: GET /api/load/memory?seconds=30
     */
    @GetMapping("/memory")
    public String burnMemory(@RequestParam(defaultValue = "10") int seconds) {
        long durationMs = seconds * 1000L;
        long startTime = System.currentTimeMillis();

        // A bounded collection to hold references so they escape analysis and hit the heap,
        // but clears itself out so we don't cause an actual OutOfMemoryError.
        List<String> retentionBuffer = new ArrayList<>(10000);
        long allocatedChunks = 0;

        while ((System.currentTimeMillis() - startTime) < durationMs) {
            if (retentionBuffer.size() > 5000) {
                retentionBuffer.clear(); // Release references to simulate GC churn
            }

            // Generating UUIDs creates a fair amount of byte[] and String allocation noise
            retentionBuffer.add(UUID.randomUUID().toString() + "-" + System.nanoTime());
            allocatedChunks++;

            // Tiny sleep to prevent locking up the entire JVM while we allocate
            if (allocatedChunks % 1000 == 0) {
                try {
                    Thread.sleep(1);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }

        return String.format("Memory Burn complete. Duration: %d seconds. Allocated %d objects.",
                seconds, allocatedChunks);
    }
}