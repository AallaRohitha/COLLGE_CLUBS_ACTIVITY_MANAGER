<%@ page contentType="text/html;charset=UTF-8" %>
<%
    // Already logged in? Send to the right dashboard.
    if (session.getAttribute("userId") != null) {
        String r = (String) session.getAttribute("role");
        if ("admin".equals(r)) response.sendRedirect("adminDashboard.jsp");
        else if ("coordinator".equals(r)) response.sendRedirect("coordinatorDashboard.jsp");
        else response.sendRedirect("dashboard.jsp");
        return;
    }
    String msg = request.getParameter("msg");
    String ok = request.getParameter("ok");
    if (msg != null) msg = msg.replace("<", "&lt;").replace(">", "&gt;");
    if (ok != null) ok = ok.replace("<", "&lt;").replace(">", "&gt;");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login | LBRCE Club Activity Manager</title>
  <link rel="icon" href="images/logo.png">
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="auth-wrap">

  <div class="auth-left">
    <div class="auth-top">
      <img src="images/logo.png" class="auth-logo" alt="LBRCE logo" onerror="this.style.display='none'">
      <div class="auth-college">LAKIREDDY BALI REDDY<br>COLLEGE OF ENGINEERING<small>Club Activity Manager</small></div>
    </div>
    <h1>Club Activity<br>Manager</h1>
    <p>One place for every club in LBRCE. Join clubs, register for events and stay updated.</p>
    <ul>
      <li>Discover and join clubs</li>
      <li>Register for events in one click</li>
      <li>Read club announcements</li>
    </ul>
  </div>

  <div class="auth-right">
    <div class="auth-card">
      <img src="images/logo.png" class="mobile-logo" alt="LBRCE logo" onerror="this.style.display='none'">
      <h2>Welcome back</h2>
      <p class="sub">Login to continue</p>

      <% if (msg != null) { %><div class="alert alert-error"><%= msg %></div><% } %>
      <% if (ok != null)  { %><div class="alert alert-ok"><%= ok %></div><% } %>

      <form action="LoginServlet" method="post">
        <div class="field">
          <label>Email</label>
          <input type="email" name="email" placeholder="you@lbrce.ac.in" required>
        </div>
        <div class="field">
          <label>Password</label>
          <input type="password" name="password" placeholder="Enter your password" required>
        </div>
        <button class="btn btn-block" type="submit">Login</button>
      </form>

      <p class="auth-foot">New student? <a href="register.jsp">Create an account</a></p>
    </div>
  </div>

</div>
</body>
</html>
