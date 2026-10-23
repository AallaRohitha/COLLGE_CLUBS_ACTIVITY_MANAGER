-- =====================================================================
--  College Clubs Activity Manager  -  Oracle 11g XE database script
--  Run in "Run SQL Command Line":
--      connect system/yourpassword
--      @C:\path\to\database.sql
--  The DROP statements show errors the first time (nothing to drop yet).
--  That is normal.
-- =====================================================================

DROP TABLE coordinator_requests;
DROP TABLE announcements;
DROP TABLE event_registrations;
DROP TABLE events;
DROP TABLE club_members;
DROP TABLE clubs;
DROP TABLE users;

DROP SEQUENCE users_seq;
DROP SEQUENCE clubs_seq;
DROP SEQUENCE members_seq;
DROP SEQUENCE events_seq;
DROP SEQUENCE regs_seq;
DROP SEQUENCE ann_seq;
DROP SEQUENCE req_seq;

-- ---------- Sequences (Oracle 11g has no auto-increment) ----------
CREATE SEQUENCE users_seq   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE clubs_seq   START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE members_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE events_seq  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE regs_seq    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE ann_seq     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE req_seq     START WITH 1 INCREMENT BY 1;

-- ---------- Users: admin / coordinator / student ----------
CREATE TABLE users (
  user_id  NUMBER PRIMARY KEY,
  name     VARCHAR2(100) NOT NULL,
  email    VARCHAR2(100) NOT NULL UNIQUE,
  password VARCHAR2(100) NOT NULL,                 -- SHA-256 hash
  role     VARCHAR2(20) DEFAULT 'student' NOT NULL
);

-- ---------- Clubs ----------
CREATE TABLE clubs (
  club_id        NUMBER PRIMARY KEY,
  club_name      VARCHAR2(100) NOT NULL,
  description    VARCHAR2(500),
  coordinator_id NUMBER REFERENCES users(user_id) ON DELETE SET NULL,
  image_file     VARCHAR2(200)                     -- file name of the club image
);

-- ---------- Join requests and memberships (includes the join form) ----------
CREATE TABLE club_members (
  member_id   NUMBER PRIMARY KEY,
  club_id     NUMBER NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
  user_id     NUMBER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  roll_no     VARCHAR2(20),
  branch      VARCHAR2(50),
  year        NUMBER(1),
  phone       VARCHAR2(15),
  reason      VARCHAR2(300),
  status      VARCHAR2(20) DEFAULT 'pending',      -- pending / approved / rejected
  joined_date DATE DEFAULT SYSDATE,
  CONSTRAINT uq_member UNIQUE (club_id, user_id)
);

-- ---------- Events ----------
CREATE TABLE events (
  event_id    NUMBER PRIMARY KEY,
  club_id     NUMBER NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
  title       VARCHAR2(150) NOT NULL,
  description VARCHAR2(500),
  event_date  DATE,
  venue       VARCHAR2(100),
  max_seats   NUMBER DEFAULT 50,
  image_file  VARCHAR2(200)                        -- file name of the event image
);

-- ---------- Event registrations (includes the registration form) ----------
CREATE TABLE event_registrations (
  reg_id   NUMBER PRIMARY KEY,
  event_id NUMBER NOT NULL REFERENCES events(event_id) ON DELETE CASCADE,
  user_id  NUMBER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  reg_date DATE DEFAULT SYSDATE,
  roll_no  VARCHAR2(20),
  branch   VARCHAR2(50),
  year     NUMBER(1),
  phone    VARCHAR2(15),
  CONSTRAINT uq_reg UNIQUE (event_id, user_id)
);

-- ---------- Announcements ----------
CREATE TABLE announcements (
  ann_id      NUMBER PRIMARY KEY,
  club_id     NUMBER NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
  title       VARCHAR2(150) NOT NULL,
  message     VARCHAR2(500),
  posted_date DATE DEFAULT SYSDATE
);

-- ---------- Coordinator applications ----------
CREATE TABLE coordinator_requests (
  req_id   NUMBER PRIMARY KEY,
  user_id  NUMBER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  club_id  NUMBER NOT NULL REFERENCES clubs(club_id) ON DELETE CASCADE,
  reason   VARCHAR2(300),
  status   VARCHAR2(20) DEFAULT 'pending',         -- pending / approved / rejected
  req_date DATE DEFAULT SYSDATE,
  CONSTRAINT uq_coord_req UNIQUE (user_id, club_id)
);

-- ---------- Default admin account ----------
-- Email: admin@lbrce.ac.in      Password: admin123   (change it after the first login)
INSERT INTO users VALUES (users_seq.NEXTVAL, 'Admin', 'admin@lbrce.ac.in', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin');
COMMIT;
