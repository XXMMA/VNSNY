extensions [gis view2.5d csv table]

; it might be confusion but the Community District number is refered to as CD or boroCD in this project
globals [
  ;date
  year
  day
  current-tick
  ;var used for environment display
  agent-type-color-map
  mouse-was-down?
  nyCDs-dataset
  heatmap-flag
  mouse-was-clicked?
  map-block-color
  map-background-color
  map-line-color
  map-highlight-color
  borough-color ; key : [boroCD-lower-limit boroCD-higher-limit]value: color-value
  heatmap-color
  boroCD-CDs
  maxval
  minval
  ;var used for model
  ;stats
  pop-ratio-each-type ; key : type value : ratio
  pop-ratio-CD-in-each-type ; key type  value : [ [CDs] [ratios] ]
  nhats-ratio-each-type ; key : [type attrname] value : [[value1 value2 ....] [ratio1 ratio2]]
  num-in-hosp-each-day

  weights ; key : [type "ER"/"Office"] value : [attr-weight social-weight effic-weight]
  nhats-attr-names
  nhats-indep-attrs
  nhats-indep-dep-attrs ; key : indep-attrs-name value: corresponding-dep-attrs-name
  nhats-indep-dep-attrs-mapping ; key : dep-attrs-name value : key : corresponding-indep-attrs-value value : dep-attrs-value
  normalize-factor ; key : "attitude"/"social_norm"/"efficacy" value :[factor intercept]
  aa ; to make it more efficient, each normalization fator and intercept is stored in an individual variable
  ba
  as
  bs
  ae
  be
  intervals ;
  last-of-stay ; key: type value: table: key : stay_days value : ratio
  decision-intervals ; key: type value: table: key : interval_days value : ratio
  num-each-type ; key:type value: num of each type
  prob-hosp-after-decision ; key: type value: [ER-ratio Office-ratio]
  ;stats
  each-decision-each-type ; key: type value: [ER-decisions-num-by-each-type Office-decisions-num-by-each-type]
  total-decisions-each-type ; key: type value: num-of-decisions-by-each-type
]

breed[nyCDs nyCD]
breed[chosen-CDs chosen-CD]
breed[people person]

patches-own[
  mapping-boroCD
]

people-own[
  boroCD
  age ;0: 75 and above, 1: below 75
  gender ;0:female, 1:male
  race ;0: non-white, 1: white
  dual-eligible ;0: no, 1: yes
  agent-type
  ;attitude
  want-find-way-to ; wb1agrwstmt2
  feel-cheerful ; wb1offelche1
  feel-bored ; wb1offelche2
  feel-full-of-life ; wb1offelche3
  feel-upset ; wb1offelche4
  ;depression;0: no depression, 1: have depression
  ;social norm
  adjust-to-change ; wb1agrwstmt3
  self-determin ; wb1agrwstmt1
  ;have-caregiver ;
  know-each-other ; cm1knowwell
  willing-help-each-other ; cm1willnghlp
  can-be-trusted ; cm1peoptrstd
  no-one-talk-to ; fl1noonetalk
  ; efficacy
  income ; ia1totinc
  education ; el1higstschl
  ;state var
  los
  state
  get-treatment
  in-hosp
  severity
  decisions-record ; [er office-clinics]
  decision-type

  attitude_er
  motivation_er
  efficacy_er
  attitude_off-cl
  motivation_off-cl
  efficacy_off-cl
  intention_er
  intention_off-cl

  hospitalization ; num of hospitalization
  days-in-hosp
  next-decision
  last-update-attr
]

nyCDs-own[
  boroCD
  trans_num
  pct_res
  pct_parks
  pct_white
  pct_over65
  pct_rent_burd
  pct_served_parks
  pct_clean_strts
  crime
  pct_unemployment
  pct_poverty
  parks_num
  hosp_clinic_num
  pop_dens
  pct_non_res
  chosen-info
]

chosen-CDs-own[
  boroCD
  CD-id
]
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------Setup--------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup
  ca
  stop-inspecting-dead-agents
  setup-CD
  ;load-CMS-info
  setup-var
  setup-people
  reset-ticks
end

;;-------------------------------------------------------Setup Community District Environment-------------------------------------------------------------------
;;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-CD
  load-CDs
  load-and-draw-CDs-shape
  load-CDs-info
  map-patches
end

to load-CDs
  let prj-filepath  "nycd\\nycd.prj"
  let shp-filepath  "nycd\\nycd.shp"
  gis:load-coordinate-system prj-filepath
  set nyCDs-dataset gis:load-dataset shp-filepath
  gis:set-world-envelope gis:envelope-of nyCDs-dataset
  set map-block-color white
  set map-background-color white
  set map-line-color black
  set map-highlight-color red
  set heatmap-color blue
end

to load-and-draw-CDs-shape
  setup-borough-color
  ask patches [set pcolor map-background-color]
  set boroCD-CDs table:make
  foreach gis:feature-list-of nyCDs-dataset[ one-block ->
    let this-borough int ((gis:property-value one-block "BOROCD") / 100)
    let this-borough-color table:get borough-color this-borough
    gis:set-drawing-color this-borough-color
    gis:fill one-block 1.0
    gis:set-drawing-color map-line-color
    gis:draw one-block 1.0
    let centroid gis:location-of gis:centroid-of one-block
    ask patch first centroid last centroid [
      sprout-nyCDs 1[
        ht
        set shape "star"
        set boroCD gis:property-value one-block "BOROCD"
        setxy first centroid last centroid
        table:put boroCD-CDs boroCD who
      ]
    ]
  ]
