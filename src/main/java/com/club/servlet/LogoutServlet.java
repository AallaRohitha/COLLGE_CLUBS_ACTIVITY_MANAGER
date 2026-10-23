package com.club.servlet;

import java.io.IOException;
import java.net.URLEncoder;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/LogoutServlet")
public class LogoutServlet extends HttpServlet {
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        if ("1".equals(req.getParameter("expired"))) {
            res.sendRedirect("login.jsp?msg=" + URLEncoder.encode("Your session expired. Please login again.", "UTF-8"));
        } else {
            res.sendRedirect("login.jsp?ok=" + URLEncoder.encode("You have been logged out.", "UTF-8"));
        }
    }
}
