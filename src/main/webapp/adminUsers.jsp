<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    StringBuilder rows = new StringBuilder();

    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(
            "SELECT user_id, name, email, role FROM users WHERE role <> 'admin' ORDER BY user_id")) {
        while (rs.next()) {
            int id = rs.getInt(1);
            String role = rs.getString(4);

            String toggle = "student".equals(role)
              ? "<small>Coordinator is chosen in Manage Clubs</small> "
              : "<form class='inline' action='adminUserAction' method='post'>"
                + "<input type='hidden' name='userId' value='" + id + "'>"
                + "<input type='hidden' name='action' value='demote'>"
                + "<button class='btn btn-small btn-grey' type='submit'>Demote</button></form> ";

            String delete = "<form class='inline' action='adminUserAction' method='post' "
                + "onsubmit=\"return confirm('Delete this user permanently?');\">"
                + "<input type='hidden' name='userId' value='" + id + "'>"
                + "<input type='hidden' name='action' value='delete'>"
                + "<button class='btn btn-small btn-red' type='submit'>Delete</button></form>";

            rows.append("<tr><td>" + id + "</td>"
                + "<td>" + Html.esc(rs.getString(2)) + "</td>"
                + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                + "<td><span class='badge badge-" + role + "'>" + Html.esc(role) + "</span></td>"
                + "<td class='actions'>" + toggle + delete + "</td></tr>");
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
  <title>Manage Users | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Manage Users</h1>
      <p>See all students and coordinators. Coordinators are chosen from a club's approved members in Manage Clubs.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <h3>Students and coordinators</h3>
      <div class="table-wrap">
        <table>
          <tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Actions</th></tr>
          <%= rows %>
        </table>
        <% if (rows.length() == 0) { %><p class="empty">No users yet. Students appear here after they register.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
