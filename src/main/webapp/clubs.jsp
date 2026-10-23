<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    String q   = request.getParameter("q") == null ? "" : request.getParameter("q").trim();
    int myId   = (Integer) session.getAttribute("userId");
    boolean isAdminUser = "admin".equals(session.getAttribute("role"));
    StringBuilder cards = new StringBuilder();

    String sql =
        "SELECT c.club_id, c.club_name, c.description, u.name, m.status, " +
        "  (SELECT COUNT(*) FROM club_members x WHERE x.club_id = c.club_id AND x.status = 'approved'), " +
        "  c.image_file, c.coordinator_id " +
        "FROM clubs c " +
        "LEFT JOIN users u ON c.coordinator_id = u.user_id " +
        "LEFT JOIN club_members m ON m.club_id = c.club_id AND m.user_id = ? " +
        "WHERE LOWER(c.club_name) LIKE ? ORDER BY c.club_name";

    try (Connection con = DBUtil.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, myId);
        ps.setString(2, "%" + q.toLowerCase() + "%");
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            int id = rs.getInt(1);
            String status = rs.getString(5);
            String coord = rs.getString(4);
            boolean iAmCoordinator = rs.getInt(8) == myId;
            String details = "<a class='btn btn-small btn-grey' href='clubDetails.jsp?id=" + id + "'>";

            String action;
            if (isAdminUser) {
                action = details + "View members</a>";
            } else if (iAmCoordinator) {
                action = "<span class='badge badge-coord'>You are the Coordinator</span> " + details + "View members</a>";
            } else if (status == null) {
                action = "<a class='btn btn-small' href='joinClub.jsp?id=" + id + "'>Join Club</a> " + details + "Details</a>";
            } else if ("pending".equals(status)) {
                action = "<span class='badge badge-pending'>Request Pending</span> " + details + "Details</a>";
            } else if ("approved".equals(status)) {
                action = "<span class='badge badge-ok'>You are a Member</span> " + details + "Details</a>";
            } else {
                action = "<span class='badge badge-no'>Rejected</span> <a class='btn btn-small' href='joinClub.jsp?id=" + id + "'>Apply again</a>";
            }

            String image = rs.getString(7) != null
                ? "<a href='clubDetails.jsp?id=" + id + "'><img class='club-img' src='clubImage?id=" + id + "' alt='Club image'></a>" : "";

            cards.append("<div class='card club-card'>" + image
                + "<h3><a href='clubDetails.jsp?id=" + id + "'>" + Html.esc(rs.getString(2)) + "</a></h3>"
                + "<p class='desc'>" + Html.esc(rs.getString(3)) + "</p>"
                + "<div class='meta'><span><b>Coordinator:</b> " + (coord == null ? "Not assigned" : Html.esc(coord)) + "</span>"
                + "<span><b>Members:</b> " + rs.getInt(6) + "</span></div>"
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
  <title>All Clubs | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>All Clubs</h1>
      <p><%= isAdminUser ? "Click a club to see its members." : "Find a club and send a join request." %></p>
    </div>

    <form class="search-bar" action="clubs.jsp" method="get">
      <input type="text" name="q" placeholder="Search clubs..." value="<%= Html.esc(q) %>">
      <button class="btn" type="submit">Search</button>
    </form>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="grid" style="margin-top:22px">
      <%= cards %>
    </div>
    <% if (cards.length() == 0) { %><p class="empty">No clubs found.</p><% } %>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
