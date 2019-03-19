extensions [gis view2.5d csv]

globals [
  ;var used for environment display
  mouse-was-down?
  nyCDs-dataset
  mouse-was-clicked?
  map-block-color
  map-line-color
  map-highlight-color
  heatmap-color
  id-CDs
  boroCD-CDs
  maxval
  minval
  ;var used for model
  num-each-type
  num-er-each-type
  num-off-cl-each-type
  num-stay-each-type
  num-decisions-each-type
  max-dens
  weights-attitude
  weights-social-norm
  EM-cost-edu-transreq-effect
  ER-cost-edu-transreq-effect
  Hospital-cost-edu-transreq-effect
  SNF-cost-edu-transreq-effect
  Homecare-cost-edu-transreq-effect
  prob-hosp-after-er
  prob-hosp-after-office-clinic
]

breed[nyCDs nyCD]
breed[chosen-CDs chosen-CD]
breed[people person]

patches-own[
  mapping-boroCD
]

people-own[
  boroCD
  boroCD-id
  age ;0: above 75, 1: 75 and below
  gender ;0:female, 1:male
  race ;0: non-white, 1: white
  dual-eligible ;0: no, 1: yes
  agent-type
  ;attitude
  want-find-way-to
  feel-cheerful
  feel-bored
  feel-full-of-life
  feel-upset
  depression;0: no depression, 1: have depression
  ;social norm
  self-determin
  have-caregiver
  know-each-other
  willing-help-each-other
  can-be-trusted
  ; efficacy
  income
  education
  ;state var
  los
  state
  get-treatment
  choice ;0: stay at home, 1: er, 2: office-clinics
  severity
  choice-record ; [stay-at-home er office-clinics]
  hospitalization ; num of hospitalization
  next-decision

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
  ;CTLABEL
  ;BORONAME
  ;CT2000
  ;BOROCT2000
  ;CDELIGIBIL
  ;NTACODE
  ;NTANAME
  ;PUMA
  ;SHAPE_LENG
  ;SHAPE_AREA
  ;population-density
  ;poverty-rate
  ;unemployment
  ;bus-density
  ;sub-density
  ;sub-access
  ;intersection-access
  ;landuse-index
  ;tax-non-tax-residence-use-use
  ;tax-residence-use
  ;prop-transportation-to-work
  ;prop-walk-to-work
  ;prop-over65
  ;prop-nonwhite
  ;boro-code-num
  ;precinct-population
  ;precinct
  ;offense-per-capita
  ;num_er_08
  ;er_charges_08
  ;num_er_09
  ;er_charges_09
  ;num_er_10
  ;er_charges_10
  ;tot_er_pats
  ;tot_er_charges
  ;num_pat_08
  ;charges_08
  ;num_pat_09
  ;charges_09
  ;num_pat_10
  ;charges_10
  ;tot_pats
  ;tot_charges
  ;num_high_utils_08
  ;num_high_utils_09
  ;num_high_utils_10
]

chosen-CDs-own[
  boroCD
  CD-id
]

to setup
  ca
  stop-inspecting-dead-agents
  load-CDs
  load-CDs-shape
  load-CDs-info
  ;load-CMS-info
  map-patches
  generate-people
  setup-var
  reset-ticks
end

to load-CDs
  let prj-filepath  "nycd\\nycd.prj"
  let shp-filepath  "nycd\\nycd.shp"
  gis:load-coordinate-system prj-filepath
  set nyCDs-dataset gis:load-dataset shp-filepath
  gis:set-world-envelope gis:envelope-of nyCDs-dataset
  set map-block-color black
  set map-line-color white
  set map-highlight-color red
  set heatmap-color blue
end

