<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");

    int clubId = 0;
    String clubName = null, description = "";
    boolean hasImage = false;
    StringBuilder members = new StringBuilder();
    int count = 0;

    try (Connection con = DBUtil.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT club_id, club_name, description, image_file FROM clubs WHERE coordinator_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                clubId = rs.getInt(1);
                clubName = rs.getString(2);
                description = rs.getString(3);
                hasImage = rs.getString(4) != null;
            }
        }
        if (clubName != null) {
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT u.name, u.email, m.roll_no, m.branch, m.year, m.phone, TO_CHAR(m.joined_date, 'DD Mon YYYY'), u.user_id " +
                    "FROM club_members m JOIN users u ON u.user_id = m.user_id " +
                    "WHERE m.club_id = ? AND m.status = 'approved' ORDER BY u.name")) {
                ps.setInt(1, clubId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    count++;
                    String tag = rs.getInt(8) == myId ? "<span class='badge badge-coord'>You</span>" : "";
                    members.append("<tr><td>" + count + "</td><td><b>" + Html.esc(rs.getString(1)) + "</b> " + tag + "</td>"
                        + "<td>" + Html.esc(rs.getString(2)) + "</td>"
                        + "<td>" + (rs.getString(3) == null ? "-" : Html.esc(rs.getString(3))) + "</td>"
                        + "<td>" + (rs.getString(4) == null ? "-" : Html.esc(rs.getString(4)) + " / Year " + rs.getInt(5)) + "</td>"
                        + "<td>" + (rs.getString(6) == null ? "-" : Html.esc(rs.getString(6))) + "</td>"
                        + "<td>" + Html.esc(rs.getString(7)) + "</td></tr>");
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
  <title>My Club | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>My Club<%= clubName == null ? "" : ": " + Html.esc(clubName) %></h1>
      <p>Change the club image and description, and see all members of your club.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <% if (clubName == null) { %>
      <div class="card" style="margin-top:22px"><div class="note">The admin has not assigned a club to you yet.</div></div>
    <% } else { %>

      <div class="card" style="margin-top:22px; max-width:760px">
        <h3>Club details</h3>
        <form action="coordinatorClubAction" method="post" enctype="multipart/form-data">
          <div class="field">
            <label>Description</label>
            <textarea name="description" maxlength="500"><%= Html.esc(description) %></textarea>
          </div>
          <div class="field">
            <label>Club image</label>
            <% if (hasImage) { %>
              <img class="preview-img zoomable" src="clubImage?id=<%= clubId %>" alt="Club image">
              <label class="check"><input type="checkbox" name="removeImage" value="1"> Remove current image</label>
            <% } %>
            <input type="file" name="image" accept="image/png,image/jpeg">
            <small>Choose a new file to replace the image (JPG or PNG, max 2 MB).</small>
          </div>
          <button class="btn" type="submit">Save</button>
        </form>
      </div>

      <div class="card">
        <h3>All members of <%= Html.esc(clubName) %> (<%= count %>)</h3>
        <div class="table-wrap">
          <table>
            <tr><th>#</th><th>Name</th><th>Email</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Joined</th></tr>
            <%= members %>
          </table>
          <% if (count == 0) { %><p class="empty">No approved members yet.</p><% } %>
        </div>
        <br>
        <a class="btn btn-grey" href="coordinatorRequests.jsp">Join requests and removing members</a>
      </div>

    <% } %>
    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
