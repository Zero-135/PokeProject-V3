require 'zlib'
require 'fileutils'

SCRIPTS_FILE = 'Data/Scripts.rxdata'
#OUTPUT_DIR   = 'Scripts_Nombre'
OUTPUT_DIR   = 'Scripts_Orden'

FileUtils.mkdir_p(OUTPUT_DIR)

scripts = Marshal.load(File.binread(SCRIPTS_FILE))
i = 1
scripts.each do |id, name, code_bytes|
  begin
    code = Zlib::Inflate.inflate(code_bytes)
  rescue
    code = code_bytes
  end

  # 👉 probar como UTF-8 directo
  code = code.force_encoding("UTF-8")
             .encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
  
  safe_name = format("%03d_", i) + name
  #safe_name = name

  filename = File.join(OUTPUT_DIR, format("%s.rb", safe_name))
  File.write(filename, code, mode: "w:utf-8")

  puts "📄 Guardado: #{filename}"
  i += 1
end

puts "✅ Exportación lista en carpeta: #{OUTPUT_DIR}"
