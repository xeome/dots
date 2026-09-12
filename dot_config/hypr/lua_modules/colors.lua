-- =============================================================================
-- SHARED COLORS
-- =============================================================================
-- The Caffeine colour scheme, same values as quickshell's Theme.qml and
-- ~/.config/ghostty/themes/caffeine. Device-agnostic.
--
-- settings.lua paints the active border as a secondary -> primary gradient
-- (espresso to cream) and the inactive one flat `surface`.
-- =============================================================================

local colors = {
  background = "rgb(111111)",
  foreground = "rgb(EEEEEE)",
  primary = "rgb(FFE0C2)",
  secondary = "rgb(393028)",
  tertiary = "rgb(FFD9A0)",
  surface = "rgb(191919)",
  surface_bright = "rgb(222222)",
  surface_brightest = "rgb(2A2A2A)",
  error = "rgb(E54D2E)",
  success = "rgb(B5C98F)",
  muted = "rgb(484848)",

  -- Caffeine's terminal.ansi, verbatim. color0 is the scheme's `secondary`
  -- rather than a true black, same as the terminals.
  color0 = "rgb(393028)",
  color1 = "rgb(E06C75)",
  color2 = "rgb(B5C98F)",
  color3 = "rgb(FFD9A0)",
  color4 = "rgb(8FB0D9)",
  color5 = "rgb(CBA6C9)",
  color6 = "rgb(88C0C8)",
  color7 = "rgb(D8CBB8)",
  color8 = "rgb(5C5046)",
  color9 = "rgb(FF8A93)",
  color10 = "rgb(C9DBA8)",
  color11 = "rgb(FFE6C4)",
  color12 = "rgb(A9C3E0)",
  color13 = "rgb(DDC0DB)",
  color14 = "rgb(A4D4DA)",
  color15 = "rgb(F0E6D6)",
}

return colors
