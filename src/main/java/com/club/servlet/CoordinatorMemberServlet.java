package com.club.servlet;

import com.club.util.DBUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Coordinator: approve / reject a join request, or remove a member.
// URL starts with /coordinator, so only coordinators can use it.
@WebServlet("/coordinatorMemberAction")
public class CoordinatorMemberServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int myId = (Integer) req.getSession().getAttribute("userId");
        String action = req.getParameter("action");
        int memberId = Integer.parseInt(req.getParameter("memberId"));
        String message;

        try (Connection con = DBUtil.getConnection()) {

            // Find the coordinator's own club
            int clubId = -1;
            try (PreparedStatement ps = con.prepareStatement("SELECT club_id FROM clubs WHERE coordinator_id = ?")) {
                ps.setInt(1, myId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) clubId = rs.getInt(1);
            }
            if (clubId == -1) {
                go(res, "msg", "You do not manage any club yet");
                return;
            }

            // The "AND club_id = ?" makes sure a coordinator can only touch their own club
            if ("approve".equals(action) || "reject".equals(action)) {
                String newStatus = "approve".equals(action) ? "approved" : "rejected";
                try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE club_members SET status = ? WHERE member_id = ? AND club_id = ?")) {
                    ps.setString(1, newStatus);
                    ps.setInt(2, memberId);
                    ps.setInt(3, clubId);
                    ps.executeUpdate();
                }
                message = "approve".equals(action) ? "Member approved" : "Request rejected";

            } else if ("remove".equals(action)) {
                try (PreparedStatement ps = con.prepareStatement("SELECT user_id FROM club_members WHERE member_id = ? AND club_id = ?")) {
                    ps.setInt(1, memberId);
                    ps.setInt(2, clubId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next() && rs.getInt(1) == myId) {
                        go(res, "msg", "You cannot remove yourself while you are the coordinator");
                        return;
                    }
                }
                try (PreparedStatement ps = con.prepareStatement(
                        "DELETE FROM club_members WHERE member_id = ? AND club_id = ?")) {
                    ps.setInt(1, memberId);
                    ps.setInt(2, clubId);
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
        res.sendRedirect("coordinatorRequests.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
