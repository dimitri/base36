CREATE FUNCTION base36_dist(base36, base36)
RETURNS base36
AS 'MODULE_PATHNAME', 'int8_dist'
LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR <-> (
	LEFTARG = base36,
	RIGHTARG = base36,
	PROCEDURE = base36_dist,
	COMMUTATOR = '<->'
);

-- Create the operator class
CREATE OPERATOR CLASS gist_base36_ops
DEFAULT FOR TYPE base36 USING gist
AS
	OPERATOR	1	<  ,
	OPERATOR	2	<= ,
	OPERATOR	3	=  ,
	OPERATOR	4	>= ,
	OPERATOR	5	>  ,
	FUNCTION	1	gbt_int8_consistent (internal, int8, int2, oid, internal),
	FUNCTION	2	gbt_int8_union (bytea, internal),
	FUNCTION	3	gbt_int8_compress (internal),
	FUNCTION	4	gbt_decompress (internal),
	FUNCTION	5	gbt_int8_penalty (internal, internal, internal),
	FUNCTION	6	gbt_int8_picksplit (internal, internal),
	FUNCTION	7	gbt_int8_same (internal, internal, internal),
	STORAGE		gbtreekey16;

ALTER OPERATOR FAMILY gist_base36_ops USING gist ADD
	OPERATOR	6	<> (base36, base36) ,
	OPERATOR	15	<-> (base36, base36) FOR ORDER BY pg_catalog.integer_ops ,
	FUNCTION	8 (base36, base36) gbt_int8_distance (internal, int8, int2, oid) ;