end

to setup-borough-color
  set borough-color table:make
  table:put borough-color 1 19.5
  table:put borough-color 2 9.5
  table:put borough-color 3 49.5
  table:put borough-color 4 109.5
  table:put borough-color 5 69.5
end

to load-CDs-info
  foreach csv:from-file "community_district_data.csv" [row ->
    ask nyCDs with [boroCD = item 0 row][
      set trans_num item 1 row
      set pct_res item 2 row
      set pct_parks item 3 row
      set pct_white item 6 row
      set pct_over65 item 7 row
      set pct_rent_burd item 8 row
      set pct_served_parks item 9 row
      set pct_clean_strts item 10 row
      set crime item 11 row
      set pct_unemployment item 12 row
      set pct_poverty item 13 row
      set parks_num item 14 row
      set hosp_clinic_num item 15 row
      set pop_dens item 16 row
      set pct_non_res item 17 row
    ]
  ]
end


to map-patches
  file-open "patches_boroCD.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    let x item 0 row
    let y item 1 row
    ask patch x y [
      set mapping-boroCD item 2 row
    ]
  ]
  file-close-all
end

;-----------------------------------------------------------------Setup global variables------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-var
  load-normalize-factor
  load-weights
  load-last-of-stay
  load-decision-intervals
  load-prob-hosp-after-decision
  setup-global-var
end

to load-normalize-factor ; "attitude" "social_norm" "efficacy"  ****normalized = factor * attitude/social_norm/effficacy + intercept***
  set normalize-factor table:make
  file-open "data\\normalize_factors2.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    table:put normalize-factor item 0 row (list item 1 row item 2 row)
  ]
  file-close-all
  set aa item 0 (table:get normalize-factor "attitude")
  set ba item 1 (table:get normalize-factor "attitude")
  set as item 0 (table:get normalize-factor "social_norm")
  set bs item 1 (table:get normalize-factor "social_norm")
  set ae item 0 (table:get normalize-factor "efficacy")
  set be item 1 (table:get normalize-factor "efficacy")
end

to load-weights
  set weights table:make
  file-open "data\\weights.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    table:put weights (list item 0 row item 5 row) (list item 6 row item 7 row item 8 row)
  ]
  file-close-all
end

to load-last-of-stay
  set last-of-stay table:make
  file-open "data\\los.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    let day-ratio table:make
    foreach n-values item 1 row [i -> i] [i ->
      table:put day-ratio (item (2 + 2 * i) row) (item (2 + 2 * i + 1) row)
    ]
    table:put last-of-stay (item 0 row) day-ratio
  ]
  file-close-all
end

to load-decision-intervals
  set decision-intervals table:make
  file-open "data\\decision_intervals.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    let day-ratio table:make
    foreach n-values item 1 row [i -> i] [i ->
      table:put day-ratio (item (2 + 2 * i) row) (item (2 + 2 * i + 1) row)
    ]
    table:put decision-intervals (item 0 row) day-ratio
  ]
  file-close-all
end

to load-prob-hosp-after-decision
  set prob-hosp-after-decision table:make
  file-open "data\\hosp_prob_after_decision.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    table:put prob-hosp-after-decision item 0 row (list item 1 row item 2 row)
  ]
  file-close-all
end

to setup-global-var
  set year start-year
  set day 0
  set heatmap-flag false
end

;-----------------------------------------------------------Setup people agents----------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------------------------------------------------
to setup-people
  load-pop-distribution
  setup-people-color
  generate-people
  setup-attr-to-people
  setup-other-var-of-people
  setup-stats
end
;----------------------------------------------------------------load-pop-distribution----------------------------------------------------------------------
to load-pop-distribution
  load-pop-ratio-each-type
  load-pop-ratio-CD-in-each-type
  load-nhats-ratio-each-type
  load-nhats-indep-dep-attrs-mapping
end

to load-pop-ratio-each-type
  set pop-ratio-each-type table:make
  file-open "data\\ratio_type_over_whole_NYC.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    table:put pop-ratio-each-type item 0 row item 1 row
  ]
  file-close-all
end

to load-pop-ratio-CD-in-each-type
  set pop-ratio-CD-in-each-type table:make
  file-open "data\\ratio_CD_within_each_type.csv" ; this file !!!MUST!!! sort on type in the first column
  let headings csv:from-row file-read-line
  let CD-list []
  let ratio-list []
  let last-key -1
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    if item 0 row != last-key [
      if last-key != -1 [
        table:put pop-ratio-CD-in-each-type last-key list CD-list ratio-list
      ]
      set CD-list []
      set ratio-list []
      set last-key item 0 row
    ]
    set CD-list lput item 1 row CD-list
    set ratio-list lput item 2 row ratio-list
  ]
  table:put pop-ratio-CD-in-each-type last-key list CD-list ratio-list
  file-close-all
end

to test
  print 1
end

