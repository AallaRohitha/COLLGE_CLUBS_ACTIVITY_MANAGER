package com.club.filter;

import java.io.IOException;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;

// One filter protects the whole site.
//  - Not logged in      -> sent to login page
//  - Pages starting with /admin       -> admin only
//  - Pages starting with /coordinator -> coordinator only
@WebFilter("/*")
public class AuthFilter implements Filter {

    private boolean isPublic(String path) {
        return path.equals("/") || path.isEmpty()
            || path.equals("/login.jsp") || path.equals("/register.jsp")
            || path.equals("/LoginServlet") || path.equals("/RegisterServlet")
            || path.startsWith("/css/") || path.startsWith("/images/");
    }

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String path = req.getServletPath();

        // Stop the browser from showing old pages after logout (back button)
        res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setDateHeader("Expires", 0);

        if (isPublic(path)) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            // had a session cookie that is no longer valid  ->  the session expired
            boolean expired = req.getRequestedSessionId() != null && !req.isRequestedSessionIdValid();
            res.sendRedirect(req.getContextPath() + "/login.jsp?msg="
                + (expired ? "Your+session+has+expired.+Please+login+again." : "Please+login+first"));
            return;
        }

        String role = (String) session.getAttribute("role");
        boolean blocked =
              (path.startsWith("/admin") && !"admin".equals(role))
           || (path.startsWith("/coordinator") && !"coordinator".equals(role));

        if (blocked) {
            res.sendError(HttpServletResponse.SC_FORBIDDEN, "You are not allowed to open this page.");
            return;
        }
        chain.doFilter(request, response);
    }
}
