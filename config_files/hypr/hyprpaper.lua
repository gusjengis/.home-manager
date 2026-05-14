wallpaper = os.getenv("HOME") .. "/.home-manager/wallpapers/old_static_images/wp_00.png"

return {
    preload = wallpaper,
    wallpaper = ", " .. wallpaper,
}
