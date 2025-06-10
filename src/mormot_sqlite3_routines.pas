unit mormot_sqlite3_routines;

{$ifdef FPC}
  {$mode Delphi}
  {$H+}
  {$R+}
  {$WARN 5024 off : Parameter "$1" not used}
{$endif}

interface

function Utf16_WIN32CASE(CollateParam: pointer; s1Len: integer; S1: pointer;
  s2Len: integer; S2: pointer): integer; cdecl;

function Utf16_WIN32NOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;

function Utf8_SYSTEMNOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;

function Utf8_UNICODENOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;

function Utf8_ISO8601(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;

implementation

uses
  Math,
  mormot.core.os,
  mormot.core.datetime,
  mormot.core.unicode;

{ ------------ Extracted from mormot.db.raw.sqlite3 ------------------------- }

{ ************ High-Level Classes for SQLite3 Queries }

{ Some remarks about our custom SQLite3 functions:

  1. From WladiD: if a field is empty '' (not NULL), SQLite calls the registered
     collate function with s1len=0 or s2len=0, but the pointers s1 or s2 map to
     the string of the previous call - so s1len/s2len should be first checked.

  2. Some collations (WIN32CASE/WIN32NOCASE) may not be consistent depenging
     on the system/libray they run on: if you expect to move the SQLite3 file,
     consider SYSTEMNOCASE or UNICODENOCASE safer (and faster) functions.
  }

function Utf16_WIN32CASE(CollateParam: pointer; s1Len: integer; S1: pointer;
  s2Len: integer; S2: pointer): integer; cdecl;
begin
  if s1Len <= 0 then
    if s2Len <= 0 then
      result := 0
    else
      result := -1
  else if s2Len <= 0 then
    result := 1
  else
    // Windows / ICU comparison - warning: may vary on systems
    result := Unicode_CompareString(S1, S2, s1Len shr 1, s2Len shr 1,
      {igncase=} false) - 2;
end;

function Utf16_WIN32NOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;
begin
  if s1Len <= 0 then
    if s2Len <= 0 then
      result := 0
    else
      result := -1
  else if s2Len <= 0 then
    result := 1
  else
    // Windows / ICU case folding - warning: may vary on systems
    result := Unicode_CompareString(s1, s2, s1Len shr 1, s2Len shr 1,
      {igncase=} true) - 2;
end;

function Utf8_SYSTEMNOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;
begin
  if s1Len <= 0 then
    if s2Len <= 0 then
      result := 0
    else
      result := -1
  else if s2Len <= 0 then
    result := 1
  else
    // WinAnsi CP-1252 case folding
    result := Utf8ILComp(s1, s2, s1Len, s2Len);
end;

function Utf8_UNICODENOCASE(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;
begin
  if s1Len <= 0 then
    if s2Len <= 0 then
      result := 0
    else
      result := -1
  else if s2Len <= 0 then
    result := 1
  else
    // case folding using our Unicode 10.0 tables - will remain stable
    result := Utf8ILCompReference(s1, s2, s1Len, s2Len);
end;

function Utf8_ISO8601(CollateParam: pointer; s1Len: integer; s1: pointer;
  s2Len: integer; s2: pointer): integer; cdecl;
var
  V1, V2: TDateTime; // will handle up to .sss milliseconds resolution
begin
  if s1Len <= 0 then
    s1 := nil;
  if s2Len <= 0 then
    s2 := nil;
  if s1 = s2 then
    result := 0
  else
  begin
    Iso8601ToDateTimePUtf8CharVar(s1, s1Len, V1);
    Iso8601ToDateTimePUtf8CharVar(s2, s2Len, V2);
    if (V1 = 0) or
       (V2 = 0) then
      // any invalid date -> compare as UTF-8 strings
      result := Utf8ILComp(s1, s2, s1Len, s2Len)
    else if SameValue(V1, V2, 1 / MilliSecsPerDay) then
      result := 0
    else if V1 < V2 then
      result := -1
    else
      result := +1;
  end;
end;

end.

