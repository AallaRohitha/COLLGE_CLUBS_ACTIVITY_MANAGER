<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String msg = Html.esc(request.getParameter("msg"));
    String ok  = Html.esc(request.getParameter("ok"));
    int myId = (Integer) session.getAttribute("userId");
    String pName = "", pEmail = "";

    try (Connection con = DBUtil.getConnection();
         PreparedStatement ps = con.prepareStatement("SELECT name, email FROM users WHERE user_id = ?")) {
        ps.setInt(1, myId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) { pName = rs.getString(1); pEmail = rs.getString(2); }
    } catch (Exception e) {
        msg = "Database error: " + Html.esc(e.getMessage());
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Profile | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>My Profile</h1>
      <p>Update your name or change your password.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>
    <% if (!ok.isEmpty())  { %><div class="alert alert-ok" style="margin-top:18px"><%= ok %></div><% } %>

    <div class="card" style="margin-top:22px; max-width:640px">
      <h3>Personal details</h3>
      <form action="profileAction" method="post">
        <input type="hidden" name="action" value="updateName">
        <div class="field">
          <label>Email (cannot be changed)</label>
          <input type="text" class="readonly" value="<%= Html.esc(pEmail) %>" readonly>
        </div>
        <div class="field">
          <label>Name</label>
          <input type="text" name="name" maxlength="100" value="<%= Html.esc(pName) %>" required>
        </div>
        <button class="btn" type="submit">Save Name</button>
      </form>
    </div>

    <div class="card" style="max-width:640px">
      <h3>Change password</h3>
      <form action="profileAction" method="post">
        <input type="hidden" name="action" value="changePassword">
        <div class="field">
          <label>Current password</label>
          <input type="password" name="currentPassword" required>
        </div>
        <div class="field">
          <label>New password (min 6 characters)</label>
          <input type="password" name="newPassword" minlength="6" required>
        </div>
        <div class="field">
          <label>Confirm new password</label>
          <input type="password" name="confirmPassword" minlength="6" required>
        </div>
        <button class="btn" type="submit">Change Password</button>
      </form>
    </div>

    <div class="footer">Lakireddy Bali Reddy College of Engineering</div>
  </main>
</div>
</body>
</html>
