<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    boolean isStudent = "student".equals(session.getAttribute("role"));
    StringBuilder options = new StringBuilder();
    StringBuilder rows = new StringBuilder();

    if (isStudent) {
        try (Connection con = DBUtil.getConnection()) {
            try (Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery("SELECT club_id, club_name FROM clubs WHERE coordinator_id IS NULL AND club_id IN " +
                 "(SELECT club_id FROM club_members WHERE user_id = " + myId + " AND status = 'approved') ORDER BY club_name")) {
                while (rs.next()) {
                    options.append("<option value='" + rs.getInt(1) + "'>" + Html.esc(rs.getString(2)) + "</option>");
                }
            }
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT c.club_id, c.club_name, r.status, TO_CHAR(r.req_date, 'DD Mon YYYY') " +
                    "FROM coordinator_requests r JOIN clubs c ON c.club_id = r.club_id " +
                    "WHERE r.user_id = ? ORDER BY r.req_date DESC")) {
                ps.setInt(1, myId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    String st2 = rs.getString(3);
                    String badge = "approved".equals(st2) ? "<span class='badge badge-ok'>Approved</span>"
                                 : "pending".equals(st2)  ? "<span class='badge badge-pending'>Pending</span>"
                                                          : "<span class='badge badge-no'>Rejected</span>";
                    String cancel = "pending".equals(st2)
                        ? "<form class='inline' action='applyCoordinatorAction' method='post'>"
                          + "<input type='hidden' name='action' value='cancel'><input type='hidden' name='clubId' value='" + rs.getInt(1) + "'>"
                          + "<button class='btn btn-small btn-red' type='submit'>Cancel</button></form>"
                        : "";
                    rows.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td><td>" + badge + "</td><td>"
                        + Html.esc(rs.getString(4)) + "</td><td class='actions'>" + cancel + "</td></tr>");
                }
            }
        } catch (Exception e) {
            msg = "Database error: " + Html.esc(e.getMessage());
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Become a Coordinator | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Become a Coordinator</h1>
      <p>Apply to lead a club that has no coordinator. You must be an approved member of that club first. The admin will review your application.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <% if (!isStudent) { %>
      <div class="card" style="margin-top:22px"><div class="note">Only students can apply to become a coordinator.</div></div>
    <% } else { %>

      <div class="card" style="margin-top:22px; max-width:700px">
        <h3>New application</h3>
        <% if (options.length() == 0) { %>
          <p class="empty">No club is available. You can apply only for a club where you are an approved member and which has no coordinator. Join a club first and wait for approval.</p>
        <% } else { %>
          <form action="applyCoordinatorAction" method="post">
            <input type="hidden" name="action" value="apply">
            <div class="field">
              <label>Club</label>
              <select name="clubId" required><%= options %></select>
            </div>
            <div class="field">
              <label>Why should you be the coordinator?</label>
              <textarea name="reason" maxlength="300" required></textarea>
            </div>
            <button class="btn" type="submit">Submit Application</button>
          </form>
        <% } %>
      </div>

      <div class="card">
        <h3>My applications</h3>
        <div class="table-wrap">
          <table>
            <tr><th>Club</th><th>Status</th><th>Applied on</th><th>Action</th></tr>
            <%= rows %>
          </table>
          <% if (rows.length() == 0) { %><p class="empty">You have not applied yet.</p><% } %>
        </div>
      </div>

    <% } %>
    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
