import { basename, join } from "node:path"
import { tmpdir } from "node:os"
import { writeFile, rm } from "node:fs/promises"

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

async function playChime($, kind) {
  const tones = kind === "error"
    ? [
        { frequency: 520, durationMs: 130 },
        { frequency: 390, durationMs: 190 },
      ]
    : [
        { frequency: 659, durationMs: 110 },
        { frequency: 880, durationMs: 170 },
      ]

  const soundFile = join(tmpdir(), `opencode-${kind}.wav`)

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
        await playChime($, "error")
        return
      }

      await sendDesktopNotification($, "OpenCode finished", `${projectName}: response is ready`, "normal")
      await playChime($, "done")
    },
  }
}
