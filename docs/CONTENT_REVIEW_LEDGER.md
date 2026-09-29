# Corpus correction ledger

Baseline: `1b0205de408048f792815d26dd19199b9f40a70f`. Each of the 500 IDs below was inspected in category order against the Thai text, Myanmar meaning, English context, and the Myanmar reading aid. This is an AI-assisted text review and revision ledger, **not a fluent bilingual human sign-off**. The reading aid remains approximate, especially for Thai tones. A bilingual reviewer must check every row before broad release.

The table records fields changed in the first correction pass compared with the baseline. The high-risk column marks workplace, employment, health, emergency, police, and document categories for follow-up review; corrections from the second pass are listed after the table. A field absent from “Changed” was unchanged in the first pass, not a certification of correctness.

| # | ID | Category | Changed | High risk |
|---:|---|---|---|---|
| 1 | `greet_hello` | `greetings` | pronunciation | no |
| 2 | `greet_thanks` | `greetings` | pronunciation | no |
| 3 | `greet_sorry` | `greetings` | pronunciation | no |
| 4 | `greet_no_problem` | `greetings` | none | no |
| 5 | `intro_name` | `introductions` | pronunciation | no |
| 6 | `intro_myanmar` | `introductions` | pronunciation | no |
| 7 | `numbers_one` | `numbers` | none | no |
| 8 | `numbers_two` | `numbers` | pronunciation | no |
| 9 | `numbers_three` | `numbers` | none | no |
| 10 | `numbers_how_many` | `numbers` | pronunciation | no |
| 11 | `money_price` | `money` | pronunciation | no |
| 12 | `money_expensive` | `money` | pronunciation | no |
| 13 | `money_discount` | `money` | pronunciation | no |
| 14 | `money_cash` | `money` | pronunciation | no |
| 15 | `money_card` | `money` | pronunciation | no |
| 16 | `time_now` | `time` | pronunciation | no |
| 17 | `time_open` | `time` | pronunciation | no |
| 18 | `time_wait` | `time` | pronunciation | no |
| 19 | `date_today` | `dates` | pronunciation | no |
| 20 | `date_tomorrow` | `dates` | pronunciation | no |
| 21 | `question_where` | `questions` | pronunciation | no |
| 22 | `question_understand` | `questions` | pronunciation | no |
| 23 | `question_slowly` | `questions` | pronunciation | no |
| 24 | `food_not_spicy` | `food` | thai, thaiMale, thaiFemale, my, pronunciation | no |
| 25 | `food_no_pork` | `food` | pronunciation | no |
| 26 | `food_water` | `food` | pronunciation | no |
| 27 | `food_takeaway` | `food` | pronunciation | no |
| 28 | `food_bill` | `food` | pronunciation | no |
| 29 | `shopping_bag` | `shopping` | pronunciation | no |
| 30 | `shopping_receipt` | `shopping` | pronunciation | no |
| 31 | `shopping_this` | `shopping` | pronunciation | no |
| 32 | `store_topup` | `convenience_store` | pronunciation | no |
| 33 | `transport_go` | `transport` | pronunciation | no |
| 34 | `transport_stop` | `transport` | pronunciation | no |
| 35 | `transport_bus` | `transport` | pronunciation | no |
| 36 | `transport_fare` | `transport` | pronunciation | no |
| 37 | `directions_straight` | `directions` | pronunciation | no |
| 38 | `directions_left` | `directions` | pronunciation | no |
| 39 | `directions_right` | `directions` | pronunciation | no |
| 40 | `work_slowly` | `workplace` | pronunciation | yes |
| 41 | `work_again` | `workplace` | pronunciation | yes |
| 42 | `work_finished` | `workplace` | pronunciation | yes |
| 43 | `work_help` | `workplace` | pronunciation | yes |
| 44 | `factory_machine` | `factory` | pronunciation | yes |
| 45 | `factory_safety` | `factory` | pronunciation | yes |
| 46 | `factory_gloves` | `factory` | pronunciation | yes |
| 47 | `home_water` | `accommodation` | pronunciation | no |
| 48 | `home_rent` | `accommodation` | pronunciation | no |
| 49 | `home_electricity` | `accommodation` | pronunciation | no |
| 50 | `health_stomach` | `health` | pronunciation | yes |
| 51 | `health_headache` | `health` | pronunciation | yes |
| 52 | `health_allergy` | `health` | thai, pronunciation | yes |
| 53 | `hospital_interpreter` | `hospital_clinic` | pronunciation | yes |
| 54 | `hospital_registration` | `hospital_clinic` | pronunciation | yes |
| 55 | `pharmacy_medicine` | `pharmacy` | pronunciation | yes |
| 56 | `pharmacy_painkiller` | `pharmacy` | pronunciation | yes |
| 57 | `emergency_help` | `emergency` | thai, thaiMale, thaiFemale, pronunciation | yes |
| 58 | `emergency_interpreter` | `emergency` | pronunciation | yes |
| 59 | `police_interpreter` | `police` | pronunciation | yes |
| 60 | `immigration_question` | `immigration_documents` | pronunciation | yes |
| 61 | `bank_withdraw` | `bank` | pronunciation | no |
| 62 | `bank_transfer` | `bank` | pronunciation | no |
| 63 | `phone_sim_no_signal` | `phone_sim` | pronunciation | no |
| 64 | `phone_internet` | `phone_sim` | pronunciation | no |
| 65 | `job_looking` | `job_search` | pronunciation | yes |
| 66 | `job_vacancy` | `job_search` | pronunciation | yes |
| 67 | `job_experience` | `job_search` | pronunciation | yes |
| 68 | `salary_date` | `salary` | pronunciation | yes |
| 69 | `salary_amount` | `salary` | pronunciation | yes |
| 70 | `salary_check` | `salary` | pronunciation | yes |
| 71 | `overtime_need` | `overtime` | pronunciation | yes |
| 72 | `overtime_rate` | `overtime` | pronunciation | yes |
| 73 | `leave_sick` | `leave` | pronunciation | yes |
| 74 | `leave_request` | `leave` | pronunciation | yes |
| 75 | `daily_toilet` | `daily_life` | pronunciation | no |
| 76 | `daily_not_here` | `daily_life` | pronunciation | no |
| 77 | `daily_contact` | `daily_life` | my, pronunciation | no |
| 78 | `daily_no_thai` | `daily_life` | pronunciation | no |
| 79 | `answer_yes` | `common_answers` | pronunciation | no |
| 80 | `answer_no` | `common_answers` | pronunciation | no |
| 81 | `answer_not_sure` | `common_answers` | pronunciation | no |
| 82 | `boss_talk` | `boss_supervisor` | pronunciation | yes |
| 83 | `restaurant_table` | `restaurant` | my, pronunciation | no |
| 84 | `street_food_fresh` | `street_food` | pronunciation | no |
| 85 | `taxi_meter` | `taxi` | pronunciation | no |
| 86 | `public_transport_line` | `public_transport` | pronunciation | no |
| 87 | `apartment_washer` | `apartment_landlord` | pronunciation | no |
| 88 | `greet_good_morning` | `greetings` | pronunciation | no |
| 89 | `greet_good_evening` | `greetings` | pronunciation | no |
| 90 | `greet_see_you` | `greetings` | pronunciation | no |
| 91 | `intro_nice_to_meet` | `introductions` | pronunciation | no |
| 92 | `intro_live_thailand` | `introductions` | pronunciation | no |
| 93 | `intro_learning_thai` | `introductions` | pronunciation | no |
| 94 | `intro_work_thailand` | `introductions` | pronunciation | no |
| 95 | `numbers_0` | `numbers` | none | no |
| 96 | `numbers_4` | `numbers` | none | no |
| 97 | `numbers_5` | `numbers` | none | no |
| 98 | `numbers_6` | `numbers` | pronunciation | no |
| 99 | `numbers_7` | `numbers` | none | no |
| 100 | `numbers_8` | `numbers` | none | no |
| 101 | `numbers_9` | `numbers` | pronunciation | no |
| 102 | `money_total` | `money` | pronunciation | no |
| 103 | `money_qr_pay` | `money` | pronunciation | no |
| 104 | `money_change` | `money` | pronunciation | no |
| 105 | `money_split_bill` | `money` | pronunciation | no |
| 106 | `money_exact_amount` | `money` | pronunciation | no |
| 107 | `time_closing` | `time` | pronunciation | no |
| 108 | `time_wait_how_long` | `time` | pronunciation | no |
| 109 | `time_appointment` | `time` | pronunciation | no |
| 110 | `time_later_today` | `time` | pronunciation | no |
| 111 | `time_not_convenient` | `time` | pronunciation | no |
| 112 | `date_today_number` | `dates` | pronunciation | no |
| 113 | `date_day_off` | `dates` | pronunciation | no |
| 114 | `date_next_week` | `dates` | pronunciation | no |
| 115 | `date_make_appointment` | `dates` | pronunciation | no |
| 116 | `date_change_appointment` | `dates` | pronunciation | no |
| 117 | `date_open_today` | `dates` | pronunciation | no |
| 118 | `question_who` | `questions` | pronunciation | no |
| 119 | `question_how_to` | `questions` | pronunciation | no |
| 120 | `question_how_long` | `questions` | pronunciation | no |
| 121 | `question_how_far` | `questions` | pronunciation | no |
| 122 | `question_write_down` | `questions` | pronunciation | no |
| 123 | `question_repeat` | `questions` | pronunciation | no |
| 124 | `answer_maybe` | `common_answers` | pronunciation | no |
| 125 | `answer_not_yet` | `common_answers` | pronunciation | no |
| 126 | `answer_done` | `common_answers` | pronunciation | no |
| 127 | `answer_later` | `common_answers` | pronunciation | no |
| 128 | `answer_sure` | `common_answers` | pronunciation | no |
| 129 | `answer_dont_know` | `common_answers` | pronunciation | no |
| 130 | `food_less_spicy` | `food` | pronunciation | no |
| 131 | `food_no_sugar` | `food` | pronunciation | no |
| 132 | `food_chicken` | `food` | pronunciation | no |
| 133 | `food_one_serving` | `food` | pronunciation | no |
| 134 | `food_sauce_separate` | `food` | pronunciation | no |
| 135 | `shopping_smaller_size` | `shopping` | pronunciation | no |
| 136 | `shopping_try_on` | `shopping` | pronunciation | no |
| 137 | `shopping_other_color` | `shopping` | pronunciation | no |
| 138 | `shopping_just_looking` | `shopping` | pronunciation | no |
| 139 | `shopping_exchange` | `shopping` | pronunciation | no |
| 140 | `store_checkout` | `convenience_store` | pronunciation | no |
| 141 | `store_heat_food` | `convenience_store` | pronunciation | no |
| 142 | `store_pay_bill` | `convenience_store` | pronunciation | no |
| 143 | `store_atm` | `convenience_store` | pronunciation | no |
| 144 | `store_data_topup` | `convenience_store` | pronunciation | no |
| 145 | `store_warm_drink` | `convenience_store` | pronunciation | no |
| 146 | `store_microwave` | `convenience_store` | pronunciation | no |
| 147 | `transport_pickup` | `transport` | pronunciation | no |
| 148 | `transport_dropoff` | `transport` | pronunciation | no |
| 149 | `transport_traffic` | `transport` | pronunciation | no |
| 150 | `transport_wait_here` | `transport` | pronunciation | no |
| 151 | `transport_get_off` | `transport` | pronunciation | no |
| 152 | `transport_no_toll` | `transport` | pronunciation | no |
| 153 | `transport_use_map` | `transport` | pronunciation | no |
| 154 | `direction_bus_stop` | `directions` | pronunciation | no |
| 155 | `direction_nearby` | `directions` | pronunciation | no |
| 156 | `direction_walk` | `directions` | pronunciation | no |
| 157 | `direction_intersection` | `directions` | pronunciation | no |
| 158 | `direction_show_map` | `directions` | pronunciation | no |
| 159 | `direction_cross_street` | `directions` | pronunciation | no |
| 160 | `work_clock_in` | `workplace` | pronunciation | yes |
| 161 | `work_break_time` | `workplace` | pronunciation | yes |
| 162 | `work_finish_time` | `workplace` | pronunciation | yes |
| 163 | `work_check_my_task` | `workplace` | pronunciation | yes |
| 164 | `work_where_tool` | `workplace` | pronunciation | yes |
| 165 | `work_need_help` | `workplace` | pronunciation | yes |
| 166 | `work_repeat_instruction` | `workplace` | pronunciation | yes |
| 167 | `work_where_meeting` | `workplace` | pronunciation | yes |
| 168 | `boss_schedule` | `boss_supervisor` | pronunciation | yes |
| 169 | `boss_shift_start` | `boss_supervisor` | pronunciation | yes |
| 170 | `boss_report_problem` | `boss_supervisor` | pronunciation | yes |
| 171 | `boss_write_instruction` | `boss_supervisor` | pronunciation | yes |
| 172 | `boss_confirm_task` | `boss_supervisor` | pronunciation | yes |
| 173 | `boss_contact_person` | `boss_supervisor` | pronunciation | yes |
| 174 | `boss_check_understanding` | `boss_supervisor` | pronunciation | yes |
| 175 | `factory_line_stopped` | `factory` | pronunciation | yes |
| 176 | `factory_machine_sound` | `factory` | pronunciation | yes |
| 177 | `factory_parts_missing` | `factory` | pronunciation | yes |
| 178 | `factory_stop_for_safety` | `factory` | my, pronunciation, en | yes |
| 179 | `factory_defective_item` | `factory` | pronunciation | yes |
| 180 | `factory_safety_shoes` | `factory` | pronunciation | yes |
| 181 | `factory_first_aid` | `factory` | thai, thaiMale, thaiFemale, pronunciation | yes |
| 182 | `home_wifi_password` | `accommodation` | pronunciation | no |
| 183 | `home_trash_place` | `accommodation` | pronunciation | no |
| 184 | `home_light_broken` | `accommodation` | pronunciation | no |
| 185 | `home_hot_water` | `accommodation` | pronunciation | no |
| 186 | `home_repair_request` | `accommodation` | pronunciation | no |
| 187 | `home_kitchen` | `accommodation` | pronunciation | no |
| 188 | `apartment_deposit` | `apartment_landlord` | pronunciation | no |
| 189 | `apartment_contract_copy` | `apartment_landlord` | pronunciation | no |
| 190 | `apartment_return_deposit` | `apartment_landlord` | pronunciation | no |
| 191 | `apartment_extra_key` | `apartment_landlord` | pronunciation | no |
| 192 | `apartment_quiet_hours` | `apartment_landlord` | pronunciation | no |
| 193 | `apartment_payment_method` | `apartment_landlord` | pronunciation | no |
| 194 | `apartment_notice_move` | `apartment_landlord` | pronunciation | no |
| 195 | `restaurant_menu` | `restaurant` | pronunciation | no |
| 196 | `restaurant_table_two` | `restaurant` | pronunciation | no |
| 197 | `restaurant_wait_time` | `restaurant` | pronunciation | no |
| 198 | `restaurant_no_seafood` | `restaurant` | pronunciation | no |
| 199 | `restaurant_check_bill` | `restaurant` | pronunciation | no |
| 200 | `restaurant_separate_payment` | `restaurant` | pronunciation | no |
| 201 | `restaurant_takeaway` | `restaurant` | pronunciation | no |
| 202 | `street_no_chili` | `street_food` | none | no |
| 203 | `street_less_sweet` | `street_food` | pronunciation | no |
| 204 | `street_no_onion` | `street_food` | pronunciation | no |
| 205 | `street_chicken_available` | `street_food` | pronunciation | no |
| 206 | `street_one_portion` | `street_food` | pronunciation | no |
| 207 | `street_fresh_made` | `street_food` | thai, thaiMale, thaiFemale, pronunciation | no |
| 208 | `street_sauce_not_spicy` | `street_food` | pronunciation | no |
| 209 | `taxi_go_to_place` | `taxi` | pronunciation | no |
| 210 | `taxi_turn_left_here` | `taxi` | pronunciation | no |
| 211 | `taxi_gps` | `taxi` | pronunciation | no |
| 212 | `taxi_wait_five` | `taxi` | pronunciation | no |
| 213 | `taxi_no_change` | `taxi` | pronunciation | no |
| 214 | `taxi_drop_here` | `taxi` | pronunciation | no |
| 215 | `taxi_need_receipt` | `taxi` | pronunciation | no |
| 216 | `public_ticket_price` | `public_transport` | pronunciation | no |
| 217 | `public_platform` | `public_transport` | pronunciation | no |
| 218 | `public_change_line` | `public_transport` | pronunciation | no |
| 219 | `public_next_station` | `public_transport` | pronunciation | no |
| 220 | `public_get_off_here` | `public_transport` | pronunciation | no |
| 221 | `public_transport_card` | `public_transport` | pronunciation | no |
| 222 | `public_bus_direction` | `public_transport` | pronunciation | no |
| 223 | `health_fever` | `health` | pronunciation | yes |
| 224 | `health_cough` | `health` | pronunciation | yes |
| 225 | `health_nausea` | `health` | pronunciation | yes |
| 226 | `health_dizzy` | `health` | pronunciation | yes |
| 227 | `health_point_to_pain` | `health` | pronunciation | yes |
| 228 | `health_since_when` | `health` | pronunciation | yes |
| 229 | `hospital_talk_doctor` | `hospital_clinic` | pronunciation | yes |
| 230 | `hospital_show_passport` | `hospital_clinic` | thai, thaiMale, thaiFemale, my, pronunciation, en | yes |
| 231 | `hospital_write_information` | `hospital_clinic` | pronunciation | yes |
| 232 | `hospital_where_wait` | `hospital_clinic` | pronunciation | yes |
| 233 | `hospital_contact_family` | `hospital_clinic` | pronunciation | yes |
| 234 | `hospital_explain_cost` | `hospital_clinic` | pronunciation | yes |
| 235 | `pharmacy_explain_label` | `pharmacy` | pronunciation | yes |
| 236 | `pharmacy_show_medicine` | `pharmacy` | pronunciation | yes |
| 237 | `pharmacy_speak_pharmacist` | `pharmacy` | pronunciation | yes |
| 238 | `pharmacy_allergy_note` | `pharmacy` | pronunciation | yes |
| 239 | `pharmacy_read_instructions` | `pharmacy` | pronunciation | yes |
| 240 | `pharmacy_need_receipt` | `pharmacy` | pronunciation | yes |
| 241 | `emergency_call_ambulance` | `emergency` | pronunciation | yes |
| 242 | `emergency_call_police` | `emergency` | pronunciation | yes |
| 243 | `emergency_someone_hurt` | `emergency` | pronunciation | yes |
| 244 | `emergency_fire` | `emergency` | thai, thaiMale, thaiFemale, pronunciation | yes |
| 245 | `emergency_lost_person` | `emergency` | pronunciation | yes |
| 246 | `emergency_lost_wallet` | `emergency` | pronunciation | yes |
| 247 | `police_lost_phone` | `police` | thai, pronunciation | yes |
| 248 | `police_report_item` | `police` | pronunciation | yes |
| 249 | `police_report_copy` | `police` | thai, thaiMale, thaiFemale, my, pronunciation, en | yes |
| 250 | `police_need_interpreter` | `police` | pronunciation | yes |
| 251 | `police_understand_question` | `police` | pronunciation | yes |
| 252 | `police_contact_consulate` | `police` | pronunciation | yes |
| 253 | `police_wait_for_interpreter` | `police` | pronunciation | yes |
| 254 | `documents_submit_where` | `immigration_documents` | pronunciation | yes |
| 255 | `documents_what_to_bring` | `immigration_documents` | pronunciation | yes |
| 256 | `documents_explain_form` | `immigration_documents` | pronunciation | yes |
| 257 | `documents_appointment` | `immigration_documents` | pronunciation | yes |
| 258 | `documents_interpreter` | `immigration_documents` | pronunciation | yes |
| 259 | `documents_write_name` | `immigration_documents` | pronunciation | yes |
| 260 | `documents_check_copy` | `immigration_documents` | pronunciation | yes |
| 261 | `bank_deposit_cash` | `bank` | pronunciation | no |
| 262 | `bank_forgot_pin` | `bank` | thai, thaiMale, pronunciation | no |
| 263 | `bank_card_retained` | `bank` | pronunciation | no |
| 264 | `bank_transfer_not_arrived` | `bank` | pronunciation | no |
| 265 | `bank_account_balance` | `bank` | pronunciation | no |
| 266 | `bank_statement` | `bank` | pronunciation | no |
| 267 | `phone_buy_sim` | `phone_sim` | pronunciation | no |
| 268 | `phone_register_sim` | `phone_sim` | pronunciation | no |
| 269 | `phone_no_otp` | `phone_sim` | pronunciation | no |
| 270 | `phone_check_balance` | `phone_sim` | pronunciation | no |
| 271 | `phone_repair` | `phone_sim` | pronunciation | no |
| 272 | `phone_internet_not_working` | `phone_sim` | pronunciation | no |
| 273 | `job_type_opening` | `job_search` | pronunciation | yes |
| 274 | `job_interview_time` | `job_search` | pronunciation | yes |
| 275 | `job_work_location` | `job_search` | pronunciation | yes |
| 276 | `job_start_date` | `job_search` | pronunciation | yes |
| 277 | `job_contact` | `job_search` | pronunciation | yes |
| 278 | `salary_not_received` | `salary` | pronunciation | yes |
| 279 | `salary_check_work_hours` | `salary` | pronunciation | yes |
| 280 | `salary_deduction` | `salary` | pronunciation | yes |
| 281 | `salary_payment_slip` | `salary` | pronunciation | yes |
| 282 | `salary_payment_date` | `salary` | pronunciation | yes |
| 283 | `overtime_hours` | `overtime` | pronunciation | yes |
| 284 | `overtime_schedule` | `overtime` | pronunciation | yes |
| 285 | `overtime_record` | `overtime` | pronunciation | yes |
| 286 | `overtime_pay_rate` | `overtime` | pronunciation | yes |
| 287 | `overtime_end_time` | `overtime` | pronunciation | yes |
| 288 | `overtime_confirm_hours` | `overtime` | pronunciation | yes |
| 289 | `leave_medical_appointment` | `leave` | thai, thaiMale, thaiFemale, pronunciation, en | yes |
| 290 | `leave_notify_person` | `leave` | pronunciation | yes |
| 291 | `leave_return_date` | `leave` | pronunciation | yes |
| 292 | `leave_available_days` | `leave` | pronunciation | yes |
| 293 | `leave_cant_attend` | `leave` | pronunciation | yes |
| 294 | `leave_send_message` | `leave` | pronunciation | yes |
| 295 | `daily_need_water` | `daily_life` | pronunciation | no |
| 296 | `daily_no_cash` | `daily_life` | pronunciation | no |
| 297 | `daily_wait_for_friend` | `daily_life` | pronunciation | no |
| 298 | `daily_lost_way` | `daily_life` | thai, pronunciation | no |
| 299 | `daily_call_friend` | `daily_life` | pronunciation | no |
| 300 | `daily_need_toilet_urgent` | `daily_life` | pronunciation | no |
| 301 | `daily_where_get_water` | `daily_life` | pronunciation | no |
| 302 | `daily_charging_phone` | `daily_life` | pronunciation | no |
| 303 | `greet_how_are_you` | `greetings` | pronunciation | no |
| 304 | `greet_arrived` | `greetings` | pronunciation | no |
| 305 | `greet_thank_help` | `greetings` | pronunciation | no |
| 306 | `greet_sorry_late` | `greetings` | pronunciation | no |
| 307 | `greet_head_off` | `greetings` | pronunciation | no |
| 308 | `intro_ask_name` | `introductions` | pronunciation | no |
| 309 | `intro_call_me` | `introductions` | pronunciation | no |
| 310 | `intro_live_near` | `introductions` | pronunciation | no |
| 311 | `intro_work_at` | `introductions` | pronunciation | no |
| 312 | `intro_from_city` | `introductions` | pronunciation | no |
| 313 | `number_say_slowly` | `numbers` | pronunciation | no |
| 314 | `number_write_down` | `numbers` | pronunciation | no |
| 315 | `number_total_people` | `numbers` | pronunciation | no |
| 316 | `number_phone_digits` | `numbers` | my, pronunciation | no |
| 317 | `number_enter` | `numbers` | pronunciation | no |
| 318 | `money_small_notes` | `money` | pronunciation | no |
| 319 | `money_fee_included` | `money` | pronunciation | no |
| 320 | `money_two_items` | `money` | pronunciation | no |
| 321 | `money_bank_transfer` | `money` | my, pronunciation | no |
| 322 | `money_already_paid` | `money` | pronunciation | no |
| 323 | `money_each_item` | `money` | pronunciation | no |
| 324 | `time_arrived` | `time` | pronunciation | no |
| 325 | `time_running_late` | `time` | pronunciation | no |
| 326 | `time_ready_notice` | `time` | pronunciation | no |
| 327 | `time_my_turn` | `time` | pronunciation | no |
| 328 | `time_free_to_talk` | `time` | pronunciation | no |
| 329 | `time_move_afternoon` | `time` | pronunciation | no |
| 330 | `date_appointment_day` | `dates` | pronunciation | no |
| 331 | `date_weekday` | `dates` | pronunciation | no |
| 332 | `date_is_holiday` | `dates` | my, pronunciation | no |
| 333 | `date_next_month_day_off` | `dates` | pronunciation | no |
| 334 | `date_confirm_again` | `dates` | pronunciation | no |
| 335 | `question_word_meaning` | `questions` | pronunciation | no |
| 336 | `question_form_field` | `questions` | pronunciation | no |
| 337 | `question_which_counter` | `questions` | pronunciation | no |
| 338 | `question_show_how` | `questions` | pronunciation | no |
| 339 | `question_have_here` | `questions` | pronunciation | no |
| 340 | `question_book_ahead` | `questions` | pronunciation | no |
| 341 | `answer_understood` | `common_answers` | pronunciation | no |
| 342 | `answer_check_first` | `common_answers` | pronunciation | no |
| 343 | `answer_do_now` | `common_answers` | pronunciation | no |
| 344 | `answer_more_time` | `common_answers` | pronunciation | no |
| 345 | `answer_on_way` | `common_answers` | pronunciation | no |
| 346 | `food_more_rice` | `food` | pronunciation | no |
| 347 | `food_no_peanuts` | `food` | my, pronunciation | no |
| 348 | `food_ingredients` | `food` | pronunciation | no |
| 349 | `food_no_ice` | `food` | my, pronunciation | no |
| 350 | `food_more_cutlery` | `food` | pronunciation | no |
| 351 | `food_no_fish_sauce` | `food` | pronunciation | no |
| 352 | `shopping_specific_size` | `shopping` | pronunciation | no |
| 353 | `shopping_other_brand` | `shopping` | pronunciation | no |
| 354 | `shopping_hold_item` | `shopping` | pronunciation | no |
| 355 | `shopping_gift_wrap` | `shopping` | pronunciation | no |
| 356 | `shopping_exchange_days` | `shopping` | pronunciation | no |
| 357 | `shopping_same_price` | `shopping` | pronunciation | no |
| 358 | `store_pickup_parcel` | `convenience_store` | pronunciation | no |
| 359 | `store_charger_cable` | `convenience_store` | pronunciation | no |
| 360 | `store_transit_topup` | `convenience_store` | pronunciation | no |
| 361 | `store_have_ice` | `convenience_store` | pronunciation | no |
| 362 | `store_photocopy` | `convenience_store` | pronunciation | no |
| 363 | `transport_car_booking` | `transport` | pronunciation | no |
| 364 | `transport_waiting_entrance` | `transport` | pronunciation | no |
| 365 | `transport_near_destination` | `transport` | pronunciation | no |
| 366 | `transport_wrong_destination` | `transport` | pronunciation | no |
| 367 | `transport_heavy_luggage` | `transport` | pronunciation | no |
| 368 | `transport_lift_bag` | `transport` | pronunciation | no |
| 369 | `directions_which_building` | `directions` | pronunciation | no |
| 370 | `directions_nearest_crossing` | `directions` | pronunciation | no |
| 371 | `directions_right_way` | `directions` | pronunciation | no |
| 372 | `directions_turn_to_place` | `directions` | pronunciation | no |
| 373 | `directions_back_station` | `directions` | pronunciation | no |
| 374 | `home_lock_broken` | `accommodation` | my, pronunciation, en | no |
| 375 | `home_aircon_not_cooling` | `accommodation` | pronunciation | no |
| 376 | `home_water_leak` | `accommodation` | pronunciation | no |
| 377 | `home_power_out` | `accommodation` | pronunciation | no |
| 378 | `home_key_lost` | `accommodation` | pronunciation | no |
| 379 | `home_noise_night` | `accommodation` | pronunciation | no |
| 380 | `apt_view_before_decide` | `apartment_landlord` | pronunciation | no |
| 381 | `apt_utilities_separate` | `apartment_landlord` | pronunciation | no |
| 382 | `apt_move_in_day` | `apartment_landlord` | pronunciation | no |
| 383 | `apt_motorcycle_parking` | `apartment_landlord` | pronunciation | no |
| 384 | `apt_repair_visit_day` | `apartment_landlord` | pronunciation | no |
| 385 | `restaurant_water_no_ice` | `restaurant` | pronunciation | no |
| 386 | `restaurant_peanut_question` | `restaurant` | pronunciation | no |
| 387 | `restaurant_extra_rice` | `restaurant` | pronunciation | no |
| 388 | `restaurant_dine_in` | `restaurant` | pronunciation | no |
| 389 | `restaurant_call_staff` | `restaurant` | pronunciation | no |
| 390 | `street_no_fish_sauce` | `street_food` | pronunciation | no |
| 391 | `street_half_portion` | `street_food` | pronunciation | no |
| 392 | `street_cut_small` | `street_food` | pronunciation | no |
| 393 | `street_separate_bag` | `street_food` | pronunciation | no |
| 394 | `street_pork_or_chicken` | `street_food` | pronunciation | no |
| 395 | `taxi_aircon` | `taxi` | pronunciation | no |
| 396 | `taxi_wrong_address` | `taxi` | pronunciation | no |
| 397 | `taxi_change_destination` | `taxi` | pronunciation | no |
| 398 | `taxi_open_window` | `taxi` | pronunciation | no |
| 399 | `taxi_left_bag` | `taxi` | pronunciation | no |
| 400 | `public_nearest_exit` | `public_transport` | pronunciation | no |
| 401 | `public_train_delayed` | `public_transport` | pronunciation | no |
| 402 | `public_one_way_ticket` | `public_transport` | pronunciation | no |
| 403 | `public_next_bus_time` | `public_transport` | pronunciation | no |
| 404 | `public_ticket_return` | `public_transport` | pronunciation | no |
| 405 | `daily_meeting_person` | `daily_life` | pronunciation | no |
| 406 | `daily_send_location` | `daily_life` | pronunciation | no |
| 407 | `daily_left_item` | `daily_life` | pronunciation | no |
| 408 | `daily_borrow_pen` | `daily_life` | pronunciation | no |
| 409 | `daily_find_building` | `daily_life` | pronunciation | no |
| 410 | `daily_wait_inside` | `daily_life` | pronunciation | no |
| 411 | `bank_update_phone` | `bank` | pronunciation | no |
| 412 | `bank_lost_passbook` | `bank` | pronunciation | no |
| 413 | `bank_unknown_transaction` | `bank` | my, pronunciation | no |
| 414 | `bank_fee_explain` | `bank` | pronunciation | no |
| 415 | `bank_queue_ticket` | `bank` | pronunciation | no |
| 416 | `bank_exchange_money` | `bank` | pronunciation | no |
| 417 | `phone_lost_sim` | `phone_sim` | pronunciation | no |
| 418 | `phone_change_number` | `phone_sim` | pronunciation | no |
| 419 | `phone_set_thai_language` | `phone_sim` | pronunciation | no |
| 420 | `phone_package_expiry` | `phone_sim` | pronunciation | no |
| 421 | `phone_weak_signal` | `phone_sim` | pronunciation | no |
| 422 | `phone_need_otp` | `phone_sim` | pronunciation | no |
| 423 | `work_uniform_today` | `workplace` | pronunciation | yes |
| 424 | `work_clock_out` | `workplace` | pronunciation | yes |
| 425 | `work_priority_task` | `workplace` | thai, thaiMale, thaiFemale, pronunciation | yes |
| 426 | `work_check_step` | `workplace` | pronunciation | yes |
| 427 | `work_cannot_finish_part` | `workplace` | pronunciation | yes |
| 428 | `work_read_sign` | `workplace` | pronunciation | yes |
| 429 | `boss_schedule_changed` | `boss_supervisor` | pronunciation | yes |
| 430 | `boss_leave_status` | `boss_supervisor` | pronunciation | yes |
| 431 | `boss_report_person` | `boss_supervisor` | pronunciation | yes |
| 432 | `boss_duties_today` | `boss_supervisor` | pronunciation | yes |
| 433 | `boss_instruction_sheet` | `boss_supervisor` | pronunciation | yes |
| 434 | `boss_feedback_correction` | `boss_supervisor` | pronunciation | yes |
| 435 | `factory_machine_stopped` | `factory` | pronunciation | yes |
| 436 | `factory_part_hot` | `factory` | pronunciation | yes |
| 437 | `factory_floor_wet` | `factory` | pronunciation | yes |
| 438 | `factory_button_function` | `factory` | pronunciation | yes |
| 439 | `factory_separate_defect` | `factory` | pronunciation | yes |
| 440 | `factory_restricted_area` | `factory` | pronunciation | yes |
| 441 | `health_toothache` | `health` | pronunciation | yes |
| 442 | `health_skin_rash` | `health` | pronunciation | yes |
| 443 | `health_short_breath` | `health` | pronunciation | yes |
| 444 | `health_regular_medicine` | `health` | pronunciation | yes |
| 445 | `health_existing_condition` | `health` | pronunciation | yes |
| 446 | `health_food_allergy` | `health` | pronunciation | yes |
| 447 | `hospital_explain_result` | `hospital_clinic` | pronunciation | yes |
| 448 | `hospital_result_ready` | `hospital_clinic` | pronunciation | yes |
| 449 | `hospital_exam_room` | `hospital_clinic` | pronunciation | yes |
| 450 | `hospital_family_accompany` | `hospital_clinic` | pronunciation | yes |
| 451 | `hospital_medical_certificate` | `hospital_clinic` | pronunciation | yes |
| 452 | `hospital_queue_number` | `hospital_clinic` | pronunciation | yes |
| 453 | `pharmacy_buy_thermometer` | `pharmacy` | thai, thaiMale, thaiFemale, pronunciation | yes |
| 454 | `pharmacy_bandage` | `pharmacy` | pronunciation | yes |
| 455 | `pharmacy_write_medicine_name` | `pharmacy` | pronunciation | yes |
| 456 | `pharmacy_small_pack` | `pharmacy` | pronunciation | yes |
| 457 | `pharmacy_expiry_date` | `pharmacy` | pronunciation | yes |
| 458 | `pharmacy_read_label` | `pharmacy` | pronunciation | yes |
| 459 | `emergency_road_collision` | `emergency` | pronunciation | yes |
| 460 | `emergency_unconscious` | `emergency` | pronunciation | yes |
| 461 | `emergency_child_missing` | `emergency` | pronunciation | yes |
| 462 | `emergency_cannot_breathe` | `emergency` | pronunciation | yes |
| 463 | `emergency_location` | `emergency` | pronunciation | yes |
| 464 | `emergency_trapped` | `emergency` | pronunciation | yes |
| 465 | `police_report_accident` | `police` | pronunciation | yes |
| 466 | `police_lost_passport` | `police` | pronunciation | yes |
| 467 | `police_nearest_station` | `police` | pronunciation | yes |
| 468 | `police_reference_number` | `police` | pronunciation | yes |
| 469 | `police_contact_family` | `police` | pronunciation | yes |
| 470 | `police_translate_document` | `police` | pronunciation | yes |
| 471 | `documents_collect_day` | `immigration_documents` | pronunciation | yes |
| 472 | `documents_status_check` | `immigration_documents` | pronunciation | yes |
| 473 | `documents_copy_here` | `immigration_documents` | pronunciation | yes |
| 474 | `documents_translation_service` | `immigration_documents` | pronunciation | yes |
| 475 | `documents_update_contact` | `immigration_documents` | pronunciation | yes |
| 476 | `documents_queue_ticket` | `immigration_documents` | pronunciation | yes |
| 477 | `job_hours_per_day` | `job_search` | pronunciation | yes |
| 478 | `job_duties` | `job_search` | pronunciation | yes |
| 479 | `job_application_channel` | `job_search` | pronunciation | yes |
| 480 | `job_days_off` | `job_search` | pronunciation | yes |
| 481 | `job_interview_burmese` | `job_search` | pronunciation | yes |
| 482 | `job_start_tomorrow` | `job_search` | pronunciation | yes |
| 483 | `salary_overtime_included` | `salary` | pronunciation | yes |
| 484 | `salary_night_allowance` | `salary` | my, pronunciation | yes |
| 485 | `salary_daily_wage` | `salary` | pronunciation | yes |
| 486 | `salary_less_than_agreed` | `salary` | pronunciation | yes |
| 487 | `salary_payment_method` | `salary` | pronunciation | yes |
| 488 | `salary_calculation_days` | `salary` | pronunciation | yes |
| 489 | `overtime_can_work` | `overtime` | pronunciation | yes |
| 490 | `overtime_cannot_stay` | `overtime` | pronunciation | yes |
| 491 | `overtime_start_time` | `overtime` | pronunciation | yes |
| 492 | `overtime_break_question` | `overtime` | pronunciation | yes |
| 493 | `overtime_record_start` | `overtime` | pronunciation | yes |
| 494 | `overtime_scheduled_days` | `overtime` | pronunciation | yes |
| 495 | `leave_half_day` | `leave` | pronunciation | yes |
| 496 | `leave_family_business` | `leave` | pronunciation | yes |
| 497 | `leave_request_received` | `leave` | pronunciation | yes |
| 498 | `leave_return_statement` | `leave` | pronunciation | yes |
| 499 | `leave_annual_period` | `leave` | my, pronunciation | yes |
| 500 | `leave_early_today` | `leave` | pronunciation | yes |

