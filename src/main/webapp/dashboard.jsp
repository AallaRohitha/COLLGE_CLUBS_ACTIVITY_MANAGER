<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    int myId = (Integer) session.getAttribute("userId");
    int nClubs = 0, nUpcoming = 0, nRegs = 0;
    StringBuilder ann = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        nClubs    = Stats.scalar(con, "SELECT COUNT(*) FROM club_members WHERE user_id = ? AND status = 'approved'", myId);
        nUpcoming = Stats.scalar(con, "SELECT COUNT(*) FROM events WHERE event_date >= TRUNC(SYSDATE)");
        nRegs     = Stats.scalar(con, "SELECT COUNT(*) FROM event_registrations WHERE user_id = ?", myId);

        String sql = "SELECT * FROM (SELECT a.title, a.message, c.club_name, TO_CHAR(a.posted_date, 'DD Mon YYYY') " +
                     "FROM announcements a JOIN clubs c ON c.club_id = a.club_id " +
                     "WHERE a.club_id IN (SELECT club_id FROM club_members WHERE user_id = ? AND status = 'approved') " +
                     "ORDER BY a.posted_date DESC, a.ann_id DESC) WHERE ROWNUM <= 5";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                ann.append("<div class='ann-item'><div class='ann-top'><b>" + Html.esc(rs.getString(1)) + "</b><span>"
                    + Html.esc(rs.getString(3)) + " &middot; " + Html.esc(rs.getString(4)) + "</span></div><p>"
                    + Html.esc(rs.getString(2)) + "</p></div>");
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
  <title>Dashboard | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Welcome, <%= Html.esc((String) session.getAttribute("userName")) %></h1>
      <p>Browse clubs, join them and register for events.</p>
    </div>

    <div class="stats">
      <div class="stat"><div class="num"><%= nClubs %></div><div class="lbl">Clubs I belong to</div></div>
      <div class="stat"><div class="num"><%= nUpcoming %></div><div class="lbl">Upcoming events</div></div>
      <div class="stat"><div class="num"><%= nRegs %></div><div class="lbl">My registrations</div></div>
    </div>

    <div class="card">
      <h3>Announcements from my clubs</h3>
      <%= ann %>
      <% if (ann.length() == 0) { %><p class="empty">No announcements yet. Join a club to see its news here.</p><% } %>
    </div>

    <div class="card">
      <h3>Quick links</h3>
      <div class="quick">
        <a class="btn" href="clubs.jsp">Browse clubs</a>
        <a class="btn btn-grey" href="events.jsp">See events</a>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
