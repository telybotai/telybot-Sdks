<?php
/**
 * Runs when the plugin is deleted from the Plugins screen — not on deactivate.
 *
 * Everything this plugin ever wrote is one option holding a client id, and
 * deleting the plugin should leave the database as it found it.
 *
 * @package Telybot
 */

// WordPress defines this only when it is the one including this file. Without
// the guard, a direct request to /wp-content/plugins/telybot/uninstall.php
// would be an unauthenticated way to run it.
defined( 'WP_UNINSTALL_PLUGIN' ) || exit;

/*
 * The option name is repeated here rather than read from TELYBOT_OPTION:
 * WordPress runs uninstall.php in a fresh request with the plugin's own files
 * never loaded, so that constant does not exist at this point. If the name in
 * telybot.php ever changes, change it here too.
 */
$telybot_options = array( 'telybot_client_id', 'telybot_branding' );

if ( is_multisite() ) {
	// Each site in the network stores its own key, so deleting only the
	// current site's row would leave the rest behind for good.
	$telybot_sites = get_sites(
		array(
			'fields' => 'ids',
			'number' => 0,
		)
	);

	foreach ( $telybot_sites as $telybot_site_id ) {
		switch_to_blog( (int) $telybot_site_id );
		foreach ( $telybot_options as $telybot_option ) {
			delete_option( $telybot_option );
		}
		restore_current_blog();
	}
} else {
	foreach ( $telybot_options as $telybot_option ) {
		delete_option( $telybot_option );
	}
}
