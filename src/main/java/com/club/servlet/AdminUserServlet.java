package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Admin: demote a coordinator, or delete a user.
// (Coordinators are now chosen from the approved members of a club, in Manage Clubs.)
@WebServlet("/adminUserAction")
public class AdminUserServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        int userId = Integer.parseInt(req.getParameter("userId"));
        String message;

        try (Connection con = DBUtil.getConnection()) {

            if ("demote".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE users SET role = 'student' WHERE user_id = ? AND role = 'coordinator'")) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE clubs SET coordinator_id = NULL WHERE coordinator_id = ?")) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                message = "Coordinator changed back to student";

            } else if ("delete".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM users WHERE user_id = ? AND role <> 'admin'")) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                message = "User deleted";

            } else {
                message = "To make a coordinator, open Manage Clubs, edit the club and choose one of its approved members";
            }
            res.sendRedirect("adminUsers.jsp?ok=" + URLEncoder.encode(message, "UTF-8"));

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("adminUsers.jsp?msg=" + URLEncoder.encode("Something went wrong", "UTF-8"));
        }
    }
}
