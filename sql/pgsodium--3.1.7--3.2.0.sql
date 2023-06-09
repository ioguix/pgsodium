/*
 * change: replaced in 3.0.5 with "create_mask_view(oid, integer, boolean)".
 */
DROP FUNCTION IF EXISTS pgsodium.create_mask_view(oid, boolean);

/*
 * change: replaced in 3.0.5 by the "pgsodium.mask_columns" view.
 */
DROP FUNCTION IF EXISTS pgsodium.mask_columns(oid);

/*
 * change: schema "pgsodium_masks" removed in 3.0.4
 * FIXME: how the extension handle bw compatibility when a table having a view
 *        in pgsodium_masks is update or has a seclabel added/changed? A new
 *        view is created outside of pgsodium_masks? What about the client app
 *        and the old view?
 */
DROP SCHEMA IF EXISTS pgsodium_masks;

/*
 * change: constraint names generated by the create table pgsodium.key in
 *         pgsodium--3.2.0.sql are different from the older ones.
 */
ALTER TABLE pgsodium.key RENAME CONSTRAINT "pgsodium_raw" TO "key_check";
ALTER INDEX pgsodium.pgsodium_key_unique_name RENAME TO key_name_key;

/*
 * change: force regenerating the decrypted_key view to add the missing column
 *         "user_data" to the view.
 */
SELECT * FROM pgsodium.update_mask('pgsodium.key'::regclass::oid);

/*
 * Fix privileges
 */

REVOKE ALL ON pgsodium.key FROM pgsodium_keyiduser;

REVOKE ALL ON pgsodium.key FROM pgsodium_keymaker;
GRANT SELECT, INSERT, UPDATE, DELETE ON pgsodium.key TO pgsodium_keymaker;
REVOKE ALL ON pgsodium.decrypted_key FROM pgsodium_keymaker;
GRANT SELECT, INSERT, UPDATE, DELETE ON pgsodium.decrypted_key TO pgsodium_keymaker;

REVOKE ALL ON pgsodium.decrypted_key FROM pgsodium_keyholder;
GRANT SELECT, INSERT, UPDATE, DELETE ON pgsodium.decrypted_key TO pgsodium_keyholder;
