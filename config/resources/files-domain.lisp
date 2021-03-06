(define-resource file ()
  :class (s-prefix "nfo:FileDataObject")
  :properties `((:filename      :string     ,(s-prefix "nfo:fileName"))
                (:format        :string     ,(s-prefix "dct:format"))
                (:size          :number     ,(s-prefix "nfo:fileSize"))
                (:extension     :string     ,(s-prefix "dbpedia:fileExtension"))
                (:created       :datetime   ,(s-prefix "dct:created"))
                (:content-type  :string     ,(s-prefix "ext:contentType")))
  :has-one `((file              :via        ,(s-prefix "nie:dataSource")
                                :inverse t
                                :as "download")
             (signature         :via        ,(s-prefix "ext:handtekening")
                                :inverse t
                                :as "signature"))
  :has-many `((activity         :via        ,(s-prefix "ext:gebruiktBestand")
                                :inverse t
                                :as "activities"))
  :resource-base (s-url "http://themis.vlaanderen.be/id/bestand/")
  :features `(no-pagination-defaults include-uri)
  :on-path "files")