Summary: 500 records, 35 categories; 491 records changed. Field change counts: thai=14, thaiMale=11, thaiFemale=10, my=15, pronunciation=491, en=5.

Remaining review concerns after the later source checks: greet_sorry is context-flexible; it can apologize or politely get someone's attention, and context affects interpretation. health_allergy does not name the medicine or symptoms, and health_food_allergy does not name the food. Both allergy records remain LOW / AMBIGUOUS in the record-level audit. Their broad wording must be supplemented with the exact substance and details through a qualified health worker or interpreter. Thai tone fidelity and Myanmar learner comprehensibility still require independent fluent Thai–Myanmar review.

## Follow-up review (2026-09-29)

A second AI-assisted, record-by-record check covered all 500 records, including Thai wording and politeness, English/Myanmar meaning alignment, learner readings, categories, and the high-risk workplace, health, emergency, police, and document groups. It is not independent bilingual certification.

### Corrections in this pass

- `restaurant_water_no_ice`: retained the ID and made the Thai request explicitly say “without ice”; aligned the Myanmar meaning, learner reading, English text, and search terms.
- `health_allergy`: changed the Thai and translations to say “some medicines,” avoiding an implication that every medicine causes an allergy. The phrase still does not name the medicine.
- `health_food_allergy`: aligned the English field to “some foods,” matching the deliberately nonspecific Thai `บางอย่าง` and Myanmar meaning.