to load-CDs-shape
  set id-CDs []
  set boroCD-CDs []
  foreach gis:feature-list-of nyCDs-dataset[ one-block ->
    gis:set-drawing-color map-line-color
    gis:draw one-block 1.0
    let centroid gis:location-of gis:centroid-of one-block
    ask patch first centroid last centroid [
      sprout-nyCDs 1[
        ht
        set shape "star"
        ;set CTLABEL gis:property-value one-block "CTLABEL"
        ;set BOROCODE gis:property-value one-block "BOROCODE"
        ;set BORONAME gis:property-value one-block "BORONAME"
        set boroCD gis:property-value one-block "BOROCD"
        ;set BOROCT2000 read-from-string gis:property-value one-block "BOROCT2000"
        ;set CDELIGIBIL gis:property-value one-block "CDELIGIBIL"
        ;set NTACODE gis:property-value one-block "NTACODE"
        ;set NTANAME gis:property-value one-block "NTANAME"
        ;set PUMA gis:property-value one-block "PUMA"
        ;set SHAPE_LENG gis:property-value one-block "SHAPE_LENG"
        ;set SHAPE_AREA gis:property-value one-block "SHAPE_AREA"
        setxy first centroid last centroid
        set id-CDs lput who id-CDs
        set boroCD-CDs lput boroCD boroCD-CDs
      ]
    ]
  ]
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

to generate-people
  let pos position 104 boroCD-CDs
  let x-y-cor [list xcor ycor] of nyCD item pos id-CDs
  create-people num-agents[
    set boroCD 104
    set boroCD-id item pos id-CDs
    set age random 2
    set gender random 2
    set race random 2
    set agent-type (age + 2 * gender + 4 * race)
    set want-find-way-to random 3 - 1
    set feel-cheerful random 5 - 2
    set feel-bored random 5 - 2
    set feel-full-of-life random 5 - 2
    set feel-upset random 5 - 2
    set depression random 2
    set self-determin random 3 - 1
    set have-caregiver random 2
    set know-each-other random 3 - 1
    set willing-help-each-other random 3 - 1
    set can-be-trusted random 3 - 1
    setxy item 0 x-y-cor item 1 x-y-cor
    set severity random 3 + 1
    set income random 3 + 1
    set education random 9 + 1
    move-to one-of patches with [mapping-boroCD = [boroCD] of myself]
    setxy xcor + (random-float 1) - 0.5 ycor + (random-float 1) - 0.5
  ]
end

to setup-var
  set max-dens max [pop_dens] of nyCDs
  set num-each-type []
  foreach n-values 8 [i -> i] [i ->
    set num-each-type lput (count people with [agent-type = i]) num-each-type
  ]
  set num-er-each-type n-values 16 [0]
  set num-off-cl-each-type n-values 16 [0]
  set num-stay-each-type n-values 16 [0]
  set num-decisions-each-type n-values 16 [0]
  set EM-cost-edu-transreq-effect (list 5 4 4 1)
  set ER-cost-edu-transreq-effect (list 2 1 2 4)
  set Hospital-cost-edu-transreq-effect (list 1 5 1 5)
  set SNF-cost-edu-transreq-effect (list 4 3 3 3)
  set Homecare-cost-edu-transreq-effect (list 3 2 5 2)
end

to go
  make-decision
  ;update-var
  tick
end

