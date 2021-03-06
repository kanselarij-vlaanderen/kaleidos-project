(define-resource case ()
  :class (s-prefix "dossier:Dossier")
  :properties `((:created       :datetime ,(s-prefix "dct:created"))
                (:short-title   :string   ,(s-prefix "dct:alternative"))
                (:number        :number   ,(s-prefix "adms:identifier")) ;; NOTE: only for legacy, do we want this ??
                (:is-archived   :boolean  ,(s-prefix "ext:isGearchiveerd"))
                (:title         :string   ,(s-prefix "dct:title"))
                (:confidential  :boolean  ,(s-prefix "ext:vertrouwelijk")))
  :has-one `((publication-flow  :via      ,(s-prefix "dossier:behandelt")
                                :inverse t
                                :as "publication-flow"))
  :has-many `((subcase          :via      ,(s-prefix "dossier:doorloopt")
                                :as "subcases")
              (piece            :via      ,(s-prefix "dossier:Dossier.bestaatUit")
                                :as "pieces"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/dossier/")
  :features '(include-uri)
  :on-path "cases")

(define-resource case-type ()
  :class (s-prefix "ext:DossierTypeCode")
  :properties `((:label       :string ,(s-prefix "skos:prefLabel"))
                (:scope-note  :string ,(s-prefix "skos:scopeNote"))
                (:alt-label   :string ,(s-prefix "skos:altLabel"))
                (:deprecated  :boolean ,(s-prefix "owl:deprecated")))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/dossier-type/")
  :features '(include-uri)
  :on-path "case-types")