to load-nhats-ratio-each-type
  set nhats-ratio-each-type table:make
  file-open "data\\nhats_attr_each_type.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    set row remove "" row
    let index (range 4 length row 2)
    let value-list []
    let ratio-list []
    foreach index [ i ->
      set value-list lput item i row value-list
      set ratio-list lput item (i + 1) row ratio-list
    ]
    table:put nhats-ratio-each-type (list item 0 row item 1 row) (list value-list ratio-list)
  ]
  file-close-all
end

to load-nhats-indep-dep-attrs-mapping
  set nhats-attr-names ["want-find-way-to" "feel-cheerful" "feel-bored" "feel-full-of-life" "feel-upset" "adjust-to-change" "self-determin"
    "know-each-other" "willing-help-each-other" "can-be-trusted" "no-one-talk-to" "income" "education"]
  set nhats-indep-attrs ["want-find-way-to" "feel-cheerful" "feel-full-of-life" "adjust-to-change"
    "know-each-other" "willing-help-each-other" "can-be-trusted" "income" "education"]
  set nhats-indep-dep-attrs table:make
  table:put nhats-indep-dep-attrs "feel-full-of-life" "feel-bored"
  table:put nhats-indep-dep-attrs "feel-cheerful" "feel-upset"
  table:put nhats-indep-dep-attrs "adjust-to-change" "self-determin"
  table:put nhats-indep-dep-attrs "know-each-other" "no-one-talk-to"

  set nhats-indep-dep-attrs-mapping table:make
  file-open "data\\nhats_attr_map.csv"
  let headings csv:from-row file-read-line
  while [ not file-at-end? ] [
    let row csv:from-row file-read-line
    if table:has-key? nhats-indep-dep-attrs item 0 row
    [
      set row remove "" row
      let nvalues item 2 row
      let indep-dep table:make
      foreach (range 0 nvalues) [i ->
        table:put indep-dep item (3 + i * 2) row item (4 + i * 2) row
      ]
      table:put nhats-indep-dep-attrs-mapping (table:get nhats-indep-dep-attrs item 0 row) indep-dep
    ]
  ]
  file-close-all
end
;----------------------------------------------------------------generate-people----------------------------------------------------------------------
to-report partition-under-prob [total prob-list]
  let accprob 0
  let accnum 0
  let partition-list []
  (foreach prob-list [ this-prob ->
    set accprob accprob + this-prob
    let num round (accprob * total) - accnum
    set partition-list lput num partition-list
    set accnum accnum + num
  ])
  if accnum != total [
    set partition-list replace-item (length partition-list - 1) partition-list (last partition-list + total - accnum)
  ]
  report partition-list
end

to setup-people-color
  set agent-type-color-map table:make
  table:put agent-type-color-map 0 5.0
  table:put agent-type-color-map 1 15.0
  table:put agent-type-color-map 2 25.0
  table:put agent-type-color-map 3 35.0
  table:put agent-type-color-map 4 45.0
  table:put agent-type-color-map 5 55.0
  table:put agent-type-color-map 6 65.0
  table:put agent-type-color-map 7 75.0
  table:put agent-type-color-map 8 85.0
  table:put agent-type-color-map 9 95.0
  table:put agent-type-color-map 10 105.0
  table:put agent-type-color-map 11 115.0
  table:put agent-type-color-map 12 125.0
  table:put agent-type-color-map 13 135.0
  table:put agent-type-color-map 14 0.0
  table:put agent-type-color-map 15 43.0
  show-people-color-legend
end

to show-people-color-legend
  let left-up-x 0 - max-pxcor
  let left-up-y max-pycor
  foreach n-values 16 [i -> i] [i ->
    let dual-race-sex-age parsed-type i
    let text (word "type " i "-- dual: " item 0 dual-race-sex-age " race: " item 1 dual-race-sex-age " gender: " item 2 dual-race-sex-age " age: " item 3 dual-race-sex-age)
    let textpatch-x left-up-x + (int(0 / 8) * 30 + 25)
    let textpatch-y left-up-y - ((i mod 16) * 2 + 1)
    ask patch textpatch-x textpatch-y [
      set plabel text
      set plabel-color table:get agent-type-color-map i
    ]
    create-turtles 1 [
      set color table:get agent-type-color-map i
      set heading 0
      setxy textpatch-x + 1 textpatch-y
    ]
  ]
end

to generate-people
  ; pop-ratio-each-type => key : type value : ratio
  let type-list table:keys pop-ratio-each-type
  let type-ratio-list table:values pop-ratio-each-type
  let partition-list partition-under-prob num-agents type-ratio-list
  set num-each-type table:make
  (foreach type-list partition-list [ [this-type this-type-partition] ->
    ; pop-ratio-CD-in-each-type => key type  value: [ [CDs] [ratios] ]
    table:put num-each-type this-type this-type-partition
    let this-color table:get agent-type-color-map this-type ; add color
    let CD-list item 0 table:get pop-ratio-CD-in-each-type this-type
    let CD-ratio-list item 1 table:get pop-ratio-CD-in-each-type this-type
    let this-partition-list partition-under-prob this-type-partition CD-ratio-list
    (foreach CD-list this-partition-list [ [this-CD this-partition] ->
      create-people this-partition[
        set agent-type this-type
        set boroCD this-CD
        set color this-color ; add color
        move-to one-of patches with [mapping-boroCD = [boroCD] of myself]
        setxy xcor + (random-float 1) - 0.5 ycor + (random-float 1) - 0.5
      ]
    ])
  ])
