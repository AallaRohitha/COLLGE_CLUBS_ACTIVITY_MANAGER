package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.EventAccess;
import com.club.util.UploadUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import java.util.Objects;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Add, edit and delete events (with an optional image).
//   add / edit : coordinator or approved member of the club
//   delete     : coordinator only
@MultipartConfig(maxFileSize = 2 * 1024 * 1024, maxRequestSize = 3 * 1024 * 1024)
@WebServlet("/eventAction")
public class EventServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int myId = (Integer) req.getSession().getAttribute("userId");

        try (Connection con = DBUtil.getConnection()) {
            String action = req.getParameter("action");

            // ---------- DELETE ----------
            if ("delete".equals(action)) {
                int eventId = Integer.parseInt(req.getParameter("eventId"));
                int clubId = EventAccess.clubOfEvent(con, eventId);
                if (clubId == -1 || !EventAccess.isCoordinator(con, myId, clubId)) {
                    go(res, "msg", "Only the club coordinator can delete events");
                    return;
                }
                String oldImage = currentImage(con, eventId);
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM events WHERE event_id = ?")) {
                    ps.setInt(1, eventId);
                    ps.executeUpdate();
                }
                UploadUtil.delete(oldImage);
                go(res, "ok", "Event deleted");
                return;
            }

            // ---------- ADD / UPDATE : read the form ----------
            String title = req.getParameter("title").trim();
            String desc = req.getParameter("description").trim();
            String venue = req.getParameter("venue").trim();
            Date eventDate;
            int seats;
            try {
                eventDate = Date.valueOf(req.getParameter("eventDate"));   // yyyy-MM-dd
                seats = Integer.parseInt(req.getParameter("maxSeats"));
            } catch (IllegalArgumentException e) {
                go(res, "msg", "Please enter a valid date and number of seats");
                return;
            }
            if (title.isEmpty() || venue.isEmpty() || seats < 1 || seats > 1000) {
                go(res, "msg", "Title, venue and seats (1 to 1000) are required");
                return;
            }
            Part img = req.getPart("image");
            boolean hasImg = img != null && img.getSize() > 0;

            if ("add".equals(action)) {
                int clubId = Integer.parseInt(req.getParameter("clubId"));
                if (!EventAccess.canManage(con, myId, clubId)) {
                    go(res, "msg", "You cannot add events for this club");
                    return;
                }
                int eventId;
                try (PreparedStatement ps = con.prepareStatement("SELECT events_seq.NEXTVAL FROM dual")) {
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    eventId = rs.getInt(1);
                }
                String fileName = hasImg ? UploadUtil.save(img, eventId) : null;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO events (event_id, club_id, title, description, event_date, venue, max_seats, image_file) "
                      + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)")) {
                    ps.setInt(1, eventId);
                    ps.setInt(2, clubId);
                    ps.setString(3, title);
                    ps.setString(4, desc);
                    ps.setDate(5, eventDate);
                    ps.setString(6, venue);
                    ps.setInt(7, seats);
                    ps.setString(8, fileName);
                    ps.executeUpdate();
                } catch (SQLException e) {
                    UploadUtil.delete(fileName);
                    throw e;
                }
                go(res, "ok", "Event added");

            } else if ("update".equals(action)) {
                int eventId = Integer.parseInt(req.getParameter("eventId"));
                int clubId = EventAccess.clubOfEvent(con, eventId);
                if (clubId == -1 || !EventAccess.canManage(con, myId, clubId)) {
                    go(res, "msg", "You cannot edit this event");
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM event_registrations WHERE event_id = ?")) {
                    ps.setInt(1, eventId);
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    if (seats < rs.getInt(1)) {
                        go(res, "msg", "Seats cannot be less than the " + rs.getInt(1) + " students already registered");
                        return;
                    }
                }
                String oldImage = currentImage(con, eventId);
                String newImage = oldImage;
                if (hasImg) {
                    newImage = UploadUtil.save(img, eventId);
                } else if ("1".equals(req.getParameter("removeImage"))) {
                    newImage = null;
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE events SET title = ?, description = ?, event_date = ?, venue = ?, max_seats = ?, image_file = ? "
                      + "WHERE event_id = ?")) {
                    ps.setString(1, title);
                    ps.setString(2, desc);
                    ps.setDate(3, eventDate);
                    ps.setString(4, venue);
                    ps.setInt(5, seats);
                    ps.setString(6, newImage);
                    ps.setInt(7, eventId);
                    ps.executeUpdate();
                }
                if (!Objects.equals(oldImage, newImage)) UploadUtil.delete(oldImage);
                go(res, "ok", "Event updated");
            }

        } catch (IllegalStateException e) {
            go(res, "msg", "Image is too large (maximum 2 MB)");
        } catch (IllegalArgumentException e) {
            go(res, "msg", e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private String currentImage(Connection con, int eventId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT image_file FROM events WHERE event_id = ?")) {
            ps.setInt(1, eventId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getString(1) : null;
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("manageEvents.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
