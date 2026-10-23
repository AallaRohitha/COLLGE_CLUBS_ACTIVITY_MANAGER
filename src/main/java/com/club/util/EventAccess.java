package com.club.util;

import java.sql.*;

// Who is allowed to manage a club's events?
//   - the coordinator of that club
//   - any approved member of that club
public class EventAccess {

    public static boolean isCoordinator(Connection con, int userId, int clubId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM clubs WHERE club_id = ? AND coordinator_id = ?")) {
            ps.setInt(1, clubId);
            ps.setInt(2, userId);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1) > 0;
        }
    }

    public static boolean isApprovedMember(Connection con, int userId, int clubId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT COUNT(*) FROM club_members WHERE club_id = ? AND user_id = ? AND status = 'approved'")) {
            ps.setInt(1, clubId);
            ps.setInt(2, userId);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1) > 0;
        }
    }

    public static boolean canManage(Connection con, int userId, int clubId) throws SQLException {
        return isCoordinator(con, userId, clubId) || isApprovedMember(con, userId, clubId);
    }

    // returns the club of an event, or -1 if the event does not exist
    public static int clubOfEvent(Connection con, int eventId) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement("SELECT club_id FROM events WHERE event_id = ?")) {
            ps.setInt(1, eventId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }
}
