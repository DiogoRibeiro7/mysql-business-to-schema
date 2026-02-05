# Generators

## Clinic generator

Generate deterministic datasets for the clinic example:

PowerShell (Windows):
```powershell
python generators/clinic/generate.py --config generators/clinic/config.yaml
```

Bash (macOS/Linux/Git Bash):
```bash
python generators/clinic/generate.py --config generators/clinic/config.yaml
```

All generators now accept `--config` with a default of `config.yaml`, so this also works:

```bash
python generators/clinic/generate.py
```

Load the generated CSVs into MySQL:
- See `example_01_clinic/schema/10_load_generated.sql`
- Or run `scripts/load_generated_data.ps1` on Windows
