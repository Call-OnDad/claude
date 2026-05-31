-- Social Media Post Queue
-- Run against Callon-dad database on MariaDB (192.168.0.6)
-- mysql -u admin -p Callon-dad < social_posts.sql

CREATE TABLE IF NOT EXISTS `social_posts` (
  `id`               INT AUTO_INCREMENT PRIMARY KEY,
  `content`          TEXT NOT NULL,
  `image_url`        VARCHAR(1000) DEFAULT NULL,
  `link_url`         VARCHAR(1000) DEFAULT NULL,
  `post_twitter`     TINYINT(1) NOT NULL DEFAULT 0,
  `post_facebook`    TINYINT(1) NOT NULL DEFAULT 0,
  `post_instagram`   TINYINT(1) NOT NULL DEFAULT 0,
  `scheduled_at`     DATETIME NOT NULL,
  `status`           ENUM('pending','processing','posted','failed') NOT NULL DEFAULT 'pending',
  `twitter_status`   ENUM('pending','posted','failed','skipped') NOT NULL DEFAULT 'skipped',
  `facebook_status`  ENUM('pending','posted','failed','skipped') NOT NULL DEFAULT 'skipped',
  `instagram_status` ENUM('pending','posted','failed','skipped') NOT NULL DEFAULT 'skipped',
  `posted_at`        DATETIME DEFAULT NULL,
  `error_log`        TEXT DEFAULT NULL,
  `created_at`       DATETIME DEFAULT NOW(),
  INDEX `idx_status_scheduled` (`status`, `scheduled_at`),
  INDEX `idx_scheduled_at` (`scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Example post (runs 10 minutes from now)
-- INSERT INTO social_posts (content, image_url, post_twitter, post_facebook, post_instagram, scheduled_at)
-- VALUES ('Test post from n8n scheduler!', NULL, 1, 1, 0, DATE_ADD(NOW(), INTERVAL 10 MINUTE));