to make-decision
  foreach n-values 16 [i -> i] [ i ->
    let social-norm_er item i num-er-each-type  / item i num-decisions-each-type
    let social-norm_off-cl item i num-off-cl-each-type  / item i num-decisions-each-type
    let social-norm_stay item i num-stay-each-type  / item i num-decisions-each-type
    ask people with [agent-type = i][
      set next-decision next-decision - 1
      if next-decision <= 0
      [

        set num-decisions-each-type replace-item i num-decisions-each-type (item i num-decisions-each-type + 1)
        let attitude_er  w_wfwt_er * want-find-way-to + w_fc_er * feel-cheerful - w_fb_er * feel-bored + w_ffol_er * feel-full-of-life - w_fu_er * feel-upset
        let motivation_er w_keo_er * know-each-other + w_wheo_er * willing-help-each-other + w_cbt_er * can-be-trusted - w_sd_er * self-determin + w_hc_er * have-caregiver
        let efficacy_er w_inc_er * income + w_edu_er * education + w_trans_er * [trans_num] of nyCD borocd-id
        let intension_er wa_er * attitude_er + ws_er * social-norm_er * motivation_er + we_er * efficacy_er

        let attitude_off-cl  w_wfwt_off-cl * want-find-way-to + w_fc_off-cl * feel-cheerful - w_fb_off-cl * feel-bored + w_ffol_off-cl * feel-full-of-life - w_fu_off-cl * feel-upset
        let motivation_off-cl w_keo_off-cl * know-each-other + w_wheo_off-cl * willing-help-each-other + w_cbt_off-cl * can-be-trusted - w_sd_off-cl * self-determin + w_hc_off-cl * have-caregiver
        let efficacy_off-cl w_inc_off-cl * income + w_edu_off-cl * education + w_trans_off-cl * [trans_num] of nyCD borocd-id
        let intension_off-cl wa_off-cl * attitude_off-cl + ws_off-cl * social-norm_off-cl * motivation_off-cl + we_off-cl * efficacy_off-cl

        let attitude_stay  w_wfwt_stay * want-find-way-to + w_fc_stay * feel-cheerful - w_fb_stay * feel-bored + w_ffol_stay * feel-full-of-life - w_fu_stay * feel-upset
        let motivation_stay w_keo_stay * know-each-other + w_wheo_stay * willing-help-each-other + w_cbt_stay * can-be-trusted - w_sd_stay * self-determin + w_hc_stay * have-caregiver
        let efficacy_stay w_inc_stay * income + w_edu_stay * education + w_trans_stay * [trans_num] of nyCD borocd-id
        let intension_stay wa_stay * attitude_stay + ws_stay * social-norm_stay * motivation_stay + we_stay * efficacy_stay

        let max-intension max (list intension_er intension_off-cl intension_stay wa_stay)

        ifelse max-intension = intension_stay
        [
          set choice 0
          set state 13
          set num-stay-each-type replace-item i num-stay-each-type (item i num-stay-each-type + 1)
        ]
        [
          ifelse max-intension = intension_er
          [
            set num-er-each-type replace-item i num-er-each-type (item i num-er-each-type + 1)
            set choice 1
            let rand random 100
            if rand < prob-hosp-after-er
            [hospitalize]
          ]
          [
            set num-off-cl-each-type replace-item i num-stay-each-type (item i num-off-cl-each-type + 1)
            set choice 2
            let rand random 100
            if rand < prob-hosp-after-office-clinic
            [hospitalize]
          ]
        ]
        set next-decision random 7
      ]
    ]
  ]
end

to hospitalize
end

to update-var
  foreach n-values 16 [i -> i] [ i ->
;    set num-stay-each-type replace-item i num-stay-each-type count people with [agent-type = i and choice = 0]
;    set num-er-each-type replace-item i num-er-each-type count people with [agent-type = i and choice = 1]
;    set num-off-cl-each-type replace-item i num-off-cl-each-type count people with [agent-type = i and choice = 2]


  ]
end

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
        gis:set-drawing-color map-block-color
        gis:fill last-CD  1.0
        gis:set-drawing-color map-line-color
        gis:draw last-CD 1.0
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


;to test
;  view2.5d:turtle-view "Test" census-tracts [the-tract -> [CT2000] of the-tract]
;end

to-report mouse-clicked?
  report (mouse-was-down? = true and not mouse-down?)
end

to test-draw-different-brough
  gis:set-drawing-color white
  foreach gis:find-range nyCDs-dataset "BOROCD" 200 300 [one-block ->
  gis:draw one-block 1.0]
  tick
end

