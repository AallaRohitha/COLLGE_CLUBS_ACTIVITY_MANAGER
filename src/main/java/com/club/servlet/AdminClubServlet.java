package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.UploadUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import java.util.Objects;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Admin: add a club or edit a club (with an optional club image).
// A coordinator can only be a student who is already an APPROVED MEMBER of that club.
@MultipartConfig(maxFileSize = 2 * 1024 * 1024, maxRequestSize = 3 * 1024 * 1024)
@WebServlet("/adminClubAction")
public class AdminClubServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String savedNew = null;      // image file saved during this request (deleted again if the database fails)
        boolean done = false;

        try (Connection con = DBUtil.getConnection()) {
            String action = req.getParameter("action");
            String name = req.getParameter("clubName").trim();
            String desc = req.getParameter("description").trim();
            if (name.isEmpty()) {
                go(res, "msg", "Club name is required");
                return;
            }
            Part img = req.getPart("image");
            boolean hasImg = img != null && img.getSize() > 0;

            // ---------- ADD ----------
            if ("add".equals(action)) {
                int clubId;
                try (PreparedStatement ps = con.prepareStatement("SELECT clubs_seq.NEXTVAL FROM dual")) {
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    clubId = rs.getInt(1);
                }
                String fileName = hasImg ? UploadUtil.save(img, "club", clubId) : null;
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO clubs (club_id, club_name, description, coordinator_id, image_file) VALUES (?, ?, ?, NULL, ?)")) {
                    ps.setInt(1, clubId);
                    ps.setString(2, name);
                    ps.setString(3, desc);
                    ps.setString(4, fileName);
                    ps.executeUpdate();
                } catch (SQLException e) {
                    UploadUtil.delete(fileName);
                    throw e;
                }
                go(res, "ok", "Club added. Assign a coordinator after students join and are approved.");
                return;
            }

            // ---------- UPDATE ----------
            int clubId = Integer.parseInt(req.getParameter("clubId"));
            String coord = req.getParameter("coordinatorId");
            Integer newCoord = (coord == null || coord.isEmpty()) ? null : Integer.valueOf(coord);

            con.setAutoCommit(false);
            try {
                Integer oldCoord;
                String oldImage;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT coordinator_id, image_file FROM clubs WHERE club_id = ? FOR UPDATE")) {
                    ps.setInt(1, clubId);
                    ResultSet rs = ps.executeQuery();
                    if (!rs.next()) {
                        con.rollback();
                        go(res, "msg", "Club not found");
                        return;
                    }
                    int v = rs.getInt(1);
                    oldCoord = rs.wasNull() ? null : v;
                    oldImage = rs.getString(2);
                }

                boolean changed = (newCoord == null) ? (oldCoord != null) : !newCoord.equals(oldCoord);

                if (newCoord != null && changed) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COUNT(*) FROM club_members WHERE club_id = ? AND user_id = ? AND status = 'approved'")) {
                        ps.setInt(1, clubId); ps.setInt(2, newCoord);
                        ResultSet rs = ps.executeQuery(); rs.next();
                        if (rs.getInt(1) == 0) {
                            con.rollback();
                            go(res, "msg", "The coordinator must be an approved member of this club");
                            return;
                        }
                    }
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COUNT(*) FROM clubs WHERE coordinator_id = ? AND club_id <> ?")) {
                        ps.setInt(1, newCoord); ps.setInt(2, clubId);
                        ResultSet rs = ps.executeQuery(); rs.next();
                        if (rs.getInt(1) > 0) {
                            con.rollback();
                            go(res, "msg", "That student already coordinates another club");
                            return;
                        }
                    }
                }

                String newImage = oldImage;
                if (hasImg) {
                    savedNew = UploadUtil.save(img, "club", clubId);
                    newImage = savedNew;
                } else if ("1".equals(req.getParameter("removeImage"))) {
                    newImage = null;
                }

                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE clubs SET club_name = ?, description = ?, coordinator_id = ?, image_file = ? WHERE club_id = ?")) {
                    ps.setString(1, name);
                    ps.setString(2, desc);
                    if (newCoord == null) ps.setNull(3, Types.NUMERIC); else ps.setInt(3, newCoord);
                    ps.setString(4, newImage);
                    ps.setInt(5, clubId);
                    ps.executeUpdate();
                }

                if (changed) {
                    if (oldCoord != null) {
                        try (PreparedStatement ps = con.prepareStatement(
                                "UPDATE users SET role = 'student' WHERE user_id = ? AND role = 'coordinator'")) {
                            ps.setInt(1, oldCoord); ps.executeUpdate();
                        }
                    }
                    if (newCoord != null) {
                        try (PreparedStatement ps = con.prepareStatement(
                                "UPDATE users SET role = 'coordinator' WHERE user_id = ? AND role = 'student'")) {
                            ps.setInt(1, newCoord); ps.executeUpdate();
                        }
                    }
                }
                con.commit();
                done = true;
                if (!Objects.equals(oldImage, newImage)) UploadUtil.delete(oldImage);
                go(res, "ok", "Club updated");

            } catch (SQLException e) {
                con.rollback();
                throw e;
            }

        } catch (IllegalStateException e) {
            cleanup(savedNew, done);
            go(res, "msg", "Image is too large (maximum 2 MB)");
        } catch (IllegalArgumentException e) {
            cleanup(savedNew, done);
            go(res, "msg", e.getMessage());
        } catch (Exception e) {
            cleanup(savedNew, done);
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void cleanup(String savedNew, boolean done) {
        if (savedNew != null && !done) UploadUtil.delete(savedNew);
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("adminClubs.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
