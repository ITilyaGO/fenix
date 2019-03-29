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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 9) do

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "crypted_password"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "section_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name"
    t.integer  "index"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "section_id"
    t.integer  "min_order",   default: 10
  end

  create_table "clients", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tel"
    t.integer  "place_id"
    t.string   "org"
    t.string   "inn"
    t.string   "comment"
    t.string   "online_place"
    t.integer  "online_id"
    t.string   "shipping_company"
    t.string   "contract"
  end

  create_table "logs", force: :cascade do |t|
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "account_id"
  end

  create_table "managers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_line_comments", force: :cascade do |t|
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_line_id"
    t.string   "state"
    t.integer  "account_id"
  end

  create_table "order_lines", force: :cascade do |t|
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "product_id"
    t.integer  "price"
    t.integer  "amount"
    t.integer  "done_amount"
    t.boolean  "ignored",      default: false
    t.string   "ignored_text"
  end

  create_table "order_parts", force: :cascade do |t|
    t.integer  "state"
    t.integer  "boxes",      default: 0
    t.boolean  "transfer",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "section_id"
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.integer  "place_id"
    t.integer  "status"
    t.integer  "all_parts",                           default: 0
    t.integer  "done_parts",                          default: 0
    t.decimal  "total",       precision: 8, scale: 2, default: 0.0
    t.decimal  "done_total",  precision: 8, scale: 2, default: 0.0
    t.boolean  "moscow",                              default: false
    t.string   "track"
    t.datetime "online_at"
    t.integer  "online_id"
    t.boolean  "priority",                            default: false
  end

  create_table "places", force: :cascade do |t|
    t.string   "name"
    t.integer  "city_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "region_id"
  end

  add_index "places", ["name"], name: "index_places_on_name"

  create_table "products", force: :cascade do |t|
    t.string   "name"
    t.integer  "price"
    t.string   "des"
    t.string   "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",      default: true
    t.integer  "num_photos",  default: 0
    t.integer  "height"
    t.integer  "index"
    t.integer  "parent_id"
    t.integer  "min_order"
  end

  create_table "regions", force: :cascade do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "manager_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roundtrips", force: :cascade do |t|
    t.datetime "start_at"
    t.integer  "place_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "timelines", force: :cascade do |t|
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "duration"
    t.string   "comment"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "immediate",  default: true
  end

end
