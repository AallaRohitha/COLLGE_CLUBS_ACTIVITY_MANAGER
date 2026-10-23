package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Student: register for an event with a registration form, or cancel.
@WebServlet("/eventRegisterAction")
public class EventRegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession();
        int myId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("role");
        String action = req.getParameter("action");
        int eventId = Integer.parseInt(req.getParameter("eventId"));

        if ("admin".equals(role)) {
            go(res, "events.jsp", "msg", "Admin cannot register for events");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            if ("cancel".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM event_registrations WHERE event_id = ? AND user_id = ?")) {
                    ps.setInt(1, eventId);
                    ps.setInt(2, myId);
                    ps.executeUpdate();
                }
                go(res, "myEvents.jsp", "ok", "Registration cancelled");
                return;
            }

            // ---- read and check the registration form ----
            String rollNo = req.getParameter("rollNo").trim().toUpperCase();
            String branch = req.getParameter("branch");
            String year   = req.getParameter("year");
            String phone  = req.getParameter("phone").trim();
            String back = "registerEvent.jsp?id=" + eventId;

            if (rollNo.isEmpty() || rollNo.length() > 20 || !phone.matches("\\d{10}")
                    || !year.matches("[1-4]") || branch == null || branch.isEmpty()) {
                go(res, back, "msg", "Please fill all fields correctly (phone must be 10 digits)");
                return;
            }

            // ---- lock the event row so two students cannot take the last seat together ----
            con.setAutoCommit(false);
            try {
                int maxSeats;
                boolean past;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT max_seats, CASE WHEN event_date < TRUNC(SYSDATE) THEN 1 ELSE 0 END "
                      + "FROM events WHERE event_id = ? FOR UPDATE")) {
                    ps.setInt(1, eventId);
                    ResultSet rs = ps.executeQuery();
                    if (!rs.next()) {
                        con.rollback();
                        go(res, "events.jsp", "msg", "Event not found");
                        return;
                    }
                    maxSeats = rs.getInt(1);
                    past = rs.getInt(2) == 1;
                }
                if (past) {
                    con.rollback();
                    go(res, "events.jsp", "msg", "This event is already over");
                    return;
                }
                int taken;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM event_registrations WHERE event_id = ?")) {
                    ps.setInt(1, eventId);
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    taken = rs.getInt(1);
                }
                if (taken >= maxSeats) {
                    con.rollback();
                    go(res, "events.jsp", "msg", "Sorry, this event is full");
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO event_registrations (reg_id, event_id, user_id, roll_no, branch, year, phone) "
                      + "VALUES (regs_seq.NEXTVAL, ?, ?, ?, ?, ?, ?)")) {
                    ps.setInt(1, eventId);
                    ps.setInt(2, myId);
                    ps.setString(3, rollNo);
                    ps.setString(4, branch);
                    ps.setInt(5, Integer.parseInt(year));
                    ps.setString(6, phone);
                    ps.executeUpdate();
                }
                con.commit();
                go(res, "myEvents.jsp", "ok", "You are registered for the event");

            } catch (SQLException e) {
                con.rollback();
                if (e.getErrorCode() == 1) {          // unique rule: already registered
                    go(res, "events.jsp", "msg", "You are already registered for this event");
                } else {
                    throw e;
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "events.jsp", "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String page, String key, String text) throws IOException {
        String sep = page.contains("?") ? "&" : "?";
        res.sendRedirect(page + sep + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
