CREATE TABLE IF NOT EXISTS `lz_trash_system` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `prop_model` varchar(50) DEFAULT 'prop_bin_05a',
  `coords` longtext DEFAULT NULL,
  `heading` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;