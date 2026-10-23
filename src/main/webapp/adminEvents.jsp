<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    StringBuilder rows = new StringBuilder();

    String sql = "SELECT e.event_id, e.title, c.club_name, TO_CHAR(e.event_date, 'DD Mon YYYY'), e.venue, e.max_seats, " +
                 "(SELECT COUNT(*) FROM event_registrations r WHERE r.event_id = e.event_id), e.image_file, " +
                 "CASE WHEN e.event_date < TRUNC(SYSDATE) THEN 'Over' ELSE 'Upcoming' END " +
                 "FROM events e JOIN clubs c ON c.club_id = e.club_id ORDER BY e.event_date DESC";
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(sql)) {
        while (rs.next()) {
            int id = rs.getInt(1);
            String img = rs.getString(8) != null
                ? "<img class='thumb zoomable' src='eventImage?id=" + id + "' alt='Event image'>"
                : "<span class='badge badge-pending'>No image</span>";
            String state = "Upcoming".equals(rs.getString(9)) ? "<span class='badge badge-ok'>Upcoming</span>"
                                                                : "<span class='badge badge-no'>Over</span>";
            rows.append("<tr><td>" + img + "</td>"
                + "<td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                + "<td>" + Html.esc(rs.getString(5)) + "</td>"
                + "<td>" + rs.getInt(7) + " / " + rs.getInt(6) + "</td>"
                + "<td>" + state + "</td>"
                + "<td class='actions'><a class='btn btn-small btn-grey' href='eventRegistrations.jsp?id=" + id + "'>Registrations</a></td></tr>");
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
  <title>All Events | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>All Events</h1>
      <p>Every event of every club. Click an image to enlarge it.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>

    <div class="card" style="margin-top:22px">
      <div class="table-wrap">
        <table>
          <tr><th>Image</th><th>Event</th><th>Club</th><th>Date</th><th>Venue</th><th>Registered</th><th>Status</th><th>Action</th></tr>
          <%= rows %>
        </table>
        <% if (rows.length() == 0) { %><p class="empty">No events have been created yet.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