end

;-----------------------------------------------------------setup attributes to people-------------------------------------------------------------------
to-report random-choice-under-prob [choice-list prob-list]
  let dice random-float 1
  let accprob 0
  (foreach choice-list prob-list [ [this-choice this-prob] ->
    set accprob accprob + this-prob
    if dice < accprob [
      report this-choice
    ]
  ])
  report last choice-list
end

to parse-type [this-agent-type]
  ;set agent-type (age + 2 * gender + 4 * race + 8 * dual-eligible)
  set dual-eligible bitwise-and this-agent-type 8
  set race bitwise-and this-agent-type 4
  set gender bitwise-and this-agent-type 2
  set age bitwise-and this-agent-type 1
end

to-report parsed-type [this-agent-type]
  let this-dual-eligible bitwise-and this-agent-type 8
  let this-race bitwise-and this-agent-type 4
  let this-gender bitwise-and this-agent-type 2
  let this-age bitwise-and this-agent-type 1
  report (list this-dual-eligible this-race this-gender this-age)
end

to-report bitwise-and [num digit]
  report int (num / digit) mod 2
end

to setup-attr-to-people
  ;nhats-ratio-each-type => key : [type attrname] value: [[value1 value2 ....] [ratio1 ratio2]]
  foreach table:keys pop-ratio-each-type [ this-type ->
    let attr-dict table:make
    foreach nhats-attr-names [this-attr ->
      table:put attr-dict this-attr (table:get nhats-ratio-each-type (list this-type this-attr))
    ]
    ask people with [agent-type = this-type][
      parse-type agent-type
      foreach nhats-indep-attrs [this-attr ->
        let the-choice random-choice-under-prob (item 0 table:get attr-dict this-attr) (item 1 table:get attr-dict this-attr)
        run (word "set " this-attr " " the-choice)
      ]
      (foreach table:keys nhats-indep-dep-attrs table:values nhats-indep-dep-attrs [[this-indep-attr this-dep-attr] ->
        let this-indep-attr-val runresult this-indep-attr
        let this-dep-attr-val table:get (table:get nhats-indep-dep-attrs-mapping this-dep-attr) this-indep-attr-val
        run (word "set " this-dep-attr " " this-dep-attr-val)
      ])
    ]
  ]

end

;----------------------------------------------------------- setup other variables related to people--------------------------------------------------------------------
to setup-other-var-of-people
  ask people [
    set in-hosp false
    let potential-interval table:get decision-intervals agent-type
    set next-decision random-choice-under-prob (table:keys potential-interval) (table:values potential-interval)
    set decisions-record [0 0]
    set decision-type 0
  ]
end

to setup-stats
  set each-decision-each-type table:make
  set total-decisions-each-type table:make
  set num-in-hosp-each-day []
  foreach table:keys pop-ratio-each-type [this-type ->
    table:put total-decisions-each-type this-type 0
    table:put each-decision-each-type this-type [0 0]
  ]
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------------------Display map-----------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to overview-one-CD
  let mouse-is-down? mouse-down?
  if mouse-clicked? [
    cancel-last-chosen
    create-new-chosen
  ]
  set mouse-was-down? mouse-is-down?
end

to cancel-last-chosen
  if any? chosen-CDs[
    ask chosen-CDs[
      stop-inspecting nyCD CD-id
      ask nyCD CD-id[
        let last-CD gis:find-one-feature nyCDs-dataset "BOROCD" (word boroCD)
        let this-borough int (boroCD / 100)
        let this-borough-color table:get borough-color this-borough
        gis:set-drawing-color this-borough-color
        gis:fill last-CD  1.0
        gis:set-drawing-color map-line-color
        gis:draw last-CD 1.0
      ]
      if heatmap-flag [
        show-heatmap-oneCD CD-id boroCD
      ]
      die
    ]
  ]
end

to create-new-chosen
  create-chosen-CDs 1[
    ht
    setxy mouse-xcor mouse-ycor
    let distance-nearby []
    let CDs-nearby []
    ask nyCDs in-radius 3 [
      set distance-nearby fput distancexy mouse-xcor mouse-ycor distance-nearby
      set CDs-nearby fput who CDs-nearby
    ]
    if not empty? distance-nearby[
      set CD-id item position min distance-nearby distance-nearby CDs-nearby
      set boroCD [boroCD] of nyCD CD-id
      ask nyCD CD-id[
        inspect self
      ]
      let this-CD gis:find-one-feature nyCDs-dataset "BOROCD" (word boroCD)
      gis:set-drawing-color map-highlight-color
      gis:fill this-CD  1.0
    ]
  ]
end

to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

to test-draw-different-borough
  gis:set-drawing-color white
  foreach gis:find-range nyCDs-dataset "BOROCD" 200 300 [one-block ->
  gis:draw one-block 1.0]
end

