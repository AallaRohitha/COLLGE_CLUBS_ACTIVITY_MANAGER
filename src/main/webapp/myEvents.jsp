<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    StringBuilder rows = new StringBuilder();

    String sql = "SELECT e.event_id, e.title, c.club_name, TO_CHAR(e.event_date, 'DD Mon YYYY'), e.venue " +
                 "FROM event_registrations r JOIN events e ON e.event_id = r.event_id " +
                 "JOIN clubs c ON c.club_id = e.club_id WHERE r.user_id = ? ORDER BY e.event_date";
    try (Connection con = DBUtil.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, myId);
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            rows.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                + "<td>" + Html.esc(rs.getString(5)) + "</td>"
                + "<td class='actions'><form class='inline' action='eventRegisterAction' method='post' onsubmit=\"return confirm('Cancel this registration?');\">"
                + "<input type='hidden' name='action' value='cancel'><input type='hidden' name='eventId' value='" + rs.getInt(1) + "'>"
                + "<button class='btn btn-small btn-red' type='submit'>Cancel</button></form></td></tr>");
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
  <title>My Registrations | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>My Registrations</h1>
      <p>Events you have registered for.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <div class="table-wrap">
        <table>
          <tr><th>Event</th><th>Club</th><th>Date</th><th>Venue</th><th>Action</th></tr>
          <%= rows %>
        </table>
        <% if (rows.length() == 0) { %>
          <p class="empty">You have not registered for any event. <a href="events.jsp">Browse events</a></p>
        <% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
