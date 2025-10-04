#include <stdint.h>

typedef uint8_t Bool;

typedef struct {
  char *ptr;
  uint64_t len;
} String;

typedef enum : uint8_t {
  PG_T_ANY,
  PG_T_BOOL,
  PG_T_SYMBOL,
  PG_T_STRING,
  PG_T_NUMBER,
  PG_T_LIST,
  PG_T_DICT,
  PG_T_FUNCTION
} PgType;

typedef struct _PgValue PgValue;

typedef struct {
  PgValue *ptr;
  uint64_t len;
} PgList;

#define fptr(name_, ...) (*name_)(__VA_ARGS__)

typedef struct {
  void fptr(set, String name, PgValue value);
  PgValue *fptr(get, String name);
  uint64_t fptr(len, void);
} PgDict;

typedef struct _PgValue {
  PgType fptr(type, void);
  void *fptr(getAny, void);
  Bool fptr(getBool, void);
  float fptr(getNum, void);
  String fptr(getLit, void);
  PgList fptr(getList, void);
  PgDict fptr(getDict, void);
  char *fptr(format, void);
  char *fptr(debug, void);
} PgValue;

typedef struct {
  void fptr(push, PgValue);
  PgValue fptr(pop, Bool *err);
} PgState;