;to load-CMS-info
;  foreach csv:from-file "CMS_patient.csv" [row ->
;    ask census-tracts with [BOROCT2000 = item 0 row][
;      set num_er_08 item 2 row
;      set er_charges_08 item 3 row
;      set num_er_09 item 4 row
;      set er_charges_09 item 5 row
;      set num_er_10 item 6 row
;      set er_charges_10 item 7 row
;      set tot_er_pats item 8 row
;      set tot_er_charges item 9 row
;      set num_pat_08 item 10 row
;      set charges_08 item 11 row
;      set num_pat_09 item 12 row
;      set charges_09 item 13 row
;      set num_pat_10 item 14 row
;      set charges_10 item 15 row
;      set tot_pats item 16 row
;      set tot_charges item 17 row
;      set num_high_utils_08 item 18 row
;      set num_high_utils_09 item 19 row
;      set num_high_utils_10 item 20 row
;    ]
;  ]
;end


to show-heatmap
  clear-map
  check-min-max-val
  ;show runresult (word "[" heatmap-info "] of census-tract 10")
  let val 0
  (foreach (gis:feature-list-of nyCDs-dataset) id-CDs [ [one-block id] ->
    ask nycd id [set val runresult heatmap-info]
    if val != ""[
      gis:set-drawing-color scale-color heatmap-color val minval maxval
      gis:fill one-block 1.0
    ]
  ])
end

