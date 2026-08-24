# 1. Bekijk de Perspective-view

We beginnen rustig in VS Code. Als je nu in VS Code of Explorer `projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json` opent, dan zie je dat de gehele pagina in JSON-formaat is opgeslagen.

Open deze bestanden in Explorer:

```text
projects/demo-project/project.json
projects/demo-project/com.inductiveautomation.perspective/views/demo/view.json
```

In `view.json` zie je onder andere:

```text
LabelMachine  →  Machine: Demo
LabelStatus   →  Status: Gereed
```

Open als afsluiting de lokale Perspective-view:

```text
http://localhost:8088/data/perspective/client/demo-project/
```

Hiermee is het uitgangspunt duidelijk: wat je in de browser ziet, staat als leesbare JSON in Git.
