defmodule Mix.Tasks.Compile.Proto do
  @moduledoc """
  Compile .proto files to .ex files.

  ## Options

    * `:input` - Specify the files to compile. Pass to `protoc` as `files`.
    * `:proto_path` - Specify the directory in which to search for imports. Pass to `protoc` as `--proto_path`.
    * `:output` - Specify the directory in which to output files. Pass to `protoc` as `--elixir_out`.
    If a tuple is given, the first element is the directory and the second is a list of options. The options are:
      * `:gen_descriptors` - Generate descriptor files. Pass to `protoc` as `gen_descriptors=true`.
      * `:one_file_per_module` - Generate one file per module. Pass to `protoc` as `one_file_per_module=true`.
      * `:include_docs` - Include docs in generated files. Pass to `protoc` as `include_docs=true`.
      * `:package_prefix` - Specify the package prefix. Pass to `protoc` as `package_prefix=prefix`.
      * `:transform_module` - Specify a module transformation function. Pass to `protoc` as `transform_module=module`.
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

  defp build_arg({:output, output}) when is_binary(output) do
    "--elixir_out=#{output}"
  end

  defp build_arg({:output, {output, options}}) when is_list(options) and is_binary(output) do
    options
    |> Enum.map(&build_output_option/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> "--elixir_out=#{output}"
      opts -> "--elixir_out=#{Enum.join(opts, ",")}:#{output}"
    end
  end

  @boolean_flags [
    :gen_descriptors,
    :one_file_per_module,
    :include_docs
  ]

  for flag <- @boolean_flags do
    defp build_output_option(unquote(flag)) do
      build_output_option({unquote(flag), true})
    end

    defp build_output_option({unquote(flag), true}) do
      "#{unquote(flag)}=true"
    end

    defp build_output_option({unquote(flag), false}) do
      nil
    end
  end

  defp build_output_option({:package_prefix, package_prefix}) when is_binary(package_prefix) do
    "package_prefix=#{package_prefix}"
  end

  defp build_output_option({:transform_module, transform_module})
       when is_atom(transform_module) do
    "transform_module=#{transform_module}"
  end
end
