#Victini
Settings::DEXES_WITH_OFFSETS  = [4]
#Formas en la Pokedex
Settings::DEX_SHOWS_ALL_FORMS = false

module GameData
    class Species
        #Correccion Genero Pikachu Cosplay
        Species.singleton_class.alias_method :walter_schema, :schema
        def self.schema(compiling_forms = false)
            ret = self.walter_schema(compiling_forms)
            if compiling_forms
                ret["GenderRatio"]    = [:gender_ratio,       "e", :GenderRatio]
                ret["GrowthRate"]     = [:growth_rate,        "e", :GrowthRate]
            end
            return ret
        end

        #Imagenes
        def self.check_graphic_file(path, species, form = 0, gender = 0, shiny = false, shadow = false, subfolder = "")
            if species == :BASCULEGION
                form = gender
            end
            try_subfolder = sprintf("%s/", subfolder)
            try_species = species
            try_form    = (form > 0) ? sprintf("_%d", form) : ""
            try_gender  = (gender == 1) ? "Female/" : ""
            try_shadow  = (shadow) ? "_shadow" : ""
            factors = []
            factors.push([4, sprintf("%s shiny/", subfolder), try_subfolder]) if shiny
            factors.push([3, try_shadow, ""]) if shadow
            factors.push([2, try_gender, ""]) if gender == 1
            factors.push([1, try_form, ""]) if form > 0
            factors.push([0, try_species, "0000"])
            # Go through each combination of parameters in turn to find an existing sprite
            (2**factors.length).times do |i|
                # Set try_ parameters for this combination
                factors.each_with_index do |factor, index|
                    value = ((i / (2**index)).even?) ? factor[1] : factor[2]
                    case factor[0]
                        when 0 then try_species   = value
                        when 1 then try_form      = value
                        when 2 then try_gender    = value
                        when 3 then try_shadow    = value
                        when 4 then try_subfolder = value   # Shininess
                    end
                end
                # Look for a graphic matching this combination's parameters
                try_species_text = try_species
                ret = pbResolveBitmap(sprintf("%s%s%s%s%s%s", path, try_subfolder,
                                            try_gender, try_species_text, try_form, try_shadow))
                return ret if ret
            end
            return nil
        end

        #Tutores
        def get_tutor_moves
            case @id
                when :PIKACHU     then moves = [:VOLTTACKLE]
                when :PIKACHU_2   then moves = [:THUNDERSHOCK]
                when :PIKACHU_3   then moves = [:ICICLECRASH]
                when :PIKACHU_4   then moves = [:FLYINGPRESS]
                when :PIKACHU_5   then moves = [:ELECTRICTERRAIN]
                when :PIKACHU_6   then moves = [:DRAININGKISS]
                when :PIKACHU_7   then moves = [:METEORMASH]
                when :ROTOM_1     then moves = [:OVERHEAT]
                when :ROTOM_2     then moves = [:HYDROPUMP]
                when :ROTOM_3     then moves = [:BLIZZARD]
                when :ROTOM_4     then moves = [:AIRSLASH]
                when :ROTOM_5     then moves = [:LEAFSTORM]
                when :KYUREM_1    then moves = [:ICEBURN, :FUSIONFLARE]
                when :KYUREM_2    then moves = [:FREEZESHOCK, :FUSIONBOLT]
                when :NECROZMA_1  then moves = [:SUNSTEELSTRIKE]
                when :NECROZMA_2  then moves = [:MOONGEISTBEAM]
                when :ZACIAN_1    then moves = [:BEHEMOTHBLADE]
                when :ZAMAZENTA_1 then moves = [:BEHEMOTHBASH]
                when :CALYREX_1   then moves = [:GLACIALLANCE]
                when :CALYREX_2   then moves = [:ASTRALBARRAGE]
            end
            return @tutor_moves if !moves
            return moves.concat(@tutor_moves.clone)
        end
    end
end

#Modificaciones en tamaño de Pokédex Vistos y Obtenidos
class PokemonPokedexMenu_Scene
    def pbStartScene(commands, commands2)
        @commands = commands
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @sprites = {}
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_menu"))
        text_tag = shadowc3tag(SEEN_OBTAINED_TEXT_BASE, SEEN_OBTAINED_TEXT_SHADOW)
        @sprites["headings"] = Window_AdvancedTextPokemon.newWithSize(
            text_tag + _INTL("VISTOS") + "  " + _INTL("OBTENIDOS") + "</c3>", 270, 136, 240, 64, @viewport
        )
        @sprites["headings"].windowskin = nil
        @sprites["commands"] = Window_DexesList.new(commands, commands2, Graphics.width - 84)
        @sprites["commands"].x      = 40
        @sprites["commands"].y      = 192
        @sprites["commands"].height = 192
        @sprites["commands"].viewport = @viewport
        pbFadeInAndShow(@sprites) { pbUpdate }
    end
end

