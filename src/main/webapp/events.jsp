<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    boolean isAdmin = "admin".equals(session.getAttribute("role"));
    StringBuilder cards = new StringBuilder();

    String sql =
        "SELECT e.event_id, e.title, e.description, c.club_name, TO_CHAR(e.event_date, 'DD Mon YYYY'), e.venue, e.max_seats, " +
        "  (SELECT COUNT(*) FROM event_registrations r WHERE r.event_id = e.event_id), " +
        "  (SELECT COUNT(*) FROM event_registrations r2 WHERE r2.event_id = e.event_id AND r2.user_id = ?), e.image_file " +
        "FROM events e JOIN clubs c ON c.club_id = e.club_id " +
        "WHERE e.event_date >= TRUNC(SYSDATE) ORDER BY e.event_date";

    try (Connection con = DBUtil.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, myId);
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            int id = rs.getInt(1);
            int left = rs.getInt(7) - rs.getInt(8);
            boolean mine = rs.getInt(9) > 0;

            String action;
            if (isAdmin) {
                action = "";
            } else if (mine) {
                action = "<span class='badge badge-ok'>You are registered</span>";
            } else if (left <= 0) {
                action = "<span class='badge badge-no'>Full</span>";
            } else {
                action = "<a class='btn btn-small' href='registerEvent.jsp?id=" + id + "'>Register</a>";
            }

            cards.append("<div class='card event-card'>" + (rs.getString(10) != null ? "<img class='event-img zoomable' src='eventImage?id=" + id + "' alt='Event image'>" : "")
                + "<div class='club-name'>" + Html.esc(rs.getString(4)) + "</div>"
                + "<h3>" + Html.esc(rs.getString(2)) + "</h3>"
                + "<p class='desc'>" + Html.esc(rs.getString(3)) + "</p>"
                + "<div class='meta'><span><b>Date:</b> " + Html.esc(rs.getString(5)) + "</span>"
                + "<span><b>Venue:</b> " + Html.esc(rs.getString(6)) + "</span>"
                + "<span><b>Seats left:</b> <span class='seats-left" + (left <= 5 ? " seats-low" : "") + "'>"
                + Math.max(left, 0) + " of " + rs.getInt(7) + "</span></span></div>"
                + action + "</div>");
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
  <title>Events | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Upcoming Events</h1>
      <p>Events from all clubs. Register before the seats are full.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="grid" style="margin-top:22px">
      <%= cards %>
    </div>
    <% if (cards.length() == 0) { %><p class="empty">No upcoming events right now.</p><% } %>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