(define-resource subcase ()
  :class (s-prefix "dossier:Procedurestap")
  :properties `((:short-title         :string ,(s-prefix "dct:alternative"))
                (:title               :string ,(s-prefix "dct:title"))
                (:is-archived         :boolean   ,(s-prefix "ext:isProcedurestapGearchiveerd"))
                (:confidential        :boolean   ,(s-prefix "ext:vertrouwelijk"))
                (:subcase-name        :string ,(s-prefix "ext:procedurestapNaam"))
                (:created             :datetime ,(s-prefix "dct:created"))
                (:modified            :datetime ,(s-prefix "ext:modified"))
                (:show-as-remark      :boolean ,(s-prefix "ext:wordtGetoondAlsMededeling")))
  :has-one `((case                    :via ,(s-prefix "dossier:doorloopt")
                                      :inverse t
                                      :as "case")
             (meeting                 :via ,(s-prefix "ext:isAangevraagdVoor")
                                      :as "requested-for-meeting")
             (access-level            :via ,(s-prefix "ext:toegangsniveauVoorProcedurestap")
                                      :as "access-level")
             (subcase-type            :via ,(s-prefix "dct:type")
                                      :as "type")
             (mandatee                :via ,(s-prefix "ext:indiener")
                                      :as "requested-by")
             (user                    :via ,(s-prefix "ext:modifiedBy")
                                      :as "modified-by")
            ;; Publication hasOne relationships
             (publication-flow        :via ,(s-prefix "ext:doorloopt") ;; Should be dossier:doorloopt, mu-cl-resources polymorphism limited
                                      :inverse t
                                      :as "publication-flow"))
  :has-many `((mandatee               :via ,(s-prefix "ext:heeftBevoegde") ;; NOTE: used mandataris instead of agent
                                      :as "mandatees")
              (piece                  :via ,(s-prefix "ext:bevatReedsBezorgdeDocumentversie") ;; NOTE: instead of dct:hasPart (mu-cl-resources relation type checking workaround)
                                      :as "linked-pieces")
              (ise-code               :via ,(s-prefix "ext:heeftInhoudelijkeStructuurElementen")
                                      :as "ise-codes")
              (agenda-activity        :via ,(s-prefix "besluitvorming:vindtPlaatsTijdens") ;; TODO: but others as wel. mu-cl-resources polymorphism limitation. Rename to agenderingVindtPlaatsTijdens ?
                                      :inverse t
                                      :as "agenda-activities")
              (submission-activity    :via ,(s-prefix "ext:indieningVindtPlaatsTijdens") ;; subpredicate for besluitvorming:vindtPlaatsTijdens
                                      :inverse t
                                      :as "submission-activities")
              (agenda-item-treatment  :via ,(s-prefix "ext:beslissingVindtPlaatsTijdens") ;; mu-cl-resources polymorphism limitation. vindtPlaatsTijdens can only be used once !
                                      :inverse t
                                      :as "treatments")
              (activity               :via ,(s-prefix "dossier:vindtPlaatsTijdens") ;; Dit is de juiste relatie !! ipv besluitvorming
                                      :inverse t
                                      :as "publication-activities")) ;; this can be translationActivity, signatureActivity, publish )
  :resource-base (s-url "http://themis.vlaanderen.be/id/procedurestap/")
  :features '(include-uri)
  :on-path "subcases")

(define-resource subcase-type () ;; NOTE: Should be subclass of besluitvorming:Status (mu-cl-resources reasoner workaround)
  :class (s-prefix "ext:ProcedurestapType") ;; NOTE: as well as skos:Concept
  :properties `((:label           :string ,(s-prefix "skos:prefLabel"))
                (:scope-note      :string ,(s-prefix "skos:scopeNote"))
                (:alt-label       :string ,(s-prefix "skos:altLabel")))
  :has-many `((subcase            :via ,(s-prefix "dct:type")
                                  :inverse t
                                  :as "subcases"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/procedurestap-type/")
  :features '(include-uri)
  :on-path "subcase-types")

;; "http://mu.semte.ch/vocabularies/ext/publicatie/Vertaalactiviteit"
;; "http://mu.semte.ch/vocabularies/ext/publicatie/Handtekenactiviteit"
;; "http://mu.semte.ch/vocabularies/ext/publicatie/Drukproefactiviteit"
(define-resource activity ()
  :class (s-prefix "prov:Activity") ;; Does this belong in dossier-domain ?
  :properties `((:start-date      :datetime ,(s-prefix "dossier:Activiteit.startdatum"))
                (:end-date        :datetime ,(s-prefix "dossier:Activiteit.einddatum"))
                (:name            :string   ,(s-prefix "dct:title"))

                ;;Vertaal activiteit
                (:final-translation-date     :datetime ,(s-prefix "pub:uitersteVertaling"))
                (:withdraw-reason     :string ,(s-prefix "ext:redenVanIntrekking"))
                (:mail-content        :string ,(s-prefix "ext:bericht"))
                (:mail-subject        :string ,(s-prefix "ext:onderwerp")))

  :has-one `((subcase             :via      ,(s-prefix "dossier:vindtPlaatsTijdens")
                                  :as "subcase")
             (language            :via      ,(s-prefix "ext:doelTaal") ;; only when type === translationActivity
                                  :as "language")
             (activity-type       :via      ,(s-prefix "dct:type")
                                  :as "type")
             ;;Publicatie
             (activity            :via      ,(s-prefix "pub:publishes")
                                  :as "publishes")
             (activity-status     :via      ,(s-prefix "pub:publicatieStatus")
                                  :as "status")
                                  )
  :has-many `((piece              :via      ,(s-prefix "prov:used")
                                  :as "used-pieces")
              (piece              :via      ,(s-prefix "dossier:genereert")
                                  :as "generated-pieces")

              (file               :via      ,(s-prefix "ext:gebruiktBestand")
                                  :as "used-files")
              ;;Publicatie
              (activity           :via      ,(s-prefix "pub:publishes")
                                  :inverse t
                                  :as "published-by")
                                  )
  :resource-base (s-url "http://themis.vlaanderen.be/id/activiteit/")
  :features '(include-uri)
  :on-path "activities")