class PokemonPokedexInfo_Scene
    #Permite ver Shinies en la Pokédex
    def pbScene
        @available = pbGetAvailableForms(false)
        @available_shiny = pbGetAvailableForms(true)
        Pokemon.play_cry(@species, @form)
        loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
                pbSEStop
                Pokemon.play_cry(@species, @form) if @page == 1
            elsif Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)
                ret = pbPageCustomUse(@page_id)
                if !ret
                    case @page_id
                        when :page_info
                            pbPlayDecisionSE
                            @show_battled_count = !@show_battled_count
                            dorefresh = true
                        when :page_forms
                            if @available.length + @available_shiny.length > 1
                                pbPlayDecisionSE
                                pbChooseForm
                                dorefresh = true
                            end
                        end
                    else
                    dorefresh = true
                end
            elsif Input.repeat?(Input::UP)
                oldindex = @index
                pbGoToPrevious
                if @index != oldindex
                    pbUpdateDummyPokemon
                    @available = pbGetAvailableForms(false)
                    @available_shiny = pbGetAvailableForms(true)
                    pbSEStop
                    (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
                    dorefresh = true
                end
            elsif Input.repeat?(Input::DOWN)
                oldindex = @index
                pbGoToNext
                if @index != oldindex
                    pbUpdateDummyPokemon
                    @available = pbGetAvailableForms(false)
                    @available_shiny = pbGetAvailableForms(true)
                    pbSEStop
                    (@page == 1) ? Pokemon.play_cry(@species, @form) : pbPlayCursorSE
                    dorefresh = true
                end
            elsif Input.repeat?(Input::LEFT)
                oldpage = @page
                numpages = @page_list.length
                @page -= 1
                @page = numpages if @page < 1
                @page = 1 if @page > numpages 
                if @page != oldpage
                    pbPlayCursorSE
                    dorefresh = true
                end
            elsif Input.repeat?(Input::RIGHT)
                oldpage = @page
                numpages = @page_list.length
                @page += 1
                @page = numpages if @page < 1
                @page = 1 if @page > numpages
                if @page != oldpage
                    pbPlayCursorSE
                    dorefresh = true
                end
            end
            drawPage(@page) if dorefresh
        end
        return @index
    end

    #Revisa si se ha visualizado la forma shiny  #Doble
    def pbGetAvailableForms(shiny = nil)
        ret = []
        multiple_forms = false
        GameData::Species.each do |sp|
            next if sp.species != @species
            next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
            next if sp.pokedex_form != sp.form
            multiple_forms = true if sp.form > 0
            if sp.single_gendered?
                real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
                next if !$player.pokedex.seen_form?(@species, real_gender, sp.form, shiny) && !Settings::DEX_SHOWS_ALL_FORMS
                real_gender = 2 if sp.gender_ratio == :Genderless
                ret.push([sp.form_name, real_gender, sp.form])
            elsif !gender_difference?(sp.form)
                2.times do |real_gndr|
                    next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form, shiny) && !Settings::DEX_SHOWS_ALL_FORMS
                    ret.push([sp.form_name || _INTL("Forma Normal"), 0, sp.form])
                    break
                end
            elsif sp.form_name == _INTL("Macho") || sp.form_name == _INTL("Hembra")
                next if !$player.pokedex.seen_form?(@species, sp.form, sp.form, shiny) && !Settings::DEX_SHOWS_ALL_FORMS
                ret.push([sp.form_name, sp.form, sp.form])
            else
                g = [_INTL("Macho"), _INTL("Hembra")]
                2.times do |real_gndr|
                    next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form, shiny) && !Settings::DEX_SHOWS_ALL_FORMS
                    form_name = (sp.form_name) ? sp.form_name + " " + g[real_gndr] : g[real_gndr]
                    ret.push([form_name, real_gndr, sp.form]) 
                end
            end
        end
        ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
        ret.each do |entry|
            if entry[0]
                entry[0] = "" if !multiple_forms && !gender_difference?(entry[2])
            else
                case entry[1]
                    when 0 then entry[0] = _INTL("Macho")
                    when 1 then entry[0] = _INTL("Hembra")
                else
                    entry[0] = (multiple_forms) ? _INTL("Forma Normal") : _INTL("Sin Género")
                end
            end
            entry[1] = 0 if entry[1] == 2
        end
        return ret
    end

    #Flechas en Formas del Poke en Pokedex
    def pbChooseForm
        index = 0
        @availablePokedex = @available.length > 0 ? @available : @available_shiny

        @availablePokedex.length.times do |i|
            if @availablePokedex[i][1] == @gender && @availablePokedex[i][2] == @form
                index = i
                break
            end
        end
        oldindex = -1
        shiny = @shiny
        old_shiny = !shiny

        @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
        @sprites["leftarrow"].x = 172
        @sprites["leftarrow"].y = 308
        @sprites["leftarrow"].play
        @sprites["leftarrow"].visible = false
        @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
        @sprites["rightarrow"].x = 312
        @sprites["rightarrow"].y = 308
        @sprites["rightarrow"].play
        @sprites["rightarrow"].visible = false
        loop do
            @availablePokedex = shiny ? @available_shiny : @available
            if oldindex != index || old_shiny != shiny
                $player.pokedex.set_last_form_seen(@species, @availablePokedex[index][1], @availablePokedex[index][2], shiny)
                pbUpdateDummyPokemon
                drawPage(@page)
                @sprites["uparrow"].visible   = (index > 0)
                @sprites["downarrow"].visible = (index < @availablePokedex.length - 1)
                @sprites["rightarrow"].visible = !shiny && (@available_shiny.length > 0)
                @sprites["leftarrow"].visible = shiny && (@available.length > 0)
                oldindex = index
                old_shiny = shiny
            end
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::UP)
                pbPlayCursorSE
                index = (index != 0) ? index - 1 : 0
            elsif Input.trigger?(Input::DOWN)
                pbPlayCursorSE
                index = (index != @availablePokedex.length - 1) ? index + 1 : @availablePokedex.length - 1
            elsif Input.trigger?(Input::RIGHT)
                pbPlayCursorSE
                if @available_shiny.length > 0
                    shiny = true
                    index = (index < @available_shiny.length) ? index : @available_shiny.length - 1
                end
            elsif Input.trigger?(Input::LEFT)
                pbPlayCursorSE
                if @available.length > 0
                    shiny = false
                    index = (index < @available.length) ? index : @available.length - 1
                end
            elsif Input.trigger?(Input::BACK)
                pbPlayCancelSE
                break
            elsif Input.trigger?(Input::USE)
                pbPlayDecisionSE
                break
            end
        end
        @sprites["uparrow"].visible   = false
        @sprites["downarrow"].visible = false
        @sprites["rightarrow"].visible = false
        @sprites["leftarrow"].visible = false
        #$player.pokedex.set_last_form_seen(@species, 0, 0, false)
    end

    #Imagen Pokedex Back y Shiny
    alias walter_pbUpdateDummyPokemon pbUpdateDummyPokemon
    def pbUpdateDummyPokemon
        walter_pbUpdateDummyPokemon
        @species = @dexlist[@index][:species]
        @gender, @form, @shiny = $player.pokedex.last_form_seen(@species)
        @sprites["infosprite"].setSpeciesBitmap(@species, @gender, @form, @shiny)
        @sprites["formfront"]&.setSpeciesBitmap(@species, @gender, @form, @shiny)
        if @sprites["formback"]
            @sprites["formback"].setSpeciesBitmap(@species, @gender, @form, @shiny, false, true)
        end
        @sprites["formicon"]&.pbSetParams(@species, @gender, @form, @shiny)
    end

    #Muestra el genero del Pokemon Shiny
    def drawPageForms
        #Nuevo
        @sprites["formfront"].visible     = true
        @sprites["formback"].visible      = true
        @sprites["formicon"].visible      = true

        #Antiguo
        @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_forms"))
        overlay = @sprites["overlay"].bitmap
        base   = Color.new(88, 88, 80)
        shadow = Color.new(168, 184, 184)
        # Write species and form name
        formname = ""
        if @shiny
            @available_shiny.each do |i|
                if i[1] == @gender && i[2] == @form
                    formname = i[0]
                    break
                end
            end
        else
            @available.each do |i|
                if i[1] == @gender && i[2] == @form
                    formname = i[0]
                    break
                end
            end
        end
        textpos = [
        [GameData::Species.get(@species).name, Graphics.width / 2, Graphics.height - 82, :center, base, shadow],
        [formname, Graphics.width / 2, Graphics.height - 50, :center, base, shadow]
        ]
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
    end
end

#Orden Pokedex Specie
def pbChooseFromGameDataList(game_data, default = nil)
    if !GameData.const_defined?(game_data.to_sym)
        raise _INTL("No se encuentra la clase {1} en el módulo GameData.", game_data.to_s)
    end
    game_data_module = GameData.const_get(game_data.to_sym)
    commands = []
    game_data_module.each do |data|
        name = data.real_name
        name = yield(data) if block_given?
        next if !name
        commands.push([commands.length + 1, name, data.id])
    end
    num_sort = game_data == :Species ? -1 : 1
    return pbChooseList(commands, default, nil, num_sort)
