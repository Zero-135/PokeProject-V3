require 'zlib'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    str
  end
end

module Scripts
  def self.dump(path = "Scripts", rxdata = "Data/Scripts.rxdata")
    # Load scripts from rxdata
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) }
    if scripts.length < 10
      p "Scripts appear to already be extracted. Skipping extraction."
      return
    end

    # Ensure directory exists and is empty
    create_directory(path)
    clear_directory(path)

    folder_id = [1, 1]
    file_id = 1
    folder_path = path
    level = 0   # 0=main path, 1=subfolder, 2=sub-subfolder

    scripts.each_with_index do |entry, index|
      _, title, script = entry
      title = title_to_filename(title).strip
      script = Zlib::Inflate.inflate(script)

      # Skip titles with only '=' characters and more than three of them
      next if title.match?(/^=+$/) && title.length > 3

      if title.match?(/\[\[\s*(.+)\s*\]\]$/) # Section for folder creation
        # Extract the section name
        section_name = title[/\[\[\s*(.+)\s*\]\]$/, 1]&.strip || "Unnamed Section"

        # Folder logic: Create folder, then reset path for next section
        folder_num   = (index < scripts.length - 2) ? folder_id[level].to_digits(3) : "999"
        folder_name  = "#{folder_num}_#{section_name}"
        folder_path = File.join(path, folder_name)
        create_directory(folder_path)

        # Reset for the next set of scripts in this folder
        folder_id[level] += 1
        file_id = 1 # Reset file numbering for the new folder
      else
        next if script.empty? # Skip empty scripts
        file_num = file_id.to_digits(3)
        file_name = "#{file_num}_#{title}.rb"
        create_script(File.join(folder_path, file_name), script)
        file_id += 1
      end
    end

    # Backup the original Scripts.rxdata
    File.open("Data/ScriptsBackup.rxdata", "wb") { |f| Marshal.dump(scripts, f) }

    # Replace Scripts.rxdata with a loader script
    create_loader_scripts(rxdata)
  end

  def self.create_loader_scripts(rxdata)
    txt = "x\x9C}SM\x8F\x9B0\x10\xBD\xE7WL\xD8H\x80\x169\x9Bc+\xD1=\xF4K=\xB5\xDA\xE4\x16\"D`H\xDC%6\xB2M\xD3m\xC8\x7F\xEF\xD8@`\xD5\x8FC\"\xCF\xB3g\xE6\xCD\x9B\xC7\x1Dl\x8E\\C!Q\x83\x90\x06\xCER=\x03/\xC1\x1C\x11\x0E\xD9\t\x81.Q\xE4\xEA\xA56X\xCCg\xB3\x02\xE9Ne9\xEE\xB3\xFC9UXKef\x006r0\xC4\xB0\x98\xB3[\xC8\xF2J\n\x9C>`\x98\xE5\xC7\v\xB4{\xD3\x12L\x17\x86\xE9f?\x0F\x96\xC9%H\x8A\xFB0\xB9.C\xB8x\xDB\xBB\xCBbu\xDD\xD1\xFF\xD3\xE7\xF5:]\xBF\x7F\xFA\xF2m\xB3\xDE.V\xCC\xC8\x94\xEF\xB6\xAB\xDD\xD5\xBBR\x01\xFBSh\x1A%l\xDF\x13j\x9D\x1D\x10\xEE\xC1KD\"<:\x8C\x8D\xBFK.\x02\xC2\xBDp\x86\xA2\xE8FQ\x19\xD7\x98\x8E\x03\xA1RRQIR`,\xC74\xFF\x85\xF0.\x867\x0F\x0F\x8E\xF3'^!\x935\x8A\xC0\xBF\xA5\xB2J\x1E\xFC\b\xFC\xB3O\xF4\xA1-[(\xD9Yq\x83\xC1b\x1E:\x9A\xD0u\x03\x7F3\xE4Xq\x8D\x94\xB0\xE7\a\x06_\eS7\x06\xB8\x80\xD75)\x13+\x8Dc\x01\v\x10\xFF\xDB\f\x95\xCC\x8AT\xE7\x8A\xD7F\xA7\xA5\x92\xA7\xB4\x94U\x81*\xA83s\f\xE9uIt5e\xC7\xB0\xDD\xD9\xD0\xDD\xEA!\xFC\xC0\x15+\xA5\xB2k\xE92\xC8\f\x96\xBFk(\xF0\xA7\xB1b\x94\x10\xC7\xE03\x1F\xDAv83\xDF\xBD\b\x9C\x18\x05W\x98\e\xA9^\x1E]\r\xBB\x80\xA5U\xBF\fCx\x1C:\xB2\xBA\xD1\xC7\xA0\f\xE1m\xCFi\x00\xFA\x89\x06T\x93\xA7\xE6\xB7\xC8\x12\x9BR\xCAea]6\xEE\xE0u\xC3\b<\xE5u+\xA0\x17\xAD+\xC2h\xBA\xA2\xDF\xC1\x1E\x0F\\\xB8\x135\xFD\x91U\x81\xAD\x17\x81\xE0U\x04\x8E\x89\xF5\x93\xCE\e\x84\xB5\x93\xF4c\xEF\x88q\x7F\x13\x9C\t<\a\xA3Q\xA6\xE9}\xCA\xD4E\xD6\xE6c\x1C\xFD\xF1\x1D\x85\xD36\x7F1\xE5\xA0R\xAFU/\xEAM\xAD>\x1E\xF5r@'\xDA\x7F=2\x8A\xE7\xB0pj\xB0\x7F&z\x9D\f\x9A\xBE\xA6\xDF\x94\xC1T\xB9"
    File.open(rxdata, "wb") { |f| Marshal.dump([[62054200, "Main", txt]], f) }
  end

  def self.title_to_filename(title)
    title.gsub(/\\/, "&bs;")
         .gsub(/\//, "&fs;")
         .gsub(/:/, "&cn;")
         .gsub(/\*/, "&as;")
         .gsub(/\?/, "&qm;")
         .gsub(/"/, "&dq;")
         .gsub(/</, "&lt;")
         .gsub(/>/, "&gt;")
         .gsub(/\|/, "&po;")
  end

  def self.create_script(path, content)
    create_directory(File.dirname(path)) # Ensure the directory exists
    File.open(path, "wb") { |f| f.write(content) }
  end

  def self.clear_directory(path, delete_current = false)
    Dir.foreach(path) do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(path, entry)
      if File.directory?(full_path)
        clear_directory(full_path, true)
      else
        File.delete(full_path)
      end
    end
    Dir.delete(path) if delete_current
  end

  def self.create_directory(path)
    parts = path.split(File::SEPARATOR)
    (1..parts.length).each do |i|
      sub_path = File.join(parts[0...i])
      Dir.mkdir(sub_path) unless File.directory?(sub_path)
    end
  end
end

Scripts.dump
