
AddCSLuaFile()

sound.Add( 
{
 name = "Weapon_357Golden.Single",
 channel = CHAN_STATIC,
 volume = 0.93,
 level = SNDLVL_GUNFIRE,
 pitch = { 88, 93 },
 sound = "weapons/357_golden/357_fire.wav"
} )

if SERVER then
  resource.AddFile("materials/vgui/mttt/icon_goldenrevolver.vmt")
end

SWEP.Base                  = "weapon_tttbase"

SWEP.PrintName          = "Golden Revolver"
SWEP.Slot               = 6
SWEP.ViewModelFOV       = 64
SWEP.ViewModelFlip      = false
SWEP.HoldType              = "revolver"

SWEP.EquipMenuData = {
  type = "Weapon",
  desc = "Kills a traitor in one shot, kills user if innocent"
};

SWEP.Icon               = "vgui/mttt/icon_goldenrevolver"

SWEP.AllowDrop  = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.AutoSpawnable = false

-- if I run out of ammo types, this weapon is one I could move to a custom ammo
-- handling strategy, because you never need to pick up ammo for it
SWEP.Primary.Ammo          = "AR2AltFire"
SWEP.Primary.Recoil        = 6
SWEP.Primary.Damage        = 5
SWEP.Primary.Delay         = 0.8
SWEP.Primary.Cone          = 0.01
SWEP.Primary.ClipSize      = 2
SWEP.Primary.Automatic     = false
SWEP.Primary.DefaultClip   = 2
SWEP.Primary.ClipMax       = 2
SWEP.Primary.Sound         = "Weapon_357Golden.Single"
SWEP.Secondary.Sound       = Sound("Default.Zoom")

SWEP.Kind                  = WEAPON_EQUIP
SWEP.CanBuy                = {ROLE_DETECTIVE} -- only traitors can buy
SWEP.LimitedStock          = true -- only buyable once

SWEP.Tracer                = "Tracer"

SWEP.UseHands              = true
SWEP.ViewModel             = Model("models/weapons/v_358.mdl")
SWEP.WorldModel            = Model("models/weapons/w_358.mdl")

SWEP.IronSightsPos         = Vector( 5, -15, -2 )
SWEP.IronSightsAng         = Vector( 2.6, 1.37, 3.5 )

function SWEP:SetZoom(state)
  if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() then
     if state then
        self:GetOwner():SetFOV(20, 0.3)
     else
        self:GetOwner():SetFOV(0, 0.2)
     end
  end
end

function TestPlayer(att, tr, dmg)
  local ent = tr.Entity
  if not IsValid(ent) then return end

  if SERVER then
    if ent:IsPlayer() and ent:IsActiveTraitor() then
      ent:TakeDamage(500,dmg:GetAttacker(), dmg:GetInflictor())
    else
      att:TakeDamage(500,dmg:GetAttacker(),dmg:GetInflictor())
    end
  end 
end

function SWEP:ShootGoldenBullet()
  local cone = self.Primary.Cone
  local bullet = {}
  bullet.Num       = 1
  bullet.Src       = self:GetOwner():GetShootPos()
  bullet.Dir       = self:GetOwner():GetAimVector()
  bullet.Spread    = Vector( cone, cone, 0 )
  bullet.Tracer    = 1
  bullet.Force     = 2
  bullet.Damage    = self.Primary.Damage
  bullet.TracerName = self.Tracer
  bullet.Callback = TestPlayer

  self:GetOwner():FireBullets( bullet )
end

function SWEP:PrimaryAttack()
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self:SetNextSecondaryFire( CurTime() + 0.1 )

   if not self:CanPrimaryAttack() then return end

   self:EmitSound( self.Primary.Sound )

   self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )

   self:ShootGoldenBullet()

   self:TakePrimaryAmmo( 1 )

   if IsValid(self:GetOwner()) then
      self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

      self:GetOwner():ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
   end

   if ( (game.SinglePlayer() && SERVER) || CLIENT ) then
      self:SetNWFloat( "LastShootTime", CurTime() )
   end
end

function SWEP:SecondaryAttack()
   if not self.IronSightsPos then return end
   if self:GetNextSecondaryFire() > CurTime() then return end

   local bIronsights = not self:GetIronsights()

   self:SetIronsights( bIronsights )

   self:SetZoom(bIronsights)
   if (CLIENT) then
      self:EmitSound(self.Secondary.Sound)
   end

   self:SetNextSecondaryFire( CurTime() + 0.3)
end

function SWEP:PreDrop()
   self:SetZoom(false)
   self:SetIronsights(false)
   return self.BaseClass.PreDrop(self)
end

function SWEP:Holster()
  self:SetIronsights(false)
  self:SetZoom(false)
  return true
end

if CLIENT then
  local scope = surface.GetTextureID("sprites/scope")
  function SWEP:DrawHUD()
     if self:GetIronsights() then
        surface.SetDrawColor( 0, 0, 0, 255 )
        
        local scrW = ScrW()
        local scrH = ScrH()

        local x = scrW / 2.0
        local y = scrH / 2.0
        local scope_size = scrH

        -- crosshair
        local gap = 80
        local length = scope_size
        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )

        gap = 0
        length = 50
        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )


        -- cover edges
        local sh = scope_size / 2
        local w = (x - sh) + 2
        surface.DrawRect(0, 0, w, scope_size)
        surface.DrawRect(x + sh - 2, 0, w, scope_size)
        
        -- cover gaps on top and bottom of screen
        surface.DrawLine( 0, 0, scrW, 0 )
        surface.DrawLine( 0, scrH - 1, scrW, scrH - 1 )

        surface.SetDrawColor(255, 0, 0, 255)
        surface.DrawLine(x, y, x + 1, y + 1)

        -- scope
        surface.SetTexture(scope)
        surface.SetDrawColor(255, 255, 255, 255)

        surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)
     else
        return self.BaseClass.DrawHUD(self)
     end
  end

  function SWEP:AdjustMouseSensitivity()
     return (self:GetIronsights() and 0.2) or nil
  end
end