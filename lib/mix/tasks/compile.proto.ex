defmodule Mix.Tasks.Compile.Proto do
  @moduledoc false

  use Mix.Task.Compiler

  @recursive true

  @impl Mix.Task.Compiler
  def run(_args) do
    {input, options} =
      Mix.Project.config()
      |> Keyword.fetch!(:proto_compiler)
      |> Keyword.pop!(:input)

    args =
      options
      |> Enum.map(&build_arg/1)
      |> Enum.join(" ")

    files =
      input
      |> List.wrap()
      |> Enum.join(" ")

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
