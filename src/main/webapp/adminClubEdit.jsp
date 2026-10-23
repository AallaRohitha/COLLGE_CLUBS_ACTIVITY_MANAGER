<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("adminClubs.jsp"); return; }
    int clubId = Integer.parseInt(idParam);

    String clubName = "", description = "";
    int currentCoord = 0;
    boolean found = false, hasImage = false;
    StringBuilder options = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT club_name, description, coordinator_id, image_file FROM clubs WHERE club_id = ?")) {
            ps.setInt(1, clubId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                found = true;
                clubName = rs.getString(1);
                description = rs.getString(2);
                currentCoord = rs.getInt(3);   // 0 if empty
                hasImage = rs.getString(4) != null;
            }
        }
        // only APPROVED MEMBERS of this club who do not coordinate another club
        String sql = "SELECT u.user_id, u.name, m.roll_no FROM club_members m JOIN users u ON u.user_id = m.user_id " +
                     "WHERE m.club_id = ? AND m.status = 'approved' AND u.role IN ('student', 'coordinator') " +
                     "AND NOT EXISTS (SELECT 1 FROM clubs c2 WHERE c2.coordinator_id = u.user_id AND c2.club_id <> ?) " +
                     "ORDER BY u.name";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, clubId);
            ps.setInt(2, clubId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int uid = rs.getInt(1);
                String roll = rs.getString(3) == null ? "" : " (" + Html.esc(rs.getString(3)) + ")";
                options.append("<option value='" + uid + "'" + (uid == currentCoord ? " selected" : "") + ">"
                    + Html.esc(rs.getString(2)) + roll + "</option>");
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    if (!found) { response.sendRedirect("adminClubs.jsp?msg=Club+not+found"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Edit Club | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Edit Club</h1>
      <p>Change the name or description, and choose the coordinator from the approved members.</p>
    </div>

    <div class="card" style="margin-top:22px">
      <form action="adminClubAction" method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="clubId" value="<%= clubId %>">
        <div class="form-row">
          <div class="field">
            <label>Club name</label>
            <input type="text" name="clubName" maxlength="100" value="<%= Html.esc(clubName) %>" required>
          </div>
          <div class="field">
            <label>Coordinator (approved members only)</label>
            <select name="coordinatorId">
              <option value="">-- Not assigned --</option>
              <%= options %>
            </select>
          </div>
          <div class="field full">
            <label>Description</label>
            <textarea name="description" maxlength="500"><%= Html.esc(description) %></textarea>
          </div>
        </div>
        <% if (options.length() == 0) { %>
          <div class="note" style="margin-bottom:16px">No approved members yet. Approve some join requests first (Join Requests page).</div>
        <% } %>
        <div class="field">
          <label>Club image</label>
          <% if (hasImage) { %>
            <img class="preview-img zoomable" src="clubImage?id=<%= clubId %>" alt="Club image">
            <label class="check"><input type="checkbox" name="removeImage" value="1"> Remove current image</label>
          <% } %>
          <input type="file" name="image" accept="image/png,image/jpeg">
          <small>Choose a new file to replace the image (JPG or PNG, max 2 MB).</small>
        </div>
        <button class="btn" type="submit">Save Changes</button>
        <a class="btn btn-grey" href="adminClubs.jsp">Cancel</a>
      </form>
    </div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
