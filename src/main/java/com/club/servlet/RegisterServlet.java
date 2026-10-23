package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.PasswordUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String name = req.getParameter("name").trim();
        String email = req.getParameter("email").trim().toLowerCase();
        String password = req.getParameter("password");

        if (password.length() < 6) {
            res.sendRedirect("register.jsp?msg=" + URLEncoder.encode("Password must be at least 6 characters", "UTF-8"));
            return;
        }

        String sql = "INSERT INTO users (user_id, name, email, password, role) "
                   + "VALUES (users_seq.NEXTVAL, ?, ?, ?, 'student')";

        try (Connection con = DBUtil.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, PasswordUtil.hash(password));
            ps.executeUpdate();
            res.sendRedirect("login.jsp?ok=" + URLEncoder.encode("Account created. Please login.", "UTF-8"));
        } catch (java.sql.SQLIntegrityConstraintViolationException e) {
            res.sendRedirect("register.jsp?msg=" + URLEncoder.encode("This email is already registered", "UTF-8"));
        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect("register.jsp?msg=" + URLEncoder.encode("Something went wrong. Try again.", "UTF-8"));
        }
    }
}