to show-heatmap
  clear-map
  check-min-max-val
  set heatmap-flag true
  ;show runresult (word "[" heatmap-info "] of census-tract 10")
  ;gis:property-value one-block "BOROCD"
  ;table:values boroCD-CDs
  (foreach (gis:feature-list-of nyCDs-dataset)  [ one-block ->
    let val [runresult heatmap-info] of nycd table:get boroCD-CDs gis:property-value one-block "BOROCD"
    if val != ""[
      gis:set-drawing-color scale-color heatmap-color val minval maxval
      gis:fill one-block 1.0
    ]
  ])
end

to show-heatmap-oneCD [CDid this-boroCD]
  let val [runresult heatmap-info] of nycd CDid
    if val != ""[
      gis:set-drawing-color scale-color heatmap-color val minval maxval
      gis:fill gis:find-one-feature nyCDs-dataset "BOROCD" (word boroCD) 1.0
    ]
end


to clear-map
   set heatmap-flag false
   foreach gis:feature-list-of nyCDs-dataset[ one-block ->
    let this-borough int ((gis:property-value one-block "BOROCD") / 100)
    let this-borough-color table:get borough-color this-borough
    gis:set-drawing-color this-borough-color
    gis:fill one-block  1.0
    gis:set-drawing-color map-line-color
    gis:draw one-block 1.0
  ]
end

to check-min-max-val
  set maxval runresult (word "max [" heatmap-info "] of nyCDs")
  set minval runresult (word "min [" heatmap-info "] of nyCDs")
end

to set-chosen-info
  ask nyCDs [
    set chosen-info runresult heatmap-info
  ]
end

to show-3D-info-map
  check-min-max-val
  set-chosen-info
  let bottom-bound 0
  let up-bound 30
  let a (up-bound - bottom-bound) / (maxval - minval )
  let b bottom-bound - a * minval
  view2.5d:turtle-view view-name nyCDs with [chosen-info != ""]  [the-cd -> round ([chosen-info] of the-cd * a + b)]
  ;run (word "view2.5d:turtle-view view-name census-tracts [the-tract -> [" heatmap-info "] of the-tract]")
  ;view2.5d:set-z-scale view-name 1 / maxval * 30
  view2.5d:set-turtle-stem-thickness view-name 1
end

to adjust-3D-info-map
  view2.5d:set-observer-distance view-name 86
  view2.5d:set-observer-angles view-name 0 30
end

to-report view-name
  report "info map"
end

;--------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------Model Pipeline---------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to go
  make-decision
  update-global-var
  update-graphs
  tick
end

;---------------------------------------------------------------Decision making--------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------
to make-decision
  foreach table:keys pop-ratio-each-type [this-type ->
    let consider-social (table:get total-decisions-each-type this-type) > 0
    let prob-hosp-after-er item 0 table:get prob-hosp-after-decision this-type
    let prob-hosp-after-off-cl item 1 table:get prob-hosp-after-decision this-type
    let social-norm_er 0
    let social-norm_off-cl 0
    if consider-social
    [
      set social-norm_er (item 0 table:get each-decision-each-type this-type) / (table:get total-decisions-each-type this-type)
      set social-norm_off-cl (item 1 table:get each-decision-each-type this-type) / (table:get total-decisions-each-type this-type)
    ]
    set wa_er item 0 table:get weights (list this-type "ER")
    set ws_er item 1 table:get weights (list this-type "ER")
    set we_er item 2 table:get weights (list this-type "ER")
    set wa_off-cl item 0 table:get weights (list this-type "Office")
    set ws_off-cl item 1 table:get weights (list this-type "Office")
    set we_off-cl item 2 table:get weights (list this-type "Office")

    let new-decisions_er 0
    let new-decisions_off-cl 0
    ask people with [agent-type = this-type][
      set last-update-attr last-update-attr + 1
      ifelse in-hosp
      [action-in-hosp]
      [
        set next-decision next-decision - 1
        if next-decision <= 0 [
          if last-update-attr >= attr-update-freq
          [
            set last-update-attr 0
            update-attrs
          ]
          let potential-interval table:get decision-intervals agent-type
          set next-decision random-choice-under-prob (table:keys potential-interval) (table:values potential-interval)

          set attitude_er  w_wfwt_er * want-find-way-to + w_fc_er * feel-cheerful - w_fb_er * feel-bored + w_ffol_er * feel-full-of-life - w_fu_er * feel-upset
          set motivation_er w_keo_er * know-each-other + w_wheo_er * willing-help-each-other + w_cbt_er * can-be-trusted - w_sd_er * self-determin + w_atc_er * adjust-to-change - w_noto_er * no-one-talk-to
          set efficacy_er w_inc_er * income + w_edu_er * education
          set attitude_er (attitude_er * aa + ba)
          set motivation_er (motivation_er * as + bs)
          set efficacy_er (efficacy_er * ae + be)
          set intention_er wa_er * attitude_er +  ws_er * social-norm_er * motivation_er + we_er * efficacy_er

          set attitude_off-cl  w_wfwt_off-cl * want-find-way-to + w_fc_off-cl * feel-cheerful - w_fb_off-cl * feel-bored + w_ffol_off-cl * feel-full-of-life - w_fu_off-cl * feel-upset
          set motivation_off-cl w_keo_off-cl * know-each-other + w_wheo_off-cl * willing-help-each-other + w_cbt_off-cl * can-be-trusted - w_sd_off-cl * self-determin + w_atc_off-cl * adjust-to-change - w_noto_off-cl * no-one-talk-to
          set efficacy_off-cl w_inc_off-cl * income + w_edu_off-cl * education
          set attitude_off-cl (attitude_off-cl * aa + ba)
          set motivation_off-cl (motivation_off-cl * as + bs)
          set efficacy_off-cl (efficacy_off-cl * ae + be)
          set intention_off-cl wa_off-cl * attitude_off-cl + ws_off-cl * social-norm_off-cl * motivation_off-cl + we_off-cl * efficacy_off-cl

          let max-intention max (list intention_er intention_off-cl)
          ifelse max-intention = intention_off-cl
          [
            ifelse max-intention != intention_er
            [
              set new-decisions_off-cl new-decisions_off-cl + 1
              set decisions-record replace-item 1 decisions-record (item 1 decisions-record + 1)
              let dice random-float 1
              ifelse dice < prob-hosp-after-off-cl
              [go-to-hosp]
              []
            ]
            [
              let dice random-float 1
              ifelse dice < 0.5
              [
                set new-decisions_er new-decisions_er + 1
                set decisions-record replace-item 0 decisions-record (item 0 decisions-record + 1)
                let dice1 random-float 1
                ifelse dice1 < prob-hosp-after-er
                [go-to-hosp]
                []
              ]
              [
                set new-decisions_off-cl new-decisions_off-cl + 1
                set decisions-record replace-item 1 decisions-record (item 1 decisions-record + 1)
                let dice1 random-float 1
                ifelse dice1 < prob-hosp-after-off-cl
                [go-to-hosp]
                []
              ]
            ]
          ]
          [
            set new-decisions_er new-decisions_er + 1
            set decisions-record replace-item 0 decisions-record (item 0 decisions-record + 1)
            let dice random-float 1
            ifelse dice < prob-hosp-after-er
            [go-to-hosp]
            []
          ]
        ]
      ]
      ifelse item 0 decisions-record != 0
      [
        ifelse item 1 decisions-record != 0
        [set decision-type 3]
        [set decision-type 1]
      ]
      [
        if item 1 decisions-record != 0
        [set decision-type 2]
      ]
    ]
    update-stats this-type new-decisions_er new-decisions_off-cl
  ]
