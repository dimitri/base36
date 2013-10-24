-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION base36" to load this file. \quit

CREATE OR REPLACE FUNCTION base36_in(cstring)
RETURNS base36
AS '$libdir/base36'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION base36_out(base36)
RETURNS cstring
AS '$libdir/base36'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION base36_recv(internal)
RETURNS base36
AS '$libdir/base36'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION base36_send(base36)
RETURNS bytea
AS '$libdir/base36'
LANGUAGE C IMMUTABLE STRICT;

CREATE TYPE base36 (
	INPUT          = base36_in,
	OUTPUT         = base36_out,
	RECEIVE        = base36_recv,
	SEND           = base36_send,
	LIKE           = bigint,
	CATEGORY       = 'N'
);
COMMENT ON TYPE base36 IS 'Code AlloPass: [0-9A-Z]{8}';

CREATE OR REPLACE FUNCTION base36(text)
RETURNS base36
AS '$libdir/base36', 'base36_cast_from_text'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION text(base36)
RETURNS text
AS '$libdir/base36', 'base36_cast_to_text'
LANGUAGE C IMMUTABLE STRICT;

CREATE CAST (text as base36) WITH FUNCTION base36(text) AS IMPLICIT;
CREATE CAST (base36 as text) WITH FUNCTION text(base36);

CREATE CAST (bigint as base36) WITHOUT FUNCTION AS IMPLICIT;
CREATE CAST (base36 as bigint) WITHOUT FUNCTION AS IMPLICIT;

CREATE OR REPLACE FUNCTION base36_eq(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8eq';

CREATE OR REPLACE FUNCTION base36_ne(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8ne';

CREATE OR REPLACE FUNCTION base36_lt(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8lt';

CREATE OR REPLACE FUNCTION base36_le(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8le';

CREATE OR REPLACE FUNCTION base36_gt(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8gt';

CREATE OR REPLACE FUNCTION base36_ge(base36, base36) 
RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int8ge';

CREATE OR REPLACE FUNCTION base36_cmp(base36, base36) 
RETURNS integer LANGUAGE internal IMMUTABLE AS 'btint8cmp';

CREATE OPERATOR = (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_eq,
	COMMUTATOR = '=',
	NEGATOR = '<>',
	RESTRICT = eqsel,
	JOIN = eqjoinsel
);
COMMENT ON OPERATOR =(base36, base36) IS 'equals?';

CREATE OPERATOR <> (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_ne,
	COMMUTATOR = '<>',
	NEGATOR = '=',
	RESTRICT = neqsel,
	JOIN = neqjoinsel
);
COMMENT ON OPERATOR <>(base36, base36) IS 'not equals?';

CREATE OPERATOR < (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_lt,
	COMMUTATOR = > , 
	NEGATOR = >= ,
   	RESTRICT = scalarltsel, 
	JOIN = scalarltjoinsel
);
COMMENT ON OPERATOR <(base36, base36) IS 'less-than';

CREATE OPERATOR <= (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_le,
	COMMUTATOR = >= , 
	NEGATOR = > ,
   	RESTRICT = scalarltsel, 
	JOIN = scalarltjoinsel
);
COMMENT ON OPERATOR <=(base36, base36) IS 'less-than-or-equal';

CREATE OPERATOR > (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_gt,
	COMMUTATOR = < , 
	NEGATOR = <= ,
   	RESTRICT = scalargtsel, 
	JOIN = scalargtjoinsel
);
COMMENT ON OPERATOR >(base36, base36) IS 'greater-than';

CREATE OPERATOR >= (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_ge,
	COMMUTATOR = <= , 
	NEGATOR = < ,
   	RESTRICT = scalargtsel, 
	JOIN = scalargtjoinsel
);
COMMENT ON OPERATOR >=(base36, base36) IS 'greater-than-or-equal';

CREATE OPERATOR CLASS btree_base36_ops
DEFAULT FOR TYPE base36 USING btree
AS
        OPERATOR        1       <  ,
        OPERATOR        2       <= ,
        OPERATOR        3       =  ,
        OPERATOR        4       >= ,
        OPERATOR        5       >  ,
        FUNCTION        1       base36_cmp(base36, base36);
