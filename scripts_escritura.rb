require 'zlib'

INPUT_FILE   = 'scripts_exportados.rb'
OUTPUT_FILE  = 'Data/Scripts.rxdata'

scripts = []
current_name = nil
current_code = []
current_id   = 0

File.foreach(INPUT_FILE, chomp: true) do |line|
  if line =~ /^=+$/
    # separador, lo ignoramos
    next
  elsif line =~ /^# Script: (.+)$/
    # Si había uno anterior, lo guardamos
    unless current_name.nil?
      compressed_code = Zlib::Deflate.deflate(current_code.join("\n"))
      scripts << [current_id, current_name, compressed_code]
      current_id += 1
    end
    # Nuevo script
    current_name = $1
    current_code = []
  else
    # Acumulamos código del script
    current_code << line unless current_name.nil?
  end
end

# Guardar el último script
unless current_name.nil?
  compressed_code = Zlib::Deflate.deflate(current_code.join("\n"))
  scripts << [current_id, current_name, compressed_code]
end

# Serializar y guardar
File.open(OUTPUT_FILE, 'wb') do |f|
  f.write(Marshal.dump(scripts))
end

puts "✅ Reconstrucción lista: #{OUTPUT_FILE}"