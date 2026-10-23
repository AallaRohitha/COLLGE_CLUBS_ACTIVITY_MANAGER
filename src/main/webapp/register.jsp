<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String msg = request.getParameter("msg");
    if (msg != null) msg = msg.replace("<", "&lt;").replace(">", "&gt;");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Register | LBRCE Club Activity Manager</title>
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
    <h1>Join the<br>Community</h1>
    <p>Create your student account and start exploring the clubs of LBRCE.</p>
  </div>

  <div class="auth-right">
    <div class="auth-card">
      <img src="images/logo.png" class="mobile-logo" alt="LBRCE logo" onerror="this.style.display='none'">
      <h2>Create account</h2>
      <p class="sub">Student registration</p>

      <% if (msg != null) { %><div class="alert alert-error"><%= msg %></div><% } %>

      <form action="RegisterServlet" method="post">
        <div class="field">
          <label>Full name</label>
          <input type="text" name="name" required>
        </div>
        <div class="field">
          <label>Email</label>
          <input type="email" name="email" required>
        </div>
        <div class="field">
          <label>Password (min 6 characters)</label>
          <input type="password" name="password" minlength="6" required>
        </div>
        <button class="btn btn-block" type="submit">Register</button>
      </form>

      <p class="auth-foot">Already registered? <a href="login.jsp">Login</a></p>
    </div>
  </div>

</div>
</body>
</html>
