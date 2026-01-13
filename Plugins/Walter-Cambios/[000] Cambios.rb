#Victini
Settings::DEXES_WITH_OFFSETS  = [4]
#Formas en la Pokedex
Settings::DEX_SHOWS_ALL_FORMS = false

#Imagenes
module GameData
    class Species
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

    #Revisa si se ha visualizado la forma shiny
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

#Adicion de la descripcion de habilidades
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

#Copiar los atributos de Quilava a Cyndaquil
MultipleForms.copy(:QUILAVA, :CYNDAQUIL, :DEWOTT, :DARTRIX, :PETILIL, :RUFFLET, :GOOMY, :BERGMITE)