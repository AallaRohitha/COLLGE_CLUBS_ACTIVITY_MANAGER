<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    String clubName = null;
    StringBuilder items = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        int clubId = 0;
        try (PreparedStatement ps = con.prepareStatement("SELECT club_id, club_name FROM clubs WHERE coordinator_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { clubId = rs.getInt(1); clubName = rs.getString(2); }
        }
        if (clubName != null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT ann_id, title, message, TO_CHAR(posted_date, 'DD Mon YYYY') FROM announcements " +
                    "WHERE club_id = ? ORDER BY posted_date DESC, ann_id DESC")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    items.append("<div class='ann-item'><div class='ann-top'><b>" + Html.esc(rs.getString(2)) + "</b><span>"
                        + Html.esc(rs.getString(4)) + "</span></div><p>" + Html.esc(rs.getString(3)) + "</p>"
                        + "<form class='inline' action='coordinatorAnnouncementAction' method='post' onsubmit=\"return confirm('Delete this announcement?');\">"
                        + "<input type='hidden' name='action' value='delete'><input type='hidden' name='annId' value='" + rs.getInt(1) + "'>"
                        + "<button class='btn btn-small btn-red' type='submit' style='margin-top:8px'>Delete</button></form></div>");
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
  <title>Announcements | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Announcements</h1>
      <p><%= clubName == null ? "" : "News for members of " + Html.esc(clubName) %></p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <% if (clubName == null) { %>
      <div class="card" style="margin-top:22px"><div class="note">The admin has not assigned a club to you yet.</div></div>
    <% } else { %>

      <div class="card" style="margin-top:22px; max-width:700px">
        <h3>Post a new announcement</h3>
        <form action="coordinatorAnnouncementAction" method="post">
          <input type="hidden" name="action" value="add">
          <div class="field">
            <label>Title</label>
            <input type="text" name="title" maxlength="150" required>
          </div>
          <div class="field">
            <label>Message</label>
            <textarea name="message" maxlength="500" required></textarea>
          </div>
          <button class="btn" type="submit">Post</button>
        </form>
      </div>

      <div class="card">
        <h3>Posted announcements</h3>
        <%= items %>
        <% if (items.length() == 0) { %><p class="empty">Nothing posted yet.</p><% } %>
      </div>

    <% } %>
    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
