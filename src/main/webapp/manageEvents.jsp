<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,java.util.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");

    Map<Integer, Boolean> myClubs = new LinkedHashMap<Integer, Boolean>();   // clubId -> am I the coordinator?
    StringBuilder options = new StringBuilder();
    StringBuilder rows = new StringBuilder();

    try (Connection con = DBUtil.getConnection()) {
        String sql1 = "SELECT c.club_id, c.club_name, CASE WHEN c.coordinator_id = ? THEN 1 ELSE 0 END " +
                      "FROM clubs c WHERE c.coordinator_id = ? OR c.club_id IN " +
                      "(SELECT club_id FROM club_members WHERE user_id = ? AND status = 'approved') ORDER BY c.club_name";
        try (PreparedStatement ps = con.prepareStatement(sql1)) {
            ps.setInt(1, myId); ps.setInt(2, myId); ps.setInt(3, myId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                myClubs.put(rs.getInt(1), rs.getInt(3) == 1);
                options.append("<option value='" + rs.getInt(1) + "'>" + Html.esc(rs.getString(2)) + "</option>");
            }
        }
        if (!myClubs.isEmpty()) {
            StringBuilder ids = new StringBuilder();
            for (Integer id : myClubs.keySet()) { if (ids.length() > 0) ids.append(","); ids.append(id); }
            String sql2 = "SELECT e.event_id, e.club_id, e.title, c.club_name, TO_CHAR(e.event_date, 'DD Mon YYYY'), e.venue, e.max_seats, " +
                          "(SELECT COUNT(*) FROM event_registrations r WHERE r.event_id = e.event_id) " +
                          "FROM events e JOIN clubs c ON c.club_id = e.club_id " +
                          "WHERE e.club_id IN (" + ids + ") ORDER BY e.event_date DESC";
            try (Statement st = con.createStatement(); ResultSet rs = st.executeQuery(sql2)) {
                while (rs.next()) {
                    int eid = rs.getInt(1);
                    boolean isCoord = myClubs.get(rs.getInt(2));
                    String del = isCoord
                        ? "<form class='inline' action='eventAction' method='post' onsubmit=\"return confirm('Delete this event and its registrations?');\">"
                          + "<input type='hidden' name='action' value='delete'><input type='hidden' name='eventId' value='" + eid + "'>"
                          + "<button class='btn btn-small btn-red' type='submit'>Delete</button></form>"
                        : "";
                    rows.append("<tr><td><b>" + Html.esc(rs.getString(3)) + "</b></td>"
                        + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                        + "<td>" + Html.esc(rs.getString(5)) + "</td>"
                        + "<td>" + Html.esc(rs.getString(6)) + "</td>"
                        + "<td>" + rs.getInt(8) + " / " + rs.getInt(7) + "</td>"
                        + "<td class='actions'><a class='btn btn-small' href='eventEdit.jsp?id=" + eid + "'>Edit</a> "
                        + "<a class='btn btn-small btn-grey' href='eventRegistrations.jsp?id=" + eid + "'>Registrations</a> "
                        + del + "</td></tr>");
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
  <title>Manage Events | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Manage Events</h1>
      <p>Add and edit events of your clubs.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <% if (myClubs.isEmpty()) { %>
      <div class="card" style="margin-top:22px">
        <div class="note">You can manage events once you are the coordinator of a club, or an approved member of a club.</div>
      </div>
    <% } else { %>

      <div class="card" style="margin-top:22px">
        <h3>Add a new event</h3>
        <form action="eventAction" method="post" enctype="multipart/form-data">
          <input type="hidden" name="action" value="add">
          <div class="form-row">
            <div class="field">
              <label>Club</label>
              <select name="clubId" required><%= options %></select>
            </div>
            <div class="field">
              <label>Event title</label>
              <input type="text" name="title" maxlength="150" required>
            </div>
            <div class="field">
              <label>Date</label>
              <input type="date" name="eventDate" required>
            </div>
            <div class="field">
              <label>Venue</label>
              <input type="text" name="venue" maxlength="100" required>
            </div>
            <div class="field">
              <label>Total seats</label>
              <input type="number" name="maxSeats" min="1" max="1000" value="50" required>
            </div>
            <div class="field full">
              <label>Description</label>
              <textarea name="description" maxlength="500"></textarea>
            </div>
          </div>
          <div class="field">
            <label>Event image (optional, JPG or PNG, max 2 MB)</label>
            <input type="file" name="image" accept="image/png,image/jpeg">
          </div>
          <button class="btn" type="submit">Add Event</button>
        </form>
      </div>

      <div class="card">
        <h3>Events of your clubs</h3>
        <div class="table-wrap">
          <table>
            <tr><th>Title</th><th>Club</th><th>Date</th><th>Venue</th><th>Registered</th><th>Actions</th></tr>
            <%= rows %>
          </table>
          <% if (rows.length() == 0) { %><p class="empty">No events yet. Add the first one above.</p><% } %>
        </div>
      </div>

    <% } %>
    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
