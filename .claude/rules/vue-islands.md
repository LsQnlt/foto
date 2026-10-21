---
description: Montage des composants Vue depuis ERB
paths:
  - "app/views/**/*.erb"
---

# Îlots Vue

Utiliser `vue_component(name, **props)` pour monter un composant depuis Rails. Ne pas écrire de `data-wrapper`, de payload de montage `.to_json` ou de balise de composant directe dans l'ERB.

Passer les valeurs réelles, sans sérialisation manuelle, et les noms de props attendus côté Vue en `camelCase`. Une ligne si l'appel est court ; pour plusieurs props, isoler les délimiteurs ERB, indenter l'appel et placer une prop par ligne, sans virgule finale.

```erb
<%=
  vue_component(
    "PatientsIndex",
    exportUrl: patients_exports_path,
    tagsList: @tags_list
  )
%>
```