end

#Pregunta si se añade el poke al equipo
def pbAddPokemon(pkmn, level = 1, see_form = true)
  return false if !pkmn
  if pbBoxesFull?
    pbMessage(_INTL("¡No hay espacio para más Pokémon!") + "\1")
    pbMessage(_INTL("¡Las Cajas del PC están llenas y no tienen más espacio!"))
    return false
  end
  pkmn = Pokemon.new(pkmn, level, $player, true, false) if !pkmn.is_a?(Pokemon)
  species_name = pkmn.speciesName
  pbMessage(_INTL("¡{1} obtuvo un {2}!", $player.name, species_name) + "\\me[Pkmn get]\\wtnp[80]")
  was_owned = $player.owned?(pkmn.species)
  $player.pokedex.set_seen(pkmn.species)
  $player.pokedex.set_owned(pkmn.species)
  $player.pokedex.register(pkmn) if see_form
  # Show Pokédex entry for new species if it hasn't been owned before
  if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && see_form && !was_owned &&
    $player.has_pokedex && $player.pokedex.species_in_unlocked_dex?(pkmn.species)
    pbMessage(_INTL("Los datos de {1} se han añadido a la Pokédex.", species_name))
    $player.pokedex.register_last_seen(pkmn)
    pbFadeOutIn do
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbDexEntry(pkmn.species)
    end
  end
  # Nickname and add the Pokémon
  pbNicknameAndStore(pkmn)
  return true
end

def pbPartyScreen(idxBattler, canCancel = false, mode = 0)
    # # Fade out and hide all sprites
    # visibleSprites = pbFadeOutAndHide(@sprites)
    # # Get player's party
    # partyPos = @battle.pbPartyOrder(idxBattler)
    # partyStart, _partyEnd = @battle.pbTeamIndexRangeFromBattlerIndex(idxBattler)
    # modParty = @battle.pbPlayerDisplayParty(idxBattler)
    
    # Get player's party
    partyPos =Array.new($player.party.length) { |i| i }
    partyStart = [0][idxBattler]
    modParty = $player.party
    
    # Start party screen
    scene = PokemonParty_Scene.new
    switchScreen = PokemonPartyScreen.new(scene, modParty)
    msg = _INTL("Elige un Pokémon.")
    msg = _INTL("¿Qué Pokémon enviar al PC?") if mode == 1
    #switchScreen.pbStartScene(msg, @battle.pbNumPositions(0, 0))
    switchScreen.pbStartScene(msg, 1)
    # Loop while in party screen
    loop do
      # Select a Pokémon
      scene.pbSetHelpText(msg)
      idxParty = switchScreen.pbChoosePokemon
      if idxParty < 0
        next if !canCancel
        break
      end
      # Choose a command for the selected Pokémon
      cmdSwitch  = -1
      cmdBoxes   = -1
      cmdSummary = -1
      cmdSelect  = -1
      commands = []
      commands[cmdSwitch  = commands.length] = _INTL("Cambiar") if mode == 0 && modParty[idxParty].able? &&
                                                                     (@battle.canSwitch || !canCancel)
      commands[cmdBoxes   = commands.length] = _INTL("Enviar al PC") if mode == 1
      commands[cmdSelect  = commands.length] = _INTL("Seleccionar") if mode == 2 && modParty[idxParty].fainted?
      commands[cmdSummary = commands.length] = _INTL("Datos")
      commands[commands.length]              = _INTL("Cancelar")
      command = scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", modParty[idxParty].name), commands)
      if (cmdSwitch >= 0 && command == cmdSwitch) ||   # Switch In
         (cmdBoxes >= 0 && command == cmdBoxes)   ||   # Send to Boxes
         (cmdSelect >= 0 && command == cmdSelect)      # Select for Revival Blessing
        idxPartyRet = -1
        partyPos.each_with_index do |pos, i|
            next if pos != idxParty + partyStart
            idxPartyRet = i
            break
        end
        break if yield idxPartyRet, switchScreen
      elsif cmdSummary >= 0 && command == cmdSummary   # Summary
        scene.pbSummary(idxParty, true)
      end
    end
    # Close party screen
    switchScreen.pbEndScene
end

def pbNicknameAndStore(pkmn)
    if pbBoxesFull?
        pbMessage(_INTL("¡No hay espacio para más Pokémon!") + "\1")
        pbMessage(_INTL("¡Las Cajas del PC están llenas y no tienen más espacio!"))
        return
    end
    $player.pokedex.set_seen(pkmn.species)
    $player.pokedex.set_owned(pkmn.species)

    # Nickname the Pokémon (unless it's a Shadow Pokémon)
    if !pkmn.shadowPokemon?
        pbNickname(pkmn)
    end

    battleRules = $game_temp.battle_rules
    sendToBoxes = 1
    sendToBoxes = $PokemonSystem.sendtoboxes if Settings::NEW_CAPTURE_CAN_REPLACE_PARTY_MEMBER
    sendToBoxes = 2 if battleRules["forceCatchIntoParty"]

    scene = BattleCreationHelperMethods.create_battle_scene
    peer  = Battle::Peer.new

    # Store the Pokémon
    if $player.party_full? && (sendToBoxes == 0 || sendToBoxes == 2)   # Ask/must add to party
        cmds = [_INTL("Agregar al equipo"),
                _INTL("Enviar a una caja"),
                _INTL("Ver datos de {1}", pkmn.name),
                _INTL("Ver equipo")]
        cmds.delete_at(1) if sendToBoxes == 2   # Remove "Send to a Box" option
        loop do
            cmd = pbMessage(_INTL("¿A dónde quieres enviar a {1}?", pkmn.name), cmds, 99)
            next if cmd == 99 && sendToBoxes == 2   # Can't cancel if must add to party
            break if cmd == 99   # Cancelling = send to a Box
            cmd += 1 if cmd >= 1 && sendToBoxes == 2
            case cmd
                when 0   # Add to your party
                    pbMessage(_INTL("Elige a un Pokémon de tu equipo para enviar a las cajas."))
                    party_index = -1
                    pbPartyScreen(0, (sendToBoxes != 2), 1) do |idxParty, _partyScene|
                        party_index = idxParty
                        next true
                    end
                    next if party_index < 0   # Cancelled
                    party_size = $player.party.length
                    # Get chosen Pokémon and clear battle-related conditions
                    send_pkmn = $player.party[party_index]
                    
                    #peer.pbOnLeavingBattle(self, send_pkmn, @usedInBattle[0][party_index], true)
                    peer.pbOnLeavingBattle(self, send_pkmn, false, true)#revisar

                    send_pkmn.statusCount = 0 if send_pkmn.status == :POISON   # Bad poison becomes regular
                    send_pkmn.makeUnmega
                    send_pkmn.makeUnprimal
                    # Send chosen Pokémon to storage
                    stored_box = peer.pbStorePokemon($player, send_pkmn)
                    $player.party.delete_at(party_index)
                    box_name = peer.pbBoxName(stored_box)
                    pbMessage(_INTL("{1} fue enviado a la caja \"{2}\".", send_pkmn.name, box_name))
                    # Rearrange all remembered properties of party Pokémon          
                    # (party_index...party_size).each do |idx|
                    #   if idx < party_size - 1
                    #     @initialItems[0][idx] = @initialItems[0][idx + 1]
                    #     $game_temp.party_levels_before_battle[idx] = $game_temp.party_levels_before_battle[idx + 1]
                    #     $game_temp.party_critical_hits_dealt[idx] = $game_temp.party_critical_hits_dealt[idx + 1]
                    #     $game_temp.party_direct_damage_taken[idx] = $game_temp.party_direct_damage_taken[idx + 1]
                    #   else
                    #     @initialItems[0][idx] = nil
                    #     $game_temp.party_levels_before_battle[idx] = nil
                    #     $game_temp.party_critical_hits_dealt[idx] = nil
                    #     $game_temp.party_direct_damage_taken[idx] = nil
                    #   end
                    # end
                    break
                when 1   # Send to a Box
                    break
                when 2   # See X's summary
                    pbFadeOutIn do
                        summary_scene = PokemonSummary_Scene.new
                        summary_screen = PokemonSummaryScreen.new(summary_scene, true)
                        summary_screen.pbStartScreen([pkmn], 0)
                    end
                when 3   # Check party
                    pbPartyScreen(0, true, 2)
            end
        end
    end
    # Store as normal (add to party if there's space, or send to a Box if not)
    stored_box = peer.pbStorePokemon($player, pkmn)
    if stored_box < 0
        pbMessage(_INTL("Se agregó a {1} al equipo.", pkmn.name))
        #@initialItems[0][$player.party.length - 1] = pkmn.item_id if @initialItems
        return
    end
    # Messages saying the Pokémon was stored in a PC box
    box_name = peer.pbBoxName(stored_box)
    pbMessage(_INTL("Se envió {1} a la caja \"{2}\"!", pkmn.name, box_name))
