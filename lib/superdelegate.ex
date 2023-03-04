# https://stackoverflow.com/questions/54470436/how-to-make-a-wrapper-module-that-includes-functions-from-other-modules
# https://github.com/phoenixframework/phoenix_template/blob/d6098a7f647911f68149196c7ec19c9fba935a85/lib/phoenix/template.ex
# https://docs.w3cub.com/elixir~1.11/mix.tasks.compile.elixir
# https://github.com/mveytsman/heroicons_elixir/blob/2ff8bca42e580703d67f260b9ba8a00169f5330b/lib/heroicons/generator.ex

defmodule Superdelegate do
  defmacro __using__(_opts) do
    macroed_filename = __CALLER__.file
    macroed_dir = Path.dirname(macroed_filename)
    expected_dir = macroed_dir <> "/" <> Path.basename(macroed_filename, ".ex") <> "/"
    files_in_expected_dir = Path.wildcard(expected_dir <> "_*.ex")

    recompile_quoted =
      quote do
        @paths_hash :erlang.md5(unquote(files_in_expected_dir))
        def __mix_recompile__?() do
          macroed_filename = unquote(__CALLER__.file)
          macroed_dir = Path.dirname(macroed_filename)
          expected_dir = macroed_dir <> "/" <> Path.basename(macroed_filename, ".ex") <> "/"
          files_in_expected_dir = Path.wildcard(expected_dir <> "_*.ex")

          :erlang.md5(files_in_expected_dir) != @paths_hash
        end
      end

    defdelegates_quoted =
      for file <- files_in_expected_dir do
        basename = Path.basename(file, ".ex")
        camelized = Macro.camelize(basename)
        module = Module.safe_concat(__CALLER__.module, camelized)
        module_exports = module.module_info(:exports)

        basename_atom_without_leading_underscore =
          case basename do
            "_" <> without -> without
            _ -> basename
          end
          |> String.to_atom()

        case Enum.find(module_exports, fn {func, _arity} -> func == :call end) do
          nil ->
            nil

          {_func, arity} ->
            args = for i <- 0..arity, i > 0, do: Macro.var(:"arg#{i}", __CALLER__.module)

            quote do
              @external_resource unquote(file)
              defdelegate unquote(basename_atom_without_leading_underscore)(
                            unquote_splicing(args)
                          ),
                          to: unquote(module),
                          as: :call
            end
        end
      end

    [recompile_quoted | defdelegates_quoted]
  end
end
