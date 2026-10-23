<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    StringBuilder rows = new StringBuilder();

    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(
            "SELECT c.club_id, c.club_name, c.description, u.name, " +
            "  (SELECT COUNT(*) FROM club_members m WHERE m.club_id = c.club_id AND m.status = 'approved'), c.image_file " +
            "FROM clubs c LEFT JOIN users u ON c.coordinator_id = u.user_id ORDER BY c.club_id")) {
        while (rs.next()) {
            int id = rs.getInt(1);
            String coord = rs.getString(4);
            String img = rs.getString(6) != null
                ? "<img class='thumb zoomable' src='clubImage?id=" + id + "' alt='Club image'>"
                : "<span class='badge badge-pending'>No image</span>";
            rows.append("<tr><td>" + img + "</td>"
                + "<td><b><a href='clubDetails.jsp?id=" + id + "'>" + Html.esc(rs.getString(2)) + "</a></b></td>"
                + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                + "<td>" + rs.getInt(5) + "</td>"
                + "<td>" + (coord == null ? "<span class='badge badge-pending'>Not assigned</span>" : Html.esc(coord)) + "</td>"
                + "<td class='actions'><a class='btn btn-small btn-grey' href='clubDetails.jsp?id=" + id + "'>Members</a> "
                + "<a class='btn btn-small' href='adminClubEdit.jsp?id=" + id + "'>Edit</a></td></tr>");
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
  <title>Manage Clubs | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Manage Clubs</h1>
      <p>Add new clubs. A coordinator is chosen from the approved members of the club.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <h3>Add a new club</h3>
      <form action="adminClubAction" method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="add">
        <div class="form-row">
          <div class="field">
            <label>Club name</label>
            <input type="text" name="clubName" maxlength="100" required>
          </div>
          <div class="field">
            <label>Club image (optional, JPG or PNG, max 2 MB)</label>
            <input type="file" name="image" accept="image/png,image/jpeg">
          </div>
          <div class="field full">
            <label>Description</label>
            <textarea name="description" maxlength="500"></textarea>
          </div>
        </div>
        <div class="note" style="margin-bottom:16px">How a club gets its coordinator: students join the club, a request is approved, and then you pick one of the approved members here (Edit), or approve a student's coordinator application.</div>
        <button class="btn" type="submit">Add Club</button>
      </form>
    </div>

    <div class="card">
      <h3>All clubs</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Image</th><th>Club</th><th>Description</th><th>Members</th><th>Coordinator</th><th>Action</th></tr>
          <%= rows %>
        </table>
        <% if (rows.length() == 0) { %><p class="empty">No clubs yet. Add the first one above.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
