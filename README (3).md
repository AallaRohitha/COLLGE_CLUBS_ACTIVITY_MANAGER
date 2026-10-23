# College Clubs Activity Manager

A web application for **Lakireddy Bali Reddy College of Engineering (LBRCE)** to manage college clubs, their members, events and announcements. It is built with **JSP, Servlets and JDBC** on an **Oracle** database, and uses **HttpSession** for login and role-based access.

> Developed as a Full Stack Development (FSD) lab project.

## Features

### Student
- Register and log in
- Browse all clubs (with images) and search by name
- Send a **join request** using a registration form
- Register for events with a **registration form** (seat limit is checked)
- See club announcements on the dashboard
- Apply to become the **coordinator** of a club (only for clubs where the student is an approved member)
- Edit profile and change password

### Approved member
- Add and edit events of the club
- See the registrations of those events

### Coordinator
- Approve or reject join requests, and remove members
- See the full member list of the club
- Add, edit and delete events (with images)
- Post announcements
- Change the club image and description

### Admin
- Add and edit clubs (with images)
- Approve or reject join requests of any club
- Choose the coordinator of a club from its approved members
- Approve or reject coordinator applications
- See all events and their registrations
- Manage users

## How roles work

| Role | How a user gets it |
|---|---|
| Student | Registers on the website |
| Coordinator | Chosen by the admin from a club's approved members, or approved after applying |
| Admin | Created in the database script |

## Sessions and security

- `HttpSession` stores the user id, name, role and login time after login.
- `AuthFilter` protects every page: users who are not logged in go to the login page, and pages starting with `/admin` or `/coordinator` are limited to those roles.
- Session timeout is 30 minutes, with a countdown in the menu and an automatic logout.
- `LogoutServlet` ends the session with `session.invalidate()`.
- Passwords are stored as SHA-256 hashes.
- All database queries use `PreparedStatement` (protects against SQL injection).
- Uploaded images are checked by their file header (only real JPG and PNG files, maximum 2 MB).

## Technologies

- Java 17 or higher
- JSP and Servlets (Jakarta Servlet 6, Apache Tomcat 11)
- JDBC
- Oracle Database 11g Express Edition
- HTML and CSS (no framework)

## Project structure

```
src/main
├── java/com/club
│   ├── filter    AuthFilter
│   ├── servlet   Login, Register, Logout, Join club, Events, Admin and Coordinator servlets, image servlets
│   └── util      DBUtil, PasswordUtil, Html, EventAccess, Stats, UploadUtil
└── webapp
    ├── css/style.css
    ├── images/logo.png        (college logo)
    ├── includes               sidebar.jsp, lightbox.jsp
    ├── WEB-INF/web.xml
    └── *.jsp                  all pages
database.sql                   creates the database tables
```

## How to run

### 1. Requirements
- JDK 17 or higher
- Apache Tomcat 11
- Oracle Database 11g XE
- Eclipse IDE for Enterprise Java (or any IDE with Tomcat support)
- Oracle JDBC driver (`ojdbc8.jar`), downloaded from Oracle's website

### 2. Create the database
1. Open **Run SQL Command Line**.
2. Type: `connect system/yourpassword`
3. Run the script: `@C:\path\to\database.sql`

### 3. Set up the project
1. Create a **Dynamic Web Project** in Eclipse and copy the `src` folder into it.
2. Put `ojdbc8.jar` in `src/main/webapp/WEB-INF/lib`.
3. Open `com/club/util/DBUtil.java` and set your Oracle username and password:
   ```java
   private static final String USER = "system";
   private static final String PASS = "yourpassword";
   ```
4. Add your college logo as `src/main/webapp/images/logo.png`.
5. Right-click the project, choose **Run As, Run on Server**, and select Tomcat 11.

If you use Tomcat 9 or lower, replace `jakarta.servlet` with `javax.servlet` in the Java files.

### 4. Open the website

`http://localhost:8080/<project-name>/`

Default admin login:

| Email | Password |
|---|---|
| admin@lbrce.ac.in | admin123 |

Change the admin password after the first login (Profile page).

## Typical workflow

1. The admin adds a club.
2. Students register, log in and send join requests.
3. The admin or the coordinator approves the requests.
4. The admin chooses a coordinator from the approved members (or approves a student's coordinator application).
5. The coordinator and approved members add events and announcements.
6. Students register for events with the registration form.

## Uploaded images

Event and club images are saved in a folder named `club_uploads` inside the user's home folder (for example `C:\Users\<name>\club_uploads`), not in the project. The database stores only the file names.

## Screenshots

Add your screenshots here (login page, student dashboard, clubs page, admin panel).

## Author

Aalla Rohitha, Department of Computer Science and Engineering, LBRCE
