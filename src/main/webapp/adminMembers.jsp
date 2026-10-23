<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    StringBuilder pending = new StringBuilder();
    StringBuilder members = new StringBuilder();

    String sql = "SELECT m.member_id, c.club_name, u.name, u.email, m.roll_no, m.branch, m.year, m.phone, m.reason, " +
                 "TO_CHAR(m.joined_date, 'DD Mon YYYY'), m.status " +
                 "FROM club_members m JOIN users u ON u.user_id = m.user_id JOIN clubs c ON c.club_id = m.club_id " +
                 "WHERE m.status IN ('pending', 'approved') ORDER BY c.club_name, m.joined_date";
    try (Connection con = DBUtil.getConnection();
         Statement st = con.createStatement();
         ResultSet rs = st.executeQuery(sql)) {
        while (rs.next()) {
            int mid = rs.getInt(1);
            String branchYear = Html.esc(rs.getString(6)) + " / Year " + rs.getInt(7);
            if ("pending".equals(rs.getString(11))) {
                pending.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                    + "<td><b>" + Html.esc(rs.getString(3)) + "</b><br><small>" + Html.esc(rs.getString(4)) + "</small></td>"
                    + "<td>" + Html.esc(rs.getString(5)) + "</td>"
                    + "<td>" + branchYear + "</td>"
                    + "<td>" + Html.esc(rs.getString(8)) + "</td>"
                    + "<td class='reason-cell'>" + Html.esc(rs.getString(9)) + "</td>"
                    + "<td>" + Html.esc(rs.getString(10)) + "</td>"
                    + "<td class='actions'>"
                    + "<form class='inline' action='adminMemberAction' method='post'><input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='approve'><button class='btn btn-small btn-green' type='submit'>Approve</button></form> "
                    + "<form class='inline' action='adminMemberAction' method='post'><input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='reject'><button class='btn btn-small btn-red' type='submit'>Reject</button></form>"
                    + "</td></tr>");
            } else {
                members.append("<tr><td><b>" + Html.esc(rs.getString(2)) + "</b></td>"
                    + "<td>" + Html.esc(rs.getString(3)) + "</td>"
                    + "<td>" + Html.esc(rs.getString(4)) + "</td>"
                    + "<td>" + Html.esc(rs.getString(5)) + "</td>"
                    + "<td>" + branchYear + "</td>"
                    + "<td class='actions'><form class='inline' action='adminMemberAction' method='post' onsubmit=\"return confirm('Remove this member?');\">"
                    + "<input type='hidden' name='memberId' value='" + mid + "'><input type='hidden' name='action' value='remove'>"
                    + "<button class='btn btn-small btn-red' type='submit'>Remove</button></form></td></tr>");
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
  <title>Join Requests | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Join Requests and Members</h1>
      <p>Approve students for any club. Coordinators can also approve members of their own club.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px">
      <h3>Pending join requests</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Club</th><th>Student</th><th>Roll no</th><th>Branch / Year</th><th>Phone</th><th>Reason</th><th>Applied</th><th>Action</th></tr>
          <%= pending %>
        </table>
        <% if (pending.length() == 0) { %><p class="empty">No pending requests.</p><% } %>
      </div>
    </div>

    <div class="card">
      <h3>Approved members</h3>
      <div class="table-wrap">
        <table>
          <tr><th>Club</th><th>Name</th><th>Email</th><th>Roll no</th><th>Branch / Year</th><th>Action</th></tr>
          <%= members %>
        </table>
        <% if (members.length() == 0) { %><p class="empty">No members yet.</p><% } %>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
