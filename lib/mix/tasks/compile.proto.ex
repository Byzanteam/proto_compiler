defmodule Mix.Tasks.Compile.Proto do
  @moduledoc """
  Compile .proto files to .ex files.

  ## Options

    * `:input` - Specify the files to compile. Pass to `protoc` as `files`.
    * `:proto_path` - Specify the directory in which to search for imports. Pass to `protoc` as `--proto_path`.
    * `:output` - Specify the directory in which to output files. Pass to `protoc` as `--elixir_out`.
    * `:grpc` - Enable gRPC support. Pass to `protoc` as `--elixir_opt=plugins=grpc`.
    * `:optional` - Enable support for proto3 optional fields. Pass to `protoc` as `--experimental_allow_proto3_optional`.
    * `:debug` - Enable debug output.
  """

  use Mix.Task.Compiler

  require Logger

  @recursive true

  @impl Mix.Task.Compiler
  def run(_args) do
    {input, options} =
      Mix.Project.config()
      |> Keyword.fetch!(:proto_compiler)
      |> Keyword.pop!(:input)

    {debug, options} = Keyword.pop(options, :debug, false)

    args =
      options
      |> Enum.map(&build_arg/1)
      |> Enum.join(" ")

    files =
      input
      |> List.wrap()
      |> Enum.join(" ")

    case debug do
      :console ->
        Logger.debug("args: #{inspect(args)}")
        Logger.debug("files: #{inspect(files)}")

      :github ->
        IO.puts("args: #{inspect(args)}")
        IO.puts("files: #{inspect(files)}")

      _otherwise ->
        :ok
    end

    Mix.shell().cmd("protoc #{args} #{files}")

    :ok
  end

  defp build_arg({:grpc, false}), do: ""
  defp build_arg({:grpc, true}), do: "--elixir_opt=plugins=grpc"

  defp build_arg({:optional, false}), do: ""
  defp build_arg({:optional, true}), do: "--experimental_allow_proto3_optional"

  defp build_arg({:proto_path, proto_path}) do
    "--proto_path=#{proto_path}"
  end

  defp build_arg({:output, output}) do
    "--elixir_out=#{output}"
  end
end