end

#Queremos que viaje la forma al momento de la creacion del poke
class Pokemon
    def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
        species_data = GameData::Species.get(species)
        @species          = species_data.species
        @form             = species_data.base_form
        @forced_form      = nil
        @time_form_set    = nil
        self.level        = level
        @steps_to_hatch   = 0
        heal_status
        @gender           = nil
        @shiny            = nil
        @ability_index    = nil
        @ability          = nil
        @nature           = nil
        @nature_for_stats = nil
        @item             = nil
        @mail             = nil
        @moves            = []
        reset_moves if withMoves
        @first_moves      = []
        @ribbons          = []
        @cool             = 0
        @beauty           = 0
        @cute             = 0
        @smart            = 0
        @tough            = 0
        @sheen            = 0
        @pokerus          = 0
        @name             = nil
        @happiness        = species_data.happiness
        @poke_ball        = :POKEBALL
        @markings         = []
        @iv               = {}
        @ivMaxed          = {}
        @ev               = {}
        @evo_move_count   = {}
        @evo_crest_count  = {}
        @evo_recoil_count = 0
        @evo_step_count   = 0
        GameData::Stat.each_main do |s|
            @iv[s.id]       = rand(IV_STAT_LIMIT + 1)
            @ev[s.id]       = 0
        end
        case owner
        when Owner
            @owner = owner
        when Player, NPCTrainer
            @owner = Owner.new_from_trainer(owner)
        else
            @owner = Owner.new(0, "", 2, 2)
        end
        @obtain_method    = 0   # Met
        @obtain_method    = 4 if $game_switches && $game_switches[Settings::FATEFUL_ENCOUNTER_SWITCH]
        @obtain_map       = ($game_map) ? $game_map.map_id : 0
        @obtain_text      = nil
        @obtain_level     = level
        @hatched_map      = 0
        @timeReceived     = Time.now.to_i
        @timeEggHatched   = nil
        @fused            = nil
        @personalID       = rand(2**16) | (rand(2**16) << 16)
        @hp               = 1
        @totalhp          = 1
        calc_stats
        if @form == 0 && recheck_form
            f = MultipleForms.call("getFormOnCreation", self)
            if f
                self.form = f
                reset_moves if withMoves
            end
        end
    end
end

if Settings::USE_NEW_EXP_SHARE
    class Pokemon
        attr_accessor(:expshare)    # Repartir experiencia
        alias initialize_old initialize
        def initialize(species,level,player=$player,withMoves=true, recheck_form = true)
            initialize_old(species, level, player, withMoves, recheck_form)
            $PokemonSystem.expshareon ||= 0
            @expshare = ($PokemonGlobal&.expshare_enabled && $PokemonSystem.expshareon == 0) || 
                       $player&.has_exp_all
        end
    end
end

class Pokemon
    alias paldea_initialize initialize
    def initialize(species, level, owner = $player, withMoves = true, recheck_form = true)
        paldea_initialize(species, level, owner, withMoves, recheck_form)
        @evo_move_count   = {}
        @evo_crest_count  = {}
        @evo_recoil_count = 0
        @evo_step_count   = 0
        if @species == :BASCULEGION && recheck_form
            f = MultipleForms.call("getFormOnCreation", self)
            if f
                self.form = f
                reset_moves if withMoves
            end
        end
    end
end

#Movimiento Combate
class Battle
    def pbRegisterMove(idxBattler, idxMove, showMessages = true)
        battler = @battlers[idxBattler]
        move = battler.moves[idxMove]
        return false if !pbCanChooseMove?(idxBattler, idxMove, showMessages)

        if move.id == :STRUGGLE
            @choices[idxBattler][0] = :UseMove    # "Use move"
            @choices[idxBattler][1] = -1          # Index of move to be used
            @choices[idxBattler][2] = @struggle   # Struggle Battle::Move object
            @choices[idxBattler][3] = -1          # No target chosen yet
        else
            @choices[idxBattler][0] = :UseMove   # "Use move"
            @choices[idxBattler][1] = idxMove    # Index of move to be used
            @choices[idxBattler][2] = move       # Battle::Move object
            @choices[idxBattler][3] = -1         # No target chosen yet
        end

        return true
    end
end

