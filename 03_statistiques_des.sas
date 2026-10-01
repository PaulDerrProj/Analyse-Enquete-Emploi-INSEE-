/*
   PROJET : Dynamiques d'insertion et exclusion (25 à 49 ans), EEC 2023

*/

/*
   En France, l'accès à l'emploi est un déterminant majeur de l'intégration 
   sociale et du niveau de vie. Toutefois, les inégalités d'accès au marché 
   du travail restent prononcées, particulièrement pour les personnes en 
   situation de handicap ou confrontées à des problèmes de santé durables. 
   Ainsi, à notre échelle, nous pouvons nous demander dans quelle mesure la 
   contrainte de santé pénalise l'insertion professionnelle et modifie 
   durablement la trajectoire des individus en âge de travailler.
   
   Cette première phase de l'étude vise à comprendre le rôle de la santé 
   comme facteur d'exclusion sur la tranche d'âge centrale des 25 à 49 ans, 
   en montrant comment ce facteur interagit avec la situation vis-à-vis de l'emploi.
*/



/*
   Dans un premier temps, nous importons notre base de données enrichie 
   et formatons notre variable explicative (le frein de santé) afin de 
   garantir un cadre d'analyse rigoureux et précis.
*/
FILENAME REFFILE "/home/u64307021/Projet SQL SAS/eec_enrichie_25_49.csv"; 

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.EEC REPLACE;
    DELIMITER=';'; 
    GETNAMES=YES;
RUN;

PROC FORMAT;
    VALUE FLAG_FMT 
        0 = '0. Valide' 
        1 = '1. Frein Santé ou Handicap';
RUN;

/*
   A. Analyse descriptive de la fracture professionnelle

   Afin d'explorer ces disparités, une analyse descriptive des données sera 
   faite pour montrer les tendances et les dynamiques observées. Nous utiliserons 
   la procédure d'enquête pondérée (SURVEYFREQ) pour rendre compte fidèlement de 
   la réalité macroéconomique française, en croisant le statut d'emploi et la santé.
*/
TITLE "Axe 1 : Répartition du statut d'emploi selon la santé (avec Intervalles de Confiance)";
PROC SURVEYFREQ DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    TABLES FLAG_HANDICAP_SANTE * STATUT_EMPLOI_GLOBAL / 
        ROW CL CHISQ; 
    FORMAT FLAG_HANDICAP_SANTE FLAG_FMT.;
RUN;

/*
   B. Modèle économétrique : Évaluation de la pénalité de santé

   Comment quantifier précisément l'impact de cette vulnérabilité ? Pour ce faire, 
   nous développerons un modèle économétrique (régression logistique) ayant 
   pour variable dépendante la probabilité d'obtenir un emploi stable. 
   
   Cette méthode prendra en compte le plan de sondage pour évaluer quantitativement 
   l'impact du handicap, toutes choses égales par ailleurs. Nous définirons 
   comme référence la population valide (sans problème de santé) afin de mesurer 
   l'ampleur de l'exclusion.
*/
DATA WORK.EEC;
    SET WORK.EEC;
    IF STATUT_EMPLOI_GLOBAL = 'Emploi stable (CDI/Titu)' THEN EMP_STABLE = 1; 
    ELSE EMP_STABLE = 0;
RUN;

TITLE "Axe 1 : Modèle Logistique, Pénalité du handicap sur l'accès à l'emploi stable";
PROC SURVEYLOGISTIC DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    CLASS FLAG_HANDICAP_SANTE (PARAM=REF REF='0'); 
    MODEL EMP_STABLE (EVENT='1') = FLAG_HANDICAP_SANTE / CLODDS;
RUN;

/*
   Comme nous l'avons noté à l'issue de notre première analyse, la contrainte 
   de santé constitue une barrière majeure à l'insertion. Cependant, la précarité 
   et l'éloignement durable de l'emploi sont rarement le fruit d'un seul facteur. 
   Ainsi, à notre échelle, nous pouvons nous demander dans quelle mesure d'autres 
   critères sociaux (comme le capital scolaire ou les inégalités de genre) 
   interagissent avec les dynamiques du marché du travail pour enfermer certains 
   profils dans l'exclusion ou le halo du chômage.
   
   Cette seconde phase de l'étude vise à comprendre ces principaux facteurs 
   socio-éducatifs en montrant comment ils déterminent la trajectoire des individus.
*/

/*
   Dans un premier temps, nous recodons notre variable dépendante (l'exclusion) 
   ainsi que nos variables explicatives afin de garantir un cadre d'analyse rigoureux.
*/
PROC FORMAT;
    VALUE FLAG_EXCL_FMT 
        0 = '0. Actif ou Inséré' 
        1 = '1. Exclusion durable ou Halo';
    VALUE SEXE_FMT 
        1 = 'Homme' 
        2 = 'Femme';
    VALUE DIP_FMT  
        1 ='1. Bac+5 et plus' 2 ='2. Bac+3 ou 4' 3 ='3. Bac+2' 
        4 ='4. Bac' 5 ='5. CAP ou BEP' 6 ='6. Brevet' 7 ='7. Sans diplôme';