end

to go-to-hosp
  set in-hosp true
  set hospitalization hospitalization + 1
  let potential-los table:get last-of-stay agent-type
  set los random-choice-under-prob (table:keys potential-los) (table:values potential-los)
end

to action-in-hosp
  set days-in-hosp days-in-hosp + 1
  set los los - 1
  if los <= 0 [set in-hosp false]
end

to update-attrs
  foreach nhats-indep-attrs [this-attr ->
    let the-choice random-choice-under-prob (item 0 (table:get nhats-ratio-each-type (list agent-type this-attr)) ) (item 1 (table:get nhats-ratio-each-type (list agent-type this-attr)) )
    run (word "set " this-attr " " the-choice)
  ]
  (foreach table:keys nhats-indep-dep-attrs table:values nhats-indep-dep-attrs [[this-indep-attr this-dep-attr] ->
    let this-indep-attr-val runresult this-indep-attr
    let this-dep-attr-val table:get (table:get nhats-indep-dep-attrs-mapping this-dep-attr) this-indep-attr-val
    run (word "set " this-dep-attr " " this-dep-attr-val)
  ])
end

to update-stats [this-type new-decisions_er new-decisions_off-cl]
  let updated-decisions (list ((item 0 table:get each-decision-each-type this-type) + new-decisions_er) ((item 1 table:get each-decision-each-type this-type) + new-decisions_off-cl))
  table:put each-decision-each-type this-type updated-decisions
  table:put total-decisions-each-type this-type (table:get total-decisions-each-type this-type + new-decisions_er + new-decisions_off-cl)
end

;------------------------------------------------------------Update global variables---------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

to update-global-var
  set day day + 1
  set num-in-hosp-each-day lput count people with [in-hosp = true] num-in-hosp-each-day
  if day > 365
  [
    set day  (day mod 365)
    set year year + 1
  ]
end

;------------------------------------------------------------Update graphs---------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

to update-graphs

end
@#$#@#$#@
GRAPHICS-WINDOW
327
10
1121
805
-1
-1
7.7822
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
9
10
64
97
Setup All
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

BUTTON
6
442
320
501
Overview 0ne Community District
overview-one-CD
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
9
509
318
554
heatmap-info
heatmap-info
"trans_num" "pct_res" "pct_parks" "pct_white" "pct_over65" "pct_rent_burd" "pct_served_parks" "pct_clean_strts" "crime" "pct_unemployment" "pct_poverty" "parks_num" "hosp_clinic_num" "pop_dens" "pct_non_res"
4

BUTTON
7
562
116
617
Show Heatmap
show-heatmap\n
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
119
562
213
617
Clear Heat Map
clear-map\n
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
219
562
320
617
3D Visualization
show-3D-info-map\nwait 0.2\nadjust-3D-info-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
9
104
164
164
num-agents
5000.0
1
0
Number

PLOT
1131
12
1623
173
number of each type of people
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 0 16\nset-histogram-num-bars 16" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [agent-type] of people"