#Adicion de la descripcion de habilidades #Doble
class PokemonSummary_Scene
    def pbScene
        @pokemon.play_cry
        loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
                pbSEStop
                @pokemon.play_cry
                @show_back = !@show_back
                if PluginManager.installed?("[DBK] Animated Pokémon System")
                    @sprites["pokemon"].setSummaryBitmap(@pokemon, @show_back)
                    @sprites["pokemon"].constrict([208, 164])
                else
                    @sprites["pokemon"].setPokemonBitmap(@pokemon, @show_back)
                end
                if @show_back
                    @sprites["pokemon"].zoom_x = 2 / 3.0
                    @sprites["pokemon"].zoom_y = 2 / 3.0
                end
            elsif Input.trigger?(Input::BACK)
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::SPECIAL) && @page_id == :page_skills
                pbPlayDecisionSE
                showAbilityDescription(@pokemon)
            elsif Input.trigger?(Input::USE)
                dorefresh = pbPageCustomUse(@page_id)
                if !dorefresh
                    case @page_id
                    when :page_moves
                        pbPlayDecisionSE
                        dorefresh = pbOptions
                    when :page_ribbons
                        pbPlayDecisionSE
                        pbRibbonSelection
                        dorefresh = true
                    else
                        if !@inbattle
                            pbPlayDecisionSE
                            dorefresh = pbOptions
                        end
                    end
                end
            elsif Input.repeat?(Input::UP)
                oldindex = @partyindex
                pbGoToPrevious
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.repeat?(Input::DOWN)
                oldindex = @partyindex
                pbGoToNext
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.trigger?(Input::JUMPUP) && !@party.is_a?(PokemonBox)
                oldindex = @partyindex
                @partyindex = 0
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.trigger?(Input::JUMPDOWN) && !@party.is_a?(PokemonBox)
                oldindex = @partyindex
                @partyindex = @party.length - 1
                if @partyindex != oldindex
                    pbChangePokemon
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.repeat?(Input::LEFT)
                oldpage = @page
                numpages = @page_list.length
                @page -= 1
                @page = numpages if @page < 1
                @page = 1 if @page > numpages
                if @page != oldpage
                    pbSEPlay("GUI summary change page")
                    @ribbonOffset = 0
                    dorefresh = true
                end
            elsif Input.repeat?(Input::RIGHT)
                oldpage = @page
                numpages = @page_list.length
                @page += 1
                @page = numpages if @page < 1
                @page = 1 if @page > numpages
                if @page != oldpage
                    pbSEPlay("GUI summary change page")
                    @ribbonOffset = 0
                    dorefresh = true
                end
            end
            @show_back = false if dorefresh
            if !@show_back
                @sprites["pokemon"].zoom_x = 1.0
                @sprites["pokemon"].zoom_y = 1.0
            end
            drawPage(@page) if dorefresh
        end
        return @partyindex
    end
end

