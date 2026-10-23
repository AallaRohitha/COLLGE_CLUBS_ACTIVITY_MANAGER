package com.club.util;

import jakarta.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

// Saves event and club images in a folder OUTSIDE the project, so they stay safe
// when the project is redeployed.
//   Windows folder:  C:\Users\<your name>\club_uploads
public class UploadUtil {

    public static final File DIR = new File(System.getProperty("user.home"), "club_uploads");

    // Saves the image. prefix is "event" or "club". Returns the new file name.
    // Accepts only real JPG or PNG files.
    public static String save(Part part, String prefix, int id) throws IOException {
        String ext;
        try (InputStream in = part.getInputStream()) {
            byte[] h = in.readNBytes(8);
            if (h.length >= 3 && (h[0] & 0xFF) == 0xFF && (h[1] & 0xFF) == 0xD8 && (h[2] & 0xFF) == 0xFF) {
                ext = "jpg";
            } else if (h.length >= 4 && (h[0] & 0xFF) == 0x89 && h[1] == 'P' && h[2] == 'N' && h[3] == 'G') {
                ext = "png";
            } else {
                throw new IllegalArgumentException("Image must be a JPG or PNG file");
            }
        }
        Files.createDirectories(DIR.toPath());
        String name = prefix + "_" + id + "_" + System.currentTimeMillis() + "." + ext;
        try (InputStream in = part.getInputStream()) {
            Files.copy(in, new File(DIR, name).toPath(), StandardCopyOption.REPLACE_EXISTING);
        }
        return name;
    }

    // old name, still used for events
    public static String save(Part part, int eventId) throws IOException {
        return save(part, "event", eventId);
    }

    public static boolean isSafeName(String name) {
        return name != null && name.matches("(event|club)_\\d+_\\d+\\.(jpg|png)");
    }

    public static void delete(String name) {
        if (isSafeName(name)) new File(DIR, name).delete();
    }
}