PLOT
1129
250
1629
701
each decision type
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"no-choice" 1.0 0 -16777216 true "" "plot count people with [decision-type = 0]"
"ER-only" 1.0 0 -7500403 true "" "plot count people with [decision-type = 1]"
"Office" 1.0 0 -2674135 true "" "plot count people with [decision-type = 2]"
"Mix" 1.0 0 -955883 true "" "plot count people with [decision-type = 3]"

BUTTON
186
105
320
164
GO
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

SWITCH
8
301
184
334
social-influence-decay?
social-influence-decay?
1
1
-1000

INPUTBOX
188
301
321
361
decay-factor
0.0
1
0
Number

INPUTBOX
11
836
166
896
w_wfwt_er
1.0
1
0
Number

INPUTBOX
167
836
322
896
w_fc_er
1.0
1
0
Number

INPUTBOX
323
836
478
896
w_fb_er
1.0
1
0
Number

INPUTBOX
479
836
634
896
w_ffol_er
1.0
1
0
Number

INPUTBOX
635
836
790
896
w_fu_er
1.0
1
0
Number

INPUTBOX
810
836
965
896
w_keo_er
1.0
1
0
Number

INPUTBOX
966
836
1121
896
w_wheo_er
1.0
1
0
Number

INPUTBOX
1122
836
1277
896
w_cbt_er
1.0
1
0
Number

INPUTBOX
1278
836
1433
896
w_sd_er
1.0
1
0
Number

INPUTBOX
1434
836
1589
896
w_atc_er
1.0
1
0
Number

INPUTBOX
1766
837
1921
897
w_inc_er
1.0
1
0
Number

INPUTBOX
1922
837
2077
897
w_edu_er
1.0
1
0
Number

INPUTBOX
2098
837
2253
897
wa_er
1.0
1
0
Number

INPUTBOX
2254
837
2409
897
ws_er
1.0
1
0
Number

INPUTBOX
2411
837
2566
897
we_er
1.0
1
0
Number

INPUTBOX
11
926
166
986
w_wfwt_off-cl
1.0
1
0
Number

INPUTBOX
167
926
322
986
w_fc_off-cl
1.0
1
0
Number

INPUTBOX
323
926
478
986
w_fb_off-cl
1.0
1
0
Number

INPUTBOX
479
926
634
986
w_ffol_off-cl
1.0
1
0
Number

INPUTBOX
635
926
790
986
w_fu_off-cl
1.0
1
0
Number

INPUTBOX
810
926
965
986
w_keo_off-cl
1.0
1
0
Number

INPUTBOX
966
926
1121
986
w_wheo_off-cl
1.0
1
0
Number

INPUTBOX
1122
926
1277
986
w_cbt_off-cl
1.0
1
0
Number

INPUTBOX
1278
926
1433
986
w_sd_off-cl
1.0
1
0
Number

INPUTBOX
1434
926
1589
986
w_atc_off-cl
1.0
1
0
Number

INPUTBOX
1766
927
1921
987
w_inc_off-cl
1.0
1
0
Number

INPUTBOX
1922
927
2077
987
w_edu_off-cl
1.0
1
0
Number

INPUTBOX
2098
927
2253
987
wa_off-cl
0.0
1
0
Number

INPUTBOX
2254
927
2409
987
ws_off-cl
0.0
1
0
Number

INPUTBOX
2411
927
2566
987
we_off-cl
0.0
1
0
Number

INPUTBOX
7
371
161
431
total_sample
0.0
1
0
Number

BUTTON
10
628
321
661
NIL
test
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
1590
836
1745
896
w_noto_er
1.0
1
0
Number

INPUTBOX
1590
926
1745
986
w_noto_off-cl
1.0
1
0
Number

INPUTBOX
7
236
162
296
start-year
2008.0
1
0
Number

INPUTBOX
8
171
164
231
steps
365.0
1
0
Number

