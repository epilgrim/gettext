defmodule Gettext.PO do
  @moduledoc """
  This module provides facilities for working with `.po` files (mainly parsing).
  """

  alias Gettext.PO.Tokenizer
  alias Gettext.PO.Parser
  alias Gettext.PO.SyntaxError

  @typep line   :: pos_integer
  @typep parsed :: [Gettext.PO.Translation.t]

  @doc """
  Parses a string into a list of translations.

  This function parses a given `str` into a list of `Gettext.PO.Translation` and
  `Gettext.PO.PluralTranslation` structs. It returns `{:ok, translations}` if
  there are no errors, otherwise `{:error, line, reason}`.

  ## Examples

      iex> Gettext.PO.parse_string """
      ...> msgid "foo"
      ...> msgstr "bar"
      ...> """
      {:ok, [%Gettext.PO.Translation{msgid: "foo", msgstr: "bar"}]}

      iex> Gettext.PO.parse_string "foo"
      {:error, 1, "unknown keyword 'foo'"}

  """
  @spec parse_string(binary) :: {:ok, parsed} | {:error, line, binary}
  def parse_string(str) do
    case Tokenizer.tokenize(str) do
      {:ok, tokens}                    -> Parser.parse(tokens)
      {:error, _line, _reason} = error -> error
    end
  end

  @doc """
  Parses a string into a list of translations, raising an exception if there are
  any errors.

  Works exactly like `parse_string/1`, but returns the list of translations
  if there are no errors or raises a `Gettext.PO.SyntaxError` error if there
  are.

  ## Examples

      iex> Gettext.PO.parse_string!("msgid")
      ** (Gettext.PO.SyntaxError) 1: no space after 'msgid'

  """
  @spec parse_string!(binary) :: parsed
  def parse_string!(str) do
    case parse_string(str) do
      {:ok, parsed} ->
        parsed
      {:error, line, reason} ->
        raise SyntaxError, line: line, reason: reason
    end
  end

  @doc """
  Parses the contents of a file into a list of translations.

  This function works similarly to `parse_string/1` except that it takes a file
  and parses the contents of that file. It can return:

    * `{:ok, translations}`
    * `{:error, line, reason}` if there is an error with the contents of the
      `.po` file (e.g., a syntax error)
    * `{:error, reason}` if there is an error with reading the file (this error
      is one of the errors that can be returned by `File.read/1`)_

  ## Examples

      Gettext.PO.parse_file "translations.po"
      #=> {:ok, [%Translation{msgid: "foo", msgstr: "bar"}]}

      Gettext.PO.parse_file "nonexistent"
      #=> {:error, :enoent}

  """
  @spec parse_file(Path.t) ::
    {:ok, parsed}
    | {:error, line, binary}
    | {:error, atom}
  def parse_file(path) do
    case File.read(path) do
      {:ok, contents}           -> parse_string(contents)
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Parses the contents of a file into a list of translations, raising if there
  are any errors.

  Works like `parse_file/1`, except that it raises a `Gettext.PO.SyntaxError`
  exception if there's a syntax error in the file or a `File.Error` error if
  there's an error with reading the file.

  ## Examples

      Gettext.PO.parse_file! "nonexistent.po"
      #=> ** (File.Error) could not parse file nonexistent.po: no such file or directory

  """
  @spec parse_file!(Path.t) :: parsed
  def parse_file!(path) do
    case parse_file(path) do
      {:ok, parsed} ->
        parsed
      {:error, reason} ->
        raise File.Error, reason: reason, action: "parse", path: path
      {:error, line, reason} ->
        raise SyntaxError, file: path, line: line, reason: reason
    end
  end
end