class Battle::Battler
    #Modificaciones para las formas de Reshiram, Zekrom y Kyurem
    alias new_forms_pbCheckForm pbCheckForm
    def pbCheckForm(endOfRound = false)
        new_forms_pbCheckForm(endOfRound)
        f = MultipleForms.call("getFormOnBattle", @pokemon)
        pbChangeForm(f, _INTL("")) if f
    end

    #Cambia Formas en Ataques
    def pbProcessTurn(choice, tryFlee = true)
        return false if fainted?
        if tryFlee && wild? &&
            @battle.rules["alwaysflee"] && @battle.pbCanRun?(@index)
            pbBeginTurn(choice)
            wild_flee(_INTL("{1} fled from battle!", pbThis))
            pbEndTurn(choice)
            return true
        end
        if choice[0] == :Shift
            idxOther = -1
            case @battle.pbSideSize(@index)
            when 2
                idxOther = (@index + 2) % 4
            when 3
                if @index != 2 && @index != 3
                    idxOther = (@index.even?) ? 2 : 3
                end
            end
            if idxOther >= 0
                @battle.pbSwapBattlers(@index, idxOther)
                case @battle.pbSideSize(@index)
                when 2
                @battle.pbDisplay(_INTL("{1} moved across!", pbThis))
                when 3
                @battle.pbDisplay(_INTL("{1} moved to the center!", pbThis))
                end
            end
            pbBeginTurn(choice)
            pbCancelMoves
            @lastRoundMoved = @battle.turnCount
            return true
        end
        if choice[0] != :UseMove
            pbBeginTurn(choice)
            pbEndTurn(choice)
            return false
        end
        
        f = MultipleForms.call("getFormOnAttack", @pokemon, choice[2].id)
        pbChangeForm(f, _INTL("")) if f        
        PBDebug.log("[Use move] #{pbThis} (#{@index}) used #{choice[2].name}")
        PBDebug.logonerr { pbUseMove(choice, choice[2] == @battle.struggle) }
        pbChangeForm(f - 1, _INTL("")) if f

        @battle.pbJudge
        @battle.pbCalculatePriority if Settings::RECALCULATE_TURN_ORDER_AFTER_SPEED_CHANGES
        return true
    end

    #Actualizacion Sprite Movimientos 2 Turnos
    def pbRestoreBattlerSprite(user)
        scene = @battle.scene
        return if !scene

        sprite = scene.sprites["pokemon_#{user.index}"]
        return if !sprite

        sprite.visible = true
        sprite.opacity = 255
        sprite.pbSetPosition
    end

    def pbProcessMoveHit(move, user, targets, hitNum, skipAccuracyCheck)
        return false if user.fainted?
        # For two-turn attacks being used in a single turn
        move.pbInitialEffect(user, targets, hitNum)
        numTargets = 0   # Number of targets that are affected by this hit
        # Count a hit for Parental Bond (if it applies)
        user.effects[PBEffects::ParentalBond] -= 1 if user.effects[PBEffects::ParentalBond] > 0
        # Accuracy check (accuracy/evasion calc)
        if hitNum == 0 || move.successCheckPerHit?
            targets.each do |b|
                b.damageState.missed = false
                next if b.damageState.unaffected
                if pbSuccessCheckPerHit(move, user, b, skipAccuracyCheck)
                    numTargets += 1
                else
                    b.damageState.missed     = true
                    b.damageState.unaffected = true
                end
            end
            # If failed against all targets
            if targets.length > 0 && numTargets == 0 && !move.worksWithNoTargets?
                targets.each do |b|
                    next if !b.damageState.missed || b.damageState.magicCoat
                    pbMissMessage(move, user, b)
                    if user.itemActive?
                        Battle::ItemEffects.triggerOnMissingTarget(user.item, user, b, move, hitNum, @battle)
                    end
                    break if move.pbRepeatHit?   # Dragon Darts only shows one failure message
                end
                move.pbCrashDamage(user)
                user.pbItemHPHealCheck
                pbCancelMoves
                
                if move.pbIsChargingTurn?(user)
                    pbRestoreBattlerSprite(user)
                end
                
                return false
            end
        end
        # If we get here, this hit will happen and do something
        all_targets = targets
        targets = move.pbDesignateTargetsForHit(targets, hitNum)   # For Dragon Darts
        targets.each { |b| b.damageState.resetPerHit }
        #---------------------------------------------------------------------------
        # Calculate damage to deal
        if move.pbDamagingMove?
            targets.each do |b|
                next if b.damageState.unaffected
                # Check whether Substitute/Disguise will absorb the damage
                move.pbCheckDamageAbsorption(user, b)
                # Calculate the damage against b
                # pbCalcDamage shows the "eat berry" animation for SE-weakening
                # berries, although the message about it comes after the additional
                # effect below
                move.pbCalcDamage(user, b, targets.length)   # Stored in damageState.calcDamage
                # Lessen damage dealt because of False Swipe/Endure/etc.
                move.pbReduceDamage(user, b)   # Stored in damageState.hpLost
            end
        end
        # Show move animation (for this hit)
        move.pbShowAnimation(move.id, user, targets, hitNum)
        # Type-boosting Gem consume animation/message
        if user.effects[PBEffects::GemConsumed] && hitNum == 0
            # NOTE: The consume animation and message for Gems are shown now, but the
            #       actual removal of the item happens in def pbEffectsAfterMove.
            @battle.pbCommonAnimation("UseItem", user)
            @battle.pbDisplay(_INTL("¡{1} refuerza el poder de {2}!",
                                    GameData::Item.get(user.effects[PBEffects::GemConsumed]).name, move.name))
        end
        # Messages about missed target(s) (relevant for multi-target moves only)
        if !move.pbRepeatHit?
            targets.each do |b|
                next if !b.damageState.missed
                pbMissMessage(move, user, b)
                if user.itemActive?
                    Battle::ItemEffects.triggerOnMissingTarget(user.item, user, b, move, hitNum, @battle)
                end
            end
        end
        # Deal the damage (to all allies first simultaneously, then all foes
        # simultaneously)
        if move.pbDamagingMove?
            # This just changes the HP amounts and does nothing else
            targets.each { |b| move.pbInflictHPDamage(b) if !b.damageState.unaffected }
            # Animate the hit flashing and HP bar changes
            move.pbAnimateHitAndHPLost(user, targets)
        end
        # Self-Destruct/Explosion's damaging and fainting of user
        move.pbSelfKO(user) if hitNum == 0
        user.pbFaint if user.fainted?
        if move.pbDamagingMove?
            targets.each do |b|
                next if b.damageState.unaffected
                # NOTE: This method is also used for the OHKO special message.
                move.pbHitEffectivenessMessages(user, b, targets.length)
                # Record data about the hit for various effects' purposes
                move.pbRecordDamageLost(user, b)
            end
            # Close Combat/Superpower's stat-lowering, Flame Burst's splash damage,
            # and Incinerate's berry destruction
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbEffectWhenDealingDamage(user, b)
            end
            # Ability/item effects such as Static/Rocky Helmet, and Grudge, etc.
            targets.each do |b|
                next if b.damageState.unaffected
                pbEffectsOnMakingHit(move, user, b)
            end
            # Disguise/Endure/Sturdy/Focus Sash/Focus Band messages
            targets.each do |b|
                next if b.damageState.unaffected
                move.pbEndureKOMessage(b)
            end
            # HP-healing held items (checks all battlers rather than just targets
            # because Flame Burst's splash damage affects non-targets)
            @battle.pbPriority(true).each do |b|
                next if move.preventsBattlerConsumingHealingBerry?(b, targets)
                b.pbItemHPHealCheck
            end
            # Animate battlers fainting (checks all battlers rather than just targets
            # because Flame Burst's splash damage affects non-targets)
            @battle.pbPriority(true).each { |b| b.pbFaint if b&.fainted? }
        end
        @battle.pbJudgeCheckpoint(user, move)
        # Main effect (recoil/drain, etc.)
        targets.each do |b|
            next if b.damageState.unaffected
            move.pbEffectAgainstTarget(user, b)
        end
        move.pbEffectGeneral(user)
        targets.each { |b| b.pbFaint if b&.fainted? }
        user.pbFaint if user.fainted?
        # Additional effect
        if !user.hasActiveAbility?(:SHEERFORCE)
            targets.each do |b|
                next if b.damageState.calcDamage == 0
                chance = move.pbAdditionalEffectChance(user, b)
                next if chance <= 0
                move.pbAdditionalEffect(user, b) if @battle.pbRandom(100) < chance
            end
        end
        # Make the target flinch (because of an item/ability)
        targets.each do |b|
            next if b.fainted?
            next if b.damageState.calcDamage == 0 || b.damageState.substitute
            chance = move.pbFlinchChance(user, b)
            next if chance <= 0
            if @battle.pbRandom(100) < chance
                PBDebug.log("[Item/ability triggered] #{user.pbThis}'s King's Rock/Razor Fang or Stench")
                b.pbFlinch(user)
            end
        end
        # Message for and consuming of type-weakening berries
        # NOTE: The "consume held item" animation for type-weakening berries occurs
        #       during pbCalcDamage above (before the move's animation), but the
        #       message about it only shows here.
        targets.each do |b|
            next if b.damageState.unaffected
            next if !b.damageState.berryWeakened
            @battle.pbDisplay(_INTL("¡{1} redujo el daño de {2}!", b.itemName, b.pbThis(true)))
            b.pbConsumeItem
        end
        # Steam Engine (goes here because it should be after stat changes caused by
        # the move)
        if [:FIRE, :WATER].include?(move.calcType)
            targets.each do |b|
                next if b.damageState.unaffected
                next if b.damageState.calcDamage == 0 || b.damageState.substitute
                next if !b.hasActiveAbility?(:STEAMENGINE)
                b.pbRaiseStatStageByAbility(:SPEED, 6, b) if b.pbCanRaiseStatStage?(:SPEED, b)
            end
        end
        # Fainting
        targets.each { |b| b.pbFaint if b&.fainted? }
        user.pbFaint if user.fainted?
        # Dragon Darts' second half of attack
        if move.pbRepeatHit? && hitNum == 0 &&
            targets.any? { |b| !b.fainted? && !b.damageState.unaffected }
            pbProcessMoveHit(move, user, all_targets, 1, skipAccuracyCheck)
        end
        return true
    end

end

class Pokemon
    def gendernil
        @gender = nil
    end

    alias __evo_species__= species=
    def species=(species_id)
        self.__evo_species__ = species_id
        @gender      = nil if singleGendered? || @gender == 2
        calc_stats
    end
end

