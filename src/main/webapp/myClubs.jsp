<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    StringBuilder rows = new StringBuilder();

    String sql = "SELECT c.club_id, c.club_name, m.status, TO_CHAR(m.joined_date, 'DD Mon YYYY') " +
                 "FROM club_members m JOIN clubs c ON c.club_id = m.club_id " +
                 "WHERE m.user_id = ? ORDER BY m.joined_date DESC";

    try (Connection con = DBUtil.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, myId);
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            String status = rs.getString(3);
            String badge = "approved".equals(status) ? "<span class='badge badge-ok'>Member</span>"
                         : "pending".equals(status)  ? "<span class='badge badge-pending'>Pending</span>"
                                                     : "<span class='badge badge-no'>Rejected</span>";
            String label = "approved".equals(status) ? "Leave club" : "pending".equals(status) ? "Cancel request" : "Remove";
            rows.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                + "<td>" + badge + "</td>"
                + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                + "<td class='actions'><form class='inline' action='joinClubAction' method='post' "
                + "onsubmit=\"return confirm('Are you sure?');\">"
                + "<input type='hidden' name='action' value='cancel'>"
                + "<input type='hidden' name='clubId' value='" + rs.getInt(1) + "'>"
                + "<button class='btn btn-small btn-red' type='submit'>" + label + "</button></form></td></tr>");
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
  <title>My Clubs | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>My Clubs</h1>
      <p>Your join requests and memberships.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <div class="table-wrap">
        <table>
          <tr><th>Club</th><th>Status</th><th>Applied on</th><th>Action</th></tr>
          <%= rows %>
        </table>
        <% if (rows.length() == 0) { %>
          <p class="empty">You have not joined any club yet. <a href="clubs.jsp">Browse clubs</a></p>
        <% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
