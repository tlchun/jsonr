%%% @doc JSON decoding/encoding module
%%% @end
%%%
%%% Copyright (c) 2013-2015, Takeru Ohta <phjgt308@gmail.com>
%%%
%%% The MIT License
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
%%%
%%%---------------------------------------------------------------------------------------
-module(jsonr).

%%--------------------------------------------------------------------------------
%% Exported API
%%--------------------------------------------------------------------------------
-export([
  decode/1, decode/2,
  try_decode/1, try_decode/2,
  encode/1, encode/2,
  try_encode/1, try_encode/2
]).

-export_type([
  json_value/0,
  json_boolean/0,
  json_number/0,
  json_string/0,
  json_array/0,
  json_object/0,
  json_object_members/0,
  json_term/0,
  json_object_format_tuple/0,
  json_object_format_proplist/0,
  json_object_format_map/0,
  json_scalar/0,

  encode_option/0,
  decode_option/0,
  float_format_option/0,
  datetime_encode_format/0, datetime_format/0,
  timezone/0, utc_offset_seconds/0, stack_item/0
]).

%%--------------------------------------------------------------------------------
%% Types & Macros
%%--------------------------------------------------------------------------------
-type json_value()          :: json_number() | json_string() | json_array() | json_object() | json_boolean() | null | undefined | json_term().
-type json_boolean()        :: boolean().
-type json_number()         :: number().
-type json_string()         :: binary() | atom() | calendar:datetime(). % NOTE: `decode/1' always returns `binary()' value
-type json_array()          :: [json_value()].
-type json_object()         :: json_object_format_tuple()
| json_object_format_proplist()
| json_object_format_map().
-type json_object_members() :: [{json_string(), json_value()}].
-type json_term()           :: {{json, iolist()}} | {{json_utf8, unicode:chardata()}}.
-type json_object_format_tuple() :: {json_object_members()}.
-type json_object_format_proplist() :: [{}] | json_object_members().

-ifdef('NO_MAP_TYPE').
-opaque json_object_format_map() :: json_object_format_proplist().
%% `maps' is not supported in this erts version
-else.
-type json_object_format_map() :: map().
-endif.

-type json_scalar() :: json_boolean() | json_number() | json_string().

-type float_format_option() :: {scientific, Decimals :: 0..249}
| {decimals, Decimals :: 0..253}
| compact.

-type datetime_encode_format() :: Format::datetime_format()
| {Format::datetime_format(), TimeZone::timezone()}.


-type datetime_format() :: iso8601.
-type timezone() :: utc | local | utc_offset_seconds().
-type utc_offset_seconds() :: -86399..86399.

-type common_option() :: undefined_as_null.

-type encode_option() :: native_utf8
| native_forward_slash
| canonical_form
| {float_format, [float_format_option()]}
| {datetime_format, datetime_encode_format()}
| {object_key_type, string | scalar | value}
| {space, non_neg_integer()}
| {indent, non_neg_integer()}
| common_option().


-type decode_option() :: {object_format, tuple | proplist | map}
| {allow_ctrl_chars, boolean()}
| reject_invalid_utf8
| {'keys', 'binary' | 'atom' | 'existing_atom' | 'attempt_atom'}
| common_option().



-type stack_item() :: {Module :: module(),
  Function :: atom(),
  Arity :: arity() | (Args :: [term()]),
  Location :: [{file, Filename :: string()} |
  {line, Line :: pos_integer()}]}.

-ifdef('OTP_RELEASE').

-define(CAPTURE_STACKTRACE, :__StackTrace).
-define(GET_STACKTRACE, __StackTrace).
-else.
-define(CAPTURE_STACKTRACE, ).
-define(GET_STACKTRACE, erlang:get_stacktrace()).
-endif.


-spec decode(binary()) -> json_value().
decode(Json) ->
  decode(Json, []).


-spec decode(binary(), [decode_option()]) -> json_value().
decode(Json, Options) ->
  try
    {ok, Value, _} = try_decode(Json, Options),
    Value
  catch
    error:{badmatch, {error, {Reason, [StackItem]}}} ?CAPTURE_STACKTRACE ->
    erlang:raise(error, Reason, [StackItem | ?GET_STACKTRACE])
end.

-spec try_decode(binary()) -> {ok, json_value(), Remainings::binary()} | {error, {Reason::term(), [stack_item()]}}.
try_decode(Json) ->
  try_decode(Json, []).


-spec try_decode(binary(), [decode_option()]) -> {ok, json_value(), Remainings::binary()} | {error, {Reason::term(), [stack_item()]}}.
try_decode(Json, Options) ->
  jsone_decode:decode(Json, Options).

-spec encode(json_value()) -> binary().
encode(JsonValue) ->
  encode(JsonValue, []).


-spec encode(json_value(), [encode_option()]) -> binary().
encode(JsonValue, Options) ->
  try
    {ok, Binary} = try_encode(JsonValue, Options),
    Binary
  catch
    error:{badmatch, {error, {Reason, [StackItem]}}} ?CAPTURE_STACKTRACE ->
    erlang:raise(error, Reason, [StackItem | ?GET_STACKTRACE])
end.

-spec try_encode(json_value()) -> {ok, binary()} | {error, {Reason::term(), [stack_item()]}}.
try_encode(JsonValue) ->
  try_encode(JsonValue, []).


-spec try_encode(json_value(), [encode_option()]) -> {ok, binary()} | {error, {Reason::term(), [stack_item()]}}.
try_encode(JsonValue, Options) ->
  jsone_encode:encode(JsonValue, Options).