#Orden en las Formas
MenuHandlers.add(:pokemon_debug_menu, :species_and_form, {
  "name"   => _INTL("Especie/forma..."),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
        msg = [_INTL("Especie {1}, forma {2}.", pkmn.speciesName, pkmn.form),
                _INTL("Especie {1}, forma {2} (forzado).", pkmn.speciesName, pkmn.form)][(pkmn.forced_form.nil?) ? 0 : 1]
        cmd = screen.pbShowCommands(msg,
                                    [_INTL("Definir especie"),
                                    _INTL("Definir forma"),
                                    _INTL("Eliminar de anulados")], cmd)
        break if cmd < 0
        case cmd
            when 0   # Set species
                species = pbChooseSpeciesList(pkmn.species)
                if species && species != pkmn.species
                    pkmn.species = species
                    pkmn.calc_stats
                    $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
                    screen.pbRefreshSingle(pkmnid)
                end
            when 1   # Set form
                cmd2 = 0
                formcmds = [[], []]
                GameData::Species::DATA.values
                .sort_by { |sp| [sp.species.to_s, sp.form] }
                .each do |sp|
                    next if sp.species != pkmn.species
                    form_name = sp.form_name
                    form_name = _INTL("Forma sin nombre") if !form_name || form_name.empty?
                    form_name = sprintf("%d: %s", sp.form, form_name)
                    formcmds[0].push(sp.form)
                    formcmds[1].push(form_name)
                    cmd2 = formcmds[0].length - 1 if pkmn.form == sp.form
                end
                if formcmds[0].length <= 1
                    screen.pbDisplay(_INTL("La especie {1} solo tiene una forma.", pkmn.speciesName))
                    if pkmn.form != 0 && screen.pbConfirm(_INTL("¿Quieres reiniciar la forma a la 0?"))
                        pkmn.gendernil if pkmn.species == :PIKACHU
                        pkmn.form = 0
                        $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
                        screen.pbRefreshSingle(pkmnid)
                    end
                else
                    cmd2 = screen.pbShowCommands(_INTL("Define la forma del Pokémon."), formcmds[1], cmd2)
                    next if cmd2 < 0
                    f = formcmds[0][cmd2]
                    if f != pkmn.form
                        if MultipleForms.hasFunction?(pkmn, "getForm")
                            next if !screen.pbConfirm(_INTL("Esta especie decide su propia forma. ¿Sobreescribir?"))
                            pkmn.forced_form = f
                        end
                        pkmn.gendernil if pkmn.species == :PIKACHU
                        pkmn.form = f
                        $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
                        screen.pbRefreshSingle(pkmnid)
                    end
                end
            when 2   # Remove form override
                pkmn.forced_form = nil
                screen.pbRefreshSingle(pkmnid)
        end
    end
    next false
  }
})

#Adicion de Objetos para cambiar Formas
ItemHandlers::UseOnPokemon.add(:PIKACHUCATALOG, proc { |item, qty, pkmn, scene|
    if !pkmn.isSpecies?(:PIKACHU) || pkmn.form < 2 || pkmn.form > 7
        scene.pbDisplay(_INTL("No tendría efecto."))
        next false
    elsif pkmn.fainted?
        scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
        next false
    end
    choices = [
        _INTL("Cosplay Pikachu"),
        _INTL("Pikachu Belle"),
        _INTL("Pikachu Libre"),
        _INTL("Pikachu, Ph.D."),
        _INTL("Pikachu Pop Star"),
        _INTL("Pikachu Rock Star"),
        _INTL("Cancelar")
    ]
    new_form = scene.pbShowCommands(_INTL("¿Qué disfraz te gustaría ponerle?"), choices, pkmn.form-2)
    if new_form == pkmn.form - 2
        scene.pbDisplay(_INTL("No tendría ningún efecto."))
        next false
    elsif new_form >= 0 && new_form < choices.length - 1
        pkmn.setForm(new_form + 2) do
            scene.pbRefresh
            scene.pbDisplay(_INTL("¡{1} se disfrazó!", pkmn.name))
        end
        next true
    end
    next false
})

ItemHandlers::UseOnPokemon.add(:SCISSORS, proc { |item, qty, pkmn, scene|
    if !pkmn.isSpecies?(:FURFROU)
        scene.pbDisplay(_INTL("No tendría efecto."))
        next false
    elsif pkmn.fainted?
        scene.pbDisplay(_INTL("No se puede usar en Pokémon debilitados."))
        next false
    end
    choices = [
        _INTL("Natural Form"),
        _INTL("Heart Trim"),
        _INTL("Star Trim"),
        _INTL("Diamond Trim"),
        _INTL("Debutante Trim"),
        _INTL("Matron Trim"),
        _INTL("Dandy Trim"),
        _INTL("La Reine Trim"),
        _INTL("Kabuki Trim"),
        _INTL("Pharaoh Trim"),
        _INTL("Cancelar")
    ]
    new_form = scene.pbShowCommands(_INTL("¿Qué corte te gustaría hacerle?"), choices, pkmn.form)
    if new_form == pkmn.form
        scene.pbDisplay(_INTL("No tendría ningún efecto."))
        next false
    elsif new_form >= 0 && new_form < choices.length - 1
        pkmn.setForm(new_form) do
            scene.pbRefresh
            scene.pbDisplay(_INTL("¡{1} cambio de corte!", pkmn.name))
        end
        next true
    end
    next false
})

#Formas de Rotom
ItemHandlers::UseOnPokemon.add(:ROTOMCATALOG,
    proc { |item, qty, pkmn, scene|
        next RotomFormChange.choose_form(pkmn, scene)
    }
)

module RotomFormChange
    FORMS = {
        :NORMAL => 0,
        :HEAT   => 1,
        :WASH   => 2,
        :FROST  => 3,
        :FAN    => 4,
        :MOW    => 5
    }

    CHOICES = [
        _INTL("Bombilla"),
        _INTL("Microondas"),
        _INTL("Lavadora"),
        _INTL("Nevera"),
        _INTL("Ventilador"),
        _INTL("Corta césped"),
        _INTL("Cancelar")
    ]

    # === MÉTODO BASE (el corazón de todo) ===
    def self.apply_form(pkmn, new_form, scene = nil)
        if pkmn.form == new_form
            scene&.pbDisplay(_INTL("No tendría ningún efecto."))
            return false
        end

        pkmn.setForm(new_form) do
            scene&.pbRefresh
            scene&.pbDisplay(_INTL("¡{1} se transformó!", pkmn.name))
        end
        return true
    end

    # === USO DESDE SCRIPT (lo que tú quieres) ===
    def self.change_form(form_symbol, pkmn = nil)
        new_form = FORMS[form_symbol]
        return false if new_form.nil?

        pkmn ||= $player.party.find { |p| p.isSpecies?(:ROTOM) && !p.fainted? }
        return false if !pkmn

        apply_form(pkmn, new_form)
    end

    # === USO CON MENÚ (ROTOM CATALOG) ===
    def self.choose_form(pkmn, scene)
        if !pkmn.isSpecies?(:ROTOM)
            scene&.pbDisplay(_INTL("No se puede usar en este pokemon."))
            return false
        end
        if pkmn.fainted?
            scene&.pbDisplay(_INTL("Esto no puede ser usado en un Pokémon debilitado."))
            return false
        end

        new_form = scene.pbShowCommands(
        _INTL("¿Qué electrodoméstico quieres pedir?"),
        CHOICES,
        pkmn.form
        )
        return false if new_form < 0
        return false if new_form >= CHOICES.length - 1

        apply_form(pkmn, new_form, scene)
    end
end

#Intercambios en Mapa
def pbChoosePokemonForTradeAnyPokemon(variableNumber, nameVarNumber)
    pbChooseTradablePokemon(variableNumber, nameVarNumber, proc { |pkmn|
        next true
    })
end

