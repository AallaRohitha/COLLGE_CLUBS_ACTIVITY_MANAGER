<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("manageEvents.jsp"); return; }
    int eventId = Integer.parseInt(idParam);
    int myId = (Integer) session.getAttribute("userId");
    boolean isAdminUser = "admin".equals(session.getAttribute("role"));

    String title = "";
    boolean allowed = false;
    StringBuilder rows = new StringBuilder();
    int count = 0;

    try (Connection con = DBUtil.getConnection()) {
        int clubId = EventAccess.clubOfEvent(con, eventId);
        if (clubId != -1 && (isAdminUser || EventAccess.canManage(con, myId, clubId))) {
            allowed = true;
            try (PreparedStatement ps = con.prepareStatement("SELECT title FROM events WHERE event_id = ?")) {
                ps.setInt(1, eventId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) title = rs.getString(1);
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT u.name, u.email, r.roll_no, r.branch, r.year, r.phone, TO_CHAR(r.reg_date, 'DD Mon YYYY HH24:MI') " +
                    "FROM event_registrations r JOIN users u ON u.user_id = r.user_id " +
                    "WHERE r.event_id = ? ORDER BY r.reg_date")) {
                ps.setInt(1, eventId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    count++;
                    String by = rs.getString(4) == null ? "-" : Html.esc(rs.getString(4)) + " / Year " + rs.getInt(5);
                    rows.append("<tr><td>" + count + "</td><td><b>" + Html.esc(rs.getString(1)) + "</b></td><td>"
                        + Html.esc(rs.getString(2)) + "</td><td>" + (rs.getString(3) == null ? "-" : Html.esc(rs.getString(3)))
                        + "</td><td>" + by + "</td><td>" + (rs.getString(6) == null ? "-" : Html.esc(rs.getString(6)))
                        + "</td><td>" + Html.esc(rs.getString(7)) + "</td></tr>");
                }
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    if (!allowed) { response.sendRedirect("events.jsp?msg=You+cannot+view+these+registrations"); return; }
    String backPage = isAdminUser ? "adminEvents.jsp" : "manageEvents.jsp";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Event Registrations | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Registrations: <%= Html.esc(title) %></h1>
      <p><%= count %> student(s) registered.</p>
    </div>

    <div class="card" style="margin-top:22px">
      <div class="table-wrap">
        <table>
          <tr><th>#</th><th>Name</th><th>Email</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Registered on</th></tr>
          <%= rows %>
        </table>
        <% if (count == 0) { %><p class="empty">Nobody has registered yet.</p><% } %>
      </div>
      <br>
      <a class="btn btn-grey" href="<%= backPage %>">Back</a>
    </div>
  </main>
</div>
</body>
</html>
