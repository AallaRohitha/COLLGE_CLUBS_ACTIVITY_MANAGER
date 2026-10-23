<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    StringBuilder pending = new StringBuilder();
    StringBuilder history = new StringBuilder();

    String sql = "SELECT r.req_id, u.name, u.email, c.club_name, r.reason, r.status, TO_CHAR(r.req_date, 'DD Mon YYYY') " +
                 "FROM coordinator_requests r JOIN users u ON u.user_id = r.user_id JOIN clubs c ON c.club_id = r.club_id " +
                 "ORDER BY r.req_date DESC";
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(sql)) {
        while (rs.next()) {
            int id = rs.getInt(1);
            String status = rs.getString(6);
            String who = "<td><b>" + Html.esc(rs.getString(2)) + "</b><br><small>" + Html.esc(rs.getString(3)) + "</small></td>"
                       + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                       + "<td class='reason-cell'>" + Html.esc(rs.getString(5)) + "</td>"
                       + "<td>" + Html.esc(rs.getString(7)) + "</td>";
            if ("pending".equals(status)) {
                pending.append("<tr>" + who + "<td class='actions'>"
                    + "<form class='inline' action='adminCoordinatorRequestAction' method='post'><input type='hidden' name='reqId' value='" + id + "'><input type='hidden' name='action' value='approve'><button class='btn btn-small btn-green' type='submit'>Approve</button></form> "
                    + "<form class='inline' action='adminCoordinatorRequestAction' method='post'><input type='hidden' name='reqId' value='" + id + "'><input type='hidden' name='action' value='reject'><button class='btn btn-small btn-red' type='submit'>Reject</button></form>"
                    + "</td></tr>");
            } else {
                String badge = "approved".equals(status) ? "<span class='badge badge-ok'>Approved</span>" : "<span class='badge badge-no'>Rejected</span>";
                history.append("<tr>" + who + "<td>" + badge + "</td></tr>");
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
  <title>Coordinator Requests | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Coordinator Requests</h1>
      <p>Students who want to lead a club. Approving makes the student the coordinator of that club.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <h3>Waiting for your decision</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Student</th><th>Club</th><th>Reason</th><th>Applied</th><th>Action</th></tr>
          <%= pending %>
        </table>
        <% if (pending.length() == 0) { %><p class="empty">No pending applications.</p><% } %>
      </div>
    </div>

    <div class="card">
      <h3>Earlier decisions</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Student</th><th>Club</th><th>Reason</th><th>Applied</th><th>Result</th></tr>
          <%= history %>
        </table>
        <% if (history.length() == 0) { %><p class="empty">Nothing here yet.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
