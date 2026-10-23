package com.club.util;

import java.sql.*;

// Small helper: run a "SELECT COUNT(*) ..." query and return the number.
public class Stats {
    public static int scalar(Connection con, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            ResultSet rs = ps.executeQuery();
            rs.next();
            return rs.getInt(1);
        }
    }
}
