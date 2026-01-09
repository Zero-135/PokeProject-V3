# class Ejemplo
#   DATA = {}   # constante de clase
# end

# puts Ejemplo::DATA   # => {}
# Ejemplo::DATA[:uno] = "numero 1"  # intenta modificar la constante
# Ejemplo::DATA[:dos] = "2"  # intenta modificar la constante
# puts Ejemplo::DATA



# class Ejemplo
#   def initialize(nombre)
#     @nombre = nombre
#   end
#   def self.saludar
#     puts "Hola " + @nombre.to_s + " desde el metodo de clase"
#   end
#   def saludar
#     puts "Hola " + @nombre
#   end
# end

# ej = Ejemplo.new("Juan")
# Ejemplo.saludar
# ej.saludar

# module GameData
#   module ClassMethodsSymbols
#     def get(other)
#       puts other
#     end
#   end
# end

# module GameData
#   class Species
#     extend ClassMethodsSymbols
#   end
# end

# poke = GameData::Species.new
# puts GameData::Species.get("BULBASAUR")
# puts poke.get("BULBASAUR")

# flag = "DefaultForm_1"
# flag[/^DefaultForm_(\d+)$/i]   # => "DefaultForm_3"

# puts $~[0]

# class EjemploPadre
#   attr_reader :val
#   def initialize
#     @val = "valor padre"
#   end

#   def actualizar
#     @val = "valor nuevo padre"
#   end
# end


# class Ejemplo
#   attr_reader :lectura
#   attr_reader :padre
#   def initialize
#     @lectura = "valor inicial"
#     @padre = EjemploPadre.new
#     # puts lectura
#     # puts self.lectura
#   end

#   def lectura
#     puts " desde el metodo de instancia"
#   end

#   def self.lectura
#     puts " desde el metodo de clase"
#   end

#   def otro_metodo
#     self.lectura
#   end

#   def cambiar_valor
#     @lectura = "valor cambiado"
#   end

#   def mostrar_variable
#     puts @lectura
#   end

#   def mostrar_variable2
#     puts @lectura
#   end
# end

# def update(ej)
#   ej.cambiar_valor
# end

# ej = Ejemplo.new
# # puts ej.mostrar_variable
# # update(ej)
# # puts ej.mostrar_variable
# puts ej.padre.val
# ej.padre.actualizar
# puts ej.padre.val 



# module GameData
#   class Nature
#     attr_reader :id
#     attr_reader :real_name
#     attr_reader :stat_changes

#     DATA = {}

#     def self.register(hash)
#       self::DATA[hash[:id]] = self.new(hash)
#     end

#     def self.load; end
#     def self.save; end

#     def initialize(hash)
#       @id           = hash[:id]
#       @real_name    = hash[:name]         || "Sin nombre"
#       @stat_changes = hash[:stat_changes] || []
#     end

#     # @return [String] the translated name of this nature
#     def name
#       return _INTL(@real_name)
#     end
#   end
# end

# #===============================================================================

# GameData::Nature.register({
#   :id           => :HARDY,
#   :name         => "Fuerte"
# })

# GameData::Nature.register({
#   :id           => :LONELY,
#   :name         => "Huraña",
#   :stat_changes => [[:ATTACK, 10], [:DEFENSE, -10]]
# })

# puts GameData::Nature::DATA.keys


# my_proc = proc { |x| x*2 }
# puts my_proc.call(5)  # => 10

class Pokemon
  def initialize(species, level, player=0)
    puts species
    puts level
    puts player
  end
end

class Pokemon
  alias initialize_old initialize
  def initialize(species,level,player)
    initialize_old(species,level)
    puts "Nuevo metodo"
  end
end

class Pokemon
  def initialize(species, level, player=0)
    puts species
    puts level
    puts player
  end
end

class Pokemon
  alias initialize_old initialize
  def initialize(species,level,player)
    initialize_old(species,level,player)
    puts "Nuevo metodo"
  end
end

pkm = Pokemon.new(:Pikachu, 5, 1)