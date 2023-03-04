defmodule Superdelegate do
  defmacro __using__(_opts) do
    macroed_filename = __CALLER__.file
    macroed_dir = Path.dirname(macroed_filename)
    expected_dir = macroed_dir <> "/" <> Path.basename(macroed_filename, ".ex") <> "/"
    files_in_expected_dir = Path.wildcard(expected_dir <> "*.ex")

    for file <- files_in_expected_dir do
      basename = Path.basename(file, ".ex")
      camelized = Macro.camelize(basename)
      module = Module.safe_concat(__CALLER__.module, camelized)
      Code.ensure_loaded!(module)
      module_exports = module.module_info(:exports)

      case Enum.find(module_exports, fn {func, _arity} -> func == :call end) do
        nil ->
          IO.puts("no find")
          nil

        {_func, arity} = found ->
          IO.puts("found")
          IO.inspect(found)
          args = for i <- 0..arity, i > 0, do: Macro.var(:"arg#{i}", __CALLER__.module)

          quote do
            defdelegate unquote(String.to_atom(basename))(unquote_splicing(args)),
              to: unquote(module),
              as: :call
          end
      end
    end
  end
end
