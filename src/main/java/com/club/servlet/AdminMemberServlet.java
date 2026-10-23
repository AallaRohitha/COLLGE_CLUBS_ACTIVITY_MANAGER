package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Admin: approve / reject join requests of ANY club, or remove a member.
// (Coordinators can do the same for their own club.)
@WebServlet("/adminMemberAction")
public class AdminMemberServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        int memberId = Integer.parseInt(req.getParameter("memberId"));
        String message;

        try (Connection con = DBUtil.getConnection()) {

            if ("approve".equals(action) || "reject".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement("UPDATE club_members SET status = ? WHERE member_id = ?")) {
                    ps.setString(1, "approve".equals(action) ? "approved" : "rejected");
                    ps.setInt(2, memberId);
                    ps.executeUpdate();
                }
                message = "approve".equals(action) ? "Member approved" : "Request rejected";

            } else if ("remove".equals(action)) {
                // a coordinator cannot be removed from his own club
                int isCoord;
                try (PreparedStatement ps = con.prepareStatement(
                        "SELECT COUNT(*) FROM club_members m JOIN clubs c ON c.club_id = m.club_id AND c.coordinator_id = m.user_id "
                      + "WHERE m.member_id = ?")) {
                    ps.setInt(1, memberId);
                    ResultSet rs = ps.executeQuery();
                    rs.next();
                    isCoord = rs.getInt(1);
                }
                if (isCoord > 0) {
                    go(res, "msg", "This student is the coordinator. Change the coordinator in Manage Clubs first.");
                    return;
                }
                try (PreparedStatement ps = con.prepareStatement("DELETE FROM club_members WHERE member_id = ?")) {
                    ps.setInt(1, memberId);
                    ps.executeUpdate();
                }
                message = "Member removed";
            } else {
                message = "Unknown action";
            }
            go(res, "ok", message);

        } catch (Exception e) {
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("adminMembers.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