(define-resource activity-status ()
  :class (s-prefix "pub:ActiviteitStatus") ;; NOTE: as well as skos:Concept
  :properties `((:label           :string ,(s-prefix "skos:prefLabel"))
                (:scope-note      :string ,(s-prefix "skos:scopeNote"))
                (:alt-label       :string ,(s-prefix "skos:altLabel")))
  :has-many `((activity           :via ,(s-prefix "pub:publicatieStatus")
                                  :inverse t
                                  :as "activities"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/activiteit-status/")
  :features '(include-uri)
  :on-path "activity-statuses")

(define-resource activity-type ()
  :class (s-prefix "ext:ActiviteitType") ;; NOTE: as well as skos:Concept
  :properties `((:label           :string ,(s-prefix "skos:prefLabel"))
                (:scope-note      :string ,(s-prefix "skos:scopeNote"))
                (:alt-label       :string ,(s-prefix "skos:altLabel")))
  :has-many `((activity           :via ,(s-prefix "dct:type")
                                  :inverse t
                                  :as "activities"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/activiteit-type/")
  :features '(include-uri)
  :on-path "activity-types")

(define-resource agenda-activity ()
  :class (s-prefix "besluitvorming:Agendering")
  :properties `((:start-date      :datetime ,(s-prefix "dossier:startDatum"))) ;; should be dossier:Activiteit.startdatum
  :has-one `((subcase             :via ,(s-prefix "besluitvorming:vindtPlaatsTijdens")
                                  :as "subcase"))
  :has-many `((agendaitem         :via ,(s-prefix "besluitvorming:genereertAgendapunt")
                                  :as "agendaitems")
             (submission-activity :via ,(s-prefix "prov:wasInformedBy")
                                  :as "submission-activities"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/agendering/")
  :features '(include-uri)
  :on-path "agenda-activities")

(define-resource submission-activity ()
  :class (s-prefix "ext:Indieningsactiviteit")
  :properties `((:start-date      :datetime ,(s-prefix "dossier:Activiteit.startdatum")))
  :has-one `((subcase             :via ,(s-prefix "ext:indieningVindtPlaatsTijdens") ;; subpredicate for besluitvorming:vindtPlaatsTijdens
                                  :as "subcase")
             (agenda-activity     :via ,(s-prefix "prov:wasInformedBy")
                                  :inverse t
                                  :as "agenda-activity"))
  :has-many `((piece              :via ,(s-prefix "prov:generated")
                                  :as "pieces")
              (mandatee           :via ,(s-prefix "prov:qualifiedAssociation")
                                  :as "submitters"))
  :resource-base (s-url "http://kanselarij.vo.data.gift/id/indieningsactiviteit/")
  :features '(include-uri)
  :on-path "submission-activities")

(define-resource access-level ()
  :class (s-prefix "ext:ToegangsniveauCode") ;; NOTE: as well as skos:Concept
  :properties `((:label       :string ,(s-prefix "skos:prefLabel"))
                (:scope-note  :string ,(s-prefix "skos:scopeNote"))
                (:alt-label   :string ,(s-prefix "skos:altLabel"))
                (:priority    :string ,(s-prefix "ext:prioriteit")))
  :has-many `((subcase        :via ,(s-prefix "ext:toegangsniveauVoorProcedurestap")
                              :inverse t
                              :as "subcases")
              (piece          :via ,(s-prefix "ext:toegangsniveauVoorDocumentVersie")
                              :inverse t
                              :as "pieces")
              (case           :via ,(s-prefix "ext:toegangsniveauVoorDossier")
                              :inverse t
                              :as "cases"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/toegangsniveau/")
  :features '(include-uri)
  :on-path "access-levels")

(define-resource person-or-organization ()
  :class (s-prefix "ext:PersonOrOrganization") ;; NOTE: as resource hack for super typing, is person or organization
  :properties `((:type :string ,(s-prefix "rdfs:type")))
  :resource-base (s-url "http://themis.vlaanderen.be/id/persoon/") ;; NOTE: Should in theory never get used, as this is a read-only hack.
  :features '(include-uri)
  :on-path "person-or-organization")
