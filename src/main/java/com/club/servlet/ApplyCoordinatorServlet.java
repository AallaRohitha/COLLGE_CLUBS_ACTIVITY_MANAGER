package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Student: apply to become the coordinator of a club, or cancel the application.
// (URL does not start with /coordinator, so students are allowed in.)
@WebServlet("/applyCoordinatorAction")
public class ApplyCoordinatorServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession();
        int myId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("role");
        String action = req.getParameter("action");
        int clubId = Integer.parseInt(req.getParameter("clubId"));

        if (!"student".equals(role)) {
            go(res, "msg", "Only students can apply");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            if ("cancel".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM coordinator_requests WHERE user_id = ? AND club_id = ? AND status = 'pending'")) {
                    ps.setInt(1, myId);
                    ps.setInt(2, clubId);
                    ps.executeUpdate();
                }
                go(res, "ok", "Application cancelled");
                return;
            }

            String reason = req.getParameter("reason").trim();
            if (reason.isEmpty()) {
                go(res, "msg", "Please write why you want to be the coordinator");
                return;
            }

            // Club must exist and must not have a coordinator yet
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM clubs WHERE club_id = ? AND coordinator_id IS NULL")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                rs.next();
                if (rs.getInt(1) == 0) {
                    go(res, "msg", "This club already has a coordinator");
                    return;
                }
            }

            // The student must be an approved member of this club
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM club_members WHERE user_id = ? AND club_id = ? AND status = 'approved'")) {
                ps.setInt(1, myId);
                ps.setInt(2, clubId);
                ResultSet rs = ps.executeQuery();
                rs.next();
                if (rs.getInt(1) == 0) {
                    go(res, "msg", "You must be an approved member of this club before you can apply");
                    return;
                }
            }

            // Applying again after a rejection
            int changed;
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE coordinator_requests SET reason = ?, status = 'pending', req_date = SYSDATE "
                  + "WHERE user_id = ? AND club_id = ? AND status = 'rejected'")) {
                ps.setString(1, reason);
                ps.setInt(2, myId);
                ps.setInt(3, clubId);
                changed = ps.executeUpdate();
            }
            if (changed == 0) {
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO coordinator_requests (req_id, user_id, club_id, reason) VALUES (req_seq.NEXTVAL, ?, ?, ?)")) {
                    ps.setInt(1, myId);
                    ps.setInt(2, clubId);
                    ps.setString(3, reason);
                    ps.executeUpdate();
                } catch (SQLException dup) {
                    if (dup.getErrorCode() == 1) {
                        go(res, "msg", "You have already applied for this club");
                        return;
                    }
                    throw dup;
                }
            }
            go(res, "ok", "Application sent. The admin will review it.");

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("applyCoordinator.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
