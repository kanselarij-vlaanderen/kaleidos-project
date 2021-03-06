(define-resource agenda ()
  :class (s-prefix "besluitvorming:Agenda")
  :properties `((:issued      :datetime   ,(s-prefix "dct:issued"))
                (:title        :string     ,(s-prefix "dct:title"))
                (:serialnumber :string    ,(s-prefix "besluitvorming:volgnummer"))
                (:created     :datetime       ,(s-prefix "dct:created"))
                ; (:agendatype  :url        ,(s-prefix "dct:type")) // Currently not implemented ( https://test.data.vlaanderen.be/doc/applicatieprofiel/besluitvorming/#Agenda )
                (:modified    :datetime   ,(s-prefix "dct:modified")))
  :has-one `((meeting         :via        ,(s-prefix "besluitvorming:isAgendaVoor")
                              :as "created-for")
             (agendastatus    :via        ,(s-prefix "besluitvorming:agendaStatus")
                              :as "status")
             (access-level    :via ,(s-prefix "besluitvorming:vertrouwelijkheidsniveau")
                              :as "access-level")
             (agenda          :via        ,(s-prefix "prov:wasRevisionOf")
                              :as "previous-version")
             (agenda           :via        ,(s-prefix "prov:wasRevisionOf")
                               :inverse t
                               :as "next-version"))
  :has-many `((agendaitem     :via        ,(s-prefix "dct:hasPart")
                              :as "agendaitems"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/agenda/")
  :features '(include-uri)
  :on-path "agendas")

(define-resource agendastatus ()
  :class (s-prefix "kans:AgendaStatus")
  :properties `((:label       :string ,(s-prefix "skos:prefLabel"))
                  (:scope-note  :string ,(s-prefix "skos:scopeNote"))
                  (:alt-label   :string ,(s-prefix "skos:altLabel")))
  :has-many `((agenda     :via        ,(s-prefix "besluitvorming:agendaStatus")
                          :inverse t
                          :as "agendas"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/agenda-status/")
  :features '(include-uri)
  :on-path "agendastatuses")

(define-resource agendaitem ()
  :class (s-prefix "besluit:Agendapunt")
  :properties `((:created             :datetime ,(s-prefix "besluitvorming:aanmaakdatum")) ;; NOTE: What is the URI of property 'aanmaakdatum'? Made up besluitvorming:aanmaakdatum
                (:retracted           :boolean  ,(s-prefix "besluitvorming:ingetrokken")) ;; NOTE: What is the URI of property 'ingetrokken'? Made up besluitvorming:ingetrokken
                (:priority            :number   ,(s-prefix "ext:prioriteit"))
                (:for-press           :boolean  ,(s-prefix "ext:forPress"))
                (:record              :string   ,(s-prefix "besluitvorming:notulen")) ;; NOTE: What is the URI of property 'notulen'? Made up besluitvorming:notulen
                (:title-press         :string   ,(s-prefix "besluitvorming:titelPersagenda"))
                (:explanation         :string   ,(s-prefix "ext:toelichting"))
                (:text-press          :string   ,(s-prefix "besluitvorming:tekstPersagenda"))
                ;; Added properties from subcases
                (:short-title         :string   ,(s-prefix "dct:alternative"))
                (:title               :string   ,(s-prefix "dct:title"))
                (:modified            :datetime ,(s-prefix "ext:modified"))
                (:formally-ok         :url      ,(s-prefix "ext:formeelOK"))
                (:show-as-remark      :boolean  ,(s-prefix "ext:wordtGetoondAlsMededeling"))
                (:is-approval         :boolean  ,(s-prefix "ext:isGoedkeuringVanDeNotulen"))) ;; NOTE: What is the URI of property 'titelPersagenda'? Made up besluitvorming:titelPersagenda
  :has-one `((agendaitem              :via      ,(s-prefix "besluit:aangebrachtNa")
                                      :as "previous-agenda-item")
             (user                    :via      ,(s-prefix "ext:modifiedBy")
                                      :as "modified-by")
             (agenda                  :via      ,(s-prefix "dct:hasPart")
                                      :inverse t
                                      :as "agenda")
             (agendaitem              :via        ,(s-prefix "prov:wasRevisionOf")
                                      :as "previous-version")
             (agendaitem              :via        ,(s-prefix "prov:wasRevisionOf")
                                      :inverse t
                                      :as "next-version")
             (agenda-activity         :via      ,(s-prefix "besluitvorming:genereertAgendapunt")
                                      :inverse t
                                      :as "agenda-activity"))
  :has-many `((agenda-item-treatment  :via        ,(s-prefix "besluitvorming:heeftOnderwerp")
                                      :inverse t
                                      :as "treatments")
            ;; Added has-many relations from subcases
              (approval               :via      ,(s-prefix "ext:agendapuntGoedkeuring")
                                      :as "approvals")
              (mandatee               :via      ,(s-prefix "ext:heeftBevoegdeVoorAgendapunt") ;; NOTE: used mandataris instead of agent
                                      :as "mandatees")
              (piece                  :via      ,(s-prefix "besluitvorming:geagendeerdStuk")
                                      :as "pieces")
              (piece                  :via ,(s-prefix "ext:bevatReedsBezorgdAgendapuntDocumentversie") ;; NOTE: instead of dct:hasPart (mu-cl-resources relation type checking workaround)
                                      :as "linked-pieces"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/agendapunt/")
  :features `(no-pagination-defaults include-uri)
  :on-path "agendaitems")


  (define-resource approval ()
  :class (s-prefix "ext:Goedkeuring")
  :properties `((:created   :datetime ,(s-prefix "ext:aangemaakt")))
  :has-one `((mandatee      :via ,(s-prefix "ext:goedkeuringen")
                            :inverse t
                            :as "mandatee")
             (agendaitem    :via ,(s-prefix "ext:agendapuntGoedkeuring")
                            :inverse t
                            :as "agendaitem"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/goedkeuring/")
  :on-path "approvals")

(define-resource agenda-item-treatment ()
  :class (s-prefix "besluit:BehandelingVanAgendapunt") ; Also includes properties/relations from besluitvorming:Beslissingsactiviteit
  :properties `(
                (:created     :datetime       ,(s-prefix "dct:created"))
                (:modified    :datetime   ,(s-prefix "dct:modified"))
                )
  :has-many `(
              ; Omdat de mu-cl-resources configuratie momenteel onze meest accurate documentatie is over huidig model / huidige data, laat ik 'm er toch graag in. Dit predicaat is in-data veel aanwezig (en waardevolle data), en zal in de toekomst terug opgepikt worden
              ; (piece      :via ,(s-prefix "ext:documentenVoorBeslissing")
              ;                :as "pieces")
              )
  :has-one `((agendaitem            :via        ,(s-prefix "besluitvorming:heeftOnderwerp")
                                    :as "agendaitem")
             (subcase               :via        ,(s-prefix "ext:beslissingVindtPlaatsTijdens")
                                    :as "subcase")
             (piece                 :via        ,(s-prefix "besluitvorming:genereertVerslag")
                                    :as "report") ;In sommige gevallen waren er hier meerdere voorkomens van. Nader te bekijken hoe wat waarom?
             (newsletter-info       :via        ,(s-prefix "prov:generated")
                                    :as "newsletter-info")
             (decision-result-code  :via        ,(s-prefix "besluitvorming:resultaat")
                                    :as "decision-result-code"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/behandeling-van-agendapunt/")
  :features '(include-uri)
  :on-path "agenda-item-treatments")

(define-resource decision-result-code ()
  :class (s-prefix "ext:BeslissingsResultaatCode")
  :properties `(
                (:label       :string ,(s-prefix "skos:prefLabel"))
                (:priority    :number ,(s-prefix "ext:priority"))
               )
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/beslissingsresultaat-code/")
  :features '(include-uri)
  :on-path "decision-result-codes")

(define-resource government-unit ()
  :class (s-prefix "besluit:Bestuurseenheid")
  :properties `((:name :string ,(s-prefix "skos:prefLabel")))
  :has-one `((jurisdiction-area :via ,(s-prefix "besluit:werkingsgebied")
                                   :as "area-of-jurisdiction")
             (government-unit-classification-code :via ,(s-prefix "besluit:classificatie")
                                                  :as "classification"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/bestuurseenheid/")
  :features '(include-uri)
  :on-path "government-units")

;; Unmodified from lblod/loket
(define-resource jurisdiction-area ()
  :class (s-prefix "prov:Location")
  :properties `((:name :string ,(s-prefix "rdfs:label"))
                (:level :string, (s-prefix "ext:werkingsgebiedNiveau")))
  :has-many `((government-unit :via ,(s-prefix "besluit:werkingsgebied")
                               :inverse t
                               :as "government-units"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/werkingsgebied/")
  :features '(include-uri)
  :on-path "jurisdiction-areas")

;; Unmodified from lblod/loket
(define-resource government-unit-classification-code ()
  :class (s-prefix "ext:BestuurseenheidClassificatieCode")
  :properties `((:label :string ,(s-prefix "skos:prefLabel"))
                (:scope-note :string ,(s-prefix "skos:scopeNote"))
                (:alt-label :string ,(s-prefix "skos:altLabel")))
  :resource-base (s-url "http://themis.vlaanderen.be/id/concept/bestuurseenheid-classificatie-code/")
  :features '(include-uri)
  :on-path "government-unit-classification-codes")

(define-resource meeting ()
  :class (s-prefix "besluit:Vergaderactiviteit")
  :properties `((:planned-start         :datetime ,(s-prefix "besluit:geplandeStart"))
                (:started-on            :datetime ,(s-prefix "prov:startedAtTime")) ;; NOTE: Kept ':geplande-start' from besluit instead of ':start' from besluitvorming
                (:ended-on              :datetime ,(s-prefix "prov:endedAtTime")) ;; NOTE: Kept ':geeindigd-op-tijdstip' from besluit instead of ':eind' from besluitvorming
                (:location              :string   ,(s-prefix "prov:atLocation"))
                (:released-decisions    :datetime ,(s-prefix "ext:releasedDecisions"))
                (:released-documents    :datetime ,(s-prefix "ext:releasedDocuments"))
                (:number                :number   ,(s-prefix "adms:identifier"))
                (:is-final              :boolean  ,(s-prefix "ext:finaleZittingVersie")) ;; 2019-01-09: Also see note on agenda "is-final". "ext:finaleZittingVersie" == true means "agenda afgesloten" but not at a version level
                (:kind                  :url      ,(s-prefix "dct:type"))
                (:extra-info            :string   ,(s-prefix "ext:extraInfo"))
                (:number-representation :string   ,(s-prefix "ext:numberRepresentation")))
  :has-many `((agenda                   :via      ,(s-prefix "besluitvorming:isAgendaVoor")
                                        :inverse t
                                        :as "agendas")
              (subcase                  :via      ,(s-prefix "ext:isAangevraagdVoor")
                                        :inverse t
                                        :as "requested-subcases")
              (piece                    :via      ,(s-prefix "ext:zittingDocumentversie")
                                        :as "pieces"))
  :has-one `((agenda                    :via      ,(s-prefix "besluitvorming:behandelt");; NOTE: What is the URI of property 'behandelt'? Made up besluitvorming:behandelt
                                        :as "agenda")
             (newsletter-info           :via      ,(s-prefix "ext:algemeneNieuwsbrief")
                                        :as "newsletter")
             (signature                 :via      ,(s-prefix "ext:heeftHandtekening")
                                        :as "signature")
              ;; (piece                    :via ,(s-prefix "dossier:genereert") ;; this relation exists in legacy data, but we do not show this in the frontend currently
              ;;                           :as "notes") ;; note: is this a hasOne or hasMany ?
             (mail-campaign             :via      ,(s-prefix "ext:heeftMailCampagnes")
                                        :as "mail-campaign")
             (meeting                   :via      ,(s-prefix "dct:isPartOf")
                                        :as "main-meeting"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/zitting/")
  :features '(include-uri)
  :on-path "meetings")
