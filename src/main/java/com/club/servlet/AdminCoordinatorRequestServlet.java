package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Admin: approve or reject a coordinator application.
@WebServlet("/adminCoordinatorRequestAction")
public class AdminCoordinatorRequestServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        int reqId = Integer.parseInt(req.getParameter("reqId"));
        String message;

        try (Connection con = DBUtil.getConnection()) {
            con.setAutoCommit(false);
            try {
                if ("reject".equals(action)) {
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE coordinator_requests SET status = 'rejected' WHERE req_id = ? AND status = 'pending'")) {
                        ps.setInt(1, reqId);
                        ps.executeUpdate();
                    }
                    message = "Application rejected";

                } else if ("approve".equals(action)) {
                    int userId = -1, clubId = -1;
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT user_id, club_id FROM coordinator_requests WHERE req_id = ? AND status = 'pending' FOR UPDATE")) {
                        ps.setInt(1, reqId);
                        ResultSet rs = ps.executeQuery();
                        if (rs.next()) { userId = rs.getInt(1); clubId = rs.getInt(2); }
                    }
                    if (userId == -1) {
                        con.rollback();
                        go(res, "msg", "This application is no longer pending");
                        return;
                    }
                    // the club must still be free
                    boolean free;
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT coordinator_id FROM clubs WHERE club_id = ? FOR UPDATE")) {
                        ps.setInt(1, clubId);
                        ResultSet rs = ps.executeQuery();
                        free = rs.next() && rs.getObject(1) == null;
                    }
                    if (!free) {
                        con.rollback();
                        go(res, "msg", "This club already has a coordinator");
                        return;
                    }
                    // the student must still be an approved member of the club
                    boolean member;
                    try (PreparedStatement ps = con.prepareStatement(
                            "SELECT COUNT(*) FROM club_members WHERE user_id = ? AND club_id = ? AND status = 'approved'")) {
                        ps.setInt(1, userId);
                        ps.setInt(2, clubId);
                        ResultSet rs = ps.executeQuery();
                        rs.next();
                        member = rs.getInt(1) > 0;
                    }
                    if (!member) {
                        con.rollback();
                        go(res, "msg", "This student is not an approved member of the club");
                        return;
                    }
                    // the user must still be a plain student
                    boolean isStudent;
                    try (PreparedStatement ps = con.prepareStatement("SELECT role FROM users WHERE user_id = ?")) {
                        ps.setInt(1, userId);
                        ResultSet rs = ps.executeQuery();
                        isStudent = rs.next() && "student".equals(rs.getString(1));
                    }
                    if (!isStudent) {
                        con.rollback();
                        go(res, "msg", "This user is not a student any more");
                        return;
                    }

                    try (PreparedStatement ps = con.prepareStatement("UPDATE clubs SET coordinator_id = ? WHERE club_id = ?")) {
                        ps.setInt(1, userId); ps.setInt(2, clubId); ps.executeUpdate();
                    }
                    try (PreparedStatement ps = con.prepareStatement("UPDATE users SET role = 'coordinator' WHERE user_id = ?")) {
                        ps.setInt(1, userId); ps.executeUpdate();
                    }
                    try (PreparedStatement ps = con.prepareStatement("UPDATE coordinator_requests SET status = 'approved' WHERE req_id = ?")) {
                        ps.setInt(1, reqId); ps.executeUpdate();
                    }
                    // other pending applications for this club, or by this student, are closed
                    try (PreparedStatement ps = con.prepareStatement(
                            "UPDATE coordinator_requests SET status = 'rejected' "
                          + "WHERE status = 'pending' AND req_id <> ? AND (club_id = ? OR user_id = ?)")) {
                        ps.setInt(1, reqId); ps.setInt(2, clubId); ps.setInt(3, userId); ps.executeUpdate();
                    }
                    message = "Approved. The student is now the coordinator of this club.";
                } else {
                    message = "Unknown action";
                }
                con.commit();
                go(res, "ok", message);

            } catch (SQLException e) {
                con.rollback();
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("adminCoordinatorRequests.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
