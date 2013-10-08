# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131008064416) do

  create_table "achieve_counts", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "chapter_id"
    t.integer  "round_id"
    t.integer  "prop_id"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "achieve_counts", ["chapter_id"], :name => "index_achieve_counts_on_chapter_id"
  add_index "achieve_counts", ["course_id"], :name => "index_achieve_counts_on_course_id"
  add_index "achieve_counts", ["prop_id"], :name => "index_achieve_counts_on_prop_id"
  add_index "achieve_counts", ["round_id"], :name => "index_achieve_counts_on_round_id"
  add_index "achieve_counts", ["user_id"], :name => "index_achieve_counts_on_user_id"

  create_table "achieve_data", :force => true do |t|
    t.string   "name"
    t.string   "requirement"
    t.string   "img"
    t.integer  "points"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "achieves", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "achieve_data_id"
    t.integer  "point"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "achieves", ["achieve_data_id"], :name => "index_achieves_on_achieve_data_id"
  add_index "achieves", ["course_id"], :name => "index_achieves_on_course_id"
  add_index "achieves", ["user_id"], :name => "index_achieves_on_user_id"

  create_table "branch_questions", :force => true do |t|
    t.text     "branch_content"
    t.string   "answer"
    t.string   "options"
    t.integer  "question_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "types",          :limit => 1
  end

  add_index "branch_questions", ["question_id"], :name => "index_branch_questions_on_question_id"

  create_table "buy_records", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "prop_id"
    t.integer  "count"
    t.integer  "gold"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "buy_records", ["course_id"], :name => "index_buy_records_on_course_id"
  add_index "buy_records", ["prop_id"], :name => "index_buy_records_on_prop_id"
  add_index "buy_records", ["user_id"], :name => "index_buy_records_on_user_id"

  create_table "cardbag_tag_card_relations", :force => true do |t|
    t.integer  "cardbag_tag_id"
    t.integer  "card_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cardbag_tag_card_relations", ["card_id"], :name => "index_cardbag_tag_card_relations_on_card_id"
  add_index "cardbag_tag_card_relations", ["cardbag_tag_id"], :name => "index_cardbag_tag_card_relations_on_cardbag_tag_id"

  create_table "cardbag_tags", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.string   "name"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cardbag_tags", ["course_id"], :name => "index_carbag_tags_on_course_id"
  add_index "cardbag_tags", ["user_id"], :name => "index_carbag_tags_on_user_id"

  create_table "chapters", :force => true do |t|
    t.integer  "course_id"
    t.string   "name"
    t.string   "img"
    t.integer  "round_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",      :limit => 1, :default => 0
  end

  add_index "chapters", ["course_id"], :name => "index_chapters_on_course_id"

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.string   "press"
    t.text     "description"
    t.string   "img"
    t.integer  "types"
    t.integer  "time_ratio"
    t.integer  "blood"
    t.integer  "max_score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "round_time"
    t.integer  "status",      :limit => 1, :default => 0
    t.integer  "round_count"
  end

  create_table "everyday_tasks", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "day"
    t.datetime "update_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "everyday_tasks", ["course_id"], :name => "index_everyday_tasks_on_course_id"
  add_index "everyday_tasks", ["user_id"], :name => "index_everyday_tasks_on_user_id"

  create_table "friends", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "friends", ["friend_id"], :name => "index_friends_on_friend_id"
  add_index "friends", ["user_id"], :name => "index_friends_on_user_id"

  create_table "knowledge_cards", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "course_id"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "knowledge_cards", ["course_id"], :name => "index_knowledge_cards_on_course_id"

  create_table "props", :force => true do |t|
    t.integer  "course_id"
    t.string   "name"
    t.text     "description"
    t.integer  "price"
    t.integer  "types"
    t.string   "question_types"
    t.string   "img"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "status",         :default => false
  end

  add_index "props", ["course_id"], :name => "index_props_on_course_id"

  create_table "questions", :force => true do |t|
    t.text     "content"
    t.integer  "types"
    t.integer  "knowledge_card_id"
    t.integer  "round_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["round_id"], :name => "index_questions_on_round_id"

  create_table "round_scores", :force => true do |t|
    t.integer  "user_id"
    t.integer  "chapter_id"
    t.integer  "round_id"
    t.integer  "score"
    t.datetime "day"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "round_scores", ["chapter_id"], :name => "index_round_scores_on_chapter_id"
  add_index "round_scores", ["round_id"], :name => "index_round_scores_on_round_id"
  add_index "round_scores", ["user_id"], :name => "index_round_scores_on_user_id"

  create_table "rounds", :force => true do |t|
    t.integer  "chapter_id"
    t.string   "name"
    t.integer  "questions_count"
    t.integer  "round_time"
    t.integer  "time_ratio"
    t.integer  "blood"
    t.integer  "max_score"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "course_id"
    t.integer  "status",          :limit => 1, :default => 0
  end

  add_index "rounds", ["chapter_id"], :name => "index_rounds_on_chapter_id"

  create_table "user_cards_relations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "knowledge_card_id"
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cardbag_tag_id"
  end

  add_index "user_cards_relations", ["user_id"], :name => "index_user_cards_relations_on_user_id"

  create_table "user_course_relations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "cardbag_count"
    t.integer  "cardbag_use_count"
    t.integer  "gold"
    t.integer  "gold_total"
    t.integer  "level"
    t.integer  "achieve_point"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_course_relations", ["course_id"], :name => "index_user_course_relations_on_course_id"
  add_index "user_course_relations", ["user_id"], :name => "index_user_course_relations_on_user_id"

  create_table "user_mistake_questions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "course_id"
    t.integer  "question_id"
    t.datetime "wrong_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_mistake_questions", ["course_id"], :name => "index_user_mistake_questions_on_course_id"
  add_index "user_mistake_questions", ["question_id"], :name => "index_user_mistake_questions_on_question_id"
  add_index "user_mistake_questions", ["user_id"], :name => "index_user_mistake_questions_on_user_id"

  create_table "user_prop_relations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "prop_id"
    t.integer  "user_prop_num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_prop_relations", ["prop_id"], :name => "index_user_prop_relations_on_prop_id"
  add_index "user_prop_relations", ["user_id"], :name => "index_user_prop_relations_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "name"
    t.datetime "birthday"
    t.boolean  "sex"
    t.string   "img"
    t.string   "phone"
    t.integer  "weibo_id"
    t.datetime "weibo_time"
    t.integer  "types"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
