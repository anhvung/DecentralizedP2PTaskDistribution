breed [brains brain]
brains-own [available mytask info-tasks contains-update-agent parent-brain-id refreshrate refreshlimit LbrainId Lstatus Ltaskslist Ltimestamp]
globals [types starttingpoint visited globalroot globalTasks number-of-types total-number-of-task task-list color-list error-value convergence number-tests]




;;;;;;;;;;;;;;;;;;;; SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup-graph
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output

  (ifelse Graph-type = "fully connected" [
    generate-fully-connected

    ]
    Graph-type = "graph" [
      generate-graph
    ]
    Graph-type = "tree" [
      generate-tree
    ]
    Graph-type = "small word" [
      generate-small-world

  ])

  set  convergence 0

  file-open "stats.txt"
  reset-ticks

end

to add-task

  if number-of-types = 0 [ ;; initialisation au début du programme
    set task-list list (0)(0) ;; à l'indice i se trouve le nombre de brains nécéssaires pour la tache i
    set color-list list (red)(blue) ;; à l'indice i se trouve la couleur associée à la tache i
    set total-number-of-task 0
  ]

  if new-task-number != 0[

    set number-of-types number-of-types + 1
    set total-number-of-task (total-number-of-task + new-task-number)

    if number-of-types = 1 [
      set task-list replace-item 0 task-list new-task-number
    ]
    if number-of-types = 2 [
      set task-list replace-item 1 task-list new-task-number
    ]
    if number-of-types > 2 [
      set task-list insert-item (number-of-types - 1) task-list new-task-number
      set color-list insert-item (number-of-types - 1) color-list one-of remove red remove blue base-colors
    ]

    print(task-list)
    print(number-of-types)




  ]

end

to reset-task
  set task-list list (0)(0)
  set total-number-of-task 0
  set number-of-types 0
  set color-list list (red)(blue)
  print(task-list)
end

to setup-task-and-graph

  setup-graph

   ifelse number-of-types < 1 [ ;; si aucune tache n'a étée ajouté avant le setup on ne peut pas faire le setup
    print("You must add at least two tasks !")
  ]
  [
  (ifelse Algo = "Probabilistic" [
    setup-probabilistic
    ]
    Algo = "Deterministic" [
      setup-deterministic
    ]
    Algo = "Gossip" [
      setup-gossip
  ])
  ]

  reset-ticks
end



to setup-probabilistic

  ask brains[
    set available 0
    set mytask 0
    set info-tasks []
    set label-color black
    set color black

  ]

  ask  one-of brains [
    let i 0
    while[i < number-of-types][
      let ptask (item i task-list / total-number-of-task)
      set info-tasks insert-item 0 info-tasks ptask
      set i i + 1
    ]

    PROBABILISTIC-update-target self info-tasks
  ]

end

to setup-deterministic
  ask brains[
    set color black
    set available 0
    let j 0
    set info-tasks []
    while[j < number-of-types][
      set info-tasks insert-item 0 info-tasks (item j task-list)
      set j j + 1
    ]
    set mytask 0
  ]

  let info []
  let i 0
    while[i < number-of-types][
      let ntask (item i task-list)
      set info insert-item 0 info ntask
      set i i + 1
    ]
  ask one-of brains [
    set color yellow
    set contains-update-agent 1
    DETERMINISTIC-update-target self info
  ]

end

to setup-gossip
  set globalTasks []
  let i 0
    while[i < number-of-types][
      set globalTasks lput item i task-list globalTasks
      set i i + 1
    ]




  ask brains[
    set available 0
    set mytask -1
    set info-tasks []
    set LbrainId  []
    set Lstatus   []
    set Ltaskslist   []
    set Ltimestamp   []
    set label who
    set refreshrate one-of [1 2 3 4 5 6]
    set refreshlimit 3
    set color black
  ]


  ;Point d'entrée
  set starttingpoint one-of brains


  ;Point d'entrée
  ifelse initialize [
    ask brains [
      let j 0
      while[j < number-of-types][
        set info-tasks insert-item 0 info-tasks (item j task-list)
        set j j + 1
      ]

      let newdata 0
      let savedinfo-tasks info-tasks

      let choix random length task-list
      set color item choix color-list

      set LbrainId lput who LbrainId
      set Lstatus lput choix Lstatus
      set Ltaskslist lput savedinfo-tasks Ltaskslist
      set Ltimestamp lput -1 Ltimestamp





    ]
  ]
  [
    ask one-of brains  [

      let k 0
      while[k < number-of-types][
        set info-tasks insert-item 0 info-tasks (item k task-list)
        set k k + 1
      ]
      let newdata 0

      let savedinfo-tasks info-tasks
      set LbrainId lput who LbrainId
      set Lstatus lput -1 Lstatus
      set Ltaskslist lput savedinfo-tasks Ltaskslist
      set Ltimestamp lput -1 Ltimestamp

    ]
  ]
