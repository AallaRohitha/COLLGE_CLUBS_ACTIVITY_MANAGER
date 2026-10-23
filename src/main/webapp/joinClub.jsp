<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("clubs.jsp"); return; }
    int clubId = Integer.parseInt(idParam);
    int myId = (Integer) session.getAttribute("userId");
    String msg = Html.esc(request.getParameter("msg"));

    String clubName = null, myEmail = "", status = null;
    boolean isCoordOfClub = false;
    try (Connection con = DBUtil.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement("SELECT club_name, coordinator_id FROM clubs WHERE club_id = ?")) {
            ps.setInt(1, clubId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { clubName = rs.getString(1); isCoordOfClub = rs.getInt(2) == myId; }
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT email FROM users WHERE user_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) myEmail = rs.getString(1);
        }
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT status FROM club_members WHERE club_id = ? AND user_id = ?")) {
            ps.setInt(1, clubId);
            ps.setInt(2, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) status = rs.getString(1);
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    if (clubName == null) { response.sendRedirect("clubs.jsp?msg=Club+not+found"); return; }
    if (isCoordOfClub) {
        response.sendRedirect("clubs.jsp?msg=You+are+the+coordinator+of+this+club");
        return;
    }
    if ("pending".equals(status) || "approved".equals(status)) {
        response.sendRedirect("clubs.jsp?msg=You+already+applied+to+this+club");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Join Club | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Join: <%= Html.esc(clubName) %></h1>
      <p>Fill this registration form. The club coordinator will review it.</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>

    <div class="card" style="margin-top:22px">
      <form action="joinClubAction" method="post">
        <input type="hidden" name="action" value="join">
        <input type="hidden" name="clubId" value="<%= clubId %>">

        <div class="form-row">
          <div class="field">
            <label>Name</label>
            <input type="text" class="readonly" value="<%= Html.esc((String) session.getAttribute("userName")) %>" readonly>
          </div>
          <div class="field">
            <label>Email</label>
            <input type="text" class="readonly" value="<%= Html.esc(myEmail) %>" readonly>
          </div>
          <div class="field">
            <label>Roll number</label>
            <input type="text" name="rollNo" maxlength="20" placeholder="e.g. 22761A0501" required>
          </div>
          <div class="field">
            <label>Phone number</label>
            <input type="text" name="phone" pattern="[0-9]{10}" maxlength="10" placeholder="10 digits" required>
          </div>
          <div class="field">
            <label>Branch</label>
            <select name="branch" required>
              <option value="">-- Select --</option>
              <option>CSE</option><option>IT</option><option>ECE</option><option>EEE</option>
              <option>Mechanical</option><option>Civil</option><option>Other</option>
            </select>
          </div>
          <div class="field">
            <label>Year</label>
            <select name="year" required>
              <option value="">-- Select --</option>
              <option value="1">1st year</option><option value="2">2nd year</option>
              <option value="3">3rd year</option><option value="4">4th year</option>
            </select>
          </div>
          <div class="field full">
            <label>Why do you want to join?</label>
            <textarea name="reason" maxlength="300" required></textarea>
          </div>
        </div>

        <button class="btn" type="submit">Submit Request</button>
        <a class="btn btn-grey" href="clubs.jsp">Cancel</a>
      </form>
    </div>
  </main>
</div>
</body>
</html>
