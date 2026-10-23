package com.club.servlet;

import com.club.util.DBUtil;
import com.club.util.UploadUtil;
import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import java.util.Objects;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

// Coordinator: change the description and the image of his or her own club.
@MultipartConfig(maxFileSize = 2 * 1024 * 1024, maxRequestSize = 3 * 1024 * 1024)
@WebServlet("/coordinatorClubAction")
public class CoordinatorClubServlet extends HttpServlet {

    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int myId = (Integer) req.getSession().getAttribute("userId");
        String savedNew = null;
        boolean done = false;

        try (Connection con = DBUtil.getConnection()) {

            int clubId = -1;
            String oldImage = null;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT club_id, image_file FROM clubs WHERE coordinator_id = ?")) {
                ps.setInt(1, myId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) { clubId = rs.getInt(1); oldImage = rs.getString(2); }
            }
            if (clubId == -1) {
                go(res, "msg", "You do not manage any club yet");
                return;
            }

            String desc = req.getParameter("description").trim();
            Part img = req.getPart("image");
            boolean hasImg = img != null && img.getSize() > 0;

            String newImage = oldImage;
            if (hasImg) {
                savedNew = UploadUtil.save(img, "club", clubId);
                newImage = savedNew;
            } else if ("1".equals(req.getParameter("removeImage"))) {
                newImage = null;
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE clubs SET description = ?, image_file = ? WHERE club_id = ?")) {
                ps.setString(1, desc);
                ps.setString(2, newImage);
                ps.setInt(3, clubId);
                ps.executeUpdate();
            }
            done = true;
            if (!Objects.equals(oldImage, newImage)) UploadUtil.delete(oldImage);
            go(res, "ok", "Club details updated");

        } catch (IllegalStateException e) {
            go(res, "msg", "Image is too large (maximum 2 MB)");
        } catch (IllegalArgumentException e) {
            go(res, "msg", e.getMessage());
        } catch (Exception e) {
            if (savedNew != null && !done) UploadUtil.delete(savedNew);
            e.printStackTrace();
            go(res, "msg", "Something went wrong");
        }
    }

    private void go(HttpServletResponse res, String key, String text) throws IOException {
        res.sendRedirect("coordinatorClub.jsp?" + key + "=" + URLEncoder.encode(text, "UTF-8"));
    }
}