end
;;;;;;;;;;;;;;;;;;;; END OF SETUP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  (ifelse Algo = "Probabilistic" [
    PROBABILISTIC
    ]
    Algo = "Deterministic" [
      DETERMINISTIC
    ]
    Algo = "Gossip" [
      GOSSIP
  ])

  set error-value 0
  let indi 0
  while[indi < number-of-types][
    set error-value error-value + (abs (item indi task-list - count brains with [color = item indi color-list]) / item indi task-list )
    set indi indi + 1
  ]
  if record-stats
  [
    stats
  ]

end
to stats


  ifelse error-value = 0 [
    set  convergence convergence + 1
    if convergence = 50 [

      file-type Algo  file-type ";" file-type Graph-type  file-type ";" file-type number-brains  file-type ";" file-print ticks
      type "Saved " type number-tests type " " type Algo type " " type Graph-type type " " type number-brains type " " print ticks

      file-close
      set number-tests number-tests + 1
      if number-tests = 100 [
        stop
      ]
      setup-task-and-graph
    ]
  ][
    set  convergence 0
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;; END GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; PROBABILISTIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to PROBABILISTIC
  ask brains[
    ;On choisit au hasard avec une probabilité uniforme un voisin avec lequel on va communiquer
    let target one-of link-neighbors


    if length info-tasks > 0[  ;Si il a une information à donner (Sinon pas la peine de communiquer)

      PROBABILISTIC-update-target target info-tasks
    ]

  ]

  tick
end


to PROBABILISTIC-update-target [myTarget receinved-info-tasks]

  let myptask []
  let i 0
    while[i < number-of-types][
      set myptask insert-item i myptask (item i receinved-info-tasks)
      set i i + 1
    ]


  ifelse myTarget != nobody[ ; au cas ou s'il n'y a pas de voisin
    ask myTarget[
      let j 0
      while[j < number-of-types][
        set info-tasks insert-item 0 info-tasks (item j myptask)
        set j j + 1
      ]

      if available = 0 [ ; S'il n'est pas en train de traiter une task

      let choix random-float 1
      let total 0
      let k 0
        while[k < number-of-types][
          set total total + item k info-tasks
          if choix <= total and choix > total - item k info-tasks[
            set color item k color-list
            set mytask k

          ]

          set k k + 1
        ]


        set available 1
      ]
    ]
  ]
  [print "no voisin !!!"]


end
;;;;;;;;;;;;;;;;;;;;;;; END PROBABILISTIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;; DETERMINISTIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to DETERMINISTIC
  ask brains with [contains-update-agent = 1][
    let target one-of out-link-neighbors with [mytask = 0]
    let n  who
    ifelse target != nobody [ ;Si il existe un voisin sans tâche, on propage l'information
      print("target != nobody")
      DETERMINISTIC-update-target target info-tasks


      set contains-update-agent 0
      ask target [
        set contains-update-agent 1
        set parent-brain-id n
      ]
    ][ ;Sinon on fait remonter l'information à celui qui nous l'avait donné (selon un dfs) pour qu'il puisse la donner à un des ses voisins, ou la remonter plus haut
      set target brain parent-brain-id
      print("target = nobody")
      DETERMINISTIC-update-target target info-tasks

      set contains-update-agent 0
      ask target [
        set contains-update-agent 1
      ]
    ]
  ]
  tick
end

to DETERMINISTIC-update-target [myTarget receinved-info-tasks]
  print("info-tasks")
  print(receinved-info-tasks)

    ifelse myTarget != nobody[ ; au cas ou s'il n'y a pas de voisin
      ask myTarget[
        let n length receinved-info-tasks
        let i 0
        let done false
        if available = 0 [ ; S'il n'est pas en train de traiter une task
          while [(done = false) and (i < n)] [
            ifelse (item i receinved-info-tasks) > 0 [
              set mytask i + 1
              set color item i color-list
              set available 1
              set done true
            ][
              set i i + 1
            ]
          ]
        ]
        set info-tasks []
        let j 1
        while [j <= n] [
          let myntask item (n - j) receinved-info-tasks
          ifelse (n - j = i) and (done = true) [
            set info-tasks insert-item 0 info-tasks (myntask - 1)
          ][
            set info-tasks insert-item 0 info-tasks myntask
          ]
          set j j + 1
        ]
      ]
    ]
    [print "no voisin !!!"]


end
;;;;;;;;;;;;;;;;;;;;;; END DETERMINISTIC ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;; GOSSIP  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to GOSSIP
  ask brains[
    ;On choisit au hasard avec une probabilité uniforme un voisin avec lequel on va communiquer
    let target one-of link-neighbors


    ;Si il a une information à donner (Sinon pas la peine de communiquer)

    process-both target (brain who)


  ]

  tick
end

to process-both [myTarget me];update both sender and receiver data and update their task

  GOSSIP-prepareData me

  GOSSIP-updateData myTarget me

  GOSSIP-updateTask myTarget



end

to GOSSIP-prepareData [mybrain]
  ask mybrain[
    let myWho who
    let k 0
    let exists false

    foreach LbrainId [ x ->

      if x = myWho [
        set exists true
      ]

    ]
    if exists = false[
      set LbrainId lput who LbrainId
      set Lstatus lput mytask Lstatus
      set Ltaskslist lput [] Ltaskslist
      set Ltimestamp lput -1 Ltimestamp

    ]

  ]


end
to GOSSIP-updateData [myTarget myBrain]
  let RLbrainId []
  let RLstatus []
  let RLtaskslist []
  let RLtimestamp []

  ask myBrain [
    set RLbrainId LbrainId
    set RLstatus Lstatus
    set RLtaskslist Ltaskslist
    set RLtimestamp Ltimestamp
  ]

  ask myTarget[
    let i 0
    while [i != length RLbrainId][

      let received-id item i RLbrainId
      let received-time item i RLtimestamp
      let k 0
      let fixedlength length LbrainId
      let notexsits true
      while [k != fixedlength][

        let my-id item k LbrainId
        let my-time item k Ltimestamp

        if my-id = received-id [
          set notexsits false
          if my-time < received-time[
            set Lstatus  replace-item k Lstatus  ( item i RLstatus  )
            set Ltaskslist   replace-item k Ltaskslist   ( item i RLtaskslist   )
            set Ltimestamp   replace-item k Ltimestamp   ( item i RLtimestamp   )

          ]
        ]

        set k k + 1
      ]

      if notexsits [
        set LbrainId   lput (item i RLbrainId ) LbrainId
        set Lstatus  lput (item i RLstatus) Lstatus
        set Ltaskslist lput (item i RLtaskslist ) Ltaskslist
        set Ltimestamp lput (item i RLtimestamp ) Ltimestamp

      ]
      set i i + 1
    ]
  ]



end
to GOSSIP-updateTask [myTarget]

  ask myTarget [

    let newInfoList []
    let maxTime 0
    let myIdInList 0
    let myStatus 0
    let myTimeStamp 0

    let i 0
    while [i != length LbrainId ][

      let tmp-time 0
      let tmp-list []

      if item i LbrainId = who [
        set myIdInList  i
      ]
      set tmp-time item i Ltimestamp
      set tmp-list item i Ltaskslist


      if tmp-time > maxTime and length tmp-list > 0[
        set maxTime tmp-time
        set newInfoList tmp-list
      ]
      set i i + 1
    ]


    ;weuifhweiopfhuasioufaswofaswugfhuioawf
    set myStatus item myIdInList Lstatus
    set myTimeStamp item myIdInList Ltimestamp

    let taskstates map [ netlogoctropnul -> 0 ] globalTasks ;newInfoList
    foreach Lstatus [
      x ->

      if x >= 0 [
        set taskstates replace-item x taskstates (( item x taskstates ) + 1)
      ]

    ]

    ; set taskstates ( map [ [ currentvalue maxvalue ] -> maxvalue - currentvalue ] taskstates newInfoList)
    ;print taskstates

    let pourcentage 0
    ifelse 0 = (item 1 taskstates) +  (item 0 taskstates) [
      set refreshlimit 0
    ][
      set pourcentage min list (item 0 taskstates /( (item 1 taskstates) +  (item 0 taskstates)))  (item 1 taskstates /( (item 1 taskstates) +  (item 0 taskstates)))
      ;set refreshlimit (75 * pourcentage * pourcentage ) - (17.5 * pourcentage)
      ; set refreshlimit ((exp (10 * pourcentage)) - 1)


    ]




    set refreshrate refreshrate + 1

    set taskstates ( map [ [a b] -> a - b ] globalTasks taskstates)



   ; if refreshrate > 0 and ( random ((length Lstatus)* (log (length Lstatus) 2)) < 1 )[
    if refreshrate > 0 and ( random ((length Lstatus)) < 1 )[


      set refreshrate 0
      ;set refreshlimit one-of [8 9 10] * (pourcentage * 10 )

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


        set color item newTask color-list
        set myStatus newTask



        set mytask newTask



      ]


    ];end if







    set Lstatus   replace-item myIdInList Lstatus  (myStatus)
    set Ltaskslist    replace-item myIdInList Ltaskslist   (newInfoList)
    set Ltimestamp    replace-item myIdInList Ltimestamp   (ticks)

    ;;set info-tasks newInfoList

  ]

end


;;;;;;;;;;;;;;;;;;;;;;;;; END GOSSIP  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report occurrences [x the-list]
  report reduce
    [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 the-list)
end


;;;;;;;;;; GRAPH GENERATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to generate-tree

  ask patches [
    set pcolor white
  ]

  create-brains 1 [
    set shape "circle"
    setxy random 30 - 15 random 30 - 15
  ]

  let i 1
  while [i < number-brains][
    create-brains 1 [
      set shape "circle"
      setxy random 30 - 15 random 30 - 15
    ]

    ask brain i [
      create-link-with one-of other brains
    ]

    set i i + 1
  ]



  layout-radial brains links brain 0

end

to generate-graph

  ask patches [
    set pcolor white
  ]

  create-brains 1 [
    set shape "circle"
    setxy random 30 - 15 random 30 - 15
  ]

  let i 1
  while [i < number-brains][
    create-brains 1 [
      set shape "circle"
      setxy random 30 - 15 random 30 - 15
    ]

    ask brain i [
      create-link-with one-of other brains
    ]

    set i i + 1
  ]

  while [i < number-connections][
    let node1 one-of brains
    let node2 one-of brains with [self != node1]
    ask node1 [
      create-link-with node2
    ]

    set i i + 1
  ]



  layout-radial brains links brain 0

end

to generate-fully-connected

  ask patches [
    set pcolor white
  ]

  create-brains number-brains [
    set shape "circle"
    setxy random 30 - 15 random 30 - 15
  ]

  ask brains [
    ask other brains [
      create-link-with myself
    ]
  ]



  layout-radial brains links brain 0

end

to generate-small-world

  ask patches [
    set pcolor white
  ]

  create-brains number-brains [
    set shape "circle"
  ]

  layout-circle (sort brains) max-pxcor - 1

  let i 0
  while [i < number-brains][
    ask brain i [
      create-link-with brain ((i + 1) mod number-brains)
      create-link-with brain ((i + 2) mod number-brains)
    ]
    set i i + 1
  ]

  ask links [
    if (random-float 1) < 0.4 [
      let node1 end1
      if [count link-neighbors] of end1 < (number-brains - 1) [
        let node2 one-of brains with [(self != node1) and (not link-neighbor? node1)]
        ask node1 [
          create-link-with node2
        ]
        die
      ]
    ]
  ]



end
;;;;;;;;;; END OF GRAPH GENERATION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;; ELECT ROOT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to elect-root ;; va trouver le neud le plus proche de tous les autres

  let minimum number-brains * number-brains
  let indiceMinimum 0
  let i 0

  while [i < number-brains][ ;; pour chaque noeud, on va calculer la somme des distances qui le sépare des autres noeuds

    let liste list (0)(0) ;; cette liste va contenir à l'indice j la distance entre le noeud d'indice j et le noeud etudié i
    let j 0
    let level 1 ;; level est la distance à laquelle on se situe du noeud i étudié


    ask brain i[ ;; premiere étape : on crée la liste de taille number-brains en mettant des 1 pour les voisins du noeud étudié et des number-brains - 1 ailleurs
      while [j < number-brains][
        set liste insert-item j liste (number-brains - 1) ;; on inititalise les distances à la distance maximale possible

        if link-neighbor? brain j[
          set liste replace-item j liste level
        ]
        set j j + 1
      ]
    ]
    set liste replace-item i liste 0 ;; on met une distance de 0 pour le noeud étudié
    set level level + 1
    let q 0
    while [level < number-brains][ ;; dans le pire des cas, si tous les noeuds sont allignés on a au maximum number-brains - 1 levels
                                   ;; on va donc regarder quels sont les voisins des voisins, tout en enregistrant la distance au noeud étudié dans la liste
      let k 0
      while [k < number-brains][
        if item k liste = level - 1[ ;; si le noeud k est du niveau (level - 1) alors on va chercher ses voisins encore non connéctés pour les mettres au niveau level
          ask brain k[
            let n 0
            while [n < number-brains][

              if (link-neighbor? brain n) and (item n liste > level)[ ;; si le noeud n est voisin du noeud k et qu'il n'a pas encore été connecté au réseau alors on le connecte en indiquant qu'il est à une distance de level du noeud étudié
                set liste replace-item n liste level
              ]
              set n n + 1
            ]

          ]


        ]


        set k k + 1
      ]

      set level level + 1
    ]

    let power 0
    let p 0

    while[p < number-brains][
      set power power + item p liste
      set p p + 1
    ]

    if power <= minimum[

      set minimum power
      set indiceMinimum i
    ]
    set i i + 1
  ]


  ask brain indiceMinimum[ ;; indiceMinimum est l'indice du noeud racine
    set color yellow

  ]

end

;;;;;;;;;;;;;;;;;;; END OF ELECT ROOT ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
550
10
1131
592
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
0
0
1
ticks
30.0

SLIDER
8
120
220
153
number-brains
number-brains
0
10000
30.0
1
1
NIL
HORIZONTAL

SLIDER
7
162
219
195
number-connections
number-connections
0
1000
325.0
1
1
NIL
HORIZONTAL

BUTTON
126
759
189
792
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

CHOOSER
8
10
220
55
Graph-type
Graph-type
"fully connected" "graph" "tree" "small word"
3

BUTTON
439
13
525
52
NIL
elect-root
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
7
64
221
109
Algo
Algo
"Probabilistic" "Deterministic" "Gossip"
2

SWITCH
428
77
531
110
initialize
initialize
0
1
-1000

BUTTON
11
758
104
791
go (1 step)
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1
408
90
441
Add-task
add-task
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
0
364
212
397
new-task-number
new-task-number
0
1000
15.0
1
1
NIL
HORIZONTAL

BUTTON
99
406
201
439
reset-tasks
reset-task
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
9
594
204
705
setup
setup-task-and-graph
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
263
274
486
885
Les instruction d'un meme numéro peuvent être exécutées dans n'importe quel ordre.\n\nLes instructions de deux numéros différents doivent être exécutée dans l'ordre croissant de numéros.\n\n1. Graph-type/ Algo/number-brains/ number-connections\n\n3. New-task-number/add-task/reset-task\n\n4.setup\n\n5. go / go(1step)
16
0.0
1

MONITOR
4
446
201
491
types-of-tasks (at least 2)
task-list
17
1
11

PLOT
1158
10
1815
611
plot 1
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count brains with [color = red]"
"pen-1" 1.0 0 -13345367 true "" "plot count brains with [color = blue]"
"pen-2" 1.0 0 -7500403 true "" "plot count brains with [color = grey]"
"pen-3" 1.0 0 -955883 true "" "plot count brains with [color = orange]"
"pen-4" 1.0 0 -6459832 true "" "plot count brains with [color = brown]"
"pen-5" 1.0 0 -1184463 true "" "plot count brains with [color = yellow]"
"pen-6" 1.0 0 -10899396 true "" "plot count brains with [color = green]"
"pen-7" 1.0 0 -13840069 true "" "plot count brains with [color = lime]"
"pen-8" 1.0 0 -14835848 true "" "plot count brains with [color = turquoise]"
"pen-9" 1.0 0 -11221820 true "" "plot count brains with [color = cyan]"
"pen-10" 1.0 0 -13791810 true "" "plot count brains with [color = sky]"
"pen-11" 1.0 0 -8630108 true "" "plot count brains with [color = violet]"
"pen-12" 1.0 0 -5825686 true "" "plot count brains with [color = magenta]"
"pen-13" 1.0 0 -2064490 true "" "plot count brains with [color = pink]"

MONITOR
5
495
111
540
number-of-types
number-of-types
17
1
11

SWITCH
268
76
392
109
record-stats
record-stats
0
1
-1000

MONITOR
635
667
710
712
error-value
error-value
17
1
11

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
