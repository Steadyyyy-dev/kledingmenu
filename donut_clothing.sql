-- SQL voor donut_clothing
CREATE TABLE IF NOT EXISTS `donut_outfits` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,
  `name` VARCHAR(64) NOT NULL,
  `appearance` LONGTEXT NOT NULL,
  `share_code` VARCHAR(16) UNIQUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
