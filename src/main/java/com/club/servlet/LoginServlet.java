package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.PasswordUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String email = req.getParameter("email").trim().toLowerCase();
        String password = req.getParameter("password");

        String sql = "SELECT user_id, name, role FROM users WHERE email = ? AND password = ?";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setString(2, PasswordUtil.hash(password));
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                // New session after login (safer)
                HttpSession old = req.getSession(false);
                if (old != null) old.invalidate();
                HttpSession session = req.getSession(true);

                String role = rs.getString("role");
                session.setAttribute("userId", rs.getInt("user_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("role", role);
                session.setMaxInactiveInterval(30 * 60);
                session.setAttribute("loginTime", new java.text.SimpleDateFormat("dd MMM, hh:mm a").format(new java.util.Date()));

                // Different page for each role
                if ("admin".equals(role)) {
                    res.sendRedirect("adminDashboard.jsp");
                } else if ("coordinator".equals(role)) {
                    res.sendRedirect("coordinatorDashboard.jsp");
                } else {
                    res.sendRedirect("dashboard.jsp");
                }
            } else {
                res.sendRedirect("login.jsp?msg=" + URLEncoder.encode("Invalid email or password", "UTF-8"));
            }
        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("login.jsp?msg=" + URLEncoder.encode("Something went wrong. Try again.", "UTF-8"));
        }
    }
}
