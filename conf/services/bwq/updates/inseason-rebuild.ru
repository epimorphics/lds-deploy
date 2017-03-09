# SPARQL update query to patch up store after a publish or remove
# SKW reviews 2014-10-31
PREFIX qb:  <http://purl.org/linked-data/cube#>
PREFIX bwq: <http://environment.data.gov.uk/def/bathing-water-quality/>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX interval: <http://reference.data.gov.uk/def/intervals/>
PREFIX rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX time: <http://www.w3.org/2006/time#> 

PREFIX def-bw: <http://environment.data.gov.uk/def/bathing-water/>
PREFIX def-sp: <http://location.data.gov.uk/def/ef/SamplingPoint/>
PREFIX def-som: <http://environment.data.gov.uk/def/bwq-som/>
PREFIX def-bwq: <http://environment.data.gov.uk/def/bathing-water-quality/>
PREFIX time:    <http://www.w3.org/2006/time#>
PREFIX qb:      <http://purl.org/linked-data/cube#>
PREFIX xsd:     <http://www.w3.org/2001/XMLSchema#>
PREFIX dct:     <http://purl.org/dc/terms/>
PREFIX ugraph:  <http://environment.data.gov.uk/bwq/graph/updates/>

# Remove previous replaces/replacedBy links for sample assessment records
DELETE { GRAPH ugraph:in-season {
     ?update      dct:replaces     ?predecessor .
     ?predecessor dct:isReplacedBy ?update . } }
# Updated to a pair or unioned clauses (rather than a conjuction) 
# in case things become out of step.
WHERE {
     { ?update      a                bwq:SampleAssessment ;
                    dct:replaces     ?predecessor . 
     } UNION {
       ?predecessor a                bwq:SampleAssessment ;
                    dct:isReplacedBy ?update . 
     }
} ;
# Reconstruct links based on current replacements/withdrawals
INSERT { GRAPH ugraph:in-season {
    ?update    dct:replaces ?predecessor .
    ?predecessor dct:isReplacedBy ?update . } }
 WHERE {
   { ?update a                    bwq:SampleAssessment;
              bwq:recordStatus    bwq:withdrawal;
              bwq:bathingWater    ?bw;
              bwq:samplingPoint   ?sp;
              bwq:sampleDateTime  ?u_stime ;
              bwq:recordDate      ?u_recordDate;
   } UNION {
     ?update a                    bwq:SampleAssessment;
              bwq:recordStatus    bwq:replacement;
              bwq:bathingWater    ?bw;
              bwq:samplingPoint   ?sp;
              bwq:sampleDateTime  ?u_stime ;
              bwq:recordDate      ?u_recordDate;
   }

    # Find a ?prececessor
    ?predecessor
           a                        bwq:SampleAssessment;
           bwq:bathingWater     ?bw;
           bwq:samplingPoint    ?sp;
           bwq:sampleDateTime   ?u_stime;
           bwq:recordDate       ?pred_recordDate;
           .

     FILTER (?pred_recordDate<?u_recordDate)

     # Make sure that the is no ?probe between ?update and its immediate predecessor.
     OPTIONAL {
       ?probe
             a                        bwq:SampleAssessment;
             bwq:bathingWater    ?bw;
             bwq:samplingPoint   ?sp;
             bwq:sampleDateTime  ?u_stime;
             bwq:recordDate       ?probe_recordDate;
        FILTER ( ?probe_recordDate > ?pred_recordDate && ?u_recordDate > ?probe_recordDate)
     } FILTER (!bound(?probe))
} ;

# Clean out 'latest' slice'
DELETE { GRAPH ugraph:in-season {
   <http://environment.data.gov.uk/data/bathing-water-quality/in-season/slice/latest> qb:observation ?o .
#   ?bw bwq:latestSampleAssessment ?o .
} }
WHERE  {
   <http://environment.data.gov.uk/data/bathing-water-quality/in-season/slice/latest> qb:observation ?o .
#   OPTIONAL { ?o bwq:bathingWater ?bw }
} ;

# Brute force delete to cope with changes across year boundaries
DELETE { GRAPH ugraph:in-season {
   ?bw bwq:latestSampleAssessment ?o .
} } WHERE {
   ?bw bwq:latestSampleAssessment ?o .
} ;

INSERT DATA { GRAPH ugraph:in-season {
    <http://environment.data.gov.uk/data/bathing-water-quality/in-season/slice/latest> 
            rdf:type   <http://environment.data.gov.uk/data/bathing-water-quality/LatestSampleSlice>;
            rdfs:label  "Latest in-season sample assessments pseudo slice."@en;
            .
} } ;

