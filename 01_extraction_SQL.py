"""
Projet d'Analyse : Dynamiques d'insertion, exclusion et impact du handicap sur le marché du travail (25-49 ans)
Source de données : Enquête Emploi en Continu (EEC) 2023 - INSEE
Auteur : Paul DEROO - Analyste Statistique
Description : Pipeline d'extraction SQL (DuckDB) intégrant le filtrage de la population cible, 
              le Feature Engineering des statuts d'emploi (correction MNAR sur les indépendants), 
              et la création d'indicateurs contextuels pondérés.
"""

import duckdb
import time

def run_sql_extraction():
    print("[INFO] Démarrage du pipeline d'extraction SQL...")
    start_time = time.time()

    # Initialisation du moteur OLAP embarqué
    con = duckdb.connect(database=":memory:")

    query = """
    COPY (
        -- =====================================================================
        -- ÉTAPE 1 : EXTRACTION ET TYPAGE (Common Table Expression 1)
        -- Objectif : Isoler la population cible (25-49 ans) et exclure les 
        -- observations sans poids de redressement valide.
        -- =====================================================================
        WITH BaseData AS (
            SELECT 
                IDENT, NOI, CAST(EXTRIAN AS DOUBLE) AS EXTRIAN,
                CAST(SEXE AS VARCHAR) AS SEXE, CAST(NATIO AS VARCHAR) AS NATIO,
                CAST(PCSP AS VARCHAR) AS PCSP, CAST(TYPLOG5 AS VARCHAR) AS TYPLOG5,
                CAST(ENFRED AS VARCHAR) AS ENFRED, CAST(STCOMM2020 AS VARCHAR) AS STCOMM2020,
                CAST(METRODOM AS VARCHAR) AS METRODOM, CAST(DIP7 AS VARCHAR) AS DIP7,
                CAST(ACTEU AS VARCHAR) AS ACTEU, CAST(HALOR AS VARCHAR) AS HALOR,
                CAST(SOUSEMPLR AS VARCHAR) AS SOUSEMPLR, CAST(SALTYP AS VARCHAR) AS SALTYP,
                CAST(ANCCHOM AS VARCHAR) AS ANCCHOM, CAST(ESEG_2 AS VARCHAR) AS ESEG_2,
                CAST(RAISTP AS VARCHAR) AS RAISTP, CAST(RAISDISPPLC AS VARCHAR) AS RAISDISPPLC,
                CAST(RAISNRECNE AS VARCHAR) AS RAISNRECNE, CAST(RAISNDISPONE AS VARCHAR) AS RAISNDISPONE,
                CAST(RAISNSOUNE AS VARCHAR) AS RAISNSOUNE
            FROM read_csv('FD_csv_EEC23.csv', delim=';', header=true)
            WHERE AGE6 = '25' 
              AND EXTRIAN IS NOT NULL 
              AND EXTRIAN > 0
        ),
        
        -- =====================================================================
        -- ÉTAPE 2 : FEATURE ENGINEERING ET RECODAGE MÉTIER (CTE 2)
        -- Objectif : Construire les variables cibles pour la modélisation.
        -- =====================================================================
        FeatureEngineering AS (
            SELECT *,
                -- Résolution de la non-réponse structurelle (Missing Not At Random) sur SALTYP
                -- Les actifs occupés sans contrat sont reclassés en 'Indépendants'.
                CASE 
                    WHEN ACTEU = '1' AND SALTYP IS NULL THEN 'Indépendant'
                    WHEN ACTEU = '1' AND SALTYP IN ('1', '2') THEN 'Emploi stable (CDI/Titu)'
                    WHEN ACTEU = '1' AND SALTYP NOT IN ('1', '2') THEN 'Emploi précaire'
                    WHEN ACTEU = '2' THEN 'Chômage'
                    ELSE 'Inactivité'
                END AS STATUT_EMPLOI_GLOBAL,

                -- Création du flag Exclusion / Éloignement durable de l'emploi
                CASE 
                    WHEN HALOR = '1' OR ANCCHOM IN ('5', '6', '7', '8') THEN 1 
                    ELSE 0 
                END AS FLAG_EXCLUSION_HALO,

                -- Création du flag Santé/Handicap (approche large incluant les freins déclaratifs)
                CASE 
                    WHEN ESEG_2 = '92' 
                      OR RAISTP = '4' OR RAISDISPPLC = '2' 
                      OR RAISNRECNE = '4' OR RAISNDISPONE = '2' OR RAISNSOUNE = '3' 
                    THEN 1 ELSE 0 
                END AS FLAG_HANDICAP_SANTE
            FROM BaseData
        ),

        -- =====================================================================
        -- ÉTAPE 3 : ENRICHISSEMENT CONTEXTUEL MACRO-ÉCONOMIQUE (CTE 3)
        -- Objectif : Intégrer des effets de structure territoriaux via des 
        -- fonctions de fenêtrage pondérées par les poids de l'enquête (EXTRIAN).
        -- =====================================================================
        EnrichissementContextuel AS (
            SELECT *,
                -- Calcul du taux d'emploi stable par zone géographique (Métropole/DOM x Type d'unité urbaine)
                SUM(CASE WHEN STATUT_EMPLOI_GLOBAL = 'Emploi stable (CDI/Titu)' THEN EXTRIAN ELSE 0 END) 
                    OVER (PARTITION BY METRODOM, STCOMM2020) 
                / SUM(EXTRIAN) OVER (PARTITION BY METRODOM, STCOMM2020) AS TAUX_EMPLOI_STABLE_TERRITOIRE
            FROM FeatureEngineering
        )

        -- Export final de la table de modélisation
        SELECT * FROM EnrichissementContextuel

    ) TO 'eec_enrichie_25_49.csv' (HEADER, DELIMITER ';');
    """

    con.execute(query)
    elapsed_time = round(time.time() - start_time, 2)
    print(f"[SUCCÈS] Fichier 'eec_enrichie_25_49.csv' généré en {elapsed_time} secondes.")

if __name__ == "__main__":
    run_sql_extraction()