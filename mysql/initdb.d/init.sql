CREATE DATABASE IF NOT EXISTS testing;

CREATE USER 'mysql'@'%' IDENTIFIED BY 'mysql' PASSWORD EXPIRE;

GRANT ALL ON testing.* TO 'mysql'@'%';

GRANT PROCESS ON *.* TO 'mysql'@'%';

FLUSH PRIVILEGES;