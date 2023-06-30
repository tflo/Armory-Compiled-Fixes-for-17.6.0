
--[[
    Armory Addon for World of Warcraft(tm).
    Revision: 206 2022-11-06T14:41:54Z
    URL: http://www.wow-neighbours.com

    License:
        This program is free software; you can redistribute it and/or
        modify it under the terms of the GNU General Public License
        as published by the Free Software Foundation; either version 2
        of the License, or (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program(see GPL.txt); if not, write to the Free Software
        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

    Note:
        This AddOn's source code is specifically designed to work with
        World of Warcraft's interpreted AddOn system.
        You have an implicit licence to use this AddOn with these facilities
        since that is it's designated purpose as per:
        http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
--]]

local Armory, _ = Armory, nil;

local table, next = table, next;
local error = error;

local category;
local function Register(panel, name)
    if ( not category ) then
        category = Settings.RegisterCanvasLayoutCategory(panel, name);
        category.ID = name;
        Settings.RegisterAddOnCategory(category);
        return;
    end
    Settings.RegisterCanvasLayoutSubcategory(category, panel, name);
end

local panelControls = {};

ArmoryOptionsPanelTemplateMixin = {};

function ArmoryOptionsPanelTemplateMixin:OnLoad()
    Register(self, self:GetID());
end

function ArmoryOptionsPanelTemplateMixin:GetID()
    error("Implement GetID");
end

function ArmoryOptionsPanelTemplateMixin:RegisterControl(control)
    table.insert(self:GetControls(), control);
end

function ArmoryOptionsPanelTemplateMixin:GetControls()
    if ( not panelControls[self:GetName()] ) then
        panelControls[self:GetName()] = {};
    end
    return panelControls[self:GetName()];
end

function ArmoryOptionsPanelTemplateMixin:ForAllControls(action)
    for _, controls in next, panelControls do
        for _, control in next, controls do
            action(control);
        end
    end
end

function ArmoryOptionsPanelTemplateMixin:ForEachControl(action)
    for _, control in next, self:GetControls() do
        action(control);
    end
end
