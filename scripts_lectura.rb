require 'zlib'

SCRIPTS_FILE = 'Data/Scripts.rxdata'
OUTPUT_FILE  = 'scripts_exportados.rb'

scripts = Marshal.load(File.binread(SCRIPTS_FILE))

File.open(OUTPUT_FILE, 'wb') do |f|  # <-- Modo binario, no cambia nada
  scripts.each do |id, name, code_bytes|
    begin
      code = Zlib::Inflate.inflate(code_bytes)
    rescue
      code = code_bytes
    end

    # Aquí NO cambiamos codificación
    f.puts("#{'=' * 78}")
    f.puts("# Script: #{name}")
    f.puts("#{'=' * 78}")
    f.puts(code)
    f.puts
  end
end

puts "✅ Exportación lista: #{OUTPUT_FILE}"
