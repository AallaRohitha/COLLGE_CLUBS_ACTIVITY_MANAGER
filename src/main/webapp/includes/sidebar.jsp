<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String sbRole = (String) session.getAttribute("role");
    String sbName = (String) session.getAttribute("userName");
    String sbLogin = (String) session.getAttribute("loginTime");

    // Students who are approved members of a club also get "Manage Events"
    boolean sbCanManage = false;
    if ("student".equals(sbRole)) {
        try (Connection sbCon = DBUtil.getConnection();
             PreparedStatement sbPs = sbCon.prepareStatement(
                 "SELECT COUNT(*) FROM club_members WHERE user_id = ? AND status = 'approved'")) {
            sbPs.setInt(1, (Integer) session.getAttribute("userId"));
            ResultSet sbRs = sbPs.executeQuery();
            if (sbRs.next()) sbCanManage = sbRs.getInt(1) > 0;
        } catch (Exception ignored) { }
    }
%>
<aside class="sidebar">
  <div class="brand">
    <img src="images/logo.png" class="brand-logo" alt="LBRCE logo" onerror="this.style.display='none'">
    <div>
      <div class="b-title">LBRCE</div>
      <div class="b-sub">Lakireddy Bali Reddy<br>College of Engineering</div>
    </div>
  </div>

  <div class="userbox">
    <div class="uname"><%= Html.esc(sbName) %></div>
    <span class="role-tag"><%= sbRole %></span>
  </div>

  <div class="session-box">
    Logged in: <b><%= Html.esc(sbLogin) %></b><br>
    Session ends in: <b id="sessionTimer">--:--</b>
  </div>

  <nav class="nav">
  <% if ("admin".equals(sbRole)) { %>
      <a href="adminDashboard.jsp">Dashboard</a>
      <a href="clubs.jsp">All Clubs</a>
      <a href="adminClubs.jsp">Manage Clubs</a>
      <a href="adminMembers.jsp">Join Requests</a>
      <a href="adminEvents.jsp">All Events</a>
      <a href="adminCoordinatorRequests.jsp">Coordinator Requests</a>
      <a href="adminUsers.jsp">Manage Users</a>
      <a href="profile.jsp">Profile</a>

  <% } else if ("coordinator".equals(sbRole)) { %>
      <a href="coordinatorDashboard.jsp">Dashboard</a>
      <a href="coordinatorClub.jsp">My Club</a>
      <a href="coordinatorRequests.jsp">Members and Requests</a>
      <a href="manageEvents.jsp">Manage Events</a>
      <a href="coordinatorAnnouncements.jsp">Announcements</a>
      <div class="sec">AS A STUDENT</div>
      <a href="clubs.jsp">All Clubs</a>
      <a href="events.jsp">Events</a>
      <a href="myEvents.jsp">My Registrations</a>
      <a href="profile.jsp">Profile</a>

  <% } else { %>
      <a href="dashboard.jsp">Dashboard</a>
      <a href="clubs.jsp">All Clubs</a>
      <a href="myClubs.jsp">My Clubs</a>
      <a href="events.jsp">Events</a>
      <a href="myEvents.jsp">My Registrations</a>
      <% if (sbCanManage) { %>
        <div class="sec">CLUB MEMBER</div>
        <a href="manageEvents.jsp">Manage Events</a>
      <% } %>
      <div class="sec">MORE</div>
      <a href="applyCoordinator.jsp">Become a Coordinator</a>
      <a href="profile.jsp">Profile</a>
  <% } %>
  </nav>

  <a class="nav logout" href="LogoutServlet" style="display:block;padding:11px;border-radius:10px;color:#fecaca;">Logout</a>
</aside>

<script>
// Session countdown. Every click on the site restarts the session on the server (and this timer on the new page).
// When it reaches zero the user is logged out.
(function () {
  var left = <%= session.getMaxInactiveInterval() %>;
  var el = document.getElementById('sessionTimer');
  function tick() {
    var m = Math.floor(left / 60), s = left % 60;
    el.textContent = m + ':' + (s < 10 ? '0' : '') + s;
    if (left <= 0) { window.location = 'LogoutServlet?expired=1'; return; }
    left--;
  }
  tick();
  setInterval(tick, 1000);
})();
</script>