BUTTON
186
170
321
232
Go Steps
set current-tick ticks\nwhile [ticks < current-tick + steps]\n[go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1129
184
1191
241
Year
year
17
1
14

MONITOR
1193
183
1259
240
Day
day
17
1
14

PLOT
1630
10
2135
390
people in hospital
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
"default" 1.0 0 -16777216 true "" "plot count people with [in-hosp = true]"

INPUTBOX
170
237
321
297
attr-update-freq
14.0
1
0
Number

PLOT
1631
396
2137
803
distribution of days with inhospital patients
in-hospital people number
count of days
0.0
100.0
0.0
100.0
true
false
"" "set-plot-x-range 0 ( (max num-in-hosp-each-day) + 1)"
PENS
"default" 1.0 1 -2674135 true "" "histogram num-in-hosp-each-day"

BUTTON
94
10
230
53
Setup Environment
setup-CD\nsetup-var\nreset-ticks
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
265
10
320
98
Clear All
clear-all
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
94
59
231
98
Setup Agents
setup-people\nreset-ticks
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
168
370
320
430
Load Weights
load-weights
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1628
10
2236
673
ER
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"type 0" 1.0 0 -16777216 true "" "plot count people with [decision-type = 1 and agent-type = 0]"
"type 1" 1.0 0 -7500403 true "" "plot count people with [decision-type = 1 and agent-type = 1]"
"type 2" 1.0 0 -2674135 true "" "plot count people with [decision-type = 1 and agent-type = 2]"
"type 3" 1.0 0 -955883 true "" "plot count people with [decision-type = 1 and agent-type = 3]"
"type 4" 1.0 0 -6459832 true "" "plot count people with [decision-type = 1 and agent-type = 4]"
"type 5" 1.0 0 -1184463 true "" "plot count people with [decision-type = 1 and agent-type = 5]"
"type 6" 1.0 0 -10899396 true "" "plot count people with [decision-type = 1 and agent-type = 6]"
"type 7" 1.0 0 -13840069 true "" "plot count people with [decision-type = 1 and agent-type = 7]"
"type 8" 1.0 0 -14835848 true "" "plot count people with [decision-type = 1 and agent-type = 8]"
"type 9" 1.0 0 -11221820 true "" "plot count people with [decision-type = 1 and agent-type = 9]"
"type 10" 1.0 0 -13791810 true "" "plot count people with [decision-type = 1 and agent-type = 10]"
"type 11" 1.0 0 -13345367 true "" "plot count people with [decision-type = 1 and agent-type = 11]"
"type 12" 1.0 0 -8630108 true "" "plot count people with [decision-type = 1 and agent-type = 12]"
"type 13" 1.0 0 -5825686 true "" "plot count people with [decision-type = 1 and agent-type = 13]"
"type 14" 1.0 0 -2064490 true "" "plot count people with [decision-type = 1 and agent-type = 14]"
"type 15" 1.0 0 -408670 true "" "plot count people with [decision-type = 1 and agent-type = 15]"

PLOT
2243
10
2849
672
Office and Clinics
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"type 0" 1.0 0 -16777216 true "" "plot count people with [decision-type = 2 and agent-type = 0]"
"type 1" 1.0 0 -7500403 true "" "plot count people with [decision-type = 2 and agent-type = 1]"
"type 2" 1.0 0 -2674135 true "" "plot count people with [decision-type = 2 and agent-type = 2]"
"type 3" 1.0 0 -955883 true "" "plot count people with [decision-type = 2 and agent-type = 3]"
"type 4" 1.0 0 -6459832 true "" "plot count people with [decision-type = 2 and agent-type = 4]"
"type 5" 1.0 0 -1184463 true "" "plot count people with [decision-type = 2 and agent-type = 5]"
"type 6" 1.0 0 -10899396 true "" "plot count people with [decision-type = 2 and agent-type = 6]"
"type 7" 1.0 0 -13840069 true "" "plot count people with [decision-type = 2 and agent-type = 7]"
"type 8" 1.0 0 -14835848 true "" "plot count people with [decision-type = 2 and agent-type = 8]"
"type 9" 1.0 0 -11221820 true "" "plot count people with [decision-type = 2 and agent-type = 9]"
"type 10" 1.0 0 -13791810 true "" "plot count people with [decision-type = 2 and agent-type = 10]"
"type 11" 1.0 0 -13345367 true "" "plot count people with [decision-type = 2 and agent-type = 11]"
"type 12" 1.0 0 -8630108 true "" "plot count people with [decision-type = 2 and agent-type = 12]"
"type 13" 1.0 0 -5825686 true "" "plot count people with [decision-type = 2 and agent-type = 13]"
"type 14" 1.0 0 -2064490 true "" "plot count people with [decision-type = 2 and agent-type = 14]"
"type 15" 1.0 0 -408670 true "" "plot count people with [decision-type = 2 and agent-type = 15]"

PLOT
2855
10
3468
674
Mixture
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"type 0" 1.0 0 -16777216 true "" "plot count people with [decision-type = 3 and agent-type = 0]"
"type 1" 1.0 0 -7500403 true "" "plot count people with [decision-type = 3 and agent-type = 1]"
"type 2" 1.0 0 -2674135 true "" "plot count people with [decision-type = 3 and agent-type = 2]"
"type 3" 1.0 0 -955883 true "" "plot count people with [decision-type = 3 and agent-type = 3]"
"type 4" 1.0 0 -6459832 true "" "plot count people with [decision-type = 3 and agent-type = 4]"
"type 5" 1.0 0 -1184463 true "" "plot count people with [decision-type = 3 and agent-type = 5]"
"type 6" 1.0 0 -10899396 true "" "plot count people with [decision-type = 3 and agent-type = 6]"
"type 7" 1.0 0 -13840069 true "" "plot count people with [decision-type = 3 and agent-type = 7]"
"type 8" 1.0 0 -14835848 true "" "plot count people with [decision-type = 3 and agent-type = 8]"
"type 9" 1.0 0 -11221820 true "" "plot count people with [decision-type = 3 and agent-type = 9]"
"type 10" 1.0 0 -13791810 true "" "plot count people with [decision-type = 3 and agent-type = 10]"
"type 11" 1.0 0 -13345367 true "" "plot count people with [decision-type = 3 and agent-type = 11]"
"type 12" 1.0 0 -8630108 true "" "plot count people with [decision-type = 3 and agent-type = 12]"
"type 13" 1.0 0 -5825686 true "" "plot count people with [decision-type = 3 and agent-type = 13]"
"type 14" 1.0 0 -2064490 true "" "plot count people with [decision-type = 3 and agent-type = 14]"
"type 15" 1.0 0 -408670 true "" "plot count people with [decision-type = 3 and agent-type = 15]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

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
NetLogo 6.0.4
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
