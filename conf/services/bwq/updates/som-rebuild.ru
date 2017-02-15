PREFIX def-bw: <http://environment.data.gov.uk/def/bathing-water/>
PREFIX def-sp: <http://location.data.gov.uk/def/ef/SamplingPoint/>
PREFIX def-som: <http://environment.data.gov.uk/def/bwq-som/>
PREFIX def-bwq: <http://environment.data.gov.uk/def/bathing-water-quality/>
PREFIX time:    <http://www.w3.org/2006/time#>
PREFIX qb:      <http://purl.org/linked-data/cube#>
PREFIX xsd:     <http://www.w3.org/2001/XMLSchema#>
PREFIX dct:     <http://purl.org/dc/terms/>
PREFIX ugraph:  <http://environment.data.gov.uk/bwq/graph/updates/>

#
# Delete all dct:replaces/dct:/isReplacedBy links between SoM and PI records 
#
DELETE { GRAPH ugraph:in-season {
    ?update      dct:replaces     ?predecessor .
    ?predecessor dct:isReplacedBy ?update . } }
WHERE {
#   ?update a                         def-som:SuspensionOfMonitoring .
#  If new update has been unpublished then still want to remove the links

   VALUES ?type { 
     def-som:SuspensionOfMonitoring 
     def-som:PollutionIncident 
   }

   # Find replaces/isReplacedBy links for ?type's to delete
   # Also delete orphaned links (between things with no rdf:type).
   { ?predecessor
             a                ?type;
             dct:isReplacedBy ?update .
   } UNION {
        ?update
           a                  ?type;
           dct:replaces       ?predecessor .
   } UNION {
     ?update 
     		dct:replaces     ?predecessor .
     FILTER (    NOT EXISTS { ?predecessor a ?p_type }
              || NOT EXISTS { ?update a ?u_type } )
   } UNION {
     ?predecessor 
     		dct:isReplacedBy     ?update .
     FILTER (    NOT EXISTS { ?predecessor a ?p_type }
              || NOT EXISTS { ?update a ?u_type } )       
   }
};
#
# Build dct:replaces/dct:/isReplacedBy links between SoM records
#
INSERT { GRAPH ugraph:in-season {
    ?update      dct:replaces     ?predecessor .
    ?predecessor dct:isReplacedBy ?update . 
} } WHERE {
   VALUES ( ?type ?keyProp ?startProp ) { 
          ( def-som:SuspensionOfMonitoring def-bw:bathingWater def-som:startOfSuspension ) 
          ( def-som:PollutionIncident      def-som:incidentNotation def-som:startOfIncident ) 
   }
   
   ?update a                        ?type ;
           ?keyProp                 ?key;
           ?startProp               ?stime ;
           def-som:recordDateTime   ?u_recordDate;
           .

    # Find a ?prececessor
    ?predecessor
            a                       ?type;
           ?keyProp                 ?key;
           ?startProp               ?stime ;
           def-som:recordDateTime   ?p_recordDate;
           .

     FILTER (?p_recordDate<?u_recordDate)

     # Make sure that the is no ?probe between ?update and its immediate predecessor.
      OPTIONAL {
       ?probe
           a                      ?type;
           ?keyProp               ?key;
           ?startProp             ?stime ;
           def-som:recordDateTime ?pr_recordDate;
           .
        FILTER ( ?pr_recordDate > ?p_recordDate && ?u_recordDate > ?pr_recordDate)
     } FILTER (!bound(?probe))
} ; 
#
# Delete all links between suspensions and neighbouring sample assessments.
# (Use CONSTRUCT or SELECT instead of DELETE to debug WHERE body.)
#
DELETE { GRAPH ugraph:in-season {
    ?suspension def-som:priorAssessment ?priorAssessment;
              def-som:followingAssessment ?followingAssessment;
              def-som:relatedAssessment ?priorAssessment, ?followingAssessment;
              .
              
  ?priorAssessment
              def-som:followingSuspension ?suspension;
              def-som:relatedSuspension ?suspension .
              
  ?followingAssessment
              def-som:priorSuspension ?suspension;
              def-som:relatedSuspension ?suspension ;
} }
WHERE {
  { ?suspension def-som:followingAssessment ?followingAssessment }
  UNION
  { ?suspension def-som:priorAssessment ?priorAssessment }

};
#
# Re-insert links between suspensions and neighbouring sample assessments.
# (Use CONSTRUCT or SELECT instead of INSERT to debug WHERE body.)
#
INSERT{ GRAPH ugraph:in-season {
  ?suspension def-som:priorAssessment ?priorAssessment;
              def-som:followingAssessment ?followingAssessment;
              def-som:relatedAssessment ?priorAssessment, ?followingAssessment;
              .
              
  ?priorAssessment
              def-som:followingSuspension ?suspension;
              def-som:relatedSuspension ?suspension .
              
  ?followingAssessment
              def-som:priorSuspension ?suspension;
              def-som:relatedSuspension ?suspension .
} }
#SELECT ?suspension ?startOfSuspension ?pSampleDateTime  ?fSampleDateTime
WHERE {
   # Pick a suspension record
   ?suspension def-som:startOfSuspension  ?startOfSuspension;
         def-sp:samplingPoint             ?sp; 
         def-som:recordDateTime           ?recordDateTime;
         def-bwq:sampleYear               ?sampleYear;
            .

   # Bind the point year slice for the corresponding bw/sample year assessments 
   ?slice
         a                                def-bwq:BySamplingPointYearSlice;
         def-bwq:sampleYear               ?sampleYear;
         def-bwq:samplingPoint            ?sp;
         .       
   # Make sure that its the most recent record for the given suspension
   FILTER NOT EXISTS { ?suspension dct:isReplacedBy ?other_som }

   # Pick an unwithdrawn prior sample assessment.
   OPTIONAL { 
      ?slice qb:observation   ?priorAssessment .
      ?priorAssessment
             def-bwq:sampleDateTime  [ time:inXSDDateTime ?pSampleDateTime ] .
      FILTER NOT EXISTS { ?priorAssessment dct:isReplacedBy [] }
      FILTER NOT EXISTS { ?priorAssessment def-bwq:recordStatus def-bwq:withdrawal }
      FILTER (?pSampleDateTime<?startOfSuspension) 
    }
    # probe for a subsequent prior assessment record
    FILTER NOT EXISTS {
      ?slice qb:observation   ?probePriorAssessment .
      ?probePriorAssessment
          def-bwq:sampleDateTime  [ time:inXSDDateTime ?ppSampleDateTime ] . 
      FILTER NOT EXISTS { ?probePriorAssessment dct:isReplacedBy [] }
      FILTER NOT EXISTS { ?probePriorAssessment def-bwq:recordStatus def-bwq:withdrawal }
      FILTER (?ppSampleDateTime<?startOfSuspension &&  ?ppSampleDateTime > ?pSampleDateTime ) 
    }


   # probe for a following sample assessment
   OPTIONAL { 
     ?slice qb:observation    ?followingAssessment .
     ?followingAssessment
            def-bwq:sampleDateTime  [ time:inXSDDateTime ?fSampleDateTime ] . 
     FILTER NOT EXISTS { ?followingAssessment dct:isReplacedBy [] }
     FILTER NOT EXISTS { ?followingAssessment def-bwq:recordStatus def-bwq:withdrawal }
     FILTER (?fSampleDateTime>?startOfSuspension) 
   }
   # probe for a earlier following sample assessment or a more recent record
   FILTER NOT EXISTS {
     ?slice qb:observation    ?probeFollowingAssessment .
     ?probeFollowingAssessment
            def-bwq:sampleDateTime  [ time:inXSDDateTime ?pfSampleDateTime ] . 
     FILTER NOT EXISTS { ?probeFollowingAssessment dct:isReplacedBy [] }
     FILTER NOT EXISTS { ?probeFollowingAssessment def-bwq:recordStatus def-bwq:withdrawal }
     FILTER (?pfSampleDateTime>?startOfSuspension && ?pfSampleDateTime < ?fSampleDateTime )
   } 
};
##
## Remove 'old' links from bathing-waters to their most recent active suspension
##
DELETE { 
  GRAPH ugraph:in-season { ?bw ?latestProp ?item } 
} WHERE {
 VALUES ?latestProp {
   def-som:latestActiveSuspension 
   def-som:latestOpenIncident 
 }
 ?bw ?latestProp ?item 
}; 
##
## Link bathing-waters to their most recent active suspension
##
INSERT { 
  GRAPH ugraph:in-season { ?bw ?latestProp ?item }
}
#select ?bw ?item
WHERE {
  { 
     { 
       VALUES (?type ?keyProp ?startProp ?endProp ?latestProp ) { 
              ( def-som:SuspensionOfMonitoring def-bw:bathingWater      def-som:startOfSuspension def-som:endOfSuspension def-som:latestActiveSuspension ) 
              ( def-som:PollutionIncident      def-som:incidentNotation def-som:startOfIncident   def-som:endOfIncident   def-som:latestOpenIncident ) 
       }
  
       ?item     a                         ?type ;
                 ?keyProp                  ?key ;
                 ?startProp                ?start;
                 def-som:recordDateTime    ?recordDateTime ;
                 .
       FILTER NOT EXISTS { ?item dct:isReplacedBy ?other }                
       FILTER NOT EXISTS { ?item ?endProp ?end }                .
     } OPTIONAL {
       # Now look for a second incomplete suspension/incident that started later.
       # Want to only have *one* latestActiveSuspension/latesOpenIncident per bw.
       ?itemb  a                         ?type ;
               ?keyProp                  ?key ;
               ?startProp                ?startb;
               def-som:recordDateTime    ?recordDateTimeb ;
            .
       FILTER NOT EXISTS { ?itemb dct:isReplacedBy ?otherb }               
       FILTER NOT EXISTS { ?itemb ?endProp ?endb }  
       FILTER (?startb > ?start)
    }
     FILTER (!bound(?itemb))
  } OPTIONAL { ?item def-bw:bathingWater ?bw }
}
