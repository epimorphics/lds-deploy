# SPARQL update query to patch up store after a publish or remove of profile data
PREFIX def-bw: <http://environment.data.gov.uk/def/bathing-water/>
PREFIX def-ef: <http://location.data.gov.uk/def/ef/SamplingPoint/>
PREFIX def-bwp: <http://environment.data.gov.uk/def/bathing-water-profile/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX version: <http://environment.data.gov.uk/def/version/>
PREFIX time: <http://www.w3.org/2006/time#>
PREFIX ugraph:  <http://environment.data.gov.uk/bwq/graph/updates/>

# delete existing latest profile links
DELETE WHERE {
    GRAPH ?G { ?bw def-bwp:latestBathingWaterProfile ?bwp } 
} ;
#DELETE { GRAPH ugraph:profile {?bw def-bwp:latestBathingWaterProfile ?bwp } } WHERE
#{ ?bw def-bwp:latestBathingWaterProfile ?bwp } ;
#
# Rebuild new latest profile links
INSERT { GRAPH ugraph:profile { ?bw def-bwp:latestBathingWaterProfile ?latest_bwp } } WHERE
{
    ?latest_bwp a def-bwp:BathingWaterProfile ;
                def-bw:bathingWater ?bw ;
                version:interval/time:hasBeginning/time:inXSDDateTime ?latest_dt.

    OPTIONAL {
       ?probe_bwp  a def-bwp:BathingWaterProfile ;
                   def-bw:bathingWater ?bw ;
                   version:interval/time:hasBeginning/time:inXSDDateTime ?probe_dt.
       FILTER (?probe_dt > ?latest_dt)
     }
     FILTER (!bound(?probe_bwp))
}
