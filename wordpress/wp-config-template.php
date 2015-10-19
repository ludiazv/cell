<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '{{ getenv "CELL_DB" }}');

/** MySQL database username */
define('DB_USER', '{{ getenv "CELL_USER" }}');

/** MySQL database password */
define('DB_PASSWORD', '{{ getenv "CELL_PWD" }}');

/** MySQL hostname */
define('DB_HOST', '{{ getenv "CELL_DB_IP" }}:{{ getenv "CELL_DB_PORT" }}');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'D>z+ZX;6CaVbC,#!:DbIC#2D[^M0Ka|jkZz2$-wSDaE(lu5n/F7XHFqnh(28C(6c');
define('SECURE_AUTH_KEY',  '-#B1-K]GFTI_D4C4|8RcF2vYJs^L1U$Ih`xwG_wfEB&/ly#cgxO6RA!C8L`jPKP}');
define('LOGGED_IN_KEY',    'cJmY/-qJYFx&aX4!RBIdC{[Z,N08v)-|[r~u.()ZS 4`+d30&9v$[Qmj2cuUF2_r');
define('NONCE_KEY',        'o-rLSF(F3KJTN?leY)M!Z(#qSSQ|Qk/guAlnp|5:sMoo@{=5UR]pVNuhAjU|owZq');
define('AUTH_SALT',        '&-LV_,:+>2!-xoH}paXnRc@E5~>[;nP*</)yP/@onwmgI-*ZjeFYa@L4F[jvb_$H');
define('SECURE_AUTH_SALT', ';p8PojE)I5|-X^Ws,bVsEModk7nh^YN><vCQ)4x]S&j{4-dD5VZJ+,=:bZW?{6-f');
define('LOGGED_IN_SALT',   'y+f^>,?-7Ofb?Ku?.[:%aW#-(OSp9 :~%^@klhXdC22+?FLQ`PDqG!gg5hjhR{yM');
define('NONCE_SALT',       'oQt9V!e9`.G>],sQ@$aNwcTnL/*l_U{q.}:nS^dfs8Ru-Myk&N=0v1e-Mgts?k}y');
/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');