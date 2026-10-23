<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("manageEvents.jsp"); return; }
    int eventId = Integer.parseInt(idParam);
    int myId = (Integer) session.getAttribute("userId");

    String title = "", description = "", venue = "", dateText = "";
    int seats = 50, registered = 0, clubId = -1;
    boolean allowed = false, hasImage = false;

    try (Connection con = DBUtil.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT club_id, title, description, venue, max_seats, TO_CHAR(event_date, 'YYYY-MM-DD'), " +
                "(SELECT COUNT(*) FROM event_registrations r WHERE r.event_id = events.event_id), image_file " +
                "FROM events WHERE event_id = ?")) {
            ps.setInt(1, eventId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                clubId = rs.getInt(1);
                title = rs.getString(2);
                description = rs.getString(3);
                venue = rs.getString(4);
                seats = rs.getInt(5);
                dateText = rs.getString(6);
                registered = rs.getInt(7);
                hasImage = rs.getString(8) != null;
            }
        }
        if (clubId != -1) allowed = EventAccess.canManage(con, myId, clubId);
    } catch (Exception e) {
        e.printStackTrace();
    }
    if (!allowed) { response.sendRedirect("manageEvents.jsp?msg=You+cannot+edit+this+event"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Edit Event | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Edit Event</h1>
      <p><%= registered %> student(s) already registered.</p>
    </div>

    <div class="card" style="margin-top:22px">
      <form action="eventAction" method="post" enctype="multipart/form-data">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="eventId" value="<%= eventId %>">
        <div class="form-row">
          <div class="field">
            <label>Event title</label>
            <input type="text" name="title" maxlength="150" value="<%= Html.esc(title) %>" required>
          </div>
          <div class="field">
            <label>Date</label>
            <input type="date" name="eventDate" value="<%= Html.esc(dateText) %>" required>
          </div>
          <div class="field">
            <label>Venue</label>
            <input type="text" name="venue" maxlength="100" value="<%= Html.esc(venue) %>" required>
          </div>
          <div class="field">
            <label>Total seats</label>
            <input type="number" name="maxSeats" min="1" max="1000" value="<%= seats %>" required>
          </div>
          <div class="field full">
            <label>Description</label>
            <textarea name="description" maxlength="500"><%= Html.esc(description) %></textarea>
          </div>
        </div>
        <div class="field">
          <label>Event image</label>
          <% if (hasImage) { %>
            <img class="preview-img zoomable" src="eventImage?id=<%= eventId %>" alt="Current image">
            <label class="check"><input type="checkbox" name="removeImage" value="1"> Remove current image</label>
          <% } %>
          <input type="file" name="image" accept="image/png,image/jpeg">
          <small>Choose a new file to replace the image (JPG or PNG, max 2 MB).</small>
        </div>
        <button class="btn" type="submit">Save Changes</button>
        <a class="btn btn-grey" href="manageEvents.jsp">Cancel</a>
      </form>
    </div>
  </main>
</div>
<%@ include file="includes/lightbox.jsp" %>
</body>
</html>