### Disposition of earlier flags

- `greet_sorry` retains the useful generic `ขอโทษ` expression for apology or getting attention; its context-dependent use remains a limitation.
- `health_allergy` remains generic and the existing note tells the learner to give the exact medicine and details to a health worker and confirm understanding.
- `health_food_allergy` remains generic (“some foods”); it does not claim a specific ingredient. The app's high-risk caution remains in place.
- These cards help communicate only; they are not medical, legal, immigration, or employment advice.

### Reference checks and limits

Thai lexical spot checks used Longdo entries drawing on NECTEC Lexitron for `น้ำเปล่า`, `น้ำแข็ง`, `ฉุกเฉิน`, `งาน`, `เงิน`, and `แพ้ยา`, plus the Rural Doctor Foundation discussion of how colloquial `แพ้ยา` can be used broadly and needs clarification. Links: [น้ำเปล่า](https://dict.longdo.com/search/%E0%B8%99%E0%B9%89%E0%B8%B3%E0%B9%80%E0%B8%9B%E0%B8%A5%E0%B9%88%E0%B8%B2), [น้ำแข็ง](https://dict.longdo.com/search/%E0%B8%99%E0%B9%89%E0%B8%B3%E0%B9%81%E0%B8%82%E0%B9%87%E0%B8%87), [ฉุกเฉิน](https://dict.longdo.com/search/%E0%B8%89%E0%B8%B8%E0%B8%81%E0%B9%80%E0%B8%89%E0%B8%B4%E0%B8%99), [งาน](https://dict.longdo.com/search/%E0%B8%87%E0%B8%B2%E0%B8%99), [เงิน](https://dict.longdo.com/search/%E0%B9%80%E0%B8%87%E0%B8%B4%E0%B8%99), [แพ้ยา](https://dict.longdo.com/search/%E0%B9%81%E0%B8%9E%E0%B9%89%E0%B8%A2%E0%B8%B2), [Rural Doctor Foundation article](https://www.doctor.or.th/article/detail/4362).

These references check Thai word meanings and selected ambiguities; they do not validate every sentence's naturalness or certify the Myanmar readings. Thai tone and vowel detail remain approximate in Myanmar script. No independent fluent Thai–Myanmar reviewer has signed off on all 500 records.

## Additional source-backed follow-up: Burmese speaker pronouns (2026-09-29)

A corpus-wide check across all 500 records found six entries where the Thai female form uses `ฉัน` but the Myanmar meaning explicitly uses the masculine first-person `ကျွန်တော်` form. A further police phrase translated “my phone is missing” without expressing ownership. The seven Myanmar fields below now show both speaker-gender options or restore the first-person possessive:

| ID | Focused correction |
|---|---|
| `daily_contact` | Added the corresponding feminine form alongside the masculine “call me” form. |
| `time_my_turn` | Added the corresponding feminine first-person form. |
| `transport_wrong_destination` | Added the feminine first-person form used in the Thai variant. |
| `boss_leave_status` | Added a female-speaker option for “my leave request.” |
| `boss_duties_today` | Added a female-speaker option for “my duties.” |
| `emergency_location` | Added a female-speaker option for “I am at …”. |
| `police_lost_phone` | Restored “my” and represented male/female Burmese first-person options. |

The Northern Illinois University SEASite beginner Burmese vocabulary list explicitly distinguishes `ကျွန်တော်` (“I,” spoken by a male) from `ကျွန်မ` (“I,” spoken by a female): [Burmese Lesson 1 vocabulary](https://seasite.niu.edu/Burmese/Beginning/Blesson_1/nwords.htm). The slash notation follows the existing paired form in `number_phone_digits`. This source verifies the pronoun distinction, not complete-sentence naturalness. Confidence is **medium** for this focused alignment correction; the Burmese phrasing and the remaining corpus still need native review.

This pass changed seven `my` fields. Thai, English, and pronunciation fields were not changed. Four of the seven records carry the existing `high-risk` tag. The source checks remain lexical/phonological spot checks and do not externally validate all 500 Thai sentences, Myanmar translations, or readings. No independent fluent Thai–Myanmar reviewer has signed off on the corpus.

## Additional source-backed follow-up: Thai reading consistency (2026-09-29)

A corpus-wide consistency check applied the existing reading conventions in [CONTENT_GUIDE.md](CONTENT_GUIDE.md): ไม่ is rendered မိုင့်, and the question particle ไหม is rendered မိုင်. Among the 500 records, 43 contain ไม่, 189 use the question particle ไหม (excluding the separate word ไหม้, “burn”), and 151 contain ได้. The audit found three readings that rendered ไม่ as မိုင် (greet_no_problem, street_no_chili, and street_sauce_not_spicy) and one reading that omitted ได้ไหม (pharmacy_expiry_date). The four Myanmar-script readings now follow the project convention and include the missing syllables.

The Longdo entry, including its Royal Institute dictionary section, distinguishes question-particle ไหม from ไหม้ (“burn”): [Longdo ไหม / ไหม้](https://dict.longdo.com/search/%E0%B9%84%E0%B8%AB%E0%B8%A1). The NECTEC Thai language standard describes Thai's five tones and explains that tone is determined by more than tone marks alone, including initial consonant and syllable ending: [NECTEC Thai Language standard](https://www.nectec.or.th/it-standards/thaistd.pdf). These references support lexical distinction and the caution about tone representation; the four changes are project-convention consistency and a completeness repair, not evidence that every Myanmar-script reading is phonetically exact or human-verified.

This pass changed four pronunciation fields. No Thai, Myanmar meaning, or English fields changed in this pass. The review remains provisional; no independent fluent Thai–Myanmar reviewer has verified every reading or all 500 complete records.
## Record-level V2 audit snapshot (2026-09-29)

[CONTENT_V2_AUDIT.json](CONTENT_V2_AUDIT.json) contains one entry for each of the 500 records, compared with the user-provided starting main SHA. Each row retains original and proposed-final Thai, male/female Thai forms, Myanmar meaning, Myanmar-script reading, English context, field-level change flags, high-risk status, source-check IDs, confidence, and a remaining concern where one was identified. The snapshot reports 35 categories and 191 high-risk records.

For this V2 branch relative to starting main, field counts are: Thai text 0; Thai male form 0; Thai female form 0; Myanmar meaning 7; Myanmar-script pronunciation 4; English 0. The seven Myanmar fields align Burmese speaker pronouns/ownership; the four pronunciation fields repair three readings inconsistent with the documented ไม่/ไหม convention and one omitted ได้ไหม sequence. No phrases or categories were added.

The added research resolves the context note for greet_sorry: Longdo's NECTEC and Royal Institute entries describe ขอโทษ as a polite apology/response to an offense, and the entry also lists “excuse me”: [Longdo ขอโทษ](https://dict.longdo.com/search/%E0%B8%82%E0%B8%AD%E0%B9%82%E0%B8%97%E0%B8%A9). The phrase remains unchanged and MEDIUM confidence because the expression is context-flexible.

For health_allergy, the Longdo/NECTEC entry defines แพ้ยา as being allergic: [Longdo แพ้ยา](https://dict.longdo.com/search/%E0%B9%81%E0%B8%9E%E0%B9%89%E0%B8%A2%E0%B8%B2). A Rural Doctor Foundation article explains that colloquial use can be broad and advises asking which medicine and what symptoms occurred: [Rural Doctor Foundation: แพ้ยา](https://www.doctor.or.th/article/detail/4362). The existing Myanmar note asks the speaker to provide exact details to a health worker and confirm understanding. This supports keeping the phrase as a general communication prompt; it does not make the card medical advice.

For health_food_allergy, a Siriraj Hospital / Mahidol University health page describes food allergy and gives examples of foods: [Siriraj Hospital: food allergy](https://si.mahidol.ac.th/th/healthdetail.asp?aid=977). The phrase remains generic (“some foods”) and does not identify an ingredient. The exact food must be stated in context.

For employment and overtime vocabulary, the Ministry of Labour's Thai page uses terms such as ค่าจ้าง, การทำงานล่วงเวลา, ค่าล่วงเวลา, and วันหยุด: [Ministry of Labour: employee rights](https://www.mol.go.th/employee/%E0%B8%AA%E0%B8%B4%E0%B8%97%E0%B8%98%E0%B8%B4%E0%B8%95%E0%B8%B2%E0%B8%A1%E0%B8%81%E0%B8%8E%E0%B8%AB%E0%B8%A1%E0%B8%B2%E0%B8%A2%E0%B9%81%E0%B8%A3%E0%B8%87%E0%B8%87%E0%B8%B2%E0%B8%99). This checks terminology only and does not validate a learner's legal rights or the full phrases.

The record-level snapshot assigns 498 MEDIUM and 2 LOW / AMBIGUOUS; it assigns no HIGH ratings because the complete corpus has no independent fluent Thai–Myanmar sign-off. External source checks attach only to relevant terms, pronouns, or reading conventions and do not cover every full sentence. The complete language and pronunciation corpus remains PROVISIONAL.
## Additional Thai grammar and high-risk terminology references (2026-09-29)

The Northern Illinois University SEASite Thai-language profile explains pro-drop subject choice, first-person pronouns, negation, yes/no question particles, and polite particles as cues to speaker relationships: [A Profile of the Thai Language](https://seasite.niu.edu/thai/LLF/profile.htm). Its Spoken Thai teaching materials provide long and shortened dialogue examples with pronouns and common question/polite particles: [Spoken Thai, Unit 2 Conversation 1](https://seasite.niu.edu/Thai/spokenthai/unit2/conversation/conver1.htm). The row-level audit associates these references with matching grammar patterns in 489 records; this is general grammar and register evidence, not certification of those complete sentences.

Further lexical checks cover terms in high-risk records: Longdo/NECTEC Lexitron and the Royal Institute dictionary define เอกสาร as a document/paper ([Longdo เอกสาร](https://dict.longdo.com/search/%E0%B9%80%E0%B8%AD%E0%B8%81%E0%B8%AA%E0%B8%B2%E0%B8%A3)); Longdo lists ใบรับรองแพทย์ as a doctor's certificate ([Longdo ใบรับรองแพทย์](https://dict.longdo.com/search/%E0%B9%83%E0%B8%9A%E0%B8%A3%E0%B8%B1%E0%B8%9A%E0%B8%A3%E0%B8%AD%E0%B8%87%E0%B9%81%E0%B8%9E%E0%B8%97%E0%B8%A2%E0%B9%8C)); and Longdo/NECTEC Lexitron and the Royal Institute define ล่วงเวลา as overtime/outside scheduled time ([Longdo ล่วงเวลา](https://dict.longdo.com/search/%E0%B8%A5%E0%B9%88%E0%B8%A7%E0%B8%87%E0%B9%80%E0%B8%A7%E0%B8%A5%E0%B8%B2)). Those lexical checks attach to 11 document-term rows, one medical-certificate row, and two overtime-term rows in the snapshot.

These additional sources improve evidence for recurring Thai grammar and selected specialist vocabulary. They still do not constitute external sentence-by-sentence validation of all 500 rows or independent Thai–Myanmar human review.
