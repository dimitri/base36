/*
 * Base36 PostgreSQL input/output function for bigint
 *
 * Author: Dimitri Fontaine <dimitri@2ndQuadrant.fr>
 */

#include <stdio.h>
#include "postgres.h"

#include "access/gist.h"
#include "access/skey.h"
#include "utils/elog.h"
#include "utils/palloc.h"
#include "utils/builtins.h"
#include "libpq/pqformat.h"
#include "utils/date.h"
#include "utils/datetime.h"
#include "utils/nabstime.h"
#include "utils/guc.h"
#include <sys/time.h>
#include <time.h>
#include <stdlib.h>
#include <ctype.h>

/*
 * This code has only been tested with PostgreSQL 9.4devel
 */
#ifndef PG_VERSION_NUM
#error "Unsupported too old PostgreSQL version"
#endif

#if  PG_VERSION_NUM / 100 != 903 \
  && PG_VERSION_NUM / 100 != 904
#error "Unknown or unsupported PostgreSQL version"
#endif

PG_MODULE_MAGIC;

/*
#define  DEBUG
#define  DEBUG_CONVERT
 */

#define BASE36_LENGTH      13

typedef long long unsigned int base36;

static int base36_digits[36] =
  {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
   'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
   'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
   'U', 'V', 'W', 'X', 'Y', 'Z'
  };

static base36 base36_powers[BASE36_LENGTH] =
  {
1ULL,
    36ULL,
    1296ULL,
    46656ULL,
    1679616ULL,
    60466176ULL,
    2176782336ULL,
	78364164096ULL,
	2821109907456ULL,
	101559956668416ULL,
	3656158440062976ULL,
	131621703842267136ULL,
	4738381338321616896ULL
  };

static inline
base36 base36_from_str(const char *str)
{
  int i, d = 0, n = strlen(str);
  base36 c = 0;

  if( n == 0 || n > BASE36_LENGTH )
  {
ereport(ERROR,
			(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("value \"%s\" is out of range for type base36",
				 str)));
  }
  for(i=0; i<n; i++) {
    if( str[i] >= '0' && str[i] <= '9' )
      d = str[i] - '0';
    else if ( str[i] >= 'A' && str[i] <= 'Z' )
      d = 10 + str[i] - 'A';
    else if ( str[i] >= 'a' && str[i] <= 'z' )
      d = 10 + str[i] - 'a';
    else
      elog(ERROR, "value '%c' is not a valid digit for type base36.", str[i]);

    c += d * base36_powers[n-i-1];

if ( c < 0 )
{
ereport(ERROR,
			(errcode(ERRCODE_NUMERIC_VALUE_OUT_OF_RANGE),
				 errmsg("value \"%s\" is out of range for type base36",
				 str)));
}

#ifdef DEBUG_CONVERT
elog(NOTICE, "base36[%2d] = %2d -- base36 = %llu", n-i-1, d, c);
#endif
  }
  return c;
}

static inline
char *base36_to_str(base36 c)
{
  int i, d, p = 0;
  base36 m = c;
  bool discard = true;
  char *str = palloc0((BASE36_LENGTH + 1) * sizeof(char));

  for(i=BASE36_LENGTH-1; i>=0; i--)
  {
    d = m / base36_powers[i];
#ifdef DEBUG_CONVERT
    elog(NOTICE, "base36[%d] = %llu / %llu, d = %d", i, m, base36_powers[i], d);
#endif
    m = m - base36_powers[i] * d;

    discard = discard && d == 0;

 if( !discard )
    str[p++] = base36_digits[d];
  }

  return str;
}

Datum base36_in(PG_FUNCTION_ARGS);
Datum base36_out(PG_FUNCTION_ARGS);
Datum base36_recv(PG_FUNCTION_ARGS);
Datum base36_send(PG_FUNCTION_ARGS);
Datum base36_cast_to_text(PG_FUNCTION_ARGS);
Datum base36_cast_from_text(PG_FUNCTION_ARGS);
Datum base36_cast_to_bigint(PG_FUNCTION_ARGS);
Datum base36_cast_from_bigint(PG_FUNCTION_ARGS);

PG_FUNCTION_INFO_V1(base36_in);
Datum
base36_in(PG_FUNCTION_ARGS)
{
    char *str = PG_GETARG_CSTRING(0);
    PG_RETURN_INT64(base36_from_str(str));
}

PG_FUNCTION_INFO_V1(base36_out);
Datum
base36_out(PG_FUNCTION_ARGS)
{
  base36 c = PG_GETARG_INT64(0);
  PG_RETURN_CSTRING(base36_to_str(c));
}

PG_FUNCTION_INFO_V1(base36_recv);
Datum
base36_recv(PG_FUNCTION_ARGS)
{
    StringInfo buf = (StringInfo) PG_GETARG_POINTER(0);
    const char *str = pq_getmsgstring(buf);
    pq_getmsgend(buf);
    PG_RETURN_INT64(base36_from_str(str));
}

PG_FUNCTION_INFO_V1(base36_send);
Datum
base36_send(PG_FUNCTION_ARGS)
{
    base36 c = PG_GETARG_INT64(0);
    StringInfoData buf;

    pq_begintypsend(&buf);
    pq_sendstring(&buf, base36_to_str(c));

    PG_RETURN_BYTEA_P(pq_endtypsend(&buf));
}

PG_FUNCTION_INFO_V1(base36_cast_from_text);
Datum
base36_cast_from_text(PG_FUNCTION_ARGS)
{
  text *txt = PG_GETARG_TEXT_P(0);
  char *str = DatumGetCString(DirectFunctionCall1(textout,
						   PointerGetDatum(txt)));
  PG_RETURN_INT64(base36_from_str(str));
}

PG_FUNCTION_INFO_V1(base36_cast_to_text);
Datum
base36_cast_to_text(PG_FUNCTION_ARGS)
{
  base36 c  = PG_GETARG_INT64(0);
  text *out = (text *)DirectFunctionCall1(textin,
					  PointerGetDatum(base36_to_str(c)));
  PG_RETURN_TEXT_P(out);
}
