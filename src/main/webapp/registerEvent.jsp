<%@ page contentType="text/html;charset=UTF-8" import="java.sql.*,com.club.util.*" %>
<%
    String idParam = request.getParameter("id");
    if (idParam == null) { response.sendRedirect("events.jsp"); return; }
    if ("admin".equals(session.getAttribute("role"))) { response.sendRedirect("events.jsp?msg=Admin+cannot+register+for+events"); return; }
    int eventId = Integer.parseInt(idParam);
    int myId = (Integer) session.getAttribute("userId");
    String msg = Html.esc(request.getParameter("msg"));

    String title = null, clubName = "", dateText = "", venue = "", myEmail = "";
    int left = 0, past = 0, already = 0;
    String pRoll = "", pBranch = "", pPhone = "";
    int pYear = 0;

    try (Connection con = DBUtil.getConnection()) {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT e.title, c.club_name, TO_CHAR(e.event_date, 'DD Mon YYYY'), e.venue, " +
                "e.max_seats - (SELECT COUNT(*) FROM event_registrations r WHERE r.event_id = e.event_id), " +
                "CASE WHEN e.event_date < TRUNC(SYSDATE) THEN 1 ELSE 0 END, " +
                "(SELECT COUNT(*) FROM event_registrations r2 WHERE r2.event_id = e.event_id AND r2.user_id = ?) " +
                "FROM events e JOIN clubs c ON c.club_id = e.club_id WHERE e.event_id = ?")) {
            ps.setInt(1, myId);
            ps.setInt(2, eventId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                title = rs.getString(1); clubName = rs.getString(2); dateText = rs.getString(3);
                venue = rs.getString(4); left = rs.getInt(5); past = rs.getInt(6); already = rs.getInt(7);
            }
        }
        try (PreparedStatement ps = con.prepareStatement("SELECT email FROM users WHERE user_id = ?")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) myEmail = rs.getString(1);
        }
        // fill the form from the join form the student already submitted, if any
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT roll_no, branch, year, phone FROM club_members WHERE user_id = ? AND roll_no IS NOT NULL AND ROWNUM = 1")) {
            ps.setInt(1, myId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) { pRoll = rs.getString(1); pBranch = rs.getString(2); pYear = rs.getInt(3); pPhone = rs.getString(4); }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    if (title == null)  { response.sendRedirect("events.jsp?msg=Event+not+found"); return; }
    if (past == 1)      { response.sendRedirect("events.jsp?msg=This+event+is+already+over"); return; }
    if (already > 0)    { response.sendRedirect("events.jsp?msg=You+are+already+registered+for+this+event"); return; }
    if (left <= 0)      { response.sendRedirect("events.jsp?msg=Sorry%2C+this+event+is+full"); return; }

    String[] branches = {"CSE", "IT", "ECE", "EEE", "Mechanical", "Civil", "Other"};
    StringBuilder branchOpts = new StringBuilder("<option value=''>-- Select --</option>");
    for (String b : branches) {
        branchOpts.append("<option" + (b.equals(pBranch) ? " selected" : "") + ">" + b + "</option>");
    }
    String[] yearNames = {"1st year", "2nd year", "3rd year", "4th year"};
    StringBuilder yearOpts = new StringBuilder("<option value=''>-- Select --</option>");
    for (int y = 1; y <= 4; y++) {
        yearOpts.append("<option value='" + y + "'" + (y == pYear ? " selected" : "") + ">" + yearNames[y - 1] + "</option>");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Event Registration | LBRCE Club Manager</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<div class="layout">
  <%@ include file="includes/sidebar.jsp" %>

  <main class="content">
    <div class="topline">
      <h1>Register: <%= Html.esc(title) %></h1>
      <p><%= Html.esc(clubName) %> &middot; <%= Html.esc(dateText) %> &middot; <%= Html.esc(venue) %> &middot; <%= left %> seat(s) left</p>
    </div>

    <% if (!msg.isEmpty()) { %><div class="alert alert-error" style="margin-top:18px"><%= msg %></div><% } %>

    <div class="card" style="margin-top:22px">
      <form action="eventRegisterAction" method="post">
        <input type="hidden" name="action" value="register">
        <input type="hidden" name="eventId" value="<%= eventId %>">
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
            <input type="text" name="rollNo" maxlength="20" value="<%= Html.esc(pRoll) %>" required>
          </div>
          <div class="field">
            <label>Phone number</label>
            <input type="text" name="phone" pattern="[0-9]{10}" maxlength="10" value="<%= Html.esc(pPhone) %>" placeholder="10 digits" required>
          </div>
          <div class="field">
            <label>Branch</label>
            <select name="branch" required><%= branchOpts %></select>
          </div>
          <div class="field">
            <label>Year</label>
            <select name="year" required><%= yearOpts %></select>
          </div>
        </div>
        <button class="btn" type="submit">Confirm Registration</button>
        <a class="btn btn-grey" href="events.jsp">Cancel</a>
      </form>
    </div>
  </main>
</div>
</body>
</html>
