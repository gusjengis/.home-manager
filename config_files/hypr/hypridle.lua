return {
    listeners = {
        {
            timeout = 180,
            on_timeout = "hyprlog --idle",
            on_resume = "hyprlog --resume",
        },
    },
}
