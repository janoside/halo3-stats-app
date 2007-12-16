CREATE TABLE `halo3_clean`.`users` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `email` varchar(150)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`maps` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `image_url` varchar(150)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`playlists` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `ranked` boolean  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`game_types` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`players` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `service_tag` varchar(5)  NOT NULL,
  `insignia_url` varchar(150)  NOT NULL,
  `game_count` int NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`teams` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`weapons` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(100)  NOT NULL,
  `image_url` varchar(150)  NOT NULL,
  `icon_url` varchar(150)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;



CREATE TABLE `halo3_clean`.`medals` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `name` varchar(50)  NOT NULL,
  `icon_url` varchar(150)  NOT NULL,
  `image_url` varchar(150)  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`)
)
ENGINE = InnoDB;



CREATE TABLE `halo3_clean`.`user_logins` (
  `user_id` int  NOT NULL,
  `time` datetime  NOT NULL,
  CONSTRAINT `fk-user_logins-user_id` FOREIGN KEY `fk-user_logins-user_id` (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`games` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `map_id` int  NOT NULL,
  `playlist_id` int  NOT NULL,
  `game_type_id` int  NOT NULL,
  `length` int  NOT NULL DEFAULT 0,
  `time` datetime  NOT NULL,
  `loaded` boolean  NOT NULL DEFAULT 0,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`),
  CONSTRAINT `fk-games-map_id` FOREIGN KEY `fk-games-map_id` (`map_id`)
    REFERENCES `maps` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-games-playlist_id` FOREIGN KEY `fk-games-playlist_id` (`playlist_id`)
    REFERENCES `playlists` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-games-game_type_id` FOREIGN KEY `fk-games-game_type_id` (`game_type_id`)
    REFERENCES `game_types` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`user_players` (
  `user_id` int  NOT NULL,
  `player_id` int  NOT NULL,
  `visible` boolean  NOT NULL,
  `deleted` boolean  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  CONSTRAINT `fk-user_players-user_id` FOREIGN KEY `fk-user_players-user_id` (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-user_players-player_id` FOREIGN KEY `fk-user_players-player_id` (`player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`player_game_medals` (
  `player_id` int  NOT NULL,
  `game_id` int  NOT NULL,
  `medal_id` int  NOT NULL,
  `count` int  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  CONSTRAINT `fk-player_game_medals-player_id` FOREIGN KEY `fk-player_game_medals-player_id` (`player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_medals-game_id` FOREIGN KEY `fk-player_game_medals-game_id` (`game_id`)
    REFERENCES `games` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_medals-medal_id` FOREIGN KEY `fk-player_game_medals-medal_id` (`medal_id`)
    REFERENCES `medals` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`player_game_kills` (
  `killer_player_id` int  NOT NULL,
  `game_id` int  NOT NULL,
  `killed_player_id` int  NOT NULL,
  `count` int  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  CONSTRAINT `fk-player_game_kills-killer_player_id` FOREIGN KEY `fk-player_game_kills-killer_player_id` (`killer_player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_kills-game_id` FOREIGN KEY `fk-player_game_kills-game_id` (`game_id`)
    REFERENCES `games` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_kills-killed_player_id` FOREIGN KEY `fk-player_game_kills-killed_player_id` (`killed_player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;



CREATE TABLE `halo3_clean`.`player_game_weapon_kills` (
  `player_id` int  NOT NULL,
  `game_id` int  NOT NULL,
  `weapon_id` int  NOT NULL,
  `count` int  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  CONSTRAINT `fk-player_game_weapon_kills-player_id` FOREIGN KEY `fk-player_game_weapon_kills-player_id` (`player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_weapon_kills-game_id` FOREIGN KEY `fk-player_game_weapon_kills-game_id` (`game_id`)
    REFERENCES `games` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_game_weapon_kills-weapon_id` FOREIGN KEY `fk-player_game_weapon_kills-weapon_id` (`weapon_id`)
    REFERENCES `weapons` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`player_games` (
  `player_id` int  NOT NULL,
  `game_id` int  NOT NULL,
  `team_id` int  NOT NULL,
  `kills` int  NOT NULL,
  `assists` int  NOT NULL,
  `deaths` int  NOT NULL,
  `suicides` int  NOT NULL,
  `betrayals` int  NOT NULL,
  `headshots` int  NOT NULL,
  `best_spree` int  NOT NULL,
  `average_life` int  NOT NULL,
  `place` varchar(5)  NOT NULL,
  `score` int  NOT NULL,
  CONSTRAINT `fk-player_games-player_id` FOREIGN KEY `fk-player_games-player_id` (`player_id`)
    REFERENCES `players` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_games-game_id` FOREIGN KEY `fk-player_games-game_id` (`game_id`)
    REFERENCES `games` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT `fk-player_games-team_id` FOREIGN KEY `fk-player_games-team_id` (`team_id`)
    REFERENCES `teams` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;


CREATE TABLE `halo3_clean`.`user_game_filters` (
  `id` int  NOT NULL AUTO_INCREMENT,
  `user_id` int  NOT NULL,
  `name` varchar(50)  NOT NULL,
  `description` varchar(150) NOT NULL,
  `data` text  NOT NULL,
  `created_at` datetime  NOT NULL,
  `updated_at` datetime  NOT NULL,
  PRIMARY KEY(`id`),
  CONSTRAINT `fk-user_game_filters-user_id` FOREIGN KEY `fk-user_game_filters-user_id` (`user_id`)
    REFERENCES `users` (`id`)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
)
ENGINE = InnoDB;



