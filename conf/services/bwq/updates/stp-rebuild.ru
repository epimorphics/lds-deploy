PREFIX def-stp: <http://environment.data.gov.uk/def/bwq-stp/>
PREFIX ugraph:  <http://environment.data.gov.uk/bwq/graph/updates/>
DELETE { GRAPH ?pG { ?bw def-stp:latestRiskPrediction ?prev } }
WHERE
{ ?bw def-stp:latestRiskPrediction ?latest, ?prev .

  ?latest def-stp:predictedAt ?latest_dateTime ;
          def-stp:publishedAt ?latest_pubDateTime  .

  ?prev def-stp:predictedAt ?prev_dateTime ;
        def-stp:publishedAt ?prev_pubDateTime .

  FILTER( (?latest_dateTime > ?prev_dateTime) ||
          ( (?latest_dateTime = ?prev_dateTime) &&
            (?latest_pubDateTime > ?prev_pubDateTime) ) )

  GRAPH ?pG {?bw def-stp:latestRiskPrediction ?prev }            
} 