package com.club.util;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBUtil {
    private static final String URL  = "jdbc:oracle:thin:@localhost:1521:XE";
    private static final String USER = "yourusername";          // your Oracle username
    private static final String PASS = "yourpassword";    // your Oracle password

    public static Connection getConnection() throws Exception {
        Class.forName("oracle.jdbc.OracleDriver");
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
