import { basename, join } from "node:path"
import { tmpdir } from "node:os"
import { access, writeFile, rm } from "node:fs/promises"

const CUSTOM_SOUND_FILE = join(
  import.meta.dirname,
  "session-notify.wav",
)

function hashString(value) {
  let hash = 2166136261

  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i)
    hash = Math.imul(hash, 16777619)
  }

  return hash >>> 0
}

function tonesForDirectory(directory, kind) {
  const seed = hashString(directory)
  const roots = [220, 246.94, 261.63, 293.66, 329.63, 392, 440, 493.88]
  const brightPatterns = [
    [0, 4],
    [0, 7],
    [0, 4, 7],
    [0, 7, 12],
    [0, 2, 7],
  ]
  const darkPatterns = [
    [0, -3],
    [0, -5],
    [0, -3, -7],
    [0, -5, -12],
    [0, -2, -7],
  ]

  const root = roots[seed % roots.length]
  const patternPool = kind === "error" ? darkPatterns : brightPatterns
  const pattern = patternPool[(seed >>> 3) % patternPool.length]
  const baseDurationMs = kind === "error"
    ? 135 + ((seed >>> 7) % 45)
    : 95 + ((seed >>> 7) % 55)
  const strideMs = kind === "error" ? 34 : 22

  return pattern.map((semitones, index) => ({
    frequency: Number((root * (2 ** (semitones / 12))).toFixed(2)),
    durationMs: baseDurationMs + index * strideMs,
  }))
}

function createPcm16Wav(tones) {
  const sampleRate = 44100
  const gapMs = 40
  const amplitude = 0.22
  const samples = []

  for (const [index, tone] of tones.entries()) {
    const toneSamples = Math.max(1, Math.floor(sampleRate * tone.durationMs / 1000))

    for (let i = 0; i < toneSamples; i += 1) {
      const t = i / sampleRate
      const envelope = Math.sin(Math.PI * i / toneSamples)
      samples.push(Math.sin(2 * Math.PI * tone.frequency * t) * amplitude * envelope)
    }

    if (index < tones.length - 1) {
      const gapSamples = Math.floor(sampleRate * gapMs / 1000)
      for (let i = 0; i < gapSamples; i += 1) {
        samples.push(0)
      }
    }
  }

  const dataSize = samples.length * 2
  const buffer = Buffer.alloc(44 + dataSize)

  buffer.write("RIFF", 0)
  buffer.writeUInt32LE(36 + dataSize, 4)
  buffer.write("WAVE", 8)
  buffer.write("fmt ", 12)
  buffer.writeUInt32LE(16, 16)
  buffer.writeUInt16LE(1, 20)
  buffer.writeUInt16LE(1, 22)
  buffer.writeUInt32LE(sampleRate, 24)
  buffer.writeUInt32LE(sampleRate * 2, 28)
  buffer.writeUInt16LE(2, 32)
  buffer.writeUInt16LE(16, 34)
  buffer.write("data", 36)
  buffer.writeUInt32LE(dataSize, 40)

  for (let i = 0; i < samples.length; i += 1) {
    const value = Math.max(-1, Math.min(1, samples[i]))
    buffer.writeInt16LE(Math.round(value * 32767), 44 + i * 2)
  }

  return buffer
}

async function playChime($, directory, kind) {
  const tones = tonesForDirectory(directory, kind)

  const soundFile = join(tmpdir(), `opencode-${kind}.wav`)

  try {
    await access(CUSTOM_SOUND_FILE)
    try {
      await $`pw-play ${CUSTOM_SOUND_FILE}`
      return
    } catch {
      // Fall through to the generated tone if the custom file cannot play.
    }
  } catch {
    // Fall back to the generated tone when no custom file exists.
  }

  try {
    await writeFile(soundFile, createPcm16Wav(tones))
    await $`pw-play ${soundFile}`
    return
  } catch {
    try {
      await $`bash -lc ${"printf '\\a'"}`
    } catch {
      // Ignore notification sound failures.
    }
  } finally {
    await rm(soundFile, { force: true }).catch(() => {})
  }
}

async function sendDesktopNotification($, title, body, urgency) {
  try {
    await $`notify-send -u ${urgency} ${title} ${body}`
  } catch {
    // Ignore notification failures.
  }
}

export const SessionNotifyPlugin = async ({ $, directory }) => {
  let lastNotificationAt = 0

  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle" && event.type !== "session.error") {
        return
      }

      const now = Date.now()
      if (now - lastNotificationAt < 1500) {
        return
      }
      lastNotificationAt = now

      const projectName = basename(directory)

      if (event.type === "session.error") {
        await sendDesktopNotification($, "OpenCode error", `${projectName}: session failed`, "critical")
        await playChime($, directory, "error")
        return
      }

      await sendDesktopNotification($, "OpenCode finished", `${projectName}: response is ready`, "normal")
      await playChime($, directory, "done")
    },
  }
}
