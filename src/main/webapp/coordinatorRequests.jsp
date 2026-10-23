<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    String clubName = null;
    StringBuilder pending = new StringBuilder();
    StringBuilder members = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        int clubId = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT club_id, club_name FROM clubs WHERE coordinator_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { clubId = rs.getInt(1); clubName = rs.getString(2); }
        }
        if (clubName != null) {
            String sql = "SELECT m.member_id, u.name, u.email, m.roll_no, m.branch, m.year, m.phone, m.reason, " +
                         "TO_CHAR(m.joined_date, 'DD Mon YYYY'), m.status " +
                         "FROM club_members m JOIN users u ON u.user_id = m.user_id " +
                         "WHERE m.club_id = ? AND m.status IN ('pending', 'approved') ORDER BY m.joined_date";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    int mid = rs.getInt(1);
                    String branchYear = Html.esc(rs.getString(5)) + " / Year " + rs.getInt(6);
                    if ("pending".equals(rs.getString(10))) {
                        pending.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b><br><small>" + Html.esc(rs.getString(3)) + "</small></td>"
                            + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                            + "<td>" + branchYear + "</td>"
                            + "<td>" + Html.esc(rs.getString(7)) + "</td>"
                            + "<td class='reason-cell'>" + Html.esc(rs.getString(8)) + "</td>"
                            + "<td>" + Html.esc(rs.getString(9)) + "</td>"
                            + "<td class='actions'>"
                            + "<form class='inline' action='coordinatorMemberAction' method='post'><input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='approve'><button class='btn btn-small btn-green' type='submit'>Approve</button></form> "
                            + "<form class='inline' action='coordinatorMemberAction' method='post'><input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='reject'><button class='btn btn-small btn-red' type='submit'>Reject</button></form>"
                            + "</td></tr>");
                    } else {
                        members.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                            + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                            + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                            + "<td>" + branchYear + "</td>"
                            + "<td>" + Html.esc(rs.getString(7)) + "</td>"
                            + "<td class='actions'><form class='inline' action='coordinatorMemberAction' method='post' onsubmit=\"return confirm('Remove this member?');\">"
                            + "<input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='remove'>"
                            + "<button class='btn btn-small btn-red' type='submit'>Remove</button></form></td></tr>");
                    }
                }
            }
        }
    } catch (Exception e) {
        msg = "Database error: " + Html.esc(e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Members and Requests | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Members and Requests</h1>
      <p><%= clubName == null ? "" : "Club: " + Html.esc(clubName) %></p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <% if (clubName == null) { %>
      <div class="card" style="margin-top:22px">
        <div class="note">The admin has not assigned a club to you yet. Once a club is assigned, join requests will appear here.</div>
      </div>
    <% } else { %>

      <div class="card" style="margin-top:22px">
        <h3>Pending join requests</h3>
        <div class="table-wrap">
          <table>
            <tr><th>Student</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Reason</th><th>Applied</th><th>Action</th></tr>
            <%= pending %>
          </table>
          <% if (pending.length() == 0) { %><p class="empty">No pending requests.</p><% } %>
        </div>
      </div>

      <div class="card">
        <h3>Approved members</h3>
        <div class="table-wrap">
          <table>
            <tr><th>Name</th><th>Email</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Action</th></tr>
            <%= members %>
          </table>
          <% if (members.length() == 0) { %><p class="empty">No members yet.</p><% } %>
        </div>
      </div>

    <% } %>
    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
