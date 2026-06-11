function defaultSettings(pluginApi) {
    if (!pluginApi || !pluginApi.manifest || !pluginApi.manifest.metadata || !pluginApi.manifest.metadata.defaultSettings)
        return {}
    return pluginApi.manifest.metadata.defaultSettings
}

function setting(pluginApi, key, fallback) {
    var settings = pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings : {}
    var defaults = defaultSettings(pluginApi)
    var value = settings[key]
    if (value === undefined || value === null || value === "")
        value = defaults[key]
    if (value === undefined || value === null || value === "")
        value = fallback
    return value
}

function command(pluginApi) {
    return [
        setting(pluginApi, "codexbarPath", "codexbar"),
        "usage",
        "--provider", setting(pluginApi, "provider", "codex"),
        "--source", setting(pluginApi, "codexbarSource", "auto"),
        "--format", "json"
    ]
}

function refreshIntervalMs(pluginApi) {
    var seconds = Number(setting(pluginApi, "refreshIntervalSec", 60))
    if (isNaN(seconds))
        seconds = 60
    return Math.max(5, seconds) * 1000
}

function valueOrFallback(value, fallback) {
    return value === undefined || value === null ? fallback : value
}

function emptyUsage() {
    return {
        error: "",
        sourceName: "",
        providerName: "",
        versionText: "",
        updatedAt: "",
        accountEmail: "",
        loginMethod: "",
        providerId: "",
        primaryPercent: -1,
        secondaryPercent: -1,
        primaryWindowMinutes: 0,
        secondaryWindowMinutes: 0,
        primaryResetAt: "",
        secondaryResetAt: "",
        primaryReset: "",
        secondaryReset: "",
        creditsRemaining: 0,
        creditEventsCount: 0
    }
}

function parseUsage(output) {
    var result = emptyUsage()
    try {
        var trimmed = String(output || "").trim()
        if (trimmed === "") {
            result.error = "empty codexbar output"
            return result
        }

        var data = JSON.parse(trimmed)
        var item = Array.isArray(data) && data.length > 0 ? data[0] : data
        if (item.error) {
            result.error = item.error.message || "codexbar error"
            return result
        }

        var usage = item.usage || {}
        var identity = usage.identity || item.identity || {}
        var credits = item.credits || {}

        result.sourceName = item.source || ""
        result.providerName = item.provider || identity.providerID || ""
        result.versionText = item.version || ""
        result.updatedAt = usage.updatedAt || credits.updatedAt || ""
        result.accountEmail = usage.accountEmail || identity.accountEmail || ""
        result.loginMethod = usage.loginMethod || identity.loginMethod || ""
        result.providerId = identity.providerID || item.provider || ""
        result.creditsRemaining = Number(valueOrFallback(credits.remaining, 0))
        result.creditEventsCount = Array.isArray(credits.events) ? credits.events.length : 0

        // AIDEV-NOTE: Normalize windows by windowMinutes so the widget works across
        // providers with different primary/secondary/tertiary field conventions.
        // Codex: primary=5h, secondary=weekly.
        // Zai:   primary=weekly, secondary=monthly, tertiary=5h.
        // Strategy: collect all non-empty windows, find 5h (300 min) → primaryPercent
        // and weekly (10080 min) → secondaryPercent by minutes value.
        // Falls back to positional (primary→primary, secondary→secondary) if no match.
        var candidateWindows = []
        var rawFields = ["primary", "secondary", "tertiary"]
        for (var i = 0; i < rawFields.length; i++) {
            var w = usage[rawFields[i]]
            if (w && (w.usedPercent !== undefined || w.windowMinutes !== undefined))
                candidateWindows.push(w)
        }

        var shortWindow = null  // 5h / 300 min
        var longWindow = null   // weekly / 10080 min
        for (var j = 0; j < candidateWindows.length; j++) {
            var mins = Number(candidateWindows[j].windowMinutes)
            if (mins === 300) shortWindow = candidateWindows[j]
            else if (mins === 10080) longWindow = candidateWindows[j]
        }
        // Positional fallback when no window matches by minutes
        if (!shortWindow && !longWindow) {
            shortWindow = usage.primary || {}
            longWindow = usage.secondary || {}
        } else if (!shortWindow) {
            shortWindow = usage.primary || usage.secondary || {}
        } else if (!longWindow) {
            longWindow = usage.secondary || usage.primary || {}
        }

        result.primaryPercent = Number(valueOrFallback(shortWindow.usedPercent, -1))
        result.secondaryPercent = Number(valueOrFallback(longWindow.usedPercent, -1))
        result.primaryWindowMinutes = Number(valueOrFallback(shortWindow.windowMinutes, 0))
        result.secondaryWindowMinutes = Number(valueOrFallback(longWindow.windowMinutes, 0))
        result.primaryResetAt = shortWindow.resetsAt || ""
        result.secondaryResetAt = longWindow.resetsAt || ""
        result.primaryReset = shortWindow.resetDescription || ""
        result.secondaryReset = longWindow.resetDescription || ""
        return result
    } catch (e) {
        result.error = "parse failed: " + e
        return result
    }
}

function clampPercent(value) {
    if (value < 0 || isNaN(value))
        return 0
    return Math.min(100, Math.max(0, value))
}

function percentLabel(value) {
    if (value < 0 || isNaN(value))
        return "—"
    return Math.round(value) + "%"
}

function windowLabel(minutes) {
    if (minutes === 300)
        return "5 hour window"
    if (minutes === 10080)
        return "Weekly window"
    if (minutes >= 1440)
        return Math.round(minutes / 1440) + " day window"
    if (minutes >= 60)
        return Math.round(minutes / 60) + " hour window"
    return minutes > 0 ? minutes + " minute window" : "Window"
}