to clear-map
   foreach gis:feature-list-of nyCDs-dataset[ one-block ->
    gis:set-drawing-color map-block-color
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
20
23
125
56
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

BUTTON
138
23
277
56
NIL
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
20
64
247
109
heatmap-info
heatmap-info
"trans_num" "pct_res" "pct_parks" "pct_white" "pct_over65" "pct_rent_burd" "pct_served_parks" "pct_clean_strts" "crime" "pct_unemployment" "pct_poverty" "parks_num" "hosp_clinic_num" "pop_dens" "pct_non_res"
4

BUTTON
19
113
132
146
NIL
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
254
64
315
147
NIL
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
135
113
248
146
3D-info-map
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
19
148
174
208
num-agents
0.0
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
"set-plot-x-range 0 8\nset-histogram-num-bars 8" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [agent-type] of people"

PLOT
1130
187
1630
638
ratio of treatment of each type
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
"type0" 1.0 0 -16777216 true "" "plot (item 0 num-treatment-each-type) / (item 0 num-each-type)"
"type1" 1.0 0 -7500403 true "" "plot (item 1 num-treatment-each-type) / (item 1 num-each-type)"
"type2" 1.0 0 -2674135 true "" "plot (item 2 num-treatment-each-type) / (item 2 num-each-type)"
"type3" 1.0 0 -955883 true "" "plot (item 3 num-treatment-each-type) / (item 3 num-each-type)"
"type4" 1.0 0 -6459832 true "" "plot (item 4 num-treatment-each-type) / (item 4 num-each-type)"
"type5" 1.0 0 -1184463 true "" "plot (item 5 num-treatment-each-type) / (item 5 num-each-type)"
"type6" 1.0 0 -10899396 true "" "plot (item 6 num-treatment-each-type) / (item 6 num-each-type)"
"type7" 1.0 0 -13840069 true "" "plot (item 7 num-treatment-each-type) / (item 7 num-each-type)"

BUTTON
180
149
314
206
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

SWITCH
20
214
204
247
social-influence-decay?
social-influence-decay?
1
1
-1000

INPUTBOX
20
251
109
311
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
0.0
1
0
Number

INPUTBOX
167
836
322
896
w_fc_er
0.0
1
0
Number

INPUTBOX
323
836
478
896
w_fb_er
0.0
1
0
Number

INPUTBOX
479
836
634
896
w_ffol_er
0.0
1
0
Number

INPUTBOX
635
836
790
896
w_fu_er
0.0
1
0
Number

INPUTBOX
810
836
965
896
w_keo_er
0.0
1
0
Number

INPUTBOX
966
836
1121
896
w_wheo_er
0.0
1
0
Number

INPUTBOX
1122
836
1277
896
w_cbt_er
0.0
1
0
Number

INPUTBOX
1278
836
1433
896
w_sd_er
0.0
1
0
Number

INPUTBOX
1434
836
1589
896
w_hc_er
0.0
1
0
Number

INPUTBOX
1606
836
1761
896
w_inc_er
0.0
1
0
Number

INPUTBOX
1762
836
1917
896
w_edu_er
0.0
1
0
Number

INPUTBOX
1918
836
2073
896
w_trans_er
0.0
1
0
Number

INPUTBOX
2091
836
2246
896
wa_er
0.0
1
0
Number

INPUTBOX
2247
836
2402
896
ws_er
0.0
1
0
Number

INPUTBOX
2404
836
2559
896
we_er
0.0
1
0
Number

INPUTBOX
11
926
166
986
w_wfwt_off-cl
0.0
1
0
Number

INPUTBOX
167
926
322
986
w_fc_off-cl
0.0
1
0
Number

INPUTBOX
323
926
478
986
w_fb_off-cl
0.0
1
0
Number

INPUTBOX
479
926
634
986
w_ffol_off-cl
0.0
1
0
Number

INPUTBOX
635
926
790
986
w_fu_off-cl
0.0
1
0
Number

INPUTBOX
810
926
965
986
w_keo_off-cl
0.0
1
0
Number

INPUTBOX
966
926
1121
986
w_wheo_off-cl
0.0
1
0
Number

INPUTBOX
1122
926
1277
986
w_cbt_off-cl
0.0
1
0
Number

INPUTBOX
1278
926
1433
986
w_sd_off-cl
0.0
1
0
Number

INPUTBOX
1434
926
1589
986
w_hc_off-cl
0.0
1
0
Number

INPUTBOX
1606
926
1761
986
w_inc_off-cl
0.0
1
0
Number

INPUTBOX
1762
926
1917
986
w_edu_off-cl
0.0
1
0
Number

INPUTBOX
1918
926
2073
986
w_trans_off-cl
0.0
1
0
Number

INPUTBOX
2091
926
2246
986
wa_off-cl
0.0
1
0
Number

INPUTBOX
2247
926
2402
986
ws_off-cl
0.0
1
0
Number

INPUTBOX
2404
926
2559
986
we_off-cl
0.0
1
0
Number

INPUTBOX
11
1016
166
1076
w_wfwt_stay
0.0
1
0
Number

INPUTBOX
167
1016
322
1076
w_fc_stay
0.0
1
0
Number

INPUTBOX
323
1016
478
1076
w_fb_stay
0.0
1
0
Number

INPUTBOX
479
1016
634
1076
w_ffol_stay
0.0
1
0
Number

INPUTBOX
635
1016
790
1076
w_fu_stay
0.0
1
0
Number

INPUTBOX
810
1016
965
1076
w_keo_stay
0.0
1
0
Number

INPUTBOX
966
1016
1121
1076
w_wheo_stay
0.0
1
0
Number

INPUTBOX
1122
1016
1277
1076
w_cbt_stay
0.0
1
0
Number

INPUTBOX
1278
1016
1433
1076
w_sd_stay
0.0
1
0
Number

INPUTBOX
1434
1016
1589
1076
w_hc_stay
0.0
1
0
Number

INPUTBOX
1606
1016
1761
1076
w_inc_stay
0.0
1
0
Number

INPUTBOX
1762
1016
1917
1076
w_edu_stay
0.0
1
0
Number

INPUTBOX
1918
1016
2073
1076
w_trans_stay
0.0
1
0
Number

INPUTBOX
2091
1016
2246
1076
wa_stay
0.0
1
0
Number

INPUTBOX
2247
1016
2402
1076
ws_stay
0.0
1
0
Number

INPUTBOX
2404
1016
2559
1076
we_stay
0.0
1
0
Number

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
