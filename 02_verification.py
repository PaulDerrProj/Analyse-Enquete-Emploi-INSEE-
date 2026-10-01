import pandas as pd

print("Chargement de la base enrichie...")
df = pd.read_csv('eec_enrichie_25_49.csv', sep=';')

print("\n--- 1. DIMENSIONS ---")
print(f"Nombre d'observations : {len(df)}")
print(f"Nombre de variables : {len(df.columns)}")

print("\n--- 2. CONTRÔLE DU FEATURE ENGINEERING (STATUT_EMPLOI_GLOBAL) ---")
# On vérifie que notre CASE WHEN a bien fonctionné et corrigé les indépendants
repartition = df['STATUT_EMPLOI_GLOBAL'].value_counts(dropna=False)
print(repartition)

print("\n--- 3. CONTRÔLE DES FLAGS (HANDICAP ET EXCLUSION) ---")
print(f"Personnes avec un frein Santé/Handicap : {df['FLAG_HANDICAP_SANTE'].sum()} ({round(df['FLAG_HANDICAP_SANTE'].mean()*100, 1)}%)")
print(f"Personnes en Exclusion/Halo : {df['FLAG_EXCLUSION_HALO'].sum()} ({round(df['FLAG_EXCLUSION_HALO'].mean()*100, 1)}%)")

print("\n--- 4. CONTRÔLE DU FENÊTRAGE (TAUX D'EMPLOI MACRO) ---")
print("Aperçu du taux d'emploi stable calculé par territoire (moyenne) :")
print(df.groupby(['METRODOM', 'STCOMM2020'])['TAUX_EMPLOI_STABLE_TERRITOIRE'].mean().round(3).head())