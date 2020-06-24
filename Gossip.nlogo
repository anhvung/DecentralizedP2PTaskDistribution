breed [brains brain]
brains-own [available mytask info-tasks datalist refreshrate refreshlimit]
breed [infos info]
infos-own [ brainId status taskslist timestamp ]
globals [types type1 type2 numberoftask1 numberoftask2 starttingpoint visited update-interval]
to setup
  clear-all
  ask patches[
    set pcolor white
  ]
  set types [red blue green]
  ;CREATION DU GRAPHEAv
  setup-graph
  setup-agents


  set type1 number-type1
  set type2 number-type2
  set update-interval interval

  ;Point d'entrée
  set starttingpoint one-of brains
  print "root : "

  ;Point d'entrée
  ask starttingpoint[
    print who
    set info-tasks insert-item 0 info-tasks type2
    set info-tasks insert-item 0 info-tasks type1
    let newdata 0
    let mywho who
    let savedinfo-tasks info-tasks

    hatch-infos 1 [
      set newData who ;pour pouvoir y fqire ref apres
      set brainId mywho
      set status -1
      set taskslist savedinfo-tasks
      set timestamp -1
    ]

    set datalist insert-item 0 datalist ( info newData )

  ]


  reset-ticks
end

to go
  ask brains[
    ;On choisit au hasard avec une probabilité uniforme un voisin avec lequel on va communiquer
    let target one-of link-neighbors


    ;Si il a une information à donner (Sinon pas la peine de communiquer)

    process-both target datalist who


  ]
  if ticks > 5000 [stop]
  tick
end

to process-both [myTarget received-list sender-id];update both sender and receiver data and update their task
  ask myTarget[
    prepareData who
    prepareData sender-id
    updateData who received-list
    updateData sender-id datalist
    updateTask who
    updateTask sender-id

  ]
end

to prepareData [myId]
  let myWho who
  let k 0
  let exists false

  while [k != length datalist][

    ask item k datalist[
      if brainId = myWho [
        set exists true
      ]
    ]
    set k k + 1
  ]

  if exists = false[
    let newData 0
    let mytasksave 0
    ask brain myId[
      set mytasksave  mytask
    ]
    hatch-infos 1 [
      set newData who ;pour pouvoir y fqire ref apres
      set brainId mywho
      set status mytasksave
      set taskslist []
      set timestamp -1
    ]

    set datalist insert-item 0 datalist ( info newData )

  ]

end
to updateData [myId newList]
  ask brain myId[
    let i 0
    while [i != length newList][

      let received-id 0
      let received-time 0
      ask item i newlist[
        set received-id brainId
        set received-time timestamp
      ]
      let k 0
      let fixedlength length datalist
      let notexsits true
      while [k != fixedlength][

        let my-id 0
        let my-time 0
        ask item k datalist[
          set my-id brainId
          set my-time timestamp
        ]
        if my-id = received-id [
          set notexsits false
          if my-time < received-time[
            set datalist replace-item k datalist ( item i newlist )

          ]
        ]

        set k k + 1
      ]

      if notexsits [
        set datalist lput ( item i newlist ) datalist
      ]
      set i i + 1
    ]
  ]



end
to updateTask [myId]



  let newInfoList []
  let maxTime 0
  let myIdInList 0
  let myStatus 0
  let myTimeStamp 0
  let myWho who
  let i 0
  while [i != length datalist][

    let tmp-time 0
    let tmp-list []
    ask item i datalist[
      set tmp-time timestamp
      set tmp-list taskslist
      if brainId = myWho [
        set myIdInList  i
      ]
    ]

    if tmp-time > maxTime and length tmp-list > 0[
      set maxTime tmp-time
      set newInfoList tmp-list
    ]
    set i i + 1
  ]


  ;weuifhweiopfhuasioufaswofaswugfhuioawf
  let tempdatalist []
  ask brain myId[set tempdatalist datalist]
  ask item myIdInList datalist[
    set myStatus status
    set myTimeStamp timestamp
  ]





  ;;;;;;;;;;;;;;;;;;;;;;;;;;;



  let taskstates map [ netlogoctropnul -> 0 ]  [50 50] ;newInfoList
  foreach datalist[
    dataitem ->
    ask dataitem [
      if status >= 0 [
        set taskstates replace-item status taskstates (( item status taskstates ) + 1)
      ]
    ]
  ]

  ; set taskstates ( map [ [ currentvalue maxvalue ] -> maxvalue - currentvalue ] taskstates newInfoList)
  ;print taskstates

  ask brain myId[
    ifelse 0 = (item 1 taskstates) +  (item 0 taskstates) [
      set refreshlimit 0
    ][
      let pourcentage min list (item 0 taskstates /( (item 1 taskstates) +  (item 0 taskstates)))  (item 1 taskstates /( (item 1 taskstates) +  (item 0 taskstates)))
      set refreshlimit 0.1836 * pourcentage
    ]




    set refreshrate refreshrate + 1

  ]
  set taskstates ( map [ [a b] -> a - b ] [50 50] taskstates)





  if refreshrate > refreshlimit [
    ask brain myId[

      set refreshrate 0


      let j 0
      let newTask -1
      let tmpValue 0
      while [j != length taskstates][


        if item j taskstates > tmpValue [
          set tmpValue item j taskstates
          set newTask j
        ]

        set j j + 1
      ];end while
      if  newTask != -1 and  newTask != mytask [

        if newTask = 1[
          set color red
          set myStatus 1
        ]
        if newTask = 0[
          set color blue
          set myStatus 0
        ]

        set mytask newTask



      ]
    ]

  ];end if



  ; update son propre tasklist dans param interne et datalist
  let newData 0
  hatch-infos 1 [
    set newData who ;pour pouvoir y fqire ref apres
    set brainId mywho
    set status myStatus
    set taskslist newInfoList
    set timestamp ticks
  ]
  ;enfin on peut update

  set datalist replace-item myIdInList datalist ( info newData )
  set info-tasks newInfoList



