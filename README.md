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
