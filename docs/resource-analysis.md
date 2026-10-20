# Analyse des ressources — Projet foto

> Objectif : dimensionner correctement le nouveau VPS et comprendre ce que Coolify va nous montrer.

---

## 📊 Chiffres en local (repo de dev)

| Élément | Taille |
|---------|--------|
| `storage/` (images + DB dev/test) | **24 Mo** |
| `node_modules/` | 55 Mo *(non shipé en prod)* |
| Code source (`app/`, `lib/`, `config/`, `db/`) | ~600 Ko |
| Gems (26 dépendances principales) | ~150–200 Mo d'image Docker |
| Image Docker estimée (prod) | **300–400 Mo** |

**Profil technique** :
- Rails 8.0.2 + SQLite
- Solid Queue / Solid Cable / Solid Cache (3 DB SQLite supplémentaires)
- Active Storage en mode **local disk** (pas de S3)
- Puma + Thruster (reverse proxy intégré)
- ActiveAdmin, TailwindCSS, image variants (ImageMagick)
- Aucun service externe requis (pas de Redis, pas de Postgres)

---

## 🖥️ Commandes à exécuter sur le VPS de production

Copie-colle ce bloc sur le VPS (`54.36.100.76`) pour obtenir le **vrai** état des lieux :

```bash
ssh ubuntu@54.36.100.76 << 'EOF'
echo "═══════════════════════════════════════════════════════════════"
echo "  ANALYSE RESSOURCES FOTO (Production)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "📦 1. IMAGE DOCKER"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep foto || echo "   (image non listée explicitement)"
echo ""

echo "🐳 2. CONTENEURS EN COURS"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -i foto || docker ps
echo ""

echo "📊 3. CONSOMMATION TEMPS RÉEL (RAM / CPU)"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo ""

echo "💾 4. VOLUME 'foto_storage' (DB + images)"
docker run --rm -v foto_storage:/data alpine du -sh /data
echo "   → Détail :"
docker run --rm -v foto_storage:/data alpine sh -c '
  echo "   Total fichiers : $(find /data -type f | wc -l)"
  echo "   Bases SQLite  :"
  ls -lh /data/*.sqlite3 2>/dev/null || echo "   (pas de .sqlite3 à la racine)"
  echo "   Top 5 dossiers les plus gros :"
  du -sh /data/*/ 2>/dev/null | sort -rh | head -5 || echo "   (structure plate)"
'
echo ""

echo "🌍 5. Espace DISQUE TOTAL DU SERVEUR"
df -h /
echo ""

echo "🔍 6. MÉMOIRE ET SWAP"
free -h
echo ""

echo "⚙️  7. CPU (coeurs + load)"
nproc && uptime
echo ""
EOF
```

> **Note** : Si tu n'as pas encore les accès SSH configurés, connecte-toi manuellement et copie chaque commande.

---

## 💡 Ce que ces chiffres vont nous dire

| Métrique | Pourquoi c'est important |
|----------|--------------------------|
| **Taille de `foto_storage`** | La taille du backup à transférer. Si > 1 Go, il faudra peut-être envisager un volume externe ou S3 à long terme. |
| **RAM consommée par le container** | Pour dimensionner le nouveau VPS. Rails + SQLite + image processing = typiquement 200–600 Mo. |
| **Taille image Docker** | Espace disque consommé par les couches Docker sur le serveur. Coolify garde un historique d'images. |
| **Load CPU / Coeurs** | Pour savoir si un VPS 1 vCPU suffit (oui, très probablement) ou s'il faut 2 vCPU. |
| **Disk total utilisé** | Pour choisir la taille du disque du nouveau VPS. |

---

## 🎯 Recommandation de dimensionnement (nouveau VPS)

Vu le profil de `foto`, voici ce que je recommande chez OVH :

| Ressource | Recommandation | Justification |
|-----------|---------------|---------------|
| **vCPU** | 1–2 | Une app Rails solo avec SQLite est très légère en CPU. |
| **RAM** | 2–4 Go | Rails ~400 Mo + Coolify ~500 Mo + marge = 2 Go minimum, 4 Go confort. |
| **Disk** | 40–80 Go SSD | L'image Docker + les données + les backups Coolify. Si tu prends des photos en rafale, prévois large. |
| **Bande passante** | 100 Mbps+ | Pour servir les images rapidement. |

**Modèle OVH typique** : VPS Starter ou Value (1–2 vCPU, 2–4 Go RAM, 40 Go SSD) — environ **3–8 €/mois**.

> 🔮 **À moyen terme** : si les photos dépassent 10–20 Go, il faudra passer à un VPS avec plus de disque, ou migrer Active Storage vers un Object Storage (S3, OVH Object Storage, Scaleway...). Coolify gère très bien les volumes, mais le disque du VPS reste fini.

---

## 🏗️ Coolify vs Kamal : la visibilité

### Avec Kamal (aujourd'hui)

Tu dois tout faire à la main :

```bash
# Stats mémoire/CPU
docker stats

# Espace disque
df -h

# Taille du volume
docker run --rm -v foto_storage:/data alpine du -sh /data

# Logs
docker logs -f foto

# Aucun historique, aucune alerte, aucun graphique.
```

### Avec Coolify (après migration)

Dans l'interface web, par projet :

| Métrique | Disponible dans Coolify |
|----------|------------------------|
| CPU usage (temps réel + historique) | ✅ |
| RAM usage (temps réel + historique) | ✅ |
| Disk usage (container + volumes) | ✅ |
| Network I/O | ✅ |
| Logs (centralisés, filtrables) | ✅ |
| Redéploiements / historique des builds | ✅ |
| Alertes (CPU/RAM élevée) | ✅ (selon version) |
| SSL / certificats status | ✅ |
| Variables d'environnement (UI sécurisée) | ✅ |

**En résumé** : avec Coolify, tu ouvres l'UI et tu vois immédiatement :
- "Mon app foto prend 380 Mo de RAM"
- "Elle tourne à 3% de CPU"
- "Mon volume de stockage fait 1.2 Go"
- "Le dernier déploiement a eu lieu il y a 2 heures"

---

## 📋 Prochaine étape

1. **Exécute le bloc de commandes ci-dessus sur le VPS actuel**
2. **Mets les résultats ici** (ou garde-les pour toi) pour valider le dimensionnement du nouveau VPS
3. On continue avec le backup (Phase 0) et tu souscris le nouveau VPS en parallèle
