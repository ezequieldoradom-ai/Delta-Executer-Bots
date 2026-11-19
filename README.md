# Delta-Executer-Bots
Delta Bot support

## Remotion (videos)

```bash
npm install
npm run remotion:studio   # abre Remotion Studio
npm run remotion:render   # renderiza out/delta-intro.mp4
```

Las composiciones están en `remotion/`.

### Skills de Remotion para Claude Code

Las skills oficiales de Remotion están en `.claude/skills/` (instaladas con
`npx skills add remotion-dev/skills --agent claude-code`). Para actualizarlas:
`npx skills update`.

### Voz en off con ElevenLabs

```bash
npm run voz -- guiones/mi-video.txt mi-video
```

Genera `public/mi-video.mp3` con la voz "Dan" (eleven_v4) y
`public/mi-video.words.json` con el tiempo de cada palabra para los
subtítulos. Fuera de la nube, define `ELEVENLABS_API_KEY` antes de ejecutarlo.
