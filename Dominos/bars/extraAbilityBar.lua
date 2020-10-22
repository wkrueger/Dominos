local ExtraAbilityContainer = _G.ExtraAbilityContainer
if not ExtraAbilityContainer then
    return
end

local _, Addon = ...

local ExtraAbilityBar = Addon:CreateClass('Frame', Addon.Frame)

function ExtraAbilityBar:New()
    local bar = ExtraAbilityBar.proto.New(self, 'extra')

    -- drop need for showstates for this case
    if bar:GetShowStates() == '[extrabar]show;hide' then
        bar:SetShowStates(nil)
    end

    return bar
end

ExtraAbilityBar:Extend(
    'OnAcquire', function(self)
        local container = ExtraAbilityContainer

        container:ClearAllPoints()
        container:SetPoint('CENTER', self)
        container:SetParent(self)

        self.container = container

        self:Layout()
        self:UpdateShowBlizzardTexture()
    end
)

function ExtraAbilityBar:ThemeBar(isTheme)
    if HasExtraActionBar() then
        local button = ExtraActionBarFrame and ExtraActionBarFrame.button
        if button then
            if isTheme then
                Addon:GetModule('ButtonThemer'):Register(button, 'Extra Button')
            else
                Addon:GetModule('ButtonThemer'):Unregister(button, 'Extra Button')
            end
        end
    end

    local zoneAbilities = C_ZoneAbility.GetActiveAbilities();
    if #zoneAbilities > 0 then
        local ButtonContainer = ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer
        for button in ButtonContainer:EnumerateActive() do
            if button then
                if isTheme then
                    Addon:GetModule('ButtonThemer'):Register(button, 'Zone Button')
                else
                    Addon:GetModule('ButtonThemer'):Unregister(button, 'Zone Button')
                end
            end
        end
    end
end

function ExtraAbilityBar:OnCreate()
    ExtraAbilityBar:ThemeBar(true)
end

function ExtraAbilityBar:GetDefaults()
    return {
        point = 'BOTTOM',
        x = 0,
        y = 160,
        showInPetBattleUI = true,
        showInOverrideUI = true
    }
end

function ExtraAbilityBar:Layout()
    local w, h = self.container:GetSize()

    w = math.floor(w or 0)
    h = math.floor(h or 0)

    if w == 0 and h == 0 then
        w = 256
        h = 120
    end

    local pW, pH = self:GetPadding()

    self:SetSize(w + pW, h + pH)
end

function ExtraAbilityBar:OnCreateMenu(menu)
    self:AddLayoutPanel(menu)

    menu:AddFadingPanel()
end

function ExtraAbilityBar:AddLayoutPanel(menu)
    local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local panel = menu:NewPanel(l.Layout)

    panel:NewCheckButton{
        name = l.ExtraBarShowBlizzardTexture,
        get = function()
            return panel.owner:ShowingBlizzardTexture()
        end,
        set = function(_, enable)
            panel.owner:ShowBlizzardTexture(enable)
        end
    }

    panel.scaleSlider = panel:NewScaleSlider()
    panel.paddingSlider = panel:NewPaddingSlider()
end

function ExtraAbilityBar:ShowBlizzardTexture(show)
    self.sets.hideBlizzardTeture = not show

    self:UpdateShowBlizzardTexture()
end

function ExtraAbilityBar:ShowingBlizzardTexture()
    return not self.sets.hideBlizzardTeture
end

function ExtraAbilityBar:UpdateShowBlizzardTexture()
    if self:ShowingBlizzardTexture() then
        ExtraActionBarFrame.button.style:Show()
        ZoneAbilityFrame.Style:Show()
        ExtraAbilityBar:ThemeBar(false)
    else
        ExtraActionBarFrame.button.style:Hide()
        ZoneAbilityFrame.Style:Hide()
        ExtraAbilityBar:ThemeBar(true)
    end
end

local ExtraAbilityBarModule = Addon:NewModule('ExtraAbilityBar', 'AceEvent-3.0')

function ExtraAbilityBarModule:Load()
    if not self.initialized then
        self.initialized = true

        -- disable mouse interactions on the extra action bar
        -- as it can sometimes block the UI from being interactive
        if ExtraActionBarFrame:IsMouseEnabled() then
            ExtraActionBarFrame:EnableMouse(false)
        end

        -- setup the container watcher
        ExtraAbilityContainer.ignoreFramePositionManager = true

        ExtraAbilityContainer:HookScript(
            'OnSizeChanged', function()
                self:OnExtraAbilityContainerSizeChanged()
            end
        )

        Addon.BindableButton:AddQuickBindingSupport(ExtraActionButton1)
    end

    self.frame = ExtraAbilityBar:New()
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
end

function ExtraAbilityBarModule:Unload()
    self.frame:Free()
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function ExtraAbilityBarModule:OnExtraAbilityContainerSizeChanged()
    if InCombatLockdown() then
        self.dirty = true
        return
    end

    if self.frame then
        self.frame:Layout()
    end
end

function ExtraAbilityBarModule:PLAYER_REGEN_ENABLED()
    if self.dirty then
        self.dirty = nil
        return
    end

    if self.frame then
        self.frame:Layout()
    end
end
