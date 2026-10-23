<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("clubs.jsp"); return; }
    int clubId = Integer.parseInt(idParam);
    int myId = (Integer) session.getAttribute("userId");
    boolean isAdminUser = "admin".equals(session.getAttribute("role"));

    String clubName = null, description = "", coordName = null;
    boolean hasImage = false, iAmCoordinator = false;
    int memberCount = 0;
    StringBuilder members = new StringBuilder();
    StringBuilder events = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        int coordId = 0;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT c.club_name, c.description, c.image_file, c.coordinator_id, u.name, " +
                "(SELECT COUNT(*) FROM club_members m WHERE m.club_id = c.club_id AND m.status = 'approved') " +
                "FROM clubs c LEFT JOIN users u ON u.user_id = c.coordinator_id WHERE c.club_id = ?")) {
            ps.setInt(1, clubId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                clubName = rs.getString(1);
                description = rs.getString(2);
                hasImage = rs.getString(3) != null;
                coordId = rs.getInt(4);
                coordName = rs.getString(5);
                memberCount = rs.getInt(6);
            }
        }
        iAmCoordinator = coordId != 0 && coordId == myId;

        // The full member list is shown only to the admin and to this club's coordinator
        if (clubName != null && (isAdminUser || iAmCoordinator)) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT u.user_id, u.name, u.email, m.roll_no, m.branch, m.year, m.phone, TO_CHAR(m.joined_date, 'DD Mon YYYY') " +
                    "FROM club_members m JOIN users u ON u.user_id = m.user_id " +
                    "WHERE m.club_id = ? AND m.status = 'approved' ORDER BY u.name")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                int n = 0;
                while (rs.next()) {
                    n++;
                    String tag = rs.getInt(1) == coordId ? "<span class='badge badge-coord'>Coordinator</span>" : "";
                    members.append("<tr><td>" + n + "</td><td><b>" + Html.esc(rs.getString(2)) + "</b> " + tag + "</td>"
                        + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                        + "<td>" + (rs.getString(4) == null ? "-" : Html.esc(rs.getString(4))) + "</td>"
                        + "<td>" + (rs.getString(5) == null ? "-" : Html.esc(rs.getString(5)) + " / Year " + rs.getInt(6)) + "</td>"
                        + "<td>" + (rs.getString(7) == null ? "-" : Html.esc(rs.getString(7))) + "</td>"
                        + "<td>" + Html.esc(rs.getString(8)) + "</td></tr>");
                }
            }
        }
        if (clubName != null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT title, TO_CHAR(event_date, 'DD Mon YYYY'), venue FROM events " +
                    "WHERE club_id = ? AND event_date >= TRUNC(SYSDATE) ORDER BY event_date")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    events.append("<tr><td><b>" + Html.esc(rs.getString(1)) + "</b></td><td>" + Html.esc(rs.getString(2))
                        + "</td><td>" + Html.esc(rs.getString(3)) + "</td></tr>");
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    if (clubName == null) { response.sendRedirect("clubs.jsp?msg=Club+not+found"); return; }
    boolean canSeeMembers = isAdminUser || iAmCoordinator;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= Html.esc(clubName) %> | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1><%= Html.esc(clubName) %></h1>
      <p>Club details</p>
    </div>

    <div class="card" style="margin-top:22px">
      <div class="club-header">
        <% if (hasImage) { %><img class="big zoomable" src="clubImage?id=<%= clubId %>" alt="Club image"><% } %>
        <div class="info">
          <p><%= Html.esc(description) %></p>
          <div class="meta">
            <span><b>Coordinator:</b> <%= coordName == null ? "Not assigned" : Html.esc(coordName) %></span><br>
            <span><b>Members:</b> <%= memberCount %></span>
          </div>
          <br>
          <a class="btn btn-grey" href="clubs.jsp">Back to clubs</a>
          <% if (isAdminUser) { %><a class="btn" href="adminClubEdit.jsp?id=<%= clubId %>">Edit club</a><% } %>
          <% if (iAmCoordinator) { %><a class="btn" href="coordinatorClub.jsp">Edit my club</a><% } %>
        </div>
      </div>
    </div>

    <% if (canSeeMembers) { %>
      <div class="card">
        <h3>Members of this club (<%= memberCount %>)</h3>
        <div class="table-wrap">
          <table>
            <tr><th>#</th><th>Name</th><th>Email</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Joined</th></tr>
            <%= members %>
          </table>
          <% if (members.length() == 0) { %><p class="empty">No approved members yet.</p><% } %>
        </div>
      </div>
    <% } %>

    <div class="card">
      <h3>Upcoming events</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Event</th><th>Date</th><th>Venue</th></tr>
          <%= events %>
        </table>
        <% if (events.length() == 0) { %><p class="empty">No upcoming events.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
