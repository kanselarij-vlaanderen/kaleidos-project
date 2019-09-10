(define-resource document ()
  :class (s-prefix "foaf:Document")
  :properties `((:archived              :boolean  ,(s-prefix "besluitvorming:gearchiveerd"))
                (:title                 :string   ,(s-prefix "dct:title"))
                (:description           :string   ,(s-prefix "ext:omschrijving")) 
                (:confidential          :boolean  ,(s-prefix "ext:vertrouwelijk"))
                (:created               :datetime ,(s-prefix "dct:created"))
                (:number-vp             :string   ,(s-prefix "besluitvorming:stuknummerVP")) 
                (:number-vr             :string   ,(s-prefix "besluitvorming:stuknummerVR"))
                (:number-vr-original    :string   ,(s-prefix "ext:stuknummerVROriginal"))
                (:freeze-access-level   :boolean  ,(s-prefix "ext:freezeAccessLevel"))
                (:for-cabinet           :boolean  ,(s-prefix "ext:voorKabinetten"))) 
  :has-many `((remark                   :via ,(s-prefix "besluitvorming:opmerking")
                                        :as "remarks") 
              (document-version         :via ,(s-prefix "besluitvorming:heeftVersie")
                                        :as "document-versions"))
  :has-one `((document-type             :via ,(s-prefix "ext:documentType")
                                        :as "type")
             (access-level              :via ,(s-prefix "ext:toegangsniveauVoorDocument")
                                        :as "access-level")
             (decision                  :via ,(s-prefix "ext:beslissingsfiche")
                                        :inverse t
                                        :as "signed-decision")
             (meeting-record            :via ,(s-prefix "ext:getekendeNotulen")
                                        :inverse t
                                        :as "signed-minutes"))
  :resource-base (s-url "http://kanselarij.vo.data.gift/id/documenten/")
  :features '(include-uri)
  :on-path "documents")

(define-resource document-version ()
  :class (s-prefix "ext:DocumentVersie")
  :properties `((:version-number        :string   ,(s-prefix "ext:versieNummer"))
                (:created               :datetime ,(s-prefix "dct:created"))
                (:number-vr             :string   ,(s-prefix "besluitvorming:stuknummerVR")) 
                (:chosen-file-name      :string   ,(s-prefix "ext:gekozenDocumentNaam")))
  :has-one `((file                      :via      ,(s-prefix "ext:file")
                                        :as "file")
            (file                       :via      ,(s-prefix "ext:convertedFile")
                                        :as "converted-file")
            (document                   :via      ,(s-prefix "besluitvorming:heeftVersie")
                                        :inverse t
                                        :as "document")
            (subcase                    :via ,(s-prefix "ext:bevatDocumentversie")
                                        :inverse t
                                        :as "subcase")
            (subcase                    :via ,(s-prefix "ext:bevatReedsBezorgdeDocumentversie")
                                        :inverse t
                                        :as "linked-subcase")
            (agendaitem                 :via ,(s-prefix "ext:bevatAgendapuntDocumentversie")
                                        :inverse t
                                        :as "agendaitem")
            (agendaitem                 :via ,(s-prefix "ext:bevatReedsBezorgdAgendapuntDocumentversie")
                                        :inverse t
                                        :as "agendaitem")
            (announcement               :via ,(s-prefix "ext:mededelingBevatDocumentversie")
                                        :inverse t
                                        :as "announcement")
            (newsletter-info            :via ,(s-prefix "ext:documentenVoorPublicatie")
                                        :inverse t
                                        :as "newsletter")
            (decision                   :via ,(s-prefix "ext:documentenVoorBeslissing")
                                        :inverse t
                                        :as "decision")
            (meeting-record             :via ,(s-prefix "ext:getekendeDocumentVersiesVoorNotulen")
                                        :inverse t
                                        :as "meeting-record"))
  :resource-base (s-url "http://kanselarij.vo.data.gift/id/document-versies/")
  :features `(include-uri)
  :on-path "document-versions")

(define-resource document-type ()
  :class (s-prefix "ext:DocumentTypeCode")
  :properties `((:label             :string ,(s-prefix "skos:prefLabel"))
                (:scope-note        :string ,(s-prefix "skos:scopeNote"))
                (:priority          :number ,(s-prefix "ext:prioriteit"))
                (:is-oc             :boolean ,(s-prefix "ext:isOverlegcomité"))
                (:alt-label         :string ,(s-prefix "skos:altLabel")))
  :has-many `((document             :via    ,(s-prefix "ext:documentType")
                                    :inverse t
                                    :as "documents")
              (document-type        :via    ,(s-prefix "skos:broader")
                                    :inverse t
                                    :as "subtypes"))
  :has-one `((document-type         :via    ,(s-prefix "skos:broader")
                                    :as "supertype"))
  :resource-base (s-url "http://kanselarij.vo.data.gift/id/concept/document-type-codes/")
  :features '(include-uri)
  :on-path "document-types")

(define-resource document-state ()
  :class (s-prefix "ext:DocumentStatus")
  :properties `((:label :string ,(s-prefix "skos:prefLabel"))
                (:alt-label :string ,(s-prefix "skos:altLabel")))
  :resource-base (s-url "http://kanselarij.vo.data.gift/id/concept/document-statussen/")
  :features `(no-pagination-defaults include-uri)
  :on-path "document-states")