def pbStartTradeMySelf(pokemonIndex)
    $stats.trade_count += 1
    myPokemon = $player.party[pokemonIndex]
    yourPokemon = myPokemon
    resetmoves = false
    pbFadeOutInWithMusic do
        evo = PokemonTrade_Scene.new
        evo.pbStartScreen(myPokemon, yourPokemon, $player.name, $player.name)
        evo.pbTrade
        evo.pbEndScreen
    end
    $player.party[pokemonIndex] = yourPokemon
end

#Correccion Evolucion Intercambio
GameData::Evolution.register({
    :id            => :TradeSpecies,
    :parameter     => :Species,
    :on_trade_proc => proc { |pkmn, parameter, other_pkmn|
        next other_pkmn.species == parameter && !other_pkmn.hasItem?(:EVERSTONE)
    }
})

GameData::Evolution.register({
    :id            => :ITEMLINKING,
    :parameter     => :Item,
    :use_item_proc => proc { |pkmn, parameter, item|
        next item == :LINKINGCORD && pkmn.item == parameter
    },
    :after_evolution_proc => proc { |pkmn, new_species, parameter, evo_species|
        next false if evo_species != new_species || !pkmn.hasItem?(parameter)
        pkmn.item = nil   # Item is now consumed
        next true
    }
})

GameData::Evolution.register({
    :id            => :SPECIESLINKING,
    :parameter     => :Species,
    :use_item_proc => proc { |pkmn, parameter, item|
        next item == :LINKINGCORD && $player.has_species?(parameter)
    }
})


#Evoluciones en Batalla
class Battle
    alias battle_pbGainExpOne pbGainExpOne
    def pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
        pkmn = pbParty(0)[idxParty]
        old_level = pkmn.level
        battle_pbGainExpOne(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages)
        new_level = pkmn.level

        return if new_level <= old_level

        new_species = pkmn.check_evolution_on_level_up
        return if !new_species

        pbFadeOutInWithMusic do
            evo = PokemonEvolutionScene.new
            evo.pbStartScreen(pkmn, new_species)
            evo.pbEvolution
            evo.pbEndScreen
        end

        battler = @battlers.find { |b| b && b.pokemon.equal?(pkmn) }
        updateBattler(battler, @scene)
    end
    
    def pbPlayerDisplayParty(idxBattler = 0)
        partyOrders = pbPartyOrder(idxBattler)
        idxStart, _idxEnd = pbTeamIndexRangeFromBattlerIndex(idxBattler)
        ret = []
        (partyOrders.length...pbParty(idxBattler).length).each do |i|
            partyOrders << i
        end
        eachInTeamFromBattlerIndex(idxBattler) { |pkmn, i| ret[partyOrders[i] - idxStart] = pkmn }
        return ret
    end
end

#Metodo para actualizar el sprite luego de evolucionar
def updateBattler(battler, scene)
    if battler
        idxBattler = battler.index
        battler.pbUpdate(true)
        scene.pbChangePokemon(battler, battler.pokemon)
        scene.pbRefreshOne(idxBattler)
    end
end

#Evoluciones por Piedra
ItemHandlers::BattleUseOnPokemon.addIf(:evolution_stones,
    proc { |item| GameData::Item.get(item).is_evolution_stone? },
    proc { |item, pokemon, battler, choices, scene|
    if pokemon.shadowPokemon?
        scene.pbDisplay(_INTL("No tendría ningún efecto."))
        next false
    end
    newspecies = pokemon.check_evolution_on_use_item(item)
    if newspecies
        pbFadeOutInWithMusic do
            evo = PokemonEvolutionScene.new
            evo.pbStartScreen(pokemon, newspecies)
            evo.pbEvolution(false)
            evo.pbEndScreen
            if scene.is_a?(PokemonPartyScreen)
                scene.pbRefreshAnnotations(proc { |p| !p.check_evolution_on_use_item(item).nil? })
                scene.pbRefresh
            end
        end
        updateBattler(battler, scene)
        next true
    end
    scene.pbDisplay(_INTL("No tendría ningún efecto."))
    next false
})

alias _oldpbBattleAnimation pbBattleAnimation
def pbBattleAnimation(*args, &block)
    _oldpbBattleAnimation(*args, &block)
    $PokemonBattle = nil
end

class Battle
  alias _store_battle initialize
  def initialize(*args)
    _store_battle(*args)
    $PokemonBattle = self
  end
end

class PokemonBag_Scene
    alias old_pbUpdateAnnotation pbUpdateAnnotation
    def pbUpdateAnnotation
        if $game_temp.in_battle
            itemwindow = @sprites["itemlist"]
            item       = itemwindow.item
            itm        = GameData::Item.get(item) if item

            orderBattle = $PokemonBattle.pbPartyOrder(0)
            new_party = []
            orderBattle.each do |i|
                pkmn = $player.party[i]
                new_party << pkmn if pkmn
            end
            
            if @bag.last_viewed_pocket == 1 && item #Items Pocket
                annotations = nil
                annotations = []
                color_annotations=[]
                if itm.is_evolution_stone?
                    for i in new_party
                        elig = i.check_evolution_on_use_item(itm)
                        annotations.push((elig) ? _INTL("APTO") : _INTL("NO APTO"))
                        color_annotations.push((elig) ? nil : true)
                    end
                else
                    for i in 0...Settings::MAX_PARTY_SIZE
                        @sprites["pokemon#{i}"].text = annotations[i] if  annotations
                        @sprites["pokemon#{i}"].text_color = color_annotations[i] if annotations
                    end
                end
                for i in 0...Settings::MAX_PARTY_SIZE
                    @sprites["pokemon#{i}"].text = annotations[i] if  annotations
                    @sprites["pokemon#{i}"].text_color = color_annotations[i] if annotations
                end
            else
                old_pbUpdateAnnotation
            end
        else
            old_pbUpdateAnnotation
        end
    end
end

#Evolucion por RareCandy
ItemHandlers::BattleUseOnPokemon.add(:RARECANDY, proc { |item, pokemon, battler, choices, scene|
    if pokemon.shadowPokemon?
        scene.pbDisplay(_INTL("No tendría ningún efecto."))
        next false
    end
    if pokemon.level >= GameData::GrowthRate.max_level
        new_species = pokemon.check_evolution_on_level_up
        if !Settings::RARE_CANDY_USABLE_AT_MAX_LEVEL || !new_species
            scene.pbDisplay(_INTL("No tendría ningún efecto."))
            next false
        end
        # Check for evolution
        pbFadeOutInWithMusic do
            evo = PokemonEvolutionScene.new
            evo.pbStartScreen(pokemon, new_species)
            evo.pbEvolution
            evo.pbEndScreen
            scene.pbRefresh if scene.is_a?(PokemonPartyScreen)
        end
        updateBattler(battler, scene)
        next true
    end
    # Level up
    pbSEPlay("Pokemon level up")
    pbChangeLevel(pokemon, pokemon.level + 1, scene)
    updateBattler(battler, scene)
    next true
})