CREATE FUNCTION crypto_auth_hmacsha256_keygen()
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_auth_hmacsha256_keygen'
LANGUAGE C VOLATILE;

CREATE FUNCTION crypto_auth_hmacsha256(message bytea, secret bytea)
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_auth_hmacsha256'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION crypto_auth_hmacsha256_verify(hash bytea, message bytea, secret bytea)
RETURNS bool
AS '$libdir/pgsodium', 'pgsodium_crypto_auth_hmacsha256_verify'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION crypto_hash_sha256(message bytea)
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_hash_sha256'
LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION crypto_hash_sha512(message bytea)
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_hash_sha512'
LANGUAGE C IMMUTABLE STRICT;

DROP FUNCTION crypto_kdf_derive_from_key(subkey_size bigint, subkey_id bigint, context bytea, master_key bytea);

CREATE FUNCTION crypto_kdf_derive_from_key(subkey_size bigint, subkey_id bigint, context bytea, primary_key bytea)
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_kdf_derive_from_key'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION derive_key(key_id bigint, key_len integer = 32, context bytea = 'pgsodium')
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_derive'
LANGUAGE C VOLATILE;

CREATE FUNCTION crypto_shorthash_keygen()
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_shorthash_keygen'
LANGUAGE C VOLATILE;

CREATE FUNCTION crypto_generichash_keygen()
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_generichash_keygen'
LANGUAGE C VOLATILE;

CREATE FUNCTION crypto_secretbox_by_id(message bytea, nonce bytea, key_id bigint, context bytea = 'pgsodium')
RETURNS bytea
AS '$libdir/pgsodium', 'pgsodium_crypto_secretbox_by_id'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON EXTENSION pgsodium is 'Pgsodium is a modern cryptography library for Postgres.';

DO $$
DECLARE
	new_role text;
BEGIN
	FOREACH new_role IN ARRAY
	    ARRAY['pgsodium_keyiduser',
	          'pgsodium_keyholder',
              'pgsodium_keymaker']
	LOOP
		IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = new_role) THEN
		    EXECUTE format($i$
			CREATE ROLE %I WITH
				NOLOGIN
				NOSUPERUSER
				NOCREATEDB
				NOCREATEROLE
				INHERIT
				NOREPLICATION
				CONNECTION LIMIT -1;
	        $i$, new_role);
		END IF;
	END LOOP;
END
$$;

-- pgsodium_keymaker

DO $$
DECLARE
	func text;
BEGIN
	FOREACH func IN ARRAY
		ARRAY[
	    'derive_key',
		'pgsodium_derive',
		'randombytes_new_seed',
		'crypto_secretbox_keygen',
		'crypto_secretbox_noncegen',
		'crypto_auth_keygen',
		'crypto_box_noncegen',
		'crypto_auth_hmacsha256_keygen',
		'crypto_kdf_derive_from_key',
		'crypto_shorthash_keygen',
		'crypto_generichash_keygen',
		'crypto_kdf_keygen',
		'crypto_kx_new_keypair',
		'crypto_kx_new_seed',
		'crypto_kx_seed_new_keypair',
		'crypto_auth_hmacsha256_keygen',
		'randombytes_buf_deterministic',
		'crypto_box_new_keypair',
		'crypto_sign_new_keypair'
	]
	LOOP
		EXECUTE format($i$
			REVOKE ALL ON FUNCTION %I FROM PUBLIC;
			GRANT EXECUTE ON FUNCTION %I TO pgsodium_keymaker;
		$i$, func, func);
	END LOOP;
END
$$;

-- pgsodium_keyholder

DO $$
DECLARE
	func text;
BEGIN
	FOREACH func IN ARRAY
	ARRAY[
		'randombytes_random',
		'randombytes_uniform',
		'randombytes_buf',
		'randombytes_buf_deterministic',
		'crypto_secretbox',
		'crypto_secretbox_open',
		'crypto_auth',
		'crypto_auth_verify',
		'crypto_generichash',
		'crypto_shorthash',
		'crypto_box',
		'crypto_box_open',
		'crypto_auth_hmacsha256',
		'crypto_auth_hmacsha256_verify',
		'crypto_auth_hmacsha512',
		'crypto_auth_hmacsha512_verify',
		'crypto_sign_init',
		'crypto_sign_update',
		'crypto_sign_final_create',
		'crypto_sign_final_verify',
		'crypto_sign_update_agg1',
		'crypto_sign_update_agg2'
	]
	LOOP
		EXECUTE format($i$
			REVOKE ALL ON FUNCTION %I FROM PUBLIC;
			GRANT EXECUTE ON FUNCTION %I TO pgsodium_keyholder;
		$i$, func, func);
	END LOOP;
END
$$;

-- pgsodium_keyiduser

DO $$
DECLARE
	func text;
BEGIN
	FOREACH func IN ARRAY
	ARRAY[
		'crypto_secretbox_by_id'
	]
	LOOP
		EXECUTE format($i$
			REVOKE ALL ON FUNCTION %I FROM PUBLIC;
			GRANT EXECUTE ON FUNCTION %I TO pgsodium_keyiduser;
		$i$, func, func);
	END LOOP;
END
$$;

GRANT pgsodium_keyholder TO pgsodium_keymaker;
GRANT pgsodium_keyiduser TO pgsodium_keymaker;
GRANT pgsodium_keyiduser TO pgsodium_keyholder;
