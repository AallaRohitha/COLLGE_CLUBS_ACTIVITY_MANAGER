package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Coordinator: post or delete announcements of their own club.
@WebServlet("/coordinatorAnnouncementAction")
public class AnnouncementServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int myId = (Integer) req.getSession().getAttribute("userId");
        String action = req.getParameter("action");

        try (Connection con = DBUtil.getConnection()) {

            int clubId = -1;
            try (PreparedStatement ps = con.prepareStatement("SELECT club_id FROM clubs WHERE coordinator_id = ?")) {
                ps.setInt(1, myId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) clubId = rs.getInt(1);
            }
            if (clubId == -1) {
                go(res, "msg", "You do not manage any club yet");
                return;
            }

            if ("add".equals(action)) {
                String title = req.getParameter("title").trim();
                String message = req.getParameter("message").trim();
                if (title.isEmpty() || message.isEmpty()) {
                    go(res, "msg", "Title and message are required");
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO announcements (ann_id, club_id, title, message) VALUES (ann_seq.NEXTVAL, ?, ?, ?)")) {
                    ps.setInt(1, clubId);
                    ps.setString(2, title);
                    ps.setString(3, message);
                    ps.executeUpdate();
                }
                go(res, "ok", "Announcement posted");

            } else if ("delete".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM announcements WHERE ann_id = ? AND club_id = ?")) {
                    ps.setInt(1, Integer.parseInt(req.getParameter("annId")));
                    ps.setInt(2, clubId);
                    ps.executeUpdate();
                }
                go(res, "ok", "Announcement deleted");
            }

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("coordinatorAnnouncements.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
