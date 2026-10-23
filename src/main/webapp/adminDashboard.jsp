<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    int nClubs = 0, nUsers = 0, nEvents = 0, nReq = 0;
    try (Connection con = DBUtil.getConnection()) {
        nClubs  = Stats.scalar(con, "SELECT COUNT(*) FROM clubs");
        nUsers  = Stats.scalar(con, "SELECT COUNT(*) FROM users WHERE role <> 'admin'");
        nEvents = Stats.scalar(con, "SELECT COUNT(*) FROM events");
        nReq    = Stats.scalar(con, "SELECT COUNT(*) FROM coordinator_requests WHERE status = 'pending'");
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Admin Dashboard | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Welcome, <%= Html.esc((String) session.getAttribute("userName")) %></h1>
      <p>Manage clubs and users of LBRCE.</p>
    </div>

    <div class="stats">
      <div class="stat"><div class="num"><%= nClubs %></div><div class="lbl">Clubs</div></div>
      <div class="stat"><div class="num"><%= nUsers %></div><div class="lbl">Students and coordinators</div></div>
      <div class="stat"><div class="num"><%= nEvents %></div><div class="lbl">Events</div></div>
      <div class="stat"><div class="num"><%= nReq %></div><div class="lbl">Coordinator requests waiting</div></div>
    </div>

    <div class="card">
      <h3>Quick links</h3>
      <div class="quick">
        <a class="btn" href="adminClubs.jsp">Add or edit clubs</a>
        <a class="btn btn-grey" href="adminMembers.jsp">Join requests</a>
        <a class="btn btn-grey" href="adminEvents.jsp">All events</a>
        <a class="btn btn-grey" href="adminCoordinatorRequests.jsp">Coordinator requests</a>
        <a class="btn btn-grey" href="adminUsers.jsp">Manage users</a>
      </div>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
