package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.UploadUtil;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Shows an event image:  eventImage?id=<eventId>
@WebServlet("/eventImage")
public class ImageServlet extends HttpServlet {

    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        String name = null;
        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT image_file FROM events WHERE event_id = ?")) {
            ps.setInt(1, Integer.parseInt(req.getParameter("id")));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) name = rs.getString(1);
        } catch (Exception e) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        if (!UploadUtil.isSafeName(name)) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        File file = new File(UploadUtil.DIR, name);
        if (!file.exists()) {
            res.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        res.setContentType(name.endsWith(".png") ? "image/png" : "image/jpeg");
        res.setContentLengthLong(file.length());
        res.setHeader("Cache-Control", "private, max-age=3600");
        Files.copy(file.toPath(), res.getOutputStream());
    }
}