# Reconstruct 'latest' for 2010 data with no 2011 values
INSERT { GRAPH ugraph:in-season {
    <http://environment.data.gov.uk/data/bathing-water-quality/in-season/slice/latest> qb:observation ?o .
    ?bw bwq:latestSampleAssessment ?o .
} }
WHERE {
     {
        {
           ?year interval:ordinalYear ?yearOrd .
           FILTER (?yearOrd >= 2014)
           ?slice  a   bwq:BySamplingPointYearSlice;
           bwq:sampleYear ?year ;
           bwq:samplingPoint  ?sp .
        }

        OPTIONAL {
           ?slice2  a  bwq:BySamplingPointYearSlice;
           bwq:samplingPoint  ?sp .
           FILTER(STR(?slice2) > STR(?slice))
## (skw) need to ensure that the later slice has un-withdrawn/un-replaced observations
     FILTER EXISTS { ?slice2 qb:observation ?ob1;
             FILTER NOT EXISTS { ?ob1 bwq:recordStatus bwq:withdrawal }
             FILTER NOT EXISTS { ?ob1 dct:isReplacedBy [] }
           }
## (skw)
         }
         FILTER (!bound(?slice2))
      }

      ?slice qb:observation ?o .
      FILTER NOT EXISTS {  ?o  dct:isReplacedBy [] }
      FILTER NOT EXISTS {  ?o  bwq:recordStatus    bwq:withdrawal; }

      OPTIONAL {
            ?slice qb:observation ?o2.
        # Need to ensure that the probe observation has not been withdrawn or replaced
            FILTER NOT EXISTS {  ?o2  dct:isReplacedBy [] }
            FILTER NOT EXISTS {  ?o2  bwq:recordStatus    bwq:withdrawal; }
            ?o  bwq:sampleDateTime [ time:inXSDDateTime ?d1 ].
            ?o2 bwq:sampleDateTime [ time:inXSDDateTime ?d2 ].
            FILTER (?d2>?d1)
      }
      FILTER (!bound(?o2))
      ?o bwq:bathingWater ?bw .
}  ;
# delete latest annual compliance linkages
DELETE { GRAPH ugraph:in-season {
  ?bw bwq:latestComplianceAssessment ?o .
} } WHERE {
  ?bw bwq:latestComplianceAssessment ?o .
} ;
# recompute and reinsert latest annual compliance linakges.
INSERT { GRAPH ugraph:in-season {
  ?bw bwq:latestComplianceAssessment ?o .
} } WHERE {
  { ?slice a bwq:ComplianceByYearSlice;
           bwq:sampleYear [interval:ordinalYear ?year] .

    # Find the most recent annual compliance slice
    OPTIONAL {
      ?slice2 a bwq:ComplianceByYearSlice;
              bwq:sampleYear [ interval:ordinalYear ?year2 ] .
      FILTER (?year2>?year)
    } FILTER (!bound(?slice2))
  }
  ?slice qb:observation ?o .

  ?o bwq:bathingWater ?bw.
};

###############################################################################
# From here on matches  som-rebuild.ru
###############################################################################
#
# Delete all dct:replaces/dct:isReplacedBy links between SoM and PI records 
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
   VALUES ( ?type                          ?keyProp ) { 
          ( def-som:SuspensionOfMonitoring def-som:notation  ) 
          ( def-som:PollutionIncident      def-som:incidentNotation ) 
   }
   
   ?update a                        ?type ;
           ?keyProp                 ?key;
           def-som:recordDateTime   ?u_recordDate;
           .

    # Find a ?prececessor
    ?predecessor
            a                       ?type;
           ?keyProp                 ?key;
           def-som:recordDateTime   ?p_recordDate;
           .

     FILTER (?p_recordDate<?u_recordDate)

     # Make sure that the is no ?probe between ?update and its immediate predecessor.
      OPTIONAL {
       ?probe
           a                      ?type;
           ?keyProp               ?key;
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
       VALUES (?type                           ?keyProp                 ?startProp                ?endProp                ?latestProp ) { 
              ( def-som:SuspensionOfMonitoring def-som:notation         def-som:startOfSuspension def-som:endOfSuspension def-som:latestActiveSuspension ) 
              ( def-som:PollutionIncident      def-som:incidentNotation def-som:startOfIncident   def-som:endOfIncident   def-som:latestOpenIncident ) 
       }
  
       ?item     a                         ?type ;
                 def-bw:bathingWater       ?bw ;
                 ?startProp                ?start;
                 def-som:recordDateTime    ?recordDateTime ;
                 .
       FILTER NOT EXISTS { ?item dct:isReplacedBy ?other }                
       FILTER NOT EXISTS { ?item ?endProp ?end }                .
     } OPTIONAL {
       # Now look for a second incomplete suspension/incident that started later.
       # Want to only have *one* latestActiveSuspension/latesOpenIncident per bw.
       ?itemb  a                         ?type ;
               def-bw:bathingWater       ?bw ;
               ?startProp                ?startb;
               def-som:recordDateTime    ?recordDateTimeb ;
            .
       FILTER NOT EXISTS { ?itemb dct:isReplacedBy ?otherb }               
       FILTER NOT EXISTS { ?itemb ?endProp ?endb }  
       FILTER (?startb > ?start)
    }
    FILTER (!bound(?itemb))
  } 
}