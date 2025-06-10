library mormot_collate;

{$ifdef FPC}
  {$mode Delphi}
  {$H+}
  {$R+}
  {$WARN 5024 off : Parameter "$1" not used}
{$endif}

{$ifdef MSWINDOWS}
  {$SETPEOSVERSION 5.0}
  {$SETPESUBSYSVERSION 5.0}
  {$SETPEOPTFLAGS $0100} // IMAGE_DLLCHARACTERISTICS_NX_COMPAT - enables DEP
  {$SETPEOPTFLAGS $0040} // IMAGE_DLLCHARACTERISTICS_DYNAMIC_BASE - enables ASLR
{$endif}

uses
  {$ifdef MSWINDOWS}
  Windows,
  {$endif}
  mormot_sqlite3_routines in 'mormot_sqlite3_routines.pas';

type
  TSQLite3ApiRoutines = record
    Dummy: array [0..42] of Pointer;
    sqlite3_create_collation: function(db: Pointer; zName: PAnsiChar; eTextRep: Integer; pArg: Pointer; xCompare: Pointer): Integer; cdecl;
  end;
  PSQLite3ApiRoutines = ^TSQLite3ApiRoutines;

const
  SQLITE_OK = 0;
  SQLITE_UTF8 = 1;
  SQLITE_UTF16 = 4;

function CheckResult(const AResult: Integer): Boolean; inline;
begin
  Result := AResult = SQLITE_OK;
end;

function sqlite3_extension_init(db: Pointer; var pzErrMsg: PAnsiChar; pApi: PSQLite3ApiRoutines): Integer; cdecl;
begin
  Result := pApi.sqlite3_create_collation(db, 'SYSTEMNOCASE', SQLITE_UTF8, nil, @Utf8_SYSTEMNOCASE);
  if not CheckResult(Result) then Exit;

  Result := pApi.sqlite3_create_collation(db, 'UNICODENOCASE', SQLITE_UTF8, nil, @Utf8_UNICODENOCASE);
  if not CheckResult(Result) then Exit;

  Result := pApi.sqlite3_create_collation(db, 'ISO8601', SQLITE_UTF8, nil, @Utf8_ISO8601);
  if not CheckResult(Result) then Exit;

  Result := pApi.sqlite3_create_collation(db, 'WIN32CASE', SQLITE_UTF16, nil, @Utf16_WIN32CASE);
  if not CheckResult(Result) then Exit;

  Result := pApi.sqlite3_create_collation(db, 'WIN32NOCASE', SQLITE_UTF16, nil, @Utf16_WIN32NOCASE);
end;

exports
  sqlite3_extension_init;

begin
  IsMultiThread := True;
  {$ifdef MSWINDOWS}
  DisableThreadLibraryCalls(HInstance);
  {$endif}
end.
