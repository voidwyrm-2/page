#include <stdint.h>

typedef uint8_t Bool;

typedef struct {
  char *ptr;
  uint64_t len;
} String;

typedef enum : uint8_t {
  NPS_T_ANY,
  NPS_T_BOOL,
  NPS_T_SYMBOL,
  NPS_T_STRING,
  NPS_T_NUMBER,
  NPS_T_LIST,
  NPS_T_DICT,
  NPS_T_FUNCTION
} NpsType;

typedef struct _NpsValue NpsValue;

typedef struct {
  NpsValue *ptr;
  uint64_t len;
} NpsList;

#define fptr(name_, ret_, ...) ret_ (*name_)(__VA_ARGS__)

typedef struct {
  fptr(set, void, String name, NpsValue value);
  fptr(get, NpsValue *, String name);
  fptr(len, uint64_t, void);
} NpsDict;

typedef struct _NpsValue {
  fptr(type, NpsType, void);
  fptr(getAny, void *, void);
  fptr(getBool, Bool, void);
  fptr(getNum, float, void);
  fptr(getLit, String, void);
  fptr(getList, NpsList, void);
  fptr(getDict, NpsDict, void);
  fptr(format, char *, void);
  fptr(debug, char *, void);
} NpsValue;

typedef struct {
  fptr(push, void, NpsValue);
  fptr(pop, NpsValue, Bool *err);
} NpsState;