end



to update-target [myTarget received-list sender-id]

  ifelse myTarget != nobody[ ; au cas ou s'il n'y a pas de voisin
    ask myTarget[

      if available = 0 [ ; S'il n'est pas en train de traiter une task
        ifelse  (random-float 1) > 0 [ ;Si on choisit task2
          set mytask 2
          set color red


        ]
        [;  ELSE Si on choisit task1
          set mytask 1
          set color blue


        ]

        set available 1
      ]
    ]
  ]
  [print "no voisin !!!"]


end
to-report occurrences [x the-list]
  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
end

to setup-agents
  ask brains[
    set available 0
    set mytask -1
    set info-tasks []
    set datalist []
    set label who
    set refreshrate one-of [1 2 3 4 5 6]
    set refreshlimit update-interval
  ]
end
to setup-graph
  create-brains number-brains[
    set shape "circle"
    setxy random-pxcor random-pycor
    set color green
  ]
  ;CREATION DU GRAPHE (Liens)
  repeat number-connections[
    ask one-of brains[
      create-link-with one-of other brains
    ]
  ]
  complete-graph
end

to complete-graph   ;On complete pour avoir un graphe connexe
  set visited  n-values number-brains [0]
  let added-brain nobody
  dfs 0
  let index-a-1 []
  let index-a-0 []
  let index 0
  while [index != length visited][



    ifelse item index visited = 1[
      set index-a-1 insert-item 0 index-a-1 index
    ]
    [
      set index-a-0 insert-item 0 index-a-0 index
    ]
    set index index + 1
  ]


  let taille-comp-connexe length index-a-1

  if taille-comp-connexe < number-brains[
    let auhasard0 one-of index-a-0
    let auhasard1 one-of index-a-1
    ask brain auhasard1[
      create-link-with brain auhasard0
    ]
    ask brain auhasard0[
      create-link-with brain auhasard1
    ]

    complete-graph
  ]




end


to dfs [n] ;parcours en profondeur recusif
  if item n visited = 0[
    set visited replace-item n visited 1
    ask brain n[
      ask out-link-neighbors[;pour tous les voisins
        dfs who
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
226
58
807
640
-1
-1
17.364
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
13
51
76
84
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
109
182
142
number-brains
number-brains
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
10
154
182
187
number-connections
number-connections
0
100
76.0
1
1
NIL
HORIZONTAL

BUTTON
118
51
181
84
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
201
184
234
number-type1
number-type1
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
10
240
182
273
number-type2
number-type2
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
7
457
207
607
Task 1
Tick
Task1
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "plot count brains with [color = blue]" "plot count brains with [color = blue]"

PLOT
8
627
208
777
Task 2
Tick
Task 2
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "plot count brains with [color = blue]" "plot count brains with [color = red]"

PLOT
860
73
1599
701
Distribution
Time
Ratio
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 100 * count brains with [color = blue]/((count brains with [color = blue]) + (count brains with [color = red]))"

MONITOR
865
16
1498
61
NIL
100 * count brains with [color = blue]/((count brains with [color = blue]) + (count brains with [color = red]))
17
1
11

SLIDER
27
302
199
335
interval
interval
1
19
3.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Setup generates a simple graph showing a network of agents capable of solving tasks.

## HOW IT WORKS

An entry point is determined randomly and will spread the information of the tasks. At each tick, each agent will randomly chose a neighbor to which to information will be sent.

## HOW TO USE IT



## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
