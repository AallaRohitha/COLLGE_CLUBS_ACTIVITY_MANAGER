<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    int myId = (Integer) session.getAttribute("userId");
    String clubName = null;
    int nMembers = 0, nPending = 0, nEvents = 0, nRegs = 0;
    StringBuilder ann = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        int clubId = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT club_id, club_name FROM clubs WHERE coordinator_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { clubId = rs.getInt(1); clubName = rs.getString(2); }
        }
        if (clubName != null) {
            nMembers = Stats.scalar(con, "SELECT COUNT(*) FROM club_members WHERE club_id = ? AND status = 'approved'", clubId);
            nPending = Stats.scalar(con, "SELECT COUNT(*) FROM club_members WHERE club_id = ? AND status = 'pending'", clubId);
            nEvents  = Stats.scalar(con, "SELECT COUNT(*) FROM events WHERE club_id = ?", clubId);
            nRegs    = Stats.scalar(con, "SELECT COUNT(*) FROM event_registrations r JOIN events e ON e.event_id = r.event_id WHERE e.club_id = ?", clubId);

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT * FROM (SELECT title, message, TO_CHAR(posted_date, 'DD Mon YYYY') FROM announcements " +
                    "WHERE club_id = ? ORDER BY posted_date DESC, ann_id DESC) WHERE ROWNUM <= 5")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    ann.append("<div class='ann-item'><div class='ann-top'><b>" + Html.esc(rs.getString(1)) + "</b><span>"
                        + Html.esc(rs.getString(3)) + "</span></div><p>" + Html.esc(rs.getString(2)) + "</p></div>");
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Coordinator Dashboard | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Welcome, <%= Html.esc((String) session.getAttribute("userName")) %></h1>
      <p><%= clubName == null ? "The admin has not assigned a club to you yet." : "Coordinator of " + Html.esc(clubName) %></p>
    </div>

    <% if (clubName != null) { %>
    <div class="stats">
      <div class="stat"><div class="num"><%= nMembers %></div><div class="lbl">Members</div></div>
      <div class="stat"><div class="num"><%= nPending %></div><div class="lbl">Pending requests</div></div>
      <div class="stat"><div class="num"><%= nEvents %></div><div class="lbl">Events</div></div>
      <div class="stat"><div class="num"><%= nRegs %></div><div class="lbl">Event registrations</div></div>
    </div>

    <div class="card">
      <h3>Latest announcements</h3>
      <%= ann %>
      <% if (ann.length() == 0) { %><p class="empty">No announcements yet.</p><% } %>
    </div>

    <div class="card">
      <h3>Quick links</h3>
      <div class="quick">
        <a class="btn" href="coordinatorRequests.jsp">Review requests</a>
        <a class="btn btn-grey" href="manageEvents.jsp">Manage events</a>
        <a class="btn btn-grey" href="coordinatorAnnouncements.jsp">Post announcement</a>
      </div>
    </div>
    <% } %>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
