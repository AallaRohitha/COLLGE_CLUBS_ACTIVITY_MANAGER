package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Student: send a join request (registration form), or cancel / leave a club.
@WebServlet("/joinClubAction")
public class JoinClubServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        int userId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("role");
        String action = req.getParameter("action");
        int clubId = Integer.parseInt(req.getParameter("clubId"));

        if ("admin".equals(role)) {
            go(res, "clubs.jsp", "msg", "Admin cannot join clubs");
            return;
        }

        try (Connection con = DBUtil.getConnection()) {

            // The coordinator of a club cannot join that club
            try (PreparedStatement chk = con.prepareStatement(
                    "SELECT COUNT(*) FROM clubs WHERE club_id = ? AND coordinator_id = ?")) {
                chk.setInt(1, clubId);
                chk.setInt(2, userId);
                ResultSet rs0 = chk.executeQuery();
                rs0.next();
                if (rs0.getInt(1) > 0) {
                    go(res, "clubs.jsp", "msg", "You are the coordinator of this club");
                    return;
                }
            }

            // ---- Cancel request / leave club ----
            if ("cancel".equals(action)) {
                PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM club_members WHERE club_id = ? AND user_id = ?");
                ps.setInt(1, clubId);
                ps.setInt(2, userId);
                ps.executeUpdate();
                go(res, "myClubs.jsp", "ok", "Done. Your membership entry was removed.");
                return;
            }

            // ---- Join request ----
            String rollNo = req.getParameter("rollNo").trim().toUpperCase();
            String branch = req.getParameter("branch");
            String year   = req.getParameter("year");
            String phone  = req.getParameter("phone").trim();
            String reason = req.getParameter("reason").trim();

            if (rollNo.isEmpty() || rollNo.length() > 20 || !phone.matches("\\d{10}")
                    || !year.matches("[1-4]") || reason.isEmpty()) {
                go(res, "joinClub.jsp?id=" + clubId, "msg", "Please fill all fields correctly (phone must be 10 digits)");
                return;
            }

            // If the student was rejected before, allow applying again
            PreparedStatement up = con.prepareStatement(
                "UPDATE club_members SET roll_no = ?, branch = ?, year = ?, phone = ?, reason = ?, "
              + "status = 'pending', joined_date = SYSDATE "
              + "WHERE club_id = ? AND user_id = ? AND status = 'rejected'");
            up.setString(1, rollNo);
            up.setString(2, branch);
            up.setInt(3, Integer.parseInt(year));
            up.setString(4, phone);
            up.setString(5, reason);
            up.setInt(6, clubId);
            up.setInt(7, userId);
            int changed = up.executeUpdate();

            if (changed == 0) {
                try {
                    PreparedStatement ins = con.prepareStatement(
                        "INSERT INTO club_members (member_id, club_id, user_id, roll_no, branch, year, phone, reason, status) "
                      + "VALUES (members_seq.NEXTVAL, ?, ?, ?, ?, ?, ?, ?, 'pending')");
                    ins.setInt(1, clubId);
                    ins.setInt(2, userId);
                    ins.setString(3, rollNo);
                    ins.setString(4, branch);
                    ins.setInt(5, Integer.parseInt(year));
                    ins.setString(6, phone);
                    ins.setString(7, reason);
                    ins.executeUpdate();
                } catch (SQLException dup) {
                    if (dup instanceof SQLIntegrityConstraintViolationException && dup.getErrorCode() == 1) {
                        go(res, "clubs.jsp", "msg", "You have already applied to this club");
                        return;
                    }
                    throw dup;
                }
            }
            go(res, "myClubs.jsp", "ok", "Request sent. The coordinator will review it.");

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "clubs.jsp", "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String page, String key, String text) throws IOException {
        String sep = page.contains("?") ? "&" : "?";
        res.sendRedirect(page + sep + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
