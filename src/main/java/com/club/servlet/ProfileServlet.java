package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.PasswordUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Edit own name, or change own password.
@WebServlet("/profileAction")
public class ProfileServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession();
        int myId = (Integer) session.getAttribute("userId");
        String action = req.getParameter("action");

        try (Connection con = DBUtil.getConnection()) {

            if ("updateName".equals(action)) {
                String name = req.getParameter("name").trim();
                if (name.isEmpty() || name.length() > 100) {
                    go(res, "msg", "Please enter a valid name");
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement("UPDATE users SET name = ? WHERE user_id = ?")) {
                    ps.setString(1, name);
                    ps.setInt(2, myId);
                    ps.executeUpdate();
                }
                session.setAttribute("userName", name);      // menu shows the new name
                go(res, "ok", "Name updated");

            } else if ("changePassword".equals(action)) {
                String current = req.getParameter("currentPassword");
                String newPass = req.getParameter("newPassword");
                String confirm = req.getParameter("confirmPassword");

                if (newPass.length() < 6) {
                    go(res, "msg", "New password must be at least 6 characters");
                    return;
                }
                if (!newPass.equals(confirm)) {
                    go(res, "msg", "New password and confirm password do not match");
                    return;
                }
                int changed;
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE users SET password = ? WHERE user_id = ? AND password = ?")) {
                    ps.setString(1, PasswordUtil.hash(newPass));
                    ps.setInt(2, myId);
                    ps.setString(3, PasswordUtil.hash(current));
                    changed = ps.executeUpdate();
                }
                go(res, changed == 1 ? "ok" : "msg",
                       changed == 1 ? "Password changed" : "Current password is wrong");
            }

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("profile.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
