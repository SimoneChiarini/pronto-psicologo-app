import '../theme/app_theme.dart';

const List<TaxMacro> kTaxonomy = [
  // ── Disturbi del Neurosviluppo ────────────────────────────────────────────
  TaxMacro(code: 'neurosviluppo', label: 'Disturbi del Neurosviluppo', subs: [
    TaxSub(label: 'Disabilità Intellettiva', leaves: [
      TaxLeaf(code: 'di_disab',   label: 'Disabilità intellettiva'),
      TaxLeaf(code: 'di_ritardo', label: 'Ritardo globale dello sviluppo'),
      TaxLeaf(code: 'di_ns',      label: 'Disabilità intellettiva non specificata'),
    ]),
    TaxSub(label: 'Disturbi della Comunicazione', leaves: [
      TaxLeaf(code: 'dc_linguaggio', label: 'Disturbo del linguaggio'),
      TaxLeaf(code: 'dc_fonetico',   label: 'Disturbo fonetico-fonologico'),
      TaxLeaf(code: 'dc_balbuzie',   label: 'Balbuzie (disturbo della fluenza)'),
      TaxLeaf(code: 'dc_pragmatica', label: 'Disturbo della comunicazione sociale (pragmatica)'),
      TaxLeaf(code: 'dc_ns',         label: 'Disturbo della comunicazione non specificato'),
    ]),
    TaxSub(label: "Disturbo dello Spettro dell'Autismo", leaves: [
      TaxLeaf(code: 'dsa_autismo', label: "Disturbo dello spettro dell'autismo"),
    ]),
    TaxSub(label: 'Disturbo da Deficit di Attenzione/Iperattività (ADHD)', leaves: [
      TaxLeaf(code: 'adhd_disattento',  label: 'Presentazione prevalentemente disattenta'),
      TaxLeaf(code: 'adhd_iperattivo',  label: 'Presentazione prevalentemente iperattiva/impulsiva'),
      TaxLeaf(code: 'adhd_combinato',   label: 'Presentazione combinata'),
    ]),
    TaxSub(label: "Disturbo Specifico dell'Apprendimento", leaves: [
      TaxLeaf(code: 'dsp_dislessia',    label: 'Con compromissione della lettura (dislessia)'),
      TaxLeaf(code: 'dsp_scrittura',    label: "Con compromissione dell'espressione scritta"),
      TaxLeaf(code: 'dsp_discalculia',  label: 'Con compromissione del calcolo (discalculia)'),
    ]),
    TaxSub(label: 'Disturbi del Movimento', leaves: [
      TaxLeaf(code: 'dm_coordinazione',   label: 'Disturbo dello sviluppo della coordinazione'),
      TaxLeaf(code: 'dm_stereotipie',     label: 'Disturbo da movimenti stereotipati'),
      TaxLeaf(code: 'dm_tic',             label: 'Disturbi da tic'),
      TaxLeaf(code: 'dm_tourette',        label: 'Sindrome di Tourette'),
      TaxLeaf(code: 'dm_tic_persistente', label: 'Disturbo persistente da tic motori o vocali'),
      TaxLeaf(code: 'dm_tic_provvisorio', label: 'Disturbo provvisorio da tic'),
    ]),
  ]),

  // ── Schizofrenia e Disturbi Psicotici ────────────────────────────────────
  TaxMacro(code: 'schizo', label: 'Disturbi dello Spettro della Schizofrenia e Altri Disturbi Psicotici', leaves: [
    TaxLeaf(code: 'schizo_delirante',    label: 'Disturbo delirante'),
    TaxLeaf(code: 'schizo_breve',        label: 'Disturbo psicotico breve'),
    TaxLeaf(code: 'schizo_forma',        label: 'Disturbo schizofreniforme'),
    TaxLeaf(code: 'schizo_schizofrenia', label: 'Schizofrenia'),
    TaxLeaf(code: 'schizo_schizoaff',    label: 'Disturbo schizoaffettivo'),
    TaxLeaf(code: 'schizo_indotto',      label: 'Disturbo psicotico indotto da sostanze/farmaci'),
    TaxLeaf(code: 'schizo_medico',       label: 'Disturbo psicotico dovuto ad altra condizione medica'),
    TaxLeaf(code: 'schizo_catatonia',    label: 'Catatonia'),
  ]),

  // ── Disturbo Bipolare ─────────────────────────────────────────────────────
  TaxMacro(code: 'bipolare', label: 'Disturbo Bipolare e Disturbi Correlati', leaves: [
    TaxLeaf(code: 'bip_i',           label: 'Disturbo bipolare I'),
    TaxLeaf(code: 'bip_ii',          label: 'Disturbo bipolare II'),
    TaxLeaf(code: 'bip_ciclotimico', label: 'Disturbo ciclotimico'),
    TaxLeaf(code: 'bip_indotto',     label: 'Disturbo bipolare indotto da sostanze/farmaci'),
    TaxLeaf(code: 'bip_medico',      label: 'Disturbo bipolare dovuto ad altra condizione medica'),
  ]),

  // ── Disturbi Depressivi ───────────────────────────────────────────────────
  TaxMacro(code: 'depressivi', label: 'Disturbi Depressivi', leaves: [
    TaxLeaf(code: 'dep_maggiore',   label: 'Disturbo depressivo maggiore'),
    TaxLeaf(code: 'dep_distimia',   label: 'Disturbo depressivo persistente (distimia)'),
    TaxLeaf(code: 'dep_dirompente', label: "Disturbo da disregolazione dell'umore dirompente"),
    TaxLeaf(code: 'dep_disforico',  label: 'Disturbo disforico premestruale'),
    TaxLeaf(code: 'dep_indotto',    label: 'Disturbo depressivo indotto da sostanze/farmaci'),
    TaxLeaf(code: 'dep_medico',     label: 'Disturbo depressivo dovuto ad altra condizione medica'),
  ]),

  // ── Disturbi d'Ansia ──────────────────────────────────────────────────────
  TaxMacro(code: 'ansia', label: "Disturbi d'Ansia", leaves: [
    TaxLeaf(code: 'anx_separazione',  label: "Disturbo d'ansia da separazione"),
    TaxLeaf(code: 'anx_mutismo',      label: 'Mutismo selettivo'),
    TaxLeaf(code: 'anx_fobia_spec',   label: 'Fobia specifica'),
    TaxLeaf(code: 'anx_fobia_soc',    label: "Disturbo d'ansia sociale (fobia sociale)"),
    TaxLeaf(code: 'anx_panico',       label: 'Disturbo di panico'),
    TaxLeaf(code: 'anx_agorafobia',   label: 'Agorafobia'),
    TaxLeaf(code: 'anx_generalizzato',label: "Disturbo d'ansia generalizzato"),
    TaxLeaf(code: 'anx_indotto',      label: 'Disturbo d\'ansia indotto da sostanze/farmaci'),
    TaxLeaf(code: 'anx_medico',       label: 'Disturbo d\'ansia dovuto ad altra condizione medica'),
  ]),

  // ── DOC ───────────────────────────────────────────────────────────────────
  TaxMacro(code: 'doc', label: 'Disturbo Ossessivo-Compulsivo e Disturbi Correlati', leaves: [
    TaxLeaf(code: 'ocd_doc',            label: 'Disturbo ossessivo-compulsivo (DOC)'),
    TaxLeaf(code: 'ocd_dismorfismo',    label: 'Disturbo da dismorfismo corporeo'),
    TaxLeaf(code: 'ocd_accumulo',       label: 'Disturbo da accumulo'),
    TaxLeaf(code: 'ocd_tricotillomania',label: 'Tricotillomania'),
    TaxLeaf(code: 'ocd_escoriazione',   label: 'Disturbo da escoriazione (skin picking)'),
    TaxLeaf(code: 'ocd_indotto',        label: 'DOC indotto da sostanze/farmaci'),
    TaxLeaf(code: 'ocd_medico',         label: 'DOC dovuto ad altra condizione medica'),
  ]),

  // ── Trauma e Stress ───────────────────────────────────────────────────────
  TaxMacro(code: 'trauma', label: 'Disturbi Correlati a Trauma e Stress', leaves: [
    TaxLeaf(code: 'tra_attaccamento', label: "Disturbo reattivo dell'attaccamento"),
    TaxLeaf(code: 'tra_disinibito',   label: 'Disturbo da impegno sociale disinibito'),
    TaxLeaf(code: 'tra_ptsd',         label: 'Disturbo da stress post-traumatico (PTSD)'),
    TaxLeaf(code: 'tra_acuto',        label: 'Disturbo da stress acuto'),
    TaxLeaf(code: 'tra_adattamento',  label: "Disturbi dell'adattamento"),
  ]),

  // ── Disturbi Dissociativi ─────────────────────────────────────────────────
  TaxMacro(code: 'dissociativo', label: 'Disturbi Dissociativi', leaves: [
    TaxLeaf(code: 'dis_identita',            label: "Disturbo dissociativo dell'identità"),
    TaxLeaf(code: 'dis_amnesia',             label: 'Amnesia dissociativa'),
    TaxLeaf(code: 'dis_depersonalizzazione', label: 'Disturbo di depersonalizzazione/derealizzazione'),
  ]),

  // ── Disturbi Somatici ─────────────────────────────────────────────────────
  TaxMacro(code: 'somatico', label: 'Disturbi da Sintomi Somatici e Disturbi Correlati', leaves: [
    TaxLeaf(code: 'som_somatico',       label: 'Disturbo da sintomi somatici'),
    TaxLeaf(code: 'som_ansia_malattia', label: "Disturbo d'ansia di malattia"),
    TaxLeaf(code: 'som_conversione',    label: 'Disturbo di conversione'),
    TaxLeaf(code: 'som_fittizio',       label: 'Disturbo fittizio'),
  ]),

  // ── Alimentazione ─────────────────────────────────────────────────────────
  TaxMacro(code: 'alimentazione', label: "Disturbi della Nutrizione e dell'Alimentazione", leaves: [
    TaxLeaf(code: 'ali_anoressia',  label: 'Anoressia nervosa'),
    TaxLeaf(code: 'ali_bulimia',    label: 'Bulimia nervosa'),
    TaxLeaf(code: 'ali_binge',      label: 'Disturbo da alimentazione incontrollata (binge eating)'),
    TaxLeaf(code: 'ali_arfid',      label: 'ARFID (disturbo evitante/restrittivo)'),
    TaxLeaf(code: 'ali_pica',       label: 'Pica'),
    TaxLeaf(code: 'ali_ruminazione',label: 'Disturbo da ruminazione'),
  ]),

  // ── Evacuazione ───────────────────────────────────────────────────────────
  TaxMacro(code: 'evacuazione', label: "Disturbi dell'Evacuazione", leaves: [
    TaxLeaf(code: 'eva_enuresi',   label: 'Enuresi'),
    TaxLeaf(code: 'eva_encopresi', label: 'Encopresi'),
  ]),

  // ── Sonno ─────────────────────────────────────────────────────────────────
  TaxMacro(code: 'sonno', label: 'Disturbi del Sonno-Veglia', leaves: [
    TaxLeaf(code: 'son_insonnia',     label: 'Disturbo da insonnia'),
    TaxLeaf(code: 'son_ipersonnia',   label: 'Disturbo da ipersonnolenza'),
    TaxLeaf(code: 'son_narcolessia',  label: 'Narcolessia'),
    TaxLeaf(code: 'son_circadiano',   label: 'Disturbi del ritmo circadiano sonno-veglia'),
    TaxLeaf(code: 'son_respirazione', label: 'Disturbi del sonno correlati alla respirazione'),
    TaxLeaf(code: 'son_nrem',         label: 'Disturbi dell\'arousal del sonno NREM'),
    TaxLeaf(code: 'son_incubi',       label: 'Disturbo da incubi'),
    TaxLeaf(code: 'son_rem',          label: 'Disturbo comportamentale del sonno REM'),
    TaxLeaf(code: 'son_gambe',        label: 'Sindrome delle gambe senza riposo'),
  ]),

  // ── Disfunzioni Sessuali ──────────────────────────────────────────────────
  TaxMacro(code: 'sessuale', label: 'Disfunzioni Sessuali', leaves: [
    TaxLeaf(code: 'ses_femm_interesse', label: "Disturbo dell'interesse/eccitazione sessuale femminile"),
    TaxLeaf(code: 'ses_femm_orgasmo',   label: "Disturbo dell'orgasmo femminile"),
    TaxLeaf(code: 'ses_dolore',         label: 'Disturbo del dolore genito-pelvico e della penetrazione'),
    TaxLeaf(code: 'ses_erettile',       label: 'Disturbo erettile'),
    TaxLeaf(code: 'ses_eiac_ritardata', label: 'Eiaculazione ritardata'),
    TaxLeaf(code: 'ses_eiac_precoce',   label: 'Eiaculazione precoce'),
    TaxLeaf(code: 'ses_desiderio_masc', label: 'Disturbo del desiderio sessuale ipoattivo maschile'),
  ]),

  // ── Disforia di Genere ────────────────────────────────────────────────────
  TaxMacro(code: 'genere', label: 'Disforia di Genere', leaves: [
    TaxLeaf(code: 'gen_bambini',     label: 'Disforia di genere nei bambini'),
    TaxLeaf(code: 'gen_adolescenti', label: 'Disforia di genere negli adolescenti e adulti'),
  ]),

  // ── Comportamento Dirompente ──────────────────────────────────────────────
  TaxMacro(code: 'dirompente', label: 'Disturbi del Comportamento Dirompente, del Controllo degli Impulsi e della Condotta', leaves: [
    TaxLeaf(code: 'dir_oppositivo',  label: 'Disturbo oppositivo provocatorio'),
    TaxLeaf(code: 'dir_esplosivo',   label: 'Disturbo esplosivo intermittente'),
    TaxLeaf(code: 'dir_condotta',    label: 'Disturbo della condotta'),
    TaxLeaf(code: 'dir_antisociale', label: 'Disturbo antisociale di personalità'),
    TaxLeaf(code: 'dir_piromania',   label: 'Piromania'),
    TaxLeaf(code: 'dir_cleptomania', label: 'Cleptomania'),
  ]),

  // ── Sostanze e Addiction ──────────────────────────────────────────────────
  TaxMacro(code: 'sostanze', label: 'Disturbi Correlati a Sostanze e Disturbi da Addiction', subs: [
    TaxSub(label: 'Disturbi da Uso di Sostanze', leaves: [
      TaxLeaf(code: 'uso_alcol',        label: 'Alcol'),
      TaxLeaf(code: 'uso_caffeina',     label: 'Caffeina'),
      TaxLeaf(code: 'uso_cannabis',     label: 'Cannabis'),
      TaxLeaf(code: 'uso_allucinogeni', label: 'Allucinogeni'),
      TaxLeaf(code: 'uso_inalanti',     label: 'Inalanti'),
      TaxLeaf(code: 'uso_oppioidi',     label: 'Oppioidi'),
      TaxLeaf(code: 'uso_sedativi',     label: 'Sedativi, ipnotici e ansiolitici'),
      TaxLeaf(code: 'uso_stimolanti',   label: 'Stimolanti'),
      TaxLeaf(code: 'uso_tabacco',      label: 'Tabacco'),
      TaxLeaf(code: 'uso_altre',        label: 'Altre sostanze'),
    ]),
    TaxSub(label: 'Disturbi Comportamentali da Addiction', leaves: [
      TaxLeaf(code: 'add_gioco', label: "Disturbo da gioco d'azzardo"),
    ]),
  ]),

  // ── Disturbi Neurocognitivi ───────────────────────────────────────────────
  TaxMacro(code: 'neurocognitivo', label: 'Disturbi Neurocognitivi', subs: [
    TaxSub(label: 'Disturbo Neurocognitivo Maggiore e Lieve', leaves: [
      TaxLeaf(code: 'nc_alzheimer',  label: 'Malattia di Alzheimer'),
      TaxLeaf(code: 'nc_frontotemp', label: 'Demenza frontotemporale'),
      TaxLeaf(code: 'nc_lewy',       label: 'Demenza a corpi di Lewy'),
      TaxLeaf(code: 'nc_vascolare',  label: 'Demenza vascolare'),
      TaxLeaf(code: 'nc_trauma',     label: 'Trauma cranico'),
      TaxLeaf(code: 'nc_parkinson',  label: 'Morbo di Parkinson'),
      TaxLeaf(code: 'nc_hiv',        label: 'HIV'),
      TaxLeaf(code: 'nc_huntington', label: 'Malattia di Huntington'),
      TaxLeaf(code: 'nc_prioni',     label: 'Malattia da prioni'),
      TaxLeaf(code: 'nc_altre',      label: 'Altre condizioni mediche'),
    ]),
  ]),

  // ── Disturbi di Personalità ───────────────────────────────────────────────
  TaxMacro(code: 'personalita', label: 'Disturbi di Personalità', subs: [
    TaxSub(label: 'Cluster A', leaves: [
      TaxLeaf(code: 'pa_paranoide',    label: 'Disturbo paranoide di personalità'),
      TaxLeaf(code: 'pa_schizoide',    label: 'Disturbo schizoide di personalità'),
      TaxLeaf(code: 'pa_schizotipico', label: 'Disturbo schizotipico di personalità'),
    ]),
    TaxSub(label: 'Cluster B', leaves: [
      TaxLeaf(code: 'pb_antisociale',  label: 'Disturbo antisociale di personalità'),
      TaxLeaf(code: 'pb_borderline',   label: 'Disturbo borderline di personalità'),
      TaxLeaf(code: 'pb_istrionico',   label: 'Disturbo istrionico di personalità'),
      TaxLeaf(code: 'pb_narcisistico', label: 'Disturbo narcisistico di personalità'),
    ]),
    TaxSub(label: 'Cluster C', leaves: [
      TaxLeaf(code: 'pc_evitante',   label: 'Disturbo evitante di personalità'),
      TaxLeaf(code: 'pc_dipendente', label: 'Disturbo dipendente di personalità'),
      TaxLeaf(code: 'pc_ocd',        label: 'Disturbo ossessivo-compulsivo di personalità'),
    ]),
  ]),

  // ── Disturbi Parafilici ───────────────────────────────────────────────────
  TaxMacro(code: 'parafilico', label: 'Disturbi Parafilici', leaves: [
    TaxLeaf(code: 'par_voyeuristico',    label: 'Disturbo voyeuristico'),
    TaxLeaf(code: 'par_esibizionistico', label: 'Disturbo esibizionistico'),
    TaxLeaf(code: 'par_frotteuristico',  label: 'Disturbo frotteuristico'),
    TaxLeaf(code: 'par_masochismo',      label: 'Disturbo da masochismo sessuale'),
    TaxLeaf(code: 'par_sadismo',         label: 'Disturbo da sadismo sessuale'),
    TaxLeaf(code: 'par_pedofilico',      label: 'Disturbo pedofilico'),
    TaxLeaf(code: 'par_feticistico',     label: 'Disturbo feticistico'),
    TaxLeaf(code: 'par_travestitismo',   label: 'Disturbo da travestitismo'),
  ]),

  // ── Altre Condizioni ──────────────────────────────────────────────────────
  TaxMacro(code: 'altre', label: 'Altre Condizioni Clinicamente Rilevanti', leaves: [
    TaxLeaf(code: 'alt_relazionale', label: 'Problemi relazionali'),
    TaxLeaf(code: 'alt_familiare',   label: 'Problemi familiari'),
    TaxLeaf(code: 'alt_scolastico',  label: 'Problemi scolastici'),
    TaxLeaf(code: 'alt_lavorativo',  label: 'Problemi lavorativi'),
    TaxLeaf(code: 'alt_abitativo',   label: 'Problemi abitativi'),
    TaxLeaf(code: 'alt_economico',   label: 'Problemi economici'),
    TaxLeaf(code: 'alt_attenzione',  label: 'Condizioni oggetto di attenzione clinica'),
  ]),

  // ── Fascia d'età ──────────────────────────────────────────────────────────
  TaxMacro(code: 'fascia_eta', label: "Fascia d'età", leaves: [
    TaxLeaf(code: 'eta_infanzia',    label: 'Infanzia'),
    TaxLeaf(code: 'eta_adolescenza', label: 'Adolescenza'),
    TaxLeaf(code: 'eta_adulta',      label: 'Età adulta'),
    TaxLeaf(code: 'eta_terza',       label: 'Terza età'),
  ]),

  // ── Percorsi Relazionali e Familiari ──────────────────────────────────────
  TaxMacro(code: 'relazionale', label: 'Percorsi Relazionali e Familiari', leaves: [
    TaxLeaf(code: 'rel_genitorialita', label: 'Genitorialità'),
    TaxLeaf(code: 'rel_coppia',        label: 'Coppia'),
    TaxLeaf(code: 'rel_famiglia',      label: 'Famiglia'),
    TaxLeaf(code: 'rel_gruppi',        label: 'Gruppi'),
  ]),

  // ── Crescita Personale ────────────────────────────────────────────────────
  TaxMacro(code: 'crescita', label: 'Crescita Personale', leaves: [
    TaxLeaf(code: 'cre_autostima',   label: 'Autostima e fiducia in sé'),
    TaxLeaf(code: 'cre_emotiva',     label: 'Consapevolezza emotiva'),
    TaxLeaf(code: 'cre_emozioni',    label: 'Gestione delle emozioni'),
    TaxLeaf(code: 'cre_stress',      label: 'Gestione dello stress'),
    TaxLeaf(code: 'cre_assertivita', label: 'Assertività e comunicazione efficace'),
    TaxLeaf(code: 'cre_personale',   label: 'Crescita personale'),
  ]),
];