RUN;

/*
   A. Analyse descriptive des disparités sociales

   Afin d'explorer ces inégalités, une analyse descriptive des données sera 
   faite pour montrer les tendances observées. Nous utiliserons la procédure 
   d'enquête pondérée (SURVEYFREQ) pour rendre compte fidèlement de la 
   réalité macroéconomique française, en croisant l'exclusion avec le genre 
   et le niveau de diplôme.
*/
TITLE "Axe 2 : Taux d'exclusion selon les inégalités de genre et le niveau de diplôme";
PROC SURVEYFREQ DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    TABLES (SEXE DIP7) * FLAG_EXCLUSION_HALO / ROW CHISQ;
    FORMAT FLAG_EXCLUSION_HALO FLAG_EXCL_FMT. SEXE SEXE_FMT. DIP7 DIP_FMT.;
RUN;

/*
   B. Modèle économétrique : Évaluation des facteurs aggravants

   Comment quantifier précisément l'impact de ces vulnérabilités ? Pour ce faire, 
   nous développerons un modèle économétrique (régression logistique) ayant 
   pour variable dépendante la probabilité d'être en situation d'exclusion. 
   
   Cette méthode prendra en compte simultanément le genre et le niveau de diplôme 
   pour évaluer quantitativement l'impact de chaque facteur, toutes choses égales 
   par ailleurs. Nous définirons comme référence la situation théoriquement la 
   plus protectrice sur le marché du travail (un Homme diplômé d'un Bac+5) 
   afin de mesurer l'ampleur des disparités.
*/
TITLE "Axe 2 : Régression Logistique, Modélisation des facteurs d'exclusion";
PROC SURVEYLOGISTIC DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    CLASS SEXE (PARAM=REF REF='1') 
          DIP7 (PARAM=REF REF='1'); 
    MODEL FLAG_EXCLUSION_HALO (EVENT='1') = SEXE DIP7 / CLODDS;
RUN;


/*
   Comme nous venons de le démontrer, le capital scolaire et le genre constituent 
   des moteurs puissants de précarité. Nous allons désormais analyser, dans ce 
   troisième temps, comment l'origine sociale ou les caractéristiques territoriales 
   viennent se superposer à ces observations. 
   
   La pauvreté et l'exclusion se concentrent-elles dans certains espaces géographiques ? 
   Le milieu social d'origine continue-t-il de dicter les trajectoires d'insertion 
   indépendamment des autres facteurs ? Cette dernière étape vise à mesurer le poids 
   du déterminisme social et spatial.
*/

/*
   Nous préparons d'abord le format de notre variable cible. Pour les variables 
   géographiques (STCOMM2020) et sociales (PCSP), nous utiliserons directement 
   les valeurs textuelles issues de l'enquête pour éviter les erreurs de typage.
*/
PROC FORMAT;
    VALUE FLAG_EXCL_FMT 
        0 = '0. Actif ou Inséré' 
        1 = '1. Exclusion durable ou Halo';
RUN;

/*
   A. Analyse descriptive des fractures sociales et territoriales

   Afin d'explorer ces nouvelles dimensions, nous croisons le taux d'exclusion 
   avec la catégorie socio-professionnelle (PCSP) et le type de commune (STCOMM2020), 
   toujours en appliquant les poids de l'enquête pour refléter la population française.
*/
TITLE "Axe 3 : Taux d'exclusion selon l'origine sociale et la zone géographique";
PROC SURVEYFREQ DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    TABLES (PCSP STCOMM2020) * FLAG_EXCLUSION_HALO / ROW CHISQ;
    FORMAT FLAG_EXCLUSION_HALO FLAG_EXCL_FMT.;
RUN;

/*
   B. Modèle économétrique : L'impact du déterminisme

   Pour isoler le poids spécifique du territoire et de l'origine sociale, 
   nous intégrons ces variables dans notre modèle. Cela nous permettra de 
   voir si résider dans un certain type de commune ou être issu d'un milieu 
   modeste ajoute une difficulté supplémentaire aux individus, toutes choses 
   égales par ailleurs.
*/
TITLE "Axe 3 : Régression Logistique, Le poids de l'origine et du territoire";
PROC SURVEYLOGISTIC DATA=WORK.EEC;
    WEIGHT EXTRIAN;
    /* Nous prenons en référence la catégorie des Cadres (III-A) et une strate communale pivot (B) */
    CLASS STCOMM2020 (PARAM=REF REF='B')
          PCSP (PARAM=REF REF='III-A'); 
    MODEL FLAG_EXCLUSION_HALO (EVENT='1') = STCOMM2020 PCSP / CLODDS;
RUN;


