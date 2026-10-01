# Analyse des Facteurs d'Exclusion - Enquête Emploi (INSEE)

## Contexte
Analyse des dynamiques d'insertion et d'exclusion sur le marché du travail français pour la population des 25-49 ans, à partir des données de l'Enquête Emploi en Continu (EEC 2023). L'objectif est de quantifier l'impact de la contrainte de santé/handicap, du capital scolaire et du territoire sur l'accès à l'emploi stable.

## Stack Technique
* **Data Engineering :** SQL (DuckDB), Python (Pandas)
* **Économétrie & Statistiques :** SAS Studio (Procédures d'enquête pondérées)

## Méthodologie
1. **Extraction & Feature Engineering (SQL/DuckDB) :** Filtrage de la population cible, traitement de la non-réponse structurelle (MNAR) sur les statuts d'emploi, et création de flags d'exclusion et de handicap basés sur les freins déclaratifs.
2. **Enrichissement Contextuel :** Calcul du taux d'emploi stable par zone géographique (Métropole/DOM et type d'unité urbaine) via des fonctions de fenêtrage pondérées[cite: 6].
3. **Audit de Données (Python) :** Contrôle de cohérence, validation des dimensions et vérification des distributions du feature engineering sur la base enrichie.
4. **Modélisation Économétrique (SAS) :** 
   * Analyse descriptive pondérée pour refléter la population française (PROC SURVEYFREQ)[
   * Séries de régressions logistiques (PROC SURVEYLOGISTIC) pour mesurer la pénalité isolée du handicap sur l'emploi, puis l'impact aggravant des inégalités de genre, de diplôme, d'origine sociale (PCSP) et de territoire.

## Fichiers du projet
* `01_extraction_SQL.py` : Pipeline DuckDB de préparation et d'enrichissement macro-économique.
* `02_verification.py` : Script d'audit et de validation des données sous Pandas.
* `03_modelisation_econometrique.sas` : Script d'analyse descriptive et modèles logistiques